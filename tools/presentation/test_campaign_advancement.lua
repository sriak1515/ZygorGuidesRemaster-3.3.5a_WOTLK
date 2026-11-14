-- Exercise the actual pinned fork parser, goal completion and smart-skip semantics.
local root=assert(arg[1])
local fixtureRoot='tools/presentation/fixtures/v1/'
tinsert,tremove=table.insert,table.remove
function TableKeys(t) local r={} for k in pairs(t) do r[#r+1]=k end return r end
local locale=setmetatable({coords='%s,%s'}, {__index=function(_,k)return k end})
function ZygorGuidesViewer_L(_,_,loader) if loader then for k,v in pairs(loader())do locale[k]=v end end return locale end
assert(loadfile(root..'/Localization/enUS.lua'))()
COLOR_GOAL=function(s)return s end
plural=function(s)return s end
local currentZone='Darkshore'
GetRealZoneText=function() return currentZone end
GetZoneText=GetRealZoneText;GetSubZoneText=function()return ''end;GetMinimapZoneText=GetSubZoneText
QUEST_MONSTERS_KILLED='%s slain: %d/%d'
local levels={player=18,party1=18,party2=18,party3=18,party4=18}
local names={player='Thaloren',party1='Darethia',party2='Lunethra',party3='Faelion',party4='Saerith'}
UnitLevel=function(u)return levels[u] or 0 end
UnitExists=function(u)return levels[u]~=nil end
UnitName=function(u)return names[u]end
UnitRace=function()return 'Night Elf','NightElf'end
UnitClass=function()return 'Druid','DRUID'end
UnitFactionGroup=function()return 'Alliance'end
local inventory={}
GetItemCount=function(id)return inventory[id] or 0 end
ZygorGuidesViewer={BZL={},BSZL={},BFL={},StandingNamesEngRev={},dailyQuests={},instantQuests={},
 completedQuests={},questsbyid={},StepProto_mt={},GoalProto_mt={},maxQuestLevels={},recentlyCompletedGoals={},recentlyStickiedGoals={},
 db={profile={skipimpossible=true,skipobsolete=true,skipauxsteps=true,levelsahead=0},char={permaCompletedDailies={}}},registeredguides={}}
local ZGV=ZygorGuidesViewer
ZGV.L=locale
ZGV.recentlyVisitedCoords={}
ZGV.goalsNamed={}
local px,py=0.01,0.01
GetPlayerMapPosition=function()return px,py end
GetNumQuestLogEntries=function()local n=0 for _ in pairs(ZGV.questsbyid)do n=n+1 end return n end
GetQuestLogTitle=function(i)local n=0 for id in pairs(ZGV.questsbyid)do n=n+1 if n==i then return nil,nil,nil,nil,false,nil,nil,id end end end
function ZGV:GetQuestName()return nil end
function ZGV:RaceClassMatch()return true end
function ZGV:IsQuestPossible()return true end

assert(loadfile(root..'/Goal.lua'))()
assert(loadfile(root..'/Step.lua'))()
assert(loadfile(root..'/Parser.lua'))()
strsplit=function(delimiter,text)
 local t={} for x in (text..delimiter):gmatch('(.-)'..delimiter)do t[#t+1]=x end return unpack(t)
end
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read(root..'/ZygorGuidesViewer.lua')
local group={guides={}}
for _,name in ipairs({'RegisterGuide','EnsureGuideParsed','FocusStep','FocusStepQuiet','SkipStep','TryToCompleteStep'}) do
 local body=assert(source:match('function me:'..name..'%b()%s*\n.-\nend'),name)
 local chunk=assert(loadstring('local me,ZGV=...;local tinsert,tremove=table.insert,table.remove;local time=function() return 0 end;'..body))
 -- FindGroup is a core local; preserve native registration while supplying a simple tree.
 setfenv(chunk,setmetatable({FindGroup=function()return group end},{__index=_G}))
 chunk(ZGV,ZGV)
end
ZGV.registered_groups=group
for _,name in ipairs({'Debug','MarkGuideRecentlyParsed','TrimParsedGuideCache','StopFlashAnimation','ScrollToCurrentStep','UpdateCooldowns','UpdateCartographerExport','AnimateGears'}) do ZGV[name]=function()end end
ZGV.InlineButtonsEnabled=function()return false end
ZGV.IsRemasterSkin=function()return false end
ZGV.ClearRecentActivities=function(self) self.recentlyCompletedGoals={};self.recentlyStickiedGoals={} end
ZGV.Frame={IsVisible=function()return true end,GetAlpha=function()return 1 end}
ZGV.frameNeedsResizing=0
ZGV.db.profile.guidesinhistory=5
ZGV.db.char.guides_history={}
ZGV.completionelapsed=0;ZGV.completioninterval=0.1;ZGV.completionintervallong=0.1;ZGV.completionintervalmin=0.01
ZGV.LastSkip=1
PlaySound=function()end
InCombatLockdown=function()return false end
DeleteMacro=function()end
local waypoints,frames=0,0
ZGV.SetWaypoint=function()waypoints=waypoints+1 end
ZGV.UpdateFrame=function()frames=frames+1 end
assert(loadfile(root..'/CampaignHash.lua'))()
assert(loadfile(root..'/CampaignAdmission.lua'))()
assert(loadfile(root..'/CampaignData.lua'))()
local C=ZGV.CampaignData
assert(ZGV.RegisterCampaignGuideMetadata==nil,'unfinished narrative consumer must not accept installed packages')
assert(ZGV:CampaignPayloadHash('')=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')
assert(ZGV:CampaignPayloadHash('abc')=='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
assert(ZGV:CampaignPayloadHash(string.rep('a',1000))=='41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3')
local raw=read(fixtureRoot..'guide.txt')
local function metadata() return assert(loadfile(fixtureRoot..'narrated.lua'))() end
local registration=metadata().native_views[1].registration
local function fresh()
 assert(loadfile(root..'/CampaignData.lua'))();C=ZGV.CampaignData
 ZGV.registeredguides={};group.guides={}
end
local function register()
 ZGV:RegisterGuide(registration,raw)
 return ZGV.registeredguides[#ZGV.registeredguides]
end
-- Real registration/parse hooks, staging detached from caller mutation.
local m=metadata();assert(C:Stage(m));m.native_views[1].payload_sha256=string.rep('0',64)
assert(not C:Stage(metadata()),'duplicate definition accepted')
assert(ZGV:GetCampaignGuideStatus(registration).state=='staged')
local guide=register()
assert(not guide.parsed and ZGV:GetCampaignGuideStatus(registration).state=='registered')
assert(select(2,ZGV:EnsureGuideParsed(guide)))
assert(ZGV:GetCampaignGuideStatus(registration).state=='bound')
local status=ZGV:GetCampaignGuideStatus(registration);status.state='bad'
assert(ZGV:GetCampaignGuideStatus(registration).state=='bound')
for k in pairs(status) do assert(k=='state' or k=='code' or k=='delivery','private metadata leaked') end
-- Real cache eviction/reparse must replace the bound native objects.
guide.parsed=false;guide.steps=nil
assert(select(2,ZGV:EnsureGuideParsed(guide)))
assert(ZGV:GetCampaignGuideStatus(registration).state=='bound')
-- Native advancement driver with real parser/step/goal implementations.
ZGV.CurrentGuide=guide;ZGV.CurrentGuideName=registration
local observed={}
C:SubscribeAdvancement(function(e)
 assert(ZGV.CurrentStep.label==e.native_label,'old anchor already discarded')
 assert(not e.authorizes_story)
 observed[#observed+1]=e
 e.native_label='mutated by observer'
end)
C:SubscribeAdvancement(function()error('observer failure must not stop progression')end)
local mirrored=0
local unsubscribe=C:SubscribeAdvancement(function(e)
 assert(e.native_label==ZGV.CurrentStep.label,'observer mutated another observer payload')
 mirrored=mirrored+1
end)
ZGV:FocusStep(1)
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1 and #observed==0)
ZGV.questsbyid[456]={index=1,complete=false,goalsNamed={},goals={{num=0,needed=7},{num=0,needed=4}}}
-- Existing visibility, pause and explicit reading guards retain authority.
ZGV.pause=true;ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1 and #observed==0)
ZGV.pause=nil;ZGV.Frame.IsVisible=function()return false end
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1 and #observed==0)
ZGV.Frame.IsVisible=function()return true end
ZGV.ParchmentEnabled=function()return true end
ZGV.Parchment={ReadingActive=function()return true end}
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1 and #observed==0)
ZGV.ParchmentEnabled=nil;ZGV.Parchment=nil
local before=waypoints
ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==2 and ZGV.db.char.step==2 and waypoints>before)
assert(#observed==1 and observed[1].source_step_id=='KAL-01/accept-balance-one')
ZGV.questsbyid[456].goals[1].num=6
ZGV.questsbyid[456].goals[2].num=4
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==2 and #observed==1)
ZGV.questsbyid[456].goals[1].num=7
before=waypoints;ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==3 and waypoints>before and #observed==2)
ZGV.questsbyid[456].complete=true
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==3)
ZGV.completedQuests[456]=true
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==3,'active quest falsely treated as rewarded')
ZGV.questsbyid[456]=nil
before=waypoints;ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==4 and ZGV.CurrentStep.finish and waypoints>before and #observed==3)
assert(observed[3].source_step_id=='KAL-01/reward-balance-one')
assert(ZGV.db.char.guide_progress[registration].step==4 and frames>0)
ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==4 and ZGV.CurrentStep.finish and #observed==3)
-- Browsing and manual navigation do not emit automatic advancement candidates.
ZGV:FocusStep(1);ZGV:SkipStep(1,false);assert(#observed==3)
-- A real automatic skip of an obsolete/ineligible step is classified separately.
ZGV.questsbyid={};ZGV.completedQuests={};ZGV.pause=nil
ZGV.CurrentStep.IsObsolete=function()return true end
ZGV:TryToCompleteStep(true)
assert(#observed==4 and observed[4].reason=='policy-skip' and not observed[4].authorizes_story)
-- Manual completion can drive native advancement but never becomes story proof.
ZGV:FocusStep(1);ZGV.pause=nil
ZGV.recentlyStickiedGoals[ZGV.CurrentStep.goals[3]]=true
ZGV:TryToCompleteStep(true)
assert(#observed==5 and observed[5].manual_mark and not observed[5].authorizes_story)
assert(mirrored==5);unsubscribe()
-- Staged future prose never enters ordinary presentation snapshots.
CreateFrame=function()return {SetScript=function()end}end
assert(loadfile(root..'/Presentation.lua'))()
local function contains(value,needle)
 if type(value)=='string' then return value:find(needle,1,true)~=nil end
 if type(value)=='table' then for _,v in pairs(value) do if contains(v,needle) then return true end end end
 return false
end
local snapshot=ZGV:GetPresentationSnapshot()
for _,p in ipairs(metadata().narration) do
 assert(not contains(snapshot,p.text) and not contains(snapshot,p.title or p.text))
end
ZGV.Presentation=nil
print('PASS actual native advancement: accept, concurrent partial counts, reward guard, finish, progress persistence, waypoint refresh, old-anchor observation and browsing separation')
-- Malformed metadata and binding errors fail closed, without affecting native parsing.
for _,mutate in ipairs({
 function(v)v.interface_version=2 end,
 function(v)v.narration[1].requires={unknown=456} end,
 function(v)v.narration[1].requires=false end,
 function(v)v.narration[1].requires={class_is='DRUID'} end,
 function(v)v.narration[1].at_step='absent' end,
 function(v)v.native_views[1].steps[2].native_parts[1]=v.native_views[1].steps[1].native_parts[1] end,
 function(v)v.callback=function()end end,
 function(v)v.self=v end,
 function(v)setmetatable(v,{})end,
 function(v)v.native_views[1].goals[1].native_goal_index=0 end,
 function(v)v.narration[2].id=v.narration[1].id end,
 function(v)v.narration[1].requires={['not']={quest_rewarded='bad'}} end,
})do fresh();local value=metadata();mutate(value);assert(not C:Stage(value))end
for _,case in ipairs({'payload','label','index','quest','count','contact','duplicate','unmapped'}) do
 fresh();local value=metadata()
 if case=='payload' then value.native_views[1].payload_sha256=string.rep('0',64) end
 if case=='index' then value.native_views[1].goals[1].native_goal_index=1 end
 if case=='quest' then value.native_views[1].goals[1].quest_id=999 end
 if case=='count' then value.native_views[1].goals[2].count=999 end
 if case=='unmapped' then table.remove(value.native_views[1].goals,4);table.remove(value.source_locations,3) end
 assert(C:Stage(value));local g=register()
 if case=='duplicate' then register() end
 if case=='label' or case=='contact' then
  -- Substitute actual parser output to exercise parsed-binding mismatch, keeping hash intact.
  local parse=ZGV.ParseEntry
  ZGV.ParseEntry=function(self,bytes)
   local p=assert(parse(self,bytes))
   if case=='label' then p.steps[2].label=p.steps[1].label else p.steps[1].goals[2].npcid=999 end
   return p
  end
  assert(select(2,ZGV:EnsureGuideParsed(g)));ZGV.ParseEntry=parse
 else assert(select(2,ZGV:EnsureGuideParsed(g))) end
 assert(ZGV:GetCampaignGuideStatus(registration).state=='inactive',case)
 assert(g.parsed,'binding failure altered native parser')
end
-- Both compiler variants share native bytes and mappings; route-only also binds.
fresh();local route=assert(loadfile(fixtureRoot..'route.lua'))();assert(#route.narration==0)
assert(route.native_views[1].payload_sha256==metadata().native_views[1].payload_sha256)
assert(C:Stage(route));local g=register();ZGV:EnsureGuideParsed(g)
assert(ZGV:GetCampaignGuideStatus(registration).state=='bound')
print('PASS compiled data foundation: hashes, private detached staging, validation, registration/deferred parse/rebind, mismatches inactive; public installation gate remains closed')

-- Valid predicates retain source casing; staging only validates, never evaluates.
for _,condition in ipairs({{class_is='Druid'},{race_is='NightElf'},{all={{quest_active=456},{['not']={has_item={item_id=1,count=1}}}}}}) do
 fresh();local m=metadata();m.narration[1].requires=condition;assert(C:Stage(m))
end
fresh();register();assert(not C:Stage(metadata()),'late metadata accepted after native registration')

-- Exercise admission at the ACTUAL fresh-cache boundaries, before native callbacks
-- and advancement. Pooled quest objects are deliberately reused by QuestTracking.
table.wipe=function(t)for k in pairs(t)do t[k]=nil end end
local clock,clientLog,clientRewards=100,{},{}
GetTime=function()return clock end
GetQuestLogTitle=function(i)
 local q=clientLog[i]
 if q then return 'Played quest',1,nil,0,false,false,q.complete and 1 or nil,false,q.id end
end
GetNumQuestLeaderBoards=function(i)return #(clientLog[i].goals or {})end
GetQuestLogLeaderBoard=function(objective,index)
 local goal=clientLog[index].goals[objective]
 return string.format(QUEST_MONSTERS_KILLED,'Client creature '..objective,goal.num,goal.needed),'monster',goal.num>=goal.needed
end
GetQuestsCompleted=function()local copy={}for k,v in pairs(clientRewards)do copy[k]=v end return copy end
ERR_QUEST_COMPLETE_S='%s completed.'
ZGV.startups={};ZGV.recentlyAcceptedQuests={};ZGV.bandwidth=100;ZGV.questLogInitialized=true
ZGV.NewQuestEvent=function()end;ZGV.LostQuestEvent=function()end
assert(loadfile(root..'/QuestTracking.lua'))()
-- Keep the harness's quest-availability double: the checker has separate coverage
-- of IsQuestPossible; this test concerns fresh evidence and advancement ordering.
ZGV.IsQuestPossible=function()return true end
local function session(value,char)
 fresh();ZGV.db.char=char or {guides_history={},permaCompletedDailies={}}
 ZGV.quests={};ZGV.questsbyid={};ZGV.completedQuests={};ZGV.recentlyAcceptedQuests={}
 ZGV.pause=nil;ZGV.LastSkip=1;ZGV.lasttriedstep=nil;ZGV.lastwascompleted=nil
 assert(C:Stage(value or metadata()));local g=register();ZGV:EnsureGuideParsed(g)
 ZGV.CurrentGuide=g;ZGV.CurrentGuideName=registration;ZGV:FocusStep(1)
 clientLog={};clientRewards={}
 return g
end
local function refresh(log)
 clientLog=log;clock=clock+1
 ZGV:QUEST_LOG_UPDATE_QuestTracking()
end
local function query(rewards)
 clientRewards=rewards;clock=clock+1;ZGV:QUEST_QUERY_COMPLETE_QuestTracking()
end
local function admitted()return C:CollectAdmitted(registration)end
local function quest(a,b,complete)
 return {{id=456,complete=complete,goals={{num=a,needed=7},{num=b,needed=4}}}}
end
session();refresh({});query({})
assert(#admitted()==0 and ZGV.db.char.campaignAdmission==nil)
refresh(quest(0,0))
assert(ZGV.CurrentStepNum==2 and #admitted()==1,'acceptance story lost on immediate advancement')
local context=admitted()[1];assert(context.type=='context')
context.body='changed by caller';assert(admitted()[1].body~='changed by caller')
refresh(quest(6,4));assert(ZGV.CurrentStepNum==2 and #admitted()==1)
refresh(quest(7,4,true));assert(ZGV.CurrentStepNum==3 and #admitted()==1)
-- Native mutable completion can advance immediately while the server query lags.
ZGV.completedQuests[456]=true
refresh({})
assert(ZGV.CurrentStep.finish and #admitted()==1,'mutable cache authorized reward story')
local saved=ZGV.db.char
assert(saved.campaignAdmission and saved.banethilStory==nil)
for _,r in pairs(saved.campaignAdmission.guides[metadata().guide.id].passages) do
 assert(r.presented==nil and r.body==nil and r.title==nil,'pending facts became history or stored prose')
end
query({[456]=true})
assert(#admitted()==2 and admitted()[2].type=='moment','delayed fresh reward did not resolve real pending anchor')
local firstBody,secondBody=admitted()[1].body,admitted()[2].body
query({[456]=true});refresh({});assert(#admitted()==2,'duplicate admission')
-- Reload retains pending/eligible facts by character + passage revision; bare
-- historical quest state in a fresh character must never create an encounter.
session(nil,saved);refresh({});query({[456]=true})
assert(#admitted()==2 and admitted()[1].body==firstBody and admitted()[2].body==secondBody)
session();refresh({});query({[456]=true});ZGV:FocusStep(3)
refresh({});query({[456]=true});assert(#admitted()==0,'historical query manufactured an encounter')
-- Initial log snapshot containing an active quest is baseline, not acceptance.
session();refresh(quest(0,0));assert(#admitted()==0)
-- Browsing ahead, manual marks and generic native callbacks cannot reveal story.
session();refresh({});query({});ZGV:FocusStep(3);refresh(quest(0,0));assert(#admitted()==0)
ZGV:FocusStep(1);ZGV.recentlyStickiedGoals[ZGV.CurrentStep.goals[3]]=true
refresh({});refresh(quest(0,0));assert(#admitted()==0)
-- An abandoned completed quest remains unconfirmed; retaking cancels its candidate.
session();refresh(quest(7,4,true));query({});ZGV:FocusStep(3)
refresh({});query({});assert(#admitted()==0)
refresh(quest(0,0));ZGV:FocusStep(2);refresh({});query({[456]=true})
assert(#admitted()==0,'retake confirmed a previous abandonment')
-- No extra requires still needs confirmed turn-in action, not merely disappearance.
local m=metadata();m.narration[2].requires=nil
session(m);refresh(quest(7,4,true));query({});ZGV:FocusStep(3)
refresh({});query({});assert(#admitted()==0)
-- A real pending removal survives reload before its delayed reward query.
local pending=ZGV.db.char
session(m,pending);refresh({});query({[456]=true})
assert(#admitted()==1 and admitted()[1].type=='moment')
-- Changed prose revision cannot inherit the old passage's authorization.
m=metadata();m.narration[1].revision=string.rep('a',64);m.narration[2].revision=string.rep('b',64)
session(m,saved);refresh({});query({[456]=true});assert(#admitted()==0)
-- Unknown reveal evidence, including under NOT, does not admit an encountered passage.
m=metadata();m.narration[1].requires={['not']={quest_objective_complete={quest_id=999,objective_index=1}}}
session(m);refresh({});query({});refresh(quest(0,0));assert(#admitted()==0)
-- Definitions bound after a baseline need their own observed baseline; previously
-- unwatched absence must not be mistaken for a new quest acceptance.
session();refresh({});query({})
local later=metadata();later.guide.id='SECOND';later.native_views[1].registration='Second'
for _,g in ipairs(later.native_views[1].goals)do g.quest_id=999 end
local laterRaw=raw:gsub('456','999');later.native_views[1].payload_sha256=ZGV:CampaignPayloadHash(laterRaw)
assert(C:Stage(later));ZGV:RegisterGuide('Second',laterRaw)
local laterGuide=ZGV.registeredguides[#ZGV.registeredguides];ZGV:EnsureGuideParsed(laterGuide)
ZGV.CurrentGuide=laterGuide;ZGV.CurrentGuideName='Second';ZGV:FocusStep(1)
local laterQuest=quest(0,0);laterQuest[1].id=999
refresh(laterQuest);assert(#C:CollectAdmitted('Second')==0)
-- Unsupported/future saved-state versions are preserved and fail closed.
local future={guides_history={},permaCompletedDailies={},campaignAdmission={version=99,guides={}}}
session(nil,future);refresh({});query({});refresh(quest(0,0))
assert(#admitted()==0 and future.campaignAdmission.version==99)
assert(ZGV.RegisterCampaignGuideMetadata==nil,'delivery remains gated')
print('PASS actual quest hooks + admission: live anchors before advancement, delayed reward/reload, abandonment, character/revision isolation, no historical backfill, manual/browse denial and future-state preservation')

-- Fresh partial objective progress qualifies a kill anchor; pooled cache aliases
-- or merely focusing the step cannot simulate that progress.
m=metadata();m.narration[1].at_step=m.native_views[1].steps[2].source_step_id
session(m);refresh(quest(0,0));query({});assert(ZGV.CurrentStepNum==2 and #admitted()==0)
refresh(quest(0,0));assert(#admitted()==0)
refresh(quest(1,0));assert(#admitted()==1)
-- A fresh reward response arriving before log removal also resolves, but only
-- after absence is observed at the actual turn-in anchor.
session();refresh(quest(7,4,true));query({});ZGV:FocusStep(3)
query({[456]=true});assert(#admitted()==0)
refresh({});assert(#admitted()==1 and admitted()[1].type=='moment')
-- Registry presentation recording remains separately guarded by binding/admission.
local pendingEntries=C:CollectAdmitted(registration)
assert(#pendingEntries==1 and #C:CollectPresented(registration)==0)
assert(not C:MarkPresented(registration,'future',string.rep('f',64)))
assert(not C:MarkPresented(registration,pendingEntries[1].id,'wrong-revision'))
assert(C:MarkPresented(registration,pendingEntries[1].id,pendingEntries[1].revision))
assert(#C:CollectPresented(registration)==1)
assert(C:MarkPresented(registration,pendingEntries[1].id,pendingEntries[1].revision) and #C:CollectPresented(registration)==1)
-- Actual cache -> admission -> delivery notifications preserve live provenance.
assert(loadfile(root..'/CampaignDelivery.lua'))()
ZGV.Presentation={mode='live',storyOpen=false,Publish=function()end}
local delivery=ZGV.CampaignDelivery
assert(delivery:SetMode('moment','open'))
session();delivery:BeginSession();refresh({});query({});refresh(quest(0,0))
assert(not delivery:Context(registration).autoOpen)
refresh(quest(7,4,true));assert(ZGV.CurrentStepNum==3)
ZGV.completedQuests[456]=true;refresh({});query({[456]=true})
local delivered=delivery:Context(registration)
assert(delivered.type=='moment' and delivered.autoOpen and #C:CollectPresented(registration)==0)
local persistedAdmission=ZGV.db.char
session(nil,persistedAdmission);delivery:BeginSession();refresh({});query({[456]=true})
assert(not delivery:Context(registration).autoOpen,'restored eligibility retriggered automatic opening')
