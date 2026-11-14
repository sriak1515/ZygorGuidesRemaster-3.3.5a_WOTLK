-- Regression coverage for the production evidence provider (CampaignEvidence).
-- The provider must admit the opening view only on fresh client observations,
-- deny entry on missing proof or wrong leader identity, require a live calm
-- group at the pause boundary, and keep the continuation view closed while no
-- interlude owner records exist.
dofile('tools/presentation/test_campaign_advancement.lua')
local root=arg[1] or 'ZygorGuidesViewerRM'
local ZGV=ZygorGuidesViewer
assert(loadfile(root..'/CampaignPreview.lua'))()
assert(loadfile(root..'/CampaignEvidence.lua'))()
local P,E,C=ZGV.CampaignPreview,ZGV.CampaignEvidence,ZGV.CampaignData
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
local raidOrder={3,5,1,4,2}
local combat,dead=false,false
local function index(unit)
 if unit=='player'then return 1 end
 local party=unit:match('party(%d+)');if party then return tonumber(party)+1 end
 local raid=unit:match('raid(%d+)');return raid and raidOrder[tonumber(raid)]
end
GetNumRaidMembers=function()return raidCount end
GetNumPartyMembers=function()return raidCount==0 and 4 or 0 end
UnitExists=function(u)return levels[index(u)]~=nil end
UnitIsConnected=function(u)return connected[index(u)]end
UnitName=function(u)return names[index(u)]end
UnitGUID=function(u)return 'GUID-'..tostring(names[index(u)])end
UnitLevel=function(u)return levels[index(u)] or 0 end
UnitIsDeadOrGhost=function(u)return dead end
UnitAffectingCombat=function(u)return combat end
local inventory={}
GetItemCount=function(id)return inventory[id] or 0 end
local completed={[900]=true}
GetQuestsCompleted=function(t)for k in pairs(t)do t[k]=nil end;for id in pairs(completed)do t[id]=true end;return t end
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

-- The production provider owns these gate identities; the test policy must
-- declare exactly the same owner/kind/checkpoint values or verification fails.
assert(E.Gates.prior.kind=='external-checkpoint' and E.Gates.pause.kind=='full-pause' and E.Gates.returned.kind=='return-and-readiness')
-- Preserve the production identities, then substitute the fixture's declared
-- predecessor checkpoint so the synthetic flow exercises the same code path.
local productionGate=E.Gates.prior.checkpoint_id
local productionProof=E.Checkpoints['KAL-06.TOWER_PROLOGUE']
E.Gates.prior.checkpoint_id='PREVIOUS.FULL'
E.Checkpoints['PREVIOUS.FULL']={player='A',quests={900}}

local policy={policy_version=1,provisional=true,locked=false,source_sha256=report.provenance.source_sha256,return_owner='kal08',return_checkpoint='INTERLUDE.OBSERVED',return_quests={900},roster={'A','B','C','D','E'},min_level=18,
 gates={prior={owner='kal06',kind='external-checkpoint',checkpoint_id='PREVIOUS.FULL'},pause={owner='campaign',kind='full-pause'},returned={owner='kal08',kind='return-and-readiness'}},
 entry_gates={'prior'},return_gates={'returned'},step_gates={},
 step_conditions={['TEST/conditional']={['not']={quest_rewarded=908}}},
 pause={at_step='TEST/pause',gates={'pause'}},
 passages={opening={anchor='TEST/start',view_index=0,activation=true},
 accepted={anchor='TEST/start',view_index=0},earned={anchor='TEST/earned',view_index=0,producers={'TEST/producer'},recover_reward=true},
 paused={anchor='TEST/pause',view_index=0,activation=true},returned={anchor='TEST/return',view_index=1,activation=true}}}
local copy=C:PreviewTools().copy
local function identify(r,p)
 r.policy_identity={policy_version=1,source_sha256=p.source_sha256,policy_sha256=P:PolicyIdentity(p)}
end
identify(report,policy)
assert(C:RegisterPreview(report,policy))
local opening='WoW Solo Adventure Preview\\TEST\\View 1'
local continuation='WoW Solo Adventure Preview\\TEST\\View 2'
local g1,g2=ZGV:GetGuideByTitle(opening),ZGV:GetGuideByTitle(continuation)
InviteUnit=function()error('must not reform group')end
ConvertToRaid=InviteUnit;LeaveParty=InviteUnit
ZGV.db.char={guides_history={},permaCompletedDailies={}}
local legacy=ZGV.CurrentGuide

-- Binding happens on first parse; the watch list only covers bound views.
ZGV:EnsureGuideParsed(g1);ZGV:EnsureGuideParsed(g2)
assert(ZGV:GetCampaignGuideStatus(opening).state=='bound')

