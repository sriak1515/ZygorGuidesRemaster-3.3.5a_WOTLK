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
	local widget={kind=kind,shown=false,scripts={},text='',width=0,height=0,enabled=true}
	function widget:Show()
		local wasShown=self.shown
		self.shown=true
		if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
	end
	function widget:Hide()
		local wasShown=self.shown
		self.shown=false
		if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
	end
	function widget:IsShown() return self.shown end
	function widget:IsVisible() return self.shown end
	function widget:SetText(value) self.text=value end
	function widget:GetText() return self.text end
	function widget:SetScript(event,callback) self.scripts[event]=callback end
	function widget:GetScript(event) return self.scripts[event] end
	function widget:CreateFontString() local child=newWidget('FontString'); child:Show(); return child end
	function widget:CreateTexture() local child=newWidget('Texture'); child:Show(); return child end
	function widget:GetAlpha() return rawget(self,'alpha') or 1 end
	function widget:SetAlpha(value) self.alpha=value end
	function widget:SetSize(width,height)
		self.width,self.height=width,height
		if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,width,height) end
	end
	function widget:ClearAllPoints() self.point=nil end
	function widget:SetPoint(...) self.point={...} end
	function widget:GetCenter()
		local point=rawget(self,'point')
		if point and point[1]=='CENTER' then
			local x,y=point[2]:GetCenter()
			return x+point[4],y+point[5]
		end
		return 0,0
	end
	function widget:IsEnabled() return self.enabled end
	function widget:Enable() self.enabled=true end
	function widget:Disable() self.enabled=false end
	function widget:SetFont(path,size) self.fontPath,self.fontSize=path,size end
	function widget:SetTextColor(...) self.ink={...} end
	function widget:SetWidth(value) self.width=value end
	function widget:GetWidth() return self.width or 0 end
	function widget:SetHeight(value) self.height=value end
	function widget:GetHeight() return self.height or 0 end
	function widget:SetScrollChild(child)
		if type(child)~='table' or child.kind~='Frame' then
			error('SetScrollChild requires a Frame')
		end
		self.scrollChild=child
	end
	function widget:GetScrollChild() return self.scrollChild end
	function widget:GetVerticalScroll() return rawget(self,'verticalScroll') or 0 end
	function widget:SetVerticalScroll(value) self.verticalScroll=value end
	function widget:GetVerticalScrollRange()
		local viewport=self:GetHeight()
		if viewport<=0 then viewport=166 end
		local child=self.scrollChild
		if type(child)=='table' and child.GetHeight then
			local childHeight=child:GetHeight()
			if childHeight>viewport then return childHeight-viewport end
		end
		return 0
	end
	function widget:GetStringHeight()
		if self.kind~='FontString' then return self:GetHeight() end
		local width=self:GetWidth()
		if width<=0 then width=388 end
		local charsPerLine=math.max(1,math.floor(width/7))
		local lines=math.max(1,math.ceil(#(self.text or '')/charsPerLine))
		return lines*(rawget(self,'fontSize') or 16)
	end
	function widget:UpdateScrollChildRect() end
	function widget:EnableMouseWheel(value) self.mouseWheel=value end
	return setmetatable(widget,{__index=function() return function() end end})
end
UIParent=newWidget('Frame')
UIParent:Show()
SlashCmdList={}
STANDARD_TEXT_FONT='Fonts\\FRIZQT__.TTF'
GameFontNormal={GetFont=function() return STANDARD_TEXT_FONT end}
local createdFrames={}
CreateFrame=function(kind)
	local frame=newWidget(kind)
	createdFrames[#createdFrames+1]=frame
	return frame
end

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

-- 4b. Class and race predicates preserve the client API's second return value.
local savedClass,savedRace=UnitClass,UnitRace
UnitClass=function() return 'Druid','DRUID' end
UnitRace=function() return 'Night Elf','NightElf' end
equal(N:Evaluate({class_is='Druid'}),true,'matching class was not true')
equal(N:Evaluate({class_is='Mage'}),false,'nonmatching class was not false')
equal(N:Evaluate({race_is='NightElf'}),true,'matching race was not true')
equal(N:Evaluate({race_is='Human'}),false,'nonmatching race was not false')
local nestedTrue={
	all={
		{class_is='Druid'},
		{any={
			{race_is='NightElf'},
			{level_at_least={actor='leader',level=80}},
		}},
	},
}
equal(N:Evaluate(nestedTrue),true,'nested class/race predicate was not true')
equal(N:Evaluate({all={{class_is='Druid'},{race_is='Human'}}}),false,'nested nonmatching predicate was not false')
UnitClass=nil
equal(N:Evaluate({class_is='Druid'}),nil,'unavailable class observation was not UNKNOWN')
UnitClass=savedClass
UnitRace=nil
equal(N:Evaluate({race_is='NightElf'}),nil,'unavailable race observation was not UNKNOWN')
equal(N:Evaluate({all={{class_is='Druid'},{race_is='NightElf'}}}),nil,'nested unavailable observation was not UNKNOWN')
UnitRace=savedRace

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

-- 5b. A malformed pending subtable must not wipe intact anchors/delivered state.
local knownRevision
for _,entry in ipairs(N:GetEntries()) do
	if entry.id=='balance-first-duty' then knownRevision=entry.revision end
end
check(knownRevision,'fixture delivered revision missing')
local savedChar=ZGV.db.char
local charCorrupt={permaCompletedDailies={}}
charCorrupt.campaignNarration={version=1,guides={
	['EXAMPLE-KAL-01-BALANCE-ONE']={
		anchors={['KAL-01/accept-balance-one']=true},
		pending='corrupt',
		delivered={['balance-first-duty']=knownRevision},
	},
}}
ZGV.db.char=charCorrupt
N:OnObservations()
local repaired=N:GetStatus('WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE')
equal(repaired.anchors,1,'corrupt pending discarded valid anchors')
equal(repaired.delivered,1,'corrupt pending discarded valid delivered state')
equal(repaired.pending,0,'corrupt pending was not repaired')
ZGV.db.char=savedChar

-- 6. Character separation: a second character does not inherit the first
-- character's anchors or pending text.
local charA=savedChar
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

-- 11. A narration hook fault is debug-only and cannot abort native advancement.
local debugMessages={}
function ZGV:Debug(message) debugMessages[#debugMessages+1]=message end
local goodHook=N.OnStepCompleted
N.OnStepCompleted=function() error('synthetic narration hook fault') end
ZGV.db.char=charC
ZGV.CurrentGuide=guide
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
ZGV.CurrentStep=acceptStep
ZGV.CurrentStepNum=1
ZGV.completionelapsed=999
ZGV.skipped=0
ZGV:TryToCompleteStep(true)
equal(ZGV.skipped,1,'narration hook fault aborted native advancement')
local diagnosed=false
for _,message in ipairs(debugMessages) do
	if message:find('completion hook failed',1,true) then diagnosed=true end
end
check(diagnosed,'narration hook fault was not diagnosed in debug')
N.OnStepCompleted=goodHook

-- 11b. Native completion still runs when the narration module is unavailable.
ZGV.CurrentStep=acceptStep
ZGV.CurrentStepNum=1
ZGV.completionelapsed=999
ZGV.skipped=0
local savedNarration=ZGV.CampaignNarration
ZGV.CampaignNarration=nil
ZGV:TryToCompleteStep(true)
equal(ZGV.skipped,1,'missing narration module blocked native advancement')
ZGV.CampaignNarration=savedNarration

-- 12. Failed reader creation must leave pending narration recoverable; a later
-- successful UI build presents it and only then records delivery.
local savedCreateFrame=CreateFrame
local charFail={permaCompletedDailies={}}
ZGV.db.char=charFail
CreateFrame=nil
ZGV.CampaignNarration=nil
assert(loadfile(root..'/Narration.lua'))()
N=assert(ZGV.CampaignNarration)
local failMetadata={}
assert(loadfile(fixture..'/Metadata.lua'))('Test',failMetadata)
equal(failMetadata.metadata_accepted,true,'metadata not accepted during reader failure test')
ZGV.CurrentGuide=guide
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
ZGV.questsbyid={[456]={index=1,complete=false,goals={{num=0,needed=7},{num=0,needed=4}}}}
ZGV.questLogInitialized=true
N:OnStepFocused(guide,acceptStep)
N:OnStepCompleted(guide,acceptStep,true)
equal(status().pending,1,'reader failure lost pending narration')
equal(N:OpenLatest(),nil,'reader failure reported successful presentation')
equal(status().pending,1,'reader failure consumed pending narration')
equal(status().delivered,0,'reader failure marked narration delivered')

CreateFrame=savedCreateFrame
ZGV.CampaignNarration=nil
assert(loadfile(root..'/Narration.lua'))()
N=assert(ZGV.CampaignNarration)
local retryMetadata={}
assert(loadfile(fixture..'/Metadata.lua'))('Test',retryMetadata)
equal(retryMetadata.metadata_accepted,true,'metadata not accepted during reader retry')
ZGV.CurrentGuide=guide
ZGV.CurrentGuideName='WoW Solo Adventure V1\\EXAMPLE-KAL-01-BALANCE-ONE'
N:OnStepFocused(guide,acceptStep)
local retried=N:OpenLatest()
check(retried and retried.id=='balance-first-duty','reader retry did not present pending narration')
equal(status().pending,0,'reader retry left narration pending')
equal(status().delivered,1,'reader retry did not record delivery')
local retryScroll
for index=#createdFrames,1,-1 do
	if type(createdFrames[index].scrollChild)=='table' then retryScroll=createdFrames[index]; break end
end
check(retryScroll and retryScroll.scrollChild.kind=='Frame','reader retry did not create a Frame scroll child')
local shortChildHeight=retryScroll.scrollChild:GetHeight()
N:Close()

-- 13. Long passages use a bounded scroll viewport and respond to mouse wheel.
local longText=string.rep('Long narration line for viewport verification. ',60)
local longRegistration='Test Long\\NARRATION'
local longMetadata={
	interface_version=1,source_format_version=1,
	guide={id='TEST-LONG',title='Long narration'},
	native_views={{registration=longRegistration,payload_sha256=string.rep('c',64),
		steps={{source_step_id='long/step',source_path='/steps/0',native_parts={'long-step'}}},goals={}}},
	narration={{id='long-passage',type='context',at_step='long/step',text=longText,revision=string.rep('d',64)}},
	source_locations={},
}
equal(ZGV:RegisterCampaignGuideMetadata(longMetadata),true,'long-passage metadata was rejected')
local longGuide={title=longRegistration,steps={}}
ZGV.CurrentGuide=longGuide
ZGV.CurrentGuideName=longRegistration
local longStep={label='long-step',goals={},AreRequirementsMet=function() return true end}
N:OnStepFocused(longGuide,longStep)
N:OnStepCompleted(longGuide,longStep,true)
local longEntry=N:OpenLatest()
check(longEntry and longEntry.id=='long-passage','long passage did not open')
local scroll
for index=#createdFrames,1,-1 do
	if type(createdFrames[index].scrollChild)=='table' then scroll=createdFrames[index]; break end
end
check(scroll,'reader did not create a scroll viewport')
local child=scroll.scrollChild
check(child and child.kind=='Frame','scroll child is not a Frame')
check(child.body and child.body.kind=='FontString','scroll FontString is not inside the child Frame')
local badChild=newWidget('FontString')
local accepted=pcall(function() scroll:SetScrollChild(badChild) end)
check(not accepted,'mock accepted a non-Frame SetScrollChild')
check(scroll.scrollChild==child,'failed contract check replaced the valid scroll child')
check(child:GetHeight()>shortChildHeight,'long passage did not grow the scroll child')
check(scroll:GetVerticalScrollRange()>0,'long passage did not create scrollable overflow')
scroll.scripts.OnMouseWheel(scroll,-1)
check(scroll:GetVerticalScroll()>0,'mouse wheel did not scroll the reader body')
N:Close()

-- 14. Visual fixtures use the same reader without touching delivery state.
local function snapshot(value)
	if type(value)~='table' then return tostring(value) end
	local parts={}
	for key,item in pairs(value) do parts[#parts+1]=tostring(key)..'='..snapshot(item) end
	table.sort(parts)
	return '{'..table.concat(parts,',')..'}'
end
local beforeFixture=snapshot(ZGV.db.char)
equal(SLASH_WSAFRAME1,'/wsaframe','visual test command not registered')
for _,input in ipairs({'40','100','150','long'}) do
	SlashCmdList.WSAFRAME(input)
	check(N:IsReaderShown(),'visual fixture did not open')
	local entry=N:GetReaderEntry()
	check(entry and entry.frameTest,'fixture entered real narration delivery')
	local words=0
	for _ in entry.text:gmatch('%S+') do words=words+1 end
	equal(words,input=='long' and 600 or tonumber(input),'fixture word count')
	equal(N:Cycle(1),nil,'fixture navigation opened game content')
	equal(snapshot(ZGV.db.char),beforeFixture,'fixture changed saved state')
	N:Close()
end
check(not N:ShowFrameTest('41'),'invalid fixture accepted')
check(not N:IsReaderShown(),'invalid fixture opened the reader')
check(N:ShowFrameTest(' 40 '),'trimmed fixture input rejected')
local reader
for _,frame in ipairs(createdFrames) do
	if frame.scroll==scroll then reader=frame; break end
end
check(reader,'fixture did not reuse existing reader')
equal(reader.earlier.enabled,false,'fixture enabled history navigation')
equal(reader.later.enabled,false,'fixture enabled forward navigation')
equal(reader:GetAlpha(),0,'opening did not begin fade')
reader.scripts.OnUpdate(reader,0.15)
equal(reader:GetAlpha(),0.5,'fade did not progress with elapsed time')
reader.scripts.OnUpdate(reader,0.15)
equal(reader:GetAlpha(),1,'fade did not finish opaque')
equal(reader.scripts.OnUpdate,nil,'fade retained idle update handler')

-- Resize reflows the scroll child; drag/resize save geometry across module reload.
check(N:ShowFrameTest('long'),'long fixture did not reopen for resize')
scroll:SetWidth(312)
scroll:SetHeight(180)
reader:SetSize(360,294)
equal(child:GetWidth(),312,'resize did not reflow text width')
local beforeResize=child:GetHeight()
scroll:SetWidth(600)
scroll.scripts.OnSizeChanged(scroll)
check(child:GetHeight()<beforeResize,'wider viewport did not reduce text height')
reader:ClearAllPoints()
reader:SetPoint('CENTER',UIParent,'CENTER',123,-45)
reader.scripts.OnDragStop(reader)
equal(ZGV.db.char.campaignNarrationReader.x,123,'drag did not save position')
reader:SetSize(648,400)
reader.grip.scripts.OnMouseUp(reader.grip)
equal(ZGV.db.char.campaignNarrationReader.width,648,'resize did not save width')
N:Close()
assert(loadfile(root..'/Narration.lua'))()
N=ZGV.CampaignNarration
check(N:ShowFrameTest('long'),'fixture failed after module reload')
local restored
for _,frame in ipairs(createdFrames) do
	if type(frame.scroll)=='table' then restored=frame end
end
equal(restored:GetWidth(),648,'width not restored after reload')
equal(restored:GetHeight(),400,'height not restored after reload')
equal(restored.point[4],123,'horizontal position not restored')
equal(restored.point[5],-45,'vertical position not restored')
N:Close()
equal(restored.scripts.OnUpdate,nil,'closing retained fade handler')
local previousChar=ZGV.db.char
ZGV.db.char={}
check(N:ShowFrameTest('40'),'fixture failed for fresh character')
equal(restored:GetWidth(),520,'geometry leaked across characters')
equal(ZGV.db.char.campaignNarration,nil,'fixture created delivery state')
N:Close()
ZGV.db.char=previousChar
ZGV.db.char.campaignNarrationReader={x=0,y=0,width=0/0,height=400}
check(N:ShowFrameTest('40'),'corrupt geometry prevented opening')
equal(restored:GetWidth(),520,'corrupt geometry did not use default width')
N:Close()
N:SetAutoOpen(false)
ZGV.db.char.campaignNarrationReader=nil
check(N:Register(longMetadata),'real narration did not register after reload')
check(N:OpenLatest(),'real narration did not reopen after fixture')
equal(restored.earlier.enabled,true,'fixture left real navigation disabled')
N:Close()

-- 15. Ink controls and font preferences keep delivery state independent.
equal(restored.close.label:GetText(),'×','close symbol missing')
equal(restored.close.point[1],'TOPRIGHT','close is not in title row')
equal(restored.earlier.label:GetText(),'‹','earlier arrow missing')
equal(restored.later.label:GetText(),'›','later arrow missing')
local idleInk=restored.close.label.ink[1]
restored.close.scripts.OnEnter(restored.close)
check(restored.close.label.ink[1]<idleInk,'hover did not darken ink')
restored.close.scripts.OnLeave(restored.close)
equal(restored.close.label.ink[1],idleInk,'hover ink did not reset')
local deliveryBeforeFont=snapshot(ZGV.db.char.campaignNarration)
check(N:ShowFrameTest('long'),'font fixture did not open')
for _,size in ipairs({14,18,16}) do
	SlashCmdList.WSAFRAME('font '..size)
	equal(ZGV.db.char.campaignNarrationFontSize,size,'font preference not saved')
	equal(restored.body.fontSize,size,'open reader font not updated')
end
local savedSettings=snapshot(ZGV.db.char)
for _,input in ipairs({'font 13','font 19','font 16.5','font nope','font 16 extra'}) do
	check(not N:HandleFrameCommand(input),'invalid font setting accepted')
	equal(snapshot(ZGV.db.char),savedSettings,'invalid setting changed saved state')
end
equal(snapshot(ZGV.db.char.campaignNarration),deliveryBeforeFont,'font setting changed delivery')
SlashCmdList.WSAFRAME('font 14')
restored.scripts.OnDragStop(restored)
equal(ZGV.db.char.campaignNarrationFontSize,14,'moving reader lost font preference')
restored.close.scripts.OnClick(restored.close)
check(not N:IsReaderShown(),'close symbol did not close reader')
assert(loadfile(root..'/Narration.lua'))()
N=ZGV.CampaignNarration
check(N:ShowFrameTest('40'),'font fixture failed after reload')
for _,frame in ipairs(createdFrames) do
	if type(frame.scroll)=='table' then restored=frame end
end
equal(restored.body.fontSize,14,'font preference not restored after reload')
local fontChar=ZGV.db.char
ZGV.db.char={}
check(N:ShowFrameTest('40'),'new character fixture failed')
equal(restored.body.fontSize,16,'font preference leaked across characters')
N:Close()
check(N:HandleFrameCommand('font 18'),'closed reader setting failed')
check(not N:IsReaderShown(),'font command opened reader')
check(N:ShowFrameTest('40'),'fixture failed after closed reader setting')
equal(restored.body.fontSize,18,'closed reader setting not applied on opening')
ZGV.db.char=fontChar
N:Close()

print('PASS: narration lifecycle, scrolling, fixtures, geometry, fade, ink controls and font settings')