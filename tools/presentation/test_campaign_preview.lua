-- Reuse the existing actual Parser/Goal/Step + native advancement/registration
-- harness. Its completed baseline tests remain regression coverage for the pilot.
dofile('tools/presentation/test_campaign_advancement.lua')
local root=arg[1] or 'ZygorGuidesViewerRM'
local ZGV=ZygorGuidesViewer
assert(loadfile(root..'/CampaignPreview.lua'))()
local P,C=ZGV.CampaignPreview,ZGV.CampaignData
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read(root..'/ZygorGuidesViewer.lua')
for _,name in ipairs({'SetGuide','GetRememberedGuideStep'}) do
 local body=assert(source:match('function me:'..name..'%b()%s*\n.-\nend'))
 assert(loadstring('local me,ZGV=...;local L=me.L;local tinsert=table.insert;'..body))(ZGV,ZGV)
end
ZygorGuidesViewerFrame_Border_GuideButton={UnlockHighlight=function()end}
ZGV.Print=function()end
function ZGV:GetGuideByTitle(name)for _,g in ipairs(self.registeredguides)do if g.title==name then return g end end end
local t=1000
GetTime=function()return t end
local names={'A','B','C','D','E'}
local levels={18,18,18,18,18}
local connected={true,true,true,true,true}
local raidCount=0
local raidOrder={3,5,1,4,2} -- player is deliberately not raid1
local function index(unit)
 if unit=='player'then return 1 end
 local party=unit:match('party(%d+)');if party then return tonumber(party)+1 end
 local raid=unit:match('raid(%d+)');return raid and raidOrder[tonumber(raid)]
end
GetNumRaidMembers=function()return raidCount end
GetNumPartyMembers=function()return raidCount==0 and 4 or 0 end
UnitExists=function(u)return levels[index(u)]~=nil end
UnitIsConnected=function(u)return connected[index(u)]end
UnitName=function(u)if raidCount>0 then assert(not u:match('^party'),'raid observer assumed party slots')end;return names[index(u)]end
UnitGUID=function(u)return 'GUID-'..tostring(names[index(u)])end
UnitLevel=function(u)return levels[index(u)] or 0 end
UnitIsDeadOrGhost=function()return false end
local inventory={}
GetItemCount=function(id)return inventory[id] or 0 end
ZGV.Frame.shown=true
ZGV.Frame.Show=function(self)self.shown=true end;ZGV.Frame.Hide=function(self)self.shown=false end
ZGV.Frame.IsShown=function(self)return self.shown end;ZGV.Frame.IsVisible=ZGV.Frame.IsShown
local cleared,pointed=0,0
ZGV.ConnectedWaypointer={setwaypoint=function(_,value)if value==false then cleared=cleared+1 else pointed=pointed+1 end end}
ZGV.IsWaypointAddonReady=function()return true end
ZGV.db.profile.waypointaddon='test'
local waypoint=assert(read(root..'/Waypoints.lua'):match('function me:SetWaypoint%b()%s*\n.-\nend'))
assert(loadstring('local me,ZGV=...;'..waypoint))(ZGV,ZGV)
local report=assert(loadfile('tools/presentation/fixtures/preview/synthetic.lua'))()
local policy={policy_version=1,provisional=true,source_sha256=report.provenance.source_sha256,return_owner='interlude-owner',return_checkpoint='INTERLUDE.OBSERVED',return_quests={900},roster={'A','B','C','D','E'},min_level=18,
 gates={prior={owner='prior-owner',kind='external-checkpoint',checkpoint_id='PREVIOUS.FULL'},entry={owner='prior-owner',kind='predecessor-and-party'},returned={owner='interlude-owner',kind='return-and-readiness'},pause={owner='campaign-owner',kind='full-pause'},combat={owner='mechanics-owner',kind='combat-readiness'}},
 entry_gates={'prior','entry'},return_gates={'returned'},step_gates={['TEST/kill']={'combat'}},
 step_conditions={['TEST/conditional']={['not']={quest_rewarded=908}}},
 pause={at_step='TEST/pause',gates={'pause'},dispatch_registration='Synthetic interlude'},
 passages={opening={anchor='TEST/start',view_index=0,activation=true},
 accepted={anchor='TEST/start',view_index=0},earned={anchor='TEST/earned',view_index=0,producers={'TEST/producer'},recover_reward=true},
 paused={anchor='TEST/pause',view_index=0,activation=true},returned={anchor='TEST/return',view_index=1,activation=true}}}