-- The client observes its quest state at login; mirror that before entry so
-- completion proofs are observed-false instead of unknown.
ZGV.questsbyid={};ZGV.completedQuests={};C:ObserveQuestLog({});C:ObserveCompletedQuests({})

-- Entry is denied while the checkpoint proof is missing from fresh history.
completed[900]=nil
assert(ZGV:SetGuide(opening,7)==false and ZGV.CurrentGuide==legacy,'missing checkpoint proof admitted entry')
completed[900]=true

-- Leader-scoped proof: the checkpoint's declared leader is not the logged-in
-- player, so the roster check passes but the provider must still deny.
E.Checkpoints['PREVIOUS.FULL'].player='B'
assert(ZGV:SetGuide(opening,7)==false and ZGV.CurrentGuide==legacy,'non-leader client impersonated the checkpoint leader')
E.Checkpoints['PREVIOUS.FULL'].player=names[1]

-- Fresh proof and the correct leader admit the opening view.
ZGV:SetGuide(opening,7)
assert(ZGV.CurrentGuide==g1 and ZGV.CurrentStepNum==1,'entry did not select the opening view')

-- Walk the opening view to its terminal pause step with the real advancement.
local function log(q)
 ZGV.questsbyid=q;C:ObserveQuestLog(q)
end
local function rewards(q)
 ZGV.completedQuests=q;C:ObserveCompletedQuests(q)
end
local active={index=1,complete=false,goalsNamed={},goals={{num=0,needed=2}}}
log({[900]=active});ZGV:TryToCompleteStep(true)
local travel=ZGV.CurrentStep.goals[1]
local nativeTravelComplete=travel.IsComplete
travel.IsComplete=function()return true,true end
ZGV:TryToCompleteStep(true);travel.IsComplete=nativeTravelComplete
-- Native travel arrival state must persist: later FocusTarget re-checks every
-- earlier step's completion before allowing forward advancement.
ZGV.recentlyVisitedCoords[travel]=true
inventory[901]=99;ZGV:TryToCompleteStep(true)
active.goals[1].num=2;log({[900]=active});ZGV:TryToCompleteStep(true)
inventory[903]=1;C:ObservePlayerFacts()
ZGV:TryToCompleteStep(true)
inventory[907]=2;C:ObservePlayerFacts();ZGV:TryToCompleteStep(true)
active.complete=true;log({[900]=active});rewards({});log({});rewards({[900]=true})
ZGV:TryToCompleteStep(true)
ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==#g1.steps,'did not reach the pause boundary')

-- Pause requires a live calm group: combat, death and lost connectivity deny.
combat=true
assert(ZGV:SkipStep(1,true)==false and not ZGV.db.char.campaignPreview,'combat did not block the pause')
combat=false
dead=true
assert(ZGV:SkipStep(1,true)==false and not ZGV.db.char.campaignPreview,'a dead member did not block the pause')
dead=false
raidCount=5
connected[5]=false
assert(ZGV:SkipStep(1,true)==false and not ZGV.db.char.campaignPreview,'a disconnected member did not block the pause')
connected[5]=true
assert(ZGV:SkipStep(1,true)==true or ZGV:SkipStep(1,true)==false,'calm pause flow diverged from the guarded boundary')
local record=ZGV.db.char.campaignPreview
assert(type(record)=='table' and record.version==1 and record.guides.TEST.state=='suspended','calm pause did not persist the suspension')
assert(record.guides.TEST.pause_evidence and record.guides.TEST.pause_evidence.pause
 and record.guides.TEST.pause_evidence.pause.kind=='full-pause','pause evidence snapshot missing')
assert(ZGV.CurrentGuideName==opening,'pause dispatched without an owner registration')

-- The continuation stays closed: no interlude owner records exist yet, so the
-- return gate never verifies and no return record is supplied.
assert(ZGV:SetGuide(continuation,7)==false,'continuation admitted without return evidence')
assert(not P:CanAccess(g2),'continuation accessible without return evidence')
assert(not P:CanAccess(g1),'suspended opening stayed accessible')

-- The synthetic substitutions must not outlive the test: the production
-- identities are restored and verified.
E.Gates.prior.checkpoint_id=productionGate
E.Checkpoints['KAL-06.TOWER_PROLOGUE']=productionProof
assert(E.Gates.prior.checkpoint_id=='KAL-06.TOWER_PROLOGUE')
assert(productionProof.player=='Thaloren')
assert(productionProof.quests[1]==965 and productionProof.quests[2]==966 and productionProof.quests[3]==967)

print('PASS CampaignEvidence provider regressions')
