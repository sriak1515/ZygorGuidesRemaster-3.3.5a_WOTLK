-- Contract 1 interoperability and persisted authorization isolation; synthetic only.
dofile('tools/presentation/test_campaign_advancement.lua')
local root=arg[1] or 'ZygorGuidesViewerRM'
assert(loadfile(root..'/CampaignPreview.lua'))()
local ZGV=ZygorGuidesViewer
local P,C,A=ZGV.CampaignPreview,ZGV.CampaignData,ZGV.CampaignAdmission
local function copy(v)return C:PreviewTools().copy(v,{},{n=0,bytes=0},0)end
local vectors=assert(loadfile('tools/presentation/fixtures/preview/policy-v1-vectors.lua'))()
assert(vectors.policy_version==1 and #vectors.vectors==3)
for _,v in ipairs(vectors.vectors)do
 local hash,bytes=P:PolicyIdentity(v.policy)
 local hex=bytes:gsub('.',function(c)return string.format('%02x',c:byte())end)
 assert(hex==v.canonical_hex,v.name..': canonical bytes differ')
 assert(hash==v.sha256,v.name..': hash differs')
end
local base=vectors.vectors[1].policy
for _,mutate in ipairs({
 function(p)p.policy_sha256=string.rep('0',64)end,
 function(p)p.policy_format_version=1 end,
 function(p)p.policy_version=2 end,
 function(p)p.source_sha256='foreign' end,
 function(p)p.extra=-1 end,function(p)p.extra=0.5 end,
 function(p)p.extra=2147483648 end,function(p)p.extra=0/0 end,
 function(p)p.extra=math.huge end,function(p)p.extra=function()end end,
 function(p)p.extra=string.char(255)end,
 function(p)p.extra=string.char(192,128)end,
 function(p)p.extra=string.char(237,160,128)end,
 function(p)p.extra={[2]='hole'}end,function(p)p.extra={[1]='mixed',key=true}end,
 function(p)p['bad key']=true end,function(p)p.extra=setmetatable({},{})end,
 function(p)p.extra=p end,
 function(p)local c=p;for i=1,34 do c.extra={};c=c.extra end end,
})do
 local p=copy(base);mutate(p)
 assert(not pcall(P.PolicyIdentity,P,p),'out-of-contract identity value accepted')
end
local report=assert(loadfile('tools/presentation/fixtures/preview/synthetic.lua'))()
local function locked(r)
 local p={policy_version=1,provisional=true,locked=true,source_sha256=r.provenance.source_sha256,
  step_conditions=copy(r.source_integration.step_conditions),passages={}}
 for id,c in pairs(r.source_integration.producer_candidates)do
  p.passages[id]={anchor=c.anchor,view_index=c.view_index,producers=copy(c.producers)}
 end
 return p
end
local policy=locked(report)
local function sign(r,p)
 r.policy_identity={policy_version=1,source_sha256=p.source_sha256,policy_sha256=P:PolicyIdentity(p)}
end
assert(P:PolicyIdentity(policy)==report.policy_identity.policy_sha256,'compiler fixture identity diverged')
local registered=#ZGV.registeredguides
for _,mutate in ipairs({
 function(r,p)r.policy_identity=nil end,
 function(r,p)r.policy_identity.policy_sha256=string.rep('0',64)end,
 function(r,p)r.policy_identity.policy_version=2 end,
 function(r,p)r.policy_identity.source_sha256=string.rep('0',64)end,
 function(r,p)p.source_sha256=string.rep('0',64);sign(r,p)end,
 function(r,p)p.step_conditions={};sign(r,p)end,
 function(r,p)p.step_conditions['TEST/extra']={quest_active=900};sign(r,p)end,
 function(r,p)p.step_conditions['TEST/conditional']={quest_rewarded=908};sign(r,p)end,
 function(r,p)r.source_integration.step_conditions={};p.step_conditions={};sign(r,p)end,
 function(r,p)for _,v in ipairs(r.views)do for _,s in ipairs(v.steps)do s.only_if=nil end end end,
 function(r,p)r.views[1].steps[1].only_if={quest_active=900}end,
 function(r,p)p.passages={};sign(r,p)end,
 function(r,p)for _,entry in pairs(p.passages)do entry.activation=true;break end;sign(r,p)end,
 function(r,p)r.source_integration=false end,
})do
 local r,p=copy(report),copy(policy);mutate(r,p)
 assert(not C:RegisterPreview(r,p),'conflicting source/identity definition accepted')
 assert(#ZGV.registeredguides==registered,'rejected definition partially registered')
end
local noProjection=copy(report);noProjection.source_integration=false
assert(not C:RegisterPreview(noProjection),'missing source projection threw or registered')
assert(C:RegisterPreview(report,policy),'compiler locked definition rejected')
local previous=ZGV.CurrentGuide
for _,v in ipairs(report.views)do
 local name='WoW Solo Adventure Preview\\'..report.guide.id..'\\View '..(v.view_index+1)
 local guide
 for _,g in ipairs(ZGV.registeredguides)do if g.title==name then guide=g end end
 assert(guide);ZGV:EnsureGuideParsed(guide)
 assert(ZGV:GetCampaignGuideStatus(name).state=='bound')
 assert(not P:CanAccess(guide) and #C:CollectAdmitted(name)==0,'locked definition granted permission')
end
assert(ZGV.CurrentGuide==previous,'locked binding changed playable selection')

-- Persistent passage/history/checkpoint records cannot carry authorization into
-- another source, condition/policy, character or exact passage revision.
local function metadata(source,p,revision)
 local hash=P:PolicyIdentity(p)
 return {guide={id='ISOLATION'},runtime_scope_hash=ZGV:CampaignPayloadHash(source..hash),
  runtime_checkpoint_access=function()return true end,
  narration={{id='passage',at_step='TEST/anchor',revision=revision,type='moment',text='Synthetic text'}},
  checkpoints={{id='TEST.PROOF',at_step='TEST/anchor',proof={quest_rewarded=900}}}}
end
local original=metadata(policy.source_sha256,policy,string.rep('a',64))
local char={}
local controller=A.New(original,char)
local facts={rewards={[900]=true},log={},known={[900]=true}}
controller:Observe({{source_step_id='TEST/anchor',kind='activation',quest_id=0}},facts)
assert(#controller:Collect()==1 and controller:IsCheckpointProven('TEST.PROOF'))
assert(controller:MarkPresented('passage',string.rep('a',64)))
assert(#controller:History()==1)
local changed=copy(policy);changed.source_sha256=string.rep('1',64)
local changedCondition=copy(policy);changedCondition.step_conditions['TEST/conditional']={quest_rewarded=908}
for _,m in ipairs({
 metadata(changed.source_sha256,changed,string.rep('a',64)),
 metadata(policy.source_sha256,changedCondition,string.rep('a',64)),
 metadata(policy.source_sha256,policy,string.rep('b',64)),
})do
 local other=A.New(m,copy(char))
 assert(#other:Collect()==0 and #other:History()==0,'old passage/history crossed identity or revision')
 assert(not other:MarkPresented('passage',m.narration[1].revision))
 if m.runtime_scope_hash~=original.runtime_scope_hash then
  assert(not other:IsCheckpointProven('TEST.PROOF'),'old checkpoint crossed source/policy')
 end
end
assert(#A.New(original,{}):Collect()==0,'another character inherited admission')
assert(#A.New(original,char):History()==1,'matching restore lost presented history')
local blocked=metadata(policy.source_sha256,policy,string.rep('a',64))
blocked.runtime_checkpoint_access=function()return false end
local denied=A.New(blocked,{})
denied:ObserveCheckpoints(facts)
assert(not denied:IsCheckpointProven('TEST.PROOF'),'missing owner evidence published checkpoint')
print('PASS Policy Contract 1: all three golden byte/hash vectors, strict identity domain, source condition projections, locked consumption, source/policy/revision/character isolation')