local copy=C:PreviewTools().copy
local versioned=copy(policy,{},{n=0,bytes=0},0);versioned.policy_version=2
assert(not C:RegisterPreview(report,versioned),'unknown policy version accepted')
local invalid=copy(policy,{},{n=0,bytes=0},0);invalid.entry_gates={'entry'}
assert(not C:RegisterPreview(report,invalid),'predecessor declaration weakened by readiness flag')
invalid=copy(policy,{},{n=0,bytes=0},0);invalid.passages.returned.producers={'TEST/producer'}
assert(not C:RegisterPreview(report,invalid),'cross-view producer leaked return eligibility')
assert(not C:RegisterPreview(report,{guide_id='TEST',split_after='TEST/pause',required_gates={'entry'}}),'requirements profile became runtime permission')
for _,mutate in ipairs({
 function(r)for _,m in ipairs(r.views[1].goals)do if m.action=='use_item'then m.source_goal.complete_when=nil end end end,
 function(r)r.views[1].goals[2].source_goal.to=nil end,
 function(r)r.views[1].narration[1].requires=false end,
 function(r)r.views[1].goals[1].source_goal.only_if=false end,
})do
 local bad=copy(report,{},{n=0,bytes=0},0);mutate(bad)
 assert(not C:RegisterPreview(bad,policy),'malformed preview admitted or partially registered')
