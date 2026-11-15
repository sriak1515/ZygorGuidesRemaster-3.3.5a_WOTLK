-- Focused offline regression for the lightweight narration reader.
-- Usage: lua5.1 tools/narration/test_narration.lua <addon dir> <fixture dir>
local root=arg[1] or 'ZygorGuidesViewerRM'
local fixture=arg[2] or 'tools/narration/fixtures/kal01-balance'

local function read(path)
	local file=assert(io.open(path,'rb'))
	local source=file:read('*a')
	file:close()
	return (source:gsub('^\239\187\191',''))
end

local function fail(message) error(message,2) end
local function check(value,message) if not value then fail(message) end end
local function equal(actual,expected,message)
	if actual~=expected then
		fail((message or 'value mismatch')..': expected '..tostring(expected)..', got '..tostring(actual))
	end
end

tinsert,tremove=table.insert,table.remove
function TableKeys(t) local r={} for k in pairs(t or {}) do r[#r+1]=k end return r end
local locale=setmetatable({coords='%s,%s'},{__index=function(_,key) return key end})
function ZygorGuidesViewer_L(_,_,loader)
	if loader then for key,value in pairs(loader()) do locale[key]=value end end
	return locale
end
assert(loadfile(root..'/Localization/enUS.lua'))()
COLOR_GOAL=function(s) return s end
plural=function(s) return s end
strsplit=function(delimiter,text)
	local result={}
	for value in (text..delimiter):gmatch('(.-)'..delimiter) do result[#result+1]=value end
	return unpack(result)
end

local currentZone='Teldrassil'
GetRealZoneText=function() return currentZone end
GetZoneText=GetRealZoneText
GetSubZoneText=function() return '' end
GetMinimapZoneText=GetSubZoneText
QUEST_MONSTERS_KILLED='%s slain: %d/%d'
QUEST_ITEMS_NEEDED='%s: %d/%d'
QUEST_OBJECTS_FOUND='%s: %d/%d'
QUEST_FACTION_NEEDED='%s: %d/%d'
local levels={player=18,party1=18,party2=18,party3=18,party4=18}
local names={player='Thaloren',party1='Darethia',party2='Lunethra',party3='Faelion',party4='Saerith'}
UnitLevel=function(unit) return levels[unit] or 0 end
UnitExists=function(unit) return levels[unit]~=nil end
UnitName=function(unit) return names[unit] end
UnitRace=function() return 'Night Elf','NightElf' end
UnitClass=function() return 'Druid','DRUID' end
UnitFactionGroup=function() return 'Alliance' end
local inventory={}
GetItemCount=function(id) return inventory[id] or 0 end
GetTime=function() return 100 end
PlaySound=function() end
InCombatLockdown=function() return false end
SpellIsTargeting=function() return false end
UnitCastingInfo=function() return nil end
UnitChannelInfo=function() return nil end

local function newWidget(kind)
	local widget={shown=false,scripts={},text=''}
	function widget:Show() self.shown=true end
	function widget:Hide() self.shown=false end
	function widget:IsShown() return self.shown end
	function widget:IsVisible() return self.shown end
	function widget:SetText(value) self.text=value end
	function widget:GetText() return self.text end
	function widget:SetScript(event,callback) self.scripts[event]=callback end
	function widget:GetScript(event) return self.scripts[event] end
	function widget:CreateFontString() local child=newWidget('FontString'); child:Show(); return child end
	function widget:CreateTexture() local child=newWidget('Texture'); child:Show(); return child end
	function widget:GetAlpha() return 1 end
	return setmetatable(widget,{__index=function() return function() end end})
end
UIParent=newWidget('Frame')
UIParent:Show()
STANDARD_TEXT_FONT='Fonts\\FRIZQT__.TTF'
GameFontNormal={GetFont=function() return STANDARD_TEXT_FONT end}
CreateFrame=function(kind) return newWidget(kind) end

ZygorGuidesViewer={
	BZL={},BSZL={},BFL={},StandingNamesEngRev={},dailyQuests={},instantQuests={},
	completedQuests={},questsbyid={},StepProto_mt={},GoalProto_mt={},maxQuestLevels={},
	recentlyCompletedGoals={},recentlyStickiedGoals={},startups={},registeredguides={},
	db={profile={skipimpossible=false,skipobsolete=false,skipauxsteps=false,levelsahead=0,completesound=nil,flashborder=false},char={permaCompletedDailies={}}},
}
local ZGV=ZygorGuidesViewer
ZGV.L=locale
ZGV.recentlyVisitedCoords={}
ZGV.Frame=newWidget('Frame')
ZGV.Frame:Show()
local px,py=0.01,0.01
GetPlayerMapPosition=function() return px,py end
GetNumQuestLogEntries=function() local n=0 for _ in pairs(ZGV.questsbyid) do n=n+1 end return n end
GetQuestLogTitle=function(index)
	local n=0
	for id in pairs(ZGV.questsbyid) do
		n=n+1
		if n==index then return nil,nil,nil,nil,false,nil,nil,id end
	end
end
function ZGV:GetQuestName() return nil end
function ZGV:RaceClassMatch() return true end
function ZGV:IsQuestPossible() return true end
function ZGV:RegisterGuide(title,raw)
	local guide={title=title,raw=raw,rawdata=raw}
	self.registeredguides[#self.registeredguides+1]=guide
	return guide
end
function ZGV:Debug() end

assert(loadfile(root..'/Goal.lua'))()
assert(loadfile(root..'/Step.lua'))()
assert(loadfile(root..'/Parser.lua'))()
assert(loadfile(root..'/Narration.lua'))()
local N=assert(ZGV.CampaignNarration)

local function loadPackage()
	local namespace={}
	assert(loadfile(fixture..'/Metadata.lua'))('Test',namespace)
	assert(loadfile(fixture..'/Guide.lua'))('Test',namespace)
	return namespace
end

local function parseLastGuide()
	local guide=ZGV.registeredguides[#ZGV.registeredguides]
	assert(guide, 'native guide did not register')
	local parsed,err,line=ZGV:ParseEntry(guide.rawdata)
	assert(parsed,tostring(err)..' line '..tostring(line))
	parsed.title=guide.title
	ZGV.CurrentGuide=parsed
	ZGV.CurrentGuideName=guide.title
	for _,step in ipairs(parsed.steps) do
		setmetatable(step,ZGV.StepProto_mt)
		step.parentGuide=parsed
		for _,goal in ipairs(step.goals) do
			setmetatable(goal,ZGV.GoalProto_mt)
			goal.parentStep=step
		end
	end
	return parsed
end

local function reloadPackage()
	ZGV.registeredguides={}
	ZGV.CampaignNarration=nil
	assert(loadfile(root..'/Narration.lua'))()
	N=assert(ZGV.CampaignNarration)
	loadPackage()
	return parseLastGuide()
end

local function status()
	return N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE')
end

local function completeStep(step)
	assert(step:IsComplete(),'fixture step did not complete')
	N:OnStepCompleted(ZGV.CurrentGuide,step,true)
end

local function setQuestActive()
	ZGV.questsbyid[456]={index=1,complete=false,goals={{num=0,needed=7},{num=0,needed=4}}}
	ZGV.questLogInitialized=true
end

-- 1. Metadata acceptance, before and after native guide registration.
local namespace=loadPackage()
equal(namespace.metadata_accepted,true,'compiler metadata was not accepted')
check(type(ZGV.RegisterCampaignGuideMetadata)=='function','consumer API missing')
equal(status().passages,2,'unexpected passage count')
equal(status().pending,0,'metadata load alone revealed narration')
N:RefreshCue()
equal(N:IsReaderShown(),false,'metadata load opened the reader')

local guide=parseLastGuide()
local acceptStep,objectiveStep,rewardStep=guide.steps[1],guide.steps[2],guide.steps[3]
check(acceptStep and objectiveStep and rewardStep,'fixture steps missing')

-- Manual ahead-jump is only a focus observation, not completion.
N:OnStepFocused(guide,rewardStep)
equal(status().pending,0,'manual jump ahead revealed future narration')
equal(status().anchors,0,'manual jump ahead marked an anchor complete')

-- 2. Normal native completion records the authored anchor and retains it while
-- Zygor advances immediately to later steps.
setQuestActive()
completeStep(acceptStep)
equal(status().anchors,1,'native completion did not record its anchor')
equal(status().pending,1,'eligible context passage was lost')
local entries=N:GetEntries()
equal(#entries,1,'unexpected eligible entry count')
equal(entries[1].id,'balance-first-duty','wrong anchor association')
N:OnStepFocused(guide,objectiveStep)
N:OnStepFocused(guide,rewardStep)
equal(status().pending,1,'rapid native advancement discarded narration')
equal(N:IsReaderShown(),false,'cue mode unexpectedly opened the reader')

-- 3. Once-only presentation and reopening through history without a Mark read
-- click. Opening is the presentation event.
local first=N:OpenLatest()
check(first and first.id=='balance-first-duty','pending passage did not open')
equal(N:IsReaderShown(),true,'reader did not open')
equal(status().pending,0,'presentation left the passage pending')
equal(status().delivered,1,'presentation was not recorded')
local reopened=N:OpenHistory()
check(reopened and reopened.id==first.id,'presented passage was not reusable')
equal(status().delivered,1,'reopening duplicated delivery state')
N:Close()

-- 4. Reveal conditions are tri-state. UNKNOWN must not reveal, and a later real
-- client observation can make the same retained anchor eligible.
equal(N:Evaluate({quest_rewarded=456}),nil,'unobserved reward was treated as known')
N:OnStepCompleted(guide,rewardStep,true)
equal(status().pending,0,'UNKNOWN reveal condition exposed future text')
ZGV.quest_query_complete_received=true
equal(N:Evaluate({quest_rewarded=456}),false,'known-unrewarded quest was not false')
N:OnObservations()
equal(status().pending,0,'definitively false condition revealed text')
ZGV.completedQuests[456]=true
equal(N:Evaluate({quest_rewarded=456}),true,'real reward observation was not true')
N:OnObservations()
equal(status().pending,1,'newly true retained anchor was not delivered')
check(N:GetPendingEntry().id=='balance-first-duty-complete','wrong moment passage')

-- 5. Reload recovery: anchors and pending/delivered state survive a fresh module
-- and a fresh metadata registration without replaying the guide.
guide=reloadPackage()
ZGV.CurrentGuide=guide
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
N:OnStepFocused(guide,guide.steps[3])
equal(status().pending,1,'pending narration was lost across reload')
equal(status().delivered,1,'delivered narration was lost across reload')
equal(status().anchors,2,'completed anchors were lost across reload')
local history=N:OpenHistory()
check(history and history.id=='balance-first-duty','presented passage unavailable after reload')
N:Close()

-- 6. Character separation: a second character does not inherit the first
-- character's anchors or pending text.
local charA=ZGV.db.char
local charB={permaCompletedDailies={}}
ZGV.db.char=charB
N:OnStepFocused(guide,guide.steps[1])
equal(status().pending,0,'new character inherited pending narration')
equal(status().anchors,0,'new character inherited completed anchors')
ZGV.db.char=charA
N:OnStepFocused(guide,guide.steps[3])
equal(status().pending,1,'first character lost its pending narration')

-- 7. Combat-safe deferred presentation. Auto-open is opt-in; combat suppresses
-- it but keeps the passage pending until the real regen event.
ZGV.db.char=charB
ZGV.questsbyid={[456]={index=1,complete=false,goals={{num=0,needed=7},{num=0,needed=4}}}}
ZGV.questLogInitialized=true
N:SetAutoOpen(true)
InCombatLockdown=function() return true end
completeStep(acceptStep)
equal(status().pending,1,'combat completion discarded narration')
equal(N:IsReaderShown(),false,'combat opened the reader')
InCombatLockdown=function() return false end
N:OnCombatEnded()
equal(N:IsReaderShown(),true,'post-combat presentation did not resume')
equal(status().pending,0,'post-combat presentation did not deliver')
equal(status().delivered,1,'post-combat delivery was not recorded')
N:Close()
N:SetAutoOpen(false)

-- 8. Guide switching hides the cue for unrelated native guides and does not
-- leak the previous guide's reader.
local beforeSwitch=N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE')
ZGV.CurrentGuideName='Ordinary Native Guide'
ZGV.CurrentGuide={title='Ordinary Native Guide',steps={}}
N:OnStepFocused(ZGV.CurrentGuide,{goals={}})
equal(N:IsReaderShown(),false,'guide switch left the old reader visible')
N:RefreshCue()
local afterSwitch=N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE')
equal(afterSwitch.pending,beforeSwitch.pending,'guide switch mutated pending state')
equal(afterSwitch.delivered,beforeSwitch.delivered,'guide switch mutated delivered state')
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
ZGV.CurrentGuide=guide
N:OnStepFocused(guide,guide.steps[3])
equal(N:IsReaderShown(),false,'cue-only mode opened on guide return')

-- 9. Native guide registration remains independent of narration availability.
local before=#ZGV.registeredguides
local consumer=ZGV.RegisterCampaignGuideMetadata
ZGV.RegisterCampaignGuideMetadata=nil
local missing={}
assert(loadfile(fixture..'/Metadata.lua'))('Test',missing)
assert(loadfile(fixture..'/Guide.lua'))('Test',missing)
equal(missing.metadata_accepted,false,'missing consumer looked accepted')
equal(#ZGV.registeredguides,before+1,'missing consumer blocked native registration')
ZGV.RegisterCampaignGuideMetadata=consumer
equal(ZGV:RegisterCampaignGuideMetadata({interface_version=2}),false,'wrong interface accepted')
equal(ZGV:RegisterCampaignGuideMetadata({interface_version=1,source_format_version=1,guide={id='x',title='x'},native_views={},narration={}}),false,'invalid view accepted')
local malformed={
	interface_version=1,source_format_version=1,guide={id='x',title='x'},
	native_views={{registration='R',payload_sha256=string.rep('a',64),
		steps={{source_step_id='s',source_path='/steps/0',native_parts={'s'}}},goals={}}},
	narration={{id='p',type='context',at_step='missing',text='x',revision=string.rep('b',64)}},
}
equal(ZGV:RegisterCampaignGuideMetadata(malformed),false,'unknown narration anchor accepted')
ZGV.CampaignNarration=nil
assert(loadfile(root..'/Narration.lua'))()
N=assert(ZGV.CampaignNarration)
local valid={}
assert(loadfile(fixture..'/Metadata.lua'))('Test',valid)
equal(valid.metadata_accepted,true,'valid metadata rejected after invalid input')
N:OnObservations()

-- 10. Actual viewer lifecycle integration: execute the real TryToCompleteStep
-- from ZygorGuidesViewer.lua, not a reimplementation. Its inserted observer must
-- record the same anchor through a normal completion pass.
local source=read(root..'/ZygorGuidesViewer.lua')
local function contains(fragment,message)
	check(source:find(fragment,1,true),message)
end
contains('pcall(self.CampaignNarration.OnStepFocused,self.CampaignNarration,self.CurrentGuide,self.CurrentStep)','FocusStep narration hook missing')
contains('pcall(self.CampaignNarration.OnStepCompleted,self.CampaignNarration,self.CurrentGuide,self.CurrentStep,stepcomplete)','TryToCompleteStep narration hook missing')
local fileOrder=read(root..'/files.xml')
local narrationLoad=assert(fileOrder:find('<Script file="Narration.lua"/>',1,true),'Narration.lua not loaded')
local goalLoad=assert(fileOrder:find('<Script file="Goal.lua"/>',1,true),'Goal.lua missing')
check(narrationLoad>goalLoad,'Narration.lua must load after Goal.lua')

local charC={permaCompletedDailies={}}
ZGV.db.char=charC
ZGV.questsbyid={[456]={index=1,complete=false,goals={{num=0,needed=7},{num=0,needed=4}}}}
ZGV.questLogInitialized=true
ZGV.CurrentGuide=guide
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
ZGV.CurrentStep=acceptStep
ZGV.CurrentStepNum=1
ZGV.completionelapsed=999
ZGV.completioninterval=1
ZGV.completionintervallong=1
ZGV.completionintervalmin=0.01
ZGV.frameNeedsResizing=0
ZGV.LastSkip=1
ZGV.lasttriedstep=nil
ZGV.lastwascompleted=nil
ZGV.lastCurrentStepGoalStateSig=nil
ZGV.pause=nil
ZGV.skipped=0
function ZGV:SkipStep(delta) self.skipped=self.skipped+(delta or 0) end
function ZGV:UpdateFrame() end
function ZGV:UpdateFrameCurrent() end
function ZGV:SetWaypoint() end
function ZGV:ScrollToCurrentStep() end
function ZGV:UpdateCooldowns() end
function ZGV:StopFlashAnimation() end
function ZGV:ClearLibRoverPath() end
function ZGV:UpdateCartographerExport() end
function ZGV:InlineButtonsEnabled() return false end
function ZGV:IsRemasterSkin() return false end
local start=assert(source:find('function me:TryToCompleteStep(force)',1,true),'TryToCompleteStep missing')
local finish=assert(source:find('function me:InitializeDropDown(',start,true),'TryToCompleteStep end missing')
local chunk=assert((loadstring or load)('local me=...\n'..source:sub(start,finish-1)),'TryToCompleteStep did not load')
chunk(ZGV)
ZGV:TryToCompleteStep(true)
equal(ZGV.skipped,1,'ordinary native advancement did not run')
equal(N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE').anchors,1,'viewer lifecycle did not record narration anchor')
equal(N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE').pending,1,'viewer lifecycle lost narration')

print('PASS: narration metadata, conditions, recovery, combat, separation and viewer lifecycle')