end
assert(C:RegisterPreview(report,policy))
local opening='WoW Solo Adventure Preview\\TEST\\View 1'
local continuation='WoW Solo Adventure Preview\\TEST\\View 2'
local g1,g2=ZGV:GetGuideByTitle(opening),ZGV:GetGuideByTitle(continuation)
InviteUnit=function()error('must not reform group')end
ConvertToRaid=InviteUnit;LeaveParty=InviteUnit
local partySignature=P:Roster(policy);assert(partySignature and partySignature:find('party;',1,true)==1)
raidCount=5
local raidSignature,actors=P:Roster(policy);assert(raidSignature and #actors==5 and raidSignature:find('raid;',1,true)==1)
raidOrder={5,1,4,2,3};assert(P:Roster(policy)==raidSignature,'raid slot order changed identity')
connected[5]=false;assert(not P:Roster(policy),'disconnected Playerbot became ready');connected[5]=true
raidCount=6;assert(not P:Roster(policy),'unexpected raid member was accepted');raidCount=5
-- All positive guard tests now use the real five-unit RAID layout, not party1..4.
ZGV:EnsureGuideParsed(g1);ZGV:EnsureGuideParsed(g2)
assert(ZGV:GetCampaignGuideStatus(opening).state=='bound')
assert(ZGV:GetCampaignGuideStatus(continuation).state=='bound')
local legacy=ZGV.CurrentGuide
assert(ZGV:SetGuide(opening)==false and ZGV.CurrentGuide==legacy,'missing evidence admitted entry')
for i,g in ipairs(ZGV.registeredguides)do if g==g1 then assert(ZGV:SetGuide(i,7)==false,'numeric entry bypassed guard')end end
local gates={prior=true,entry=true,returned=true,pause=true,combat=true}
local stale=false
local foreignPolicy=false
local returnMode='observed-return'
local corruptReturn=false
P:SetEvidenceProvider(function(request)
 local result={source_sha256=request.source_sha256,policy_version=foreignPolicy==true and 2 or request.policy_version,policy_sha256=foreignPolicy=='hash' and 'foreign' or request.policy_sha256,roster=request.roster,session=request.session,observed_at=t-(stale and 31 or 0),gates={}}
 result.return_record={mode=returnMode,suspension_id=request.suspension_id,owner='interlude-owner',provenance='synthetic return',date='synthetic-date',safe_location='synthetic-hub',
  quest_states={},levels={A=18,B=18,C=18,D=18,E=18},checkpoints={['INTERLUDE.OBSERVED']=true},observations_verified=true}
 for _,name in ipairs(policy.roster)do result.return_record.quest_states[name]={[900]={active=false,rewarded=true}}end
 if returnMode=='safe-fallthrough' then result.return_record.checkpoints={};result.return_record.reason='synthetic safe postponement';result.return_record.observations_verified=false end
 if corruptReturn then result.return_record.quest_states.E=nil end
 for name,definition in pairs(policy.gates)do result.gates[name]={verified=gates[name],owner=definition.owner,kind=definition.kind,checkpoint_id=definition.checkpoint_id,provenance='synthetic test evidence'}end
 return result
end)
ZGV.db.char={guides_history={},permaCompletedDailies={}}
for _,mutate in ipairs({function()levels[2]=17 end,function()levels[3]=nil end,function()connected[4]=false end,function()names[5]='substitute'end})do
 levels={18,18,18,18,18};connected={true,true,true,true,true};names={'A','B','C','D','E'};mutate()
 assert(ZGV:SetGuide(opening,7)==false and ZGV.CurrentGuide==legacy)
end
levels={18,18,18,18,18};connected={true,true,true,true,true};names={'A','B','C','D','E'}
gates.prior=nil;assert(ZGV:SetGuide(g1,7)==false);gates.prior=true
gates.entry='UNKNOWN';assert(ZGV:SetGuide(g1,7)==false);gates.entry=true
stale=true;assert(ZGV:SetGuide(opening,7)==false);stale=false
foreignPolicy=true;assert(ZGV:SetGuide(opening,7)==false,'foreign policy evidence authorized entry')
foreignPolicy='hash';assert(ZGV:SetGuide(opening,7)==false,'foreign policy hash authorized entry');foreignPolicy=false
assert(ZGV:SetGuide(continuation)==false,'direct continuation bypassed suspension')
ZGV.questsbyid={};ZGV.completedQuests={};C:ObserveQuestLog({});C:ObserveCompletedQuests({})
ZGV:SetGuide(opening,7)
assert(ZGV.CurrentGuide==g1 and ZGV.CurrentStepNum==1,'forward selection bypassed unresolved work')
assert(#C:CollectAdmitted(opening)==1,'guarded activation did not authorize opening context')
local function log(q)
 ZGV.questsbyid=q;C:ObserveQuestLog(q)
end
local function rewards(q)
 ZGV.completedQuests=q;C:ObserveCompletedQuests(q)
end
local active={index=1,complete=false,goalsNamed={},goals={{num=0,needed=2}}}
log({[900]=active});ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==2 and #C:CollectAdmitted(opening)==2)
assert(not P:CanNavigate(),'hidden arrival created a target-derived arrow')
ZGV:SetWaypoint();assert(cleared>0)
-- Use the existing native arrival observer without a second routing engine.
local travel=ZGV.CurrentStep.goals[1]
assert(travel.force_noway and tonumber(travel.dist)==0.5 and not travel.force_nocomplete)
ZGV.recentlyVisitedCoords[travel]=true -- native travel state; not story/checkpoint proof
-- A manually marked travel row must not bypass guarded progression.
ZGV.recentlyStickiedGoals[travel]=true;assert(ZGV:SkipStep(1,true)==false)
ZGV.recentlyStickiedGoals={}
-- Test arrival at the native method boundary with the actual native goal.
local nativeTravelComplete=travel.IsComplete
travel.IsComplete=function()return true,true end
ZGV:TryToCompleteStep(true);travel.IsComplete=nativeTravelComplete
assert(ZGV.CurrentStepNum==3)
inventory[901]=99;ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==3,'bag count impersonated objective')
active.goals[1].num=2;log({[900]=active});ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==4)
inventory[903]=1;C:ObservePlayerFacts()
local objectResult=false
for _,entry in ipairs(C:CollectAdmitted(opening))do if entry.id=='object-result'then objectResult=true end end
assert(objectResult,'fresh interaction consequence lost narration')
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==4,'one concurrent condition skipped another')
inventory[907]=2;C:ObservePlayerFacts();ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==5)
assert(ZGV.CurrentStep.goals[1].useitemid==904 and ZGV.CurrentStep.goals[1].force_nocomplete,'native item affordance missing')
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==5,'use command replaced its result proof')
active.complete=true;log({[900]=active});rewards({});log({});rewards({[900]=true})
ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==6)
local entries=C:CollectAdmitted(opening);local earned=false
for _,p in ipairs(entries)do if p.id=='earned'then earned=true end;assert(p.id~='returned')end
assert(earned,'producer reward lost the later anchor')
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==7)
gates.pause=nil;assert(ZGV:SkipStep(1,true)==false and not ZGV.db.char.campaignPreview,'unknown pause dispatched')
gates.pause=true
ZGV:RegisterGuide('Synthetic interlude','step\nlabel "interlude"\naccept Quest##990\n')
ZGV:SkipStep(1,true)
assert(ZGV.CurrentGuideName=='Synthetic interlude' and ZGV.db.char.campaignPreview.guides.TEST.state=='suspended')
local pauseRecord=ZGV.db.char.campaignPreview
local savedSuspension=C:PreviewTools().copy(ZGV.db.char,{},{n=0,bytes=0},0)
local retained=ZGV.CampaignDelivery:Context(ZGV.CurrentGuideName)
assert(retained and retained.registration==opening and retained.id~='returned','guide exit lost or leaked story')
corruptReturn=true;assert(ZGV:SetGuide(continuation)==false,'missing companion quest evidence admitted return');corruptReturn=false
assert(ZGV:SetGuide(continuation)==nil and ZGV.CurrentGuide==g2)
assert(pauseRecord.guides.TEST.state=='returned' and pauseRecord.guides.TEST.return_evidence.returned.provenance)
returnMode='contradictory';assert(ZGV:SetGuide(continuation)==false)
returnMode='safe-fallthrough';assert(ZGV:SetGuide(continuation)==nil)
assert(pauseRecord.guides.TEST.return_mode=='safe-fallthrough' and not C:IsCheckpointProven(continuation,'INTERLUDE.OBSERVED'))
returnMode='observed-return'
entries=C:CollectAdmitted(continuation);local returned=false
for _,p in ipairs(entries)do if p.id=='returned'then returned=true end end
assert(returned,'verified continuation did not admit return context')
gates.combat=nil;ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1,'unknown combat readiness permitted a hunt')
log({[905]={index=1,complete=false,goalsNamed={},goals={{num=0,needed=3}}}})
gates.combat=true;ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==2)
connected[2]=false;C:ObservePlayerFacts();assert(not ZGV.Frame:IsShown() and not P:CanRun(),'roster loss did not close active view')
local held=ZGV.CurrentStepNum
assert(ZGV:FocusStep(3)==false and ZGV:SkipStep(1,true)==false and ZGV:SetGuide(continuation,3)==false and ZGV.CurrentStepNum==held,'an alternative entry bypassed roster loss')
assert(#ZGV:GetPresentationSnapshot().goals==0,'guarded preview exposed objectives')
connected[2]=true;C:ObservePlayerFacts();assert(ZGV.Frame:IsShown())
local kill={index=1,complete=false,goalsNamed={},goals={{num=3,needed=3}}}
log({[905]=kill});rewards({[900]=true,[905]=true});ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==3,'known false reward condition was not handled safely')
local beforeUnknown=ZGV.CurrentStepNum
-- Before an initial fresh quest response, NOT cannot manufacture visibility.
local originalFacts=C.PreviewFacts
C.PreviewFacts=function(self)
 local facts=originalFacts(self);local rewards={}
 for id,v in pairs(facts.rewards)do if id~=908 then rewards[id]=v end end
 facts.rewards=rewards;return facts
end
assert(ZGV:FocusStep(3)==false and ZGV.CurrentStepNum==beforeUnknown)
C.PreviewFacts=originalFacts
rewards({[900]=true,[905]=true,[908]=true});ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStep.finish,'known false visibility was not safely excluded')
C:ObservePlayerFacts();assert(ZGV.Frame:IsVisible(),'completed preview was hidden by observation refresh')
-- A changed source or stale record cannot substitute for a fresh owner return.
local saved=ZGV.db.char.campaignPreview.guides.TEST
saved.source_sha256='changed';assert(ZGV:SetGuide(continuation)==false);saved.source_sha256=report.provenance.source_sha256
local policyHash=saved.policy_sha256;saved.policy_sha256='changed';assert(ZGV:SetGuide(continuation)==false);saved.policy_sha256=policyHash
saved.policy_version=2;assert(ZGV:SetGuide(continuation)==false);saved.policy_version=1
gates.returned=nil;assert(ZGV:SetGuide(continuation)==false);gates.returned=true
-- Explicit recovery is reward-only, view-scoped and does not recreate expired setup.
ZGV.db.char={guides_history={},permaCompletedDailies={}}
ZGV.CurrentGuide=legacy;ZGV.CurrentGuideName=legacy.title;ZGV.CurrentStep=legacy.steps[1];ZGV.CurrentStepNum=1
C:ObserveQuestLog({});C:ObserveCompletedQuests({[900]=true})
ZGV:SetGuide(opening)
entries=C:CollectAdmitted(opening);earned=false
for _,p in ipairs(entries)do if p.id=='earned'then earned=true end;assert(p.id~='accepted' and p.id~='returned')end
assert(earned,'scoped earned recovery failed')
-- Restoring a suspension retains pending text without revealing the return or
-- treating a saved bookmark as authority. A new owner observation is mandatory.
ZGV.db.char=savedSuspension
ZGV.CurrentGuide=legacy;ZGV.CurrentGuideName=legacy.title;ZGV.CurrentStep=legacy.steps[1];ZGV.CurrentStepNum=1
C:ObserveQuestLog({});C:ObserveCompletedQuests({[900]=true})
assert(ZGV:SetGuide(opening)==false,'suspended opening relaunched on restore')
gates.returned=nil;assert(ZGV:SetGuide(continuation)==false)
for _,p in ipairs(C:CollectAdmitted(continuation))do assert(p.id~='returned')end
gates.returned=true;t=t+5;ZGV:SetGuide(continuation)
assert(ZGV.CurrentGuide==g2,'fresh owner archive verification did not resume')
local count=#C:CollectAdmitted(continuation)
ZGV:FocusStep(1);assert(#C:CollectAdmitted(continuation)==count,'reopening duplicated narration')
print('PASS preview: extended bindings, strict five-member/source/session evidence, guarded entry/skip/pause/return, producer anchors, scoped recovery and navigation suppression; synthetic evidence only')

-- A valid explicit destination still delegates to the existing waypointer.
-- This is an in-memory synthetic variant, not a private campaign mutation.
local visible=copy(report,{},{n=0,bytes=0},0)
visible.guide.id='NAV'
visible.provenance.source_sha256=ZGV:CampaignPayloadHash('synthetic visible navigation variant')
for _,view in ipairs(visible.views) do
 view.native_text=view.native_text:gsub(' |noway','')
 view.payload_sha256=ZGV:CampaignPayloadHash(view.native_text)
 for _,m in ipairs(view.goals) do if m.action=='travel' then m.source_goal.to.show_waypoint=true end end
end
local navPolicy=copy(policy,{},{n=0,bytes=0},0);navPolicy.source_sha256=visible.provenance.source_sha256
assert(C:RegisterPreview(visible,navPolicy))
local before=pointed
ZGV:SetGuide('WoW Solo Adventure Preview\\NAV\\View 1',2)
assert(P:CanNavigate() and pointed>before,'explicit preview destination did not reach native waypointer')

-- Optional private-source binding audit; never executes its quest progression,
-- injects permission, prints its prose, or writes it into the repository.
if arg[2] then
 local private=assert(loadfile(arg[2]))()
 assert(C:RegisterPreview(private)) -- no policy -> permanently locked
 local count=0
 for i,v in ipairs(private.views)do
  local name='WoW Solo Adventure Preview\\'..private.guide.id..'\\View '..i
  local guide=ZGV:GetGuideByTitle(name)
  ZGV:EnsureGuideParsed(guide)
  local status=ZGV:GetCampaignGuideStatus(name)
  assert(status.state=='bound',status.code or 'private binding failed')
  assert(ZGV:SetGuide(name)==false,'private report or requirements became permission')
  assert(#C:CollectAdmitted(name)==0)
  count=count+#v.goals
 end
 assert(#private.views==2 and count==48)
 print('PASS private preview: both bounded views and every action mapping bind; all activation and narrative remain blocked')
end
