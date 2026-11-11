-- Lua 5.1. Actual projection/UI plus extracted native progression functions.
-- Frame and quest goal doubles are simulation, NOT a client compatibility test.
local root=arg[1] or "ZygorGuidesViewerRM"
local Frame={};Frame.__index=Frame
local frames={}
local function frame(parent)
    local f=setmetatable({parent=parent,shown=true,alpha=1,w=360,h=440,scripts={},children={}},Frame)
    if parent then parent.children[#parent.children+1]=f end
    frames[#frames+1]=f;return f
end
function Frame:Show() self.shown=true end
function Frame:Hide() self.shown=false end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:GetAlpha() return self.alpha end
function Frame:GetName() return self.name end
function Frame:GetChildren() return unpack(self.children) end
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:SetSize(w,h) self.w,self.h=w,h end
function Frame:GetWidth() return self.allpoints and self.parent:GetWidth() or self.w end
function Frame:SetWidth(w) self.w=w end
function Frame:SetHeight(h) self.h=h end
function Frame:SetText(s) self.text=s end
function Frame:GetHeight() return self.allpoints and self.parent:GetHeight() or self.h end
function Frame:GetStringHeight()
    return math.max(1,math.ceil(#(self.text or "")/math.max(1,self:GetWidth()/((self.fontsize or 13)*0.5))))*(self.fontsize or 13)*1.4
end
function Frame:SetFont(font,size) self.font,self.fontsize=font,size;return true end
function Frame:GetFont() return self.font or "test-font",self.fontsize or 13 end
function Frame:GetFrameLevel() return 1 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetLeft() return self.left or 900 end
function Frame:CreateTexture() return frame(self) end
function Frame:SetAllPoints() self.allpoints=true end
function Frame:SetMinMaxValues(lo,hi) self.lo,self.hi=lo,hi end
function Frame:SetValue(value)
    self.value=value
    if self.scrollOwner then self.scrollOwner:SetVerticalScroll(value) end
end
function Frame:SetVerticalScroll(value)
    self.offset=value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,value) end
end
function Frame:CreateFontString() return frame(self) end
function Frame:SetPoint(...) self.point={...} end
function Frame:ClearAllPoints() self.point=nil end
for _,k in ipairs({"SetTexCoord","SetFrameLevel","SetAlpha","SetBackdropBorderColor","SetHighlightTexture","SetTexture","SetClampedToScreen","EnableMouseWheel","UpdateScrollChildRect","SetTextColor","SetJustifyV","SetSpacing","SetBackdrop","SetBackdropColor","EnableMouse","SetScrollChild","SetJustifyH","RegisterEvent"}) do Frame[k]=function() end end
UIParent=frame()
UIParent:SetSize(1920,1080)
STANDARD_TEXT_FONT="test-font"
local namedFrames={}
CreateFrame=function(kind,name,parent,template)
    local f=frame(parent)
    f.name=name
    if name then
        assert(not namedFrames[name],"duplicate frame name: "..name)
        namedFrames[name]=f
    end
    if template=="UIPanelScrollFrameTemplate" then
        -- Wrath ScrollFrame_OnLoad concatenates GetName() with child suffixes.
        -- The old anonymous construction must fail here, as in the client trace.
        local scrollbarName=f:GetName().."ScrollBar"
        assert(not namedFrames[scrollbarName],"duplicate scrollbar name")
        namedFrames[scrollbarName]=frame(f)
        namedFrames[scrollbarName].scrollOwner=f
        _G[scrollbarName]=namedFrames[scrollbarName]
    end
    return f
end
-- Prove the double models the reported template failure, independently of UI.
assert(not pcall(CreateFrame,"ScrollFrame",nil,UIParent,"UIPanelScrollFrameTemplate"))
SlashCmdList={}
local combat=false
InCombatLockdown=function() return combat end
local ZGV={DIR="test-addon",Frame=frame(UIParent),db={char={guides_history={},guide_progress={}},profile={guidesinhistory=5}},
    LastSkip=1,frameNeedsResizing=0,CurrentGuideName="test-guide",CurrentStepNum=1,completionelapsed=10,completioninterval=0.1,
    completionintervallong=0.5,completionintervalmin=0.01,recentlyCompletedGoals={}}
ZygorGuidesViewer=ZGV
local visual=frame(ZGV.Frame)
local hidden=frame(ZGV.Frame);hidden:Hide()
local count,waypoints=0,0
ZGV.Print=function(_,s) print(s) end
ZGV.SetWaypoint=function() waypoints=waypoints+1 end
for _,k in ipairs({"Debug","ClearRecentActivities","StopFlashAnimation","ScrollToCurrentStep","UpdateCooldowns","UpdateCartographerExport","AnimateGears"}) do ZGV[k]=function() end end
ZGV.InlineButtonsEnabled=function() return false end
ZGV.IsRemasterSkin=function() return false end
ZGV.UpdateFrame=function(self) count=count+1;if self.Presentation then self.Presentation:Publish() end end
local function goal(text)
    return {action="get",questid=483,objnum=1,progress=0,text=text,
        IsVisible=function() return true end,
        IsComplete=function(self) return self.progress==1,true,self.progress end,
        GetText=function(self) return self.text end,
        GetStatus=function(self) return self.progress==1 and "complete" or "incomplete",self.progress end}
end
local function step(n)
    return {num=n,title="Test "..n,label="stable-"..n,goals={goal("Relic")},
        PrepareCompletion=function() end,AreRequirementsMet=function() return true end,
        IsComplete=function(self) return self.goals[1].progress==1,true,false end,
        IsObsolete=function() return false end,IsPointlessTravel=function() return false end,
        IsAuxiliarySkippable=function() return false end}
end
ZGV.CurrentGuide={title="Test",title_short="Test",steps={step(1),step(2)}}
ZGV.CurrentStep=ZGV.CurrentGuide.steps[1]
ZGV.Pointer={ArrowFrame={waypoint={c=1,z=2,x=0.44,y=0.58,type="way",title="Test target"}}}
for _,s in ipairs(ZGV.CurrentGuide.steps) do s.parentGuide=ZGV.CurrentGuide end
-- Load exact functions from source; fail if boundaries drift.
local f=assert(io.open(root.."/ZygorGuidesViewer.lua"));local source=f:read("*a");f:close()
for _,name in ipairs({"FocusStep","FocusStepQuiet","SkipStep","TryToCompleteStep"}) do
    local body=assert(source:match("function me:"..name.."%b()%s*\n.-\nend"),name)
    assert(loadstring("local me,ZGV=...;local tinsert,tremove=table.insert,table.remove;local time=function() return 0 end;"..body))(ZGV,ZGV)
end
for _,file in ipairs({"Presentation.lua","BanethilStory.lua","PresentationFixture.lua","PresentationUI.lua"}) do assert(loadfile(root.."/"..file))() end
local P=ZGV.Presentation
-- Exercise actual renderer dispatch guards while retaining a fallback double.
local fallbackRender=ZGV.UpdateFrame
for _,name in ipairs({"UpdateFrame","UpdateFrameCurrent"}) do
    local body=assert(source:match("function me:"..name.."%b()%s*\n.-\nend"),name)
    assert(loadstring("local me=...;"..body))(ZGV)
    local real=ZGV[name]
    ZGV[name]=function(self,...)
        if P.mode=="live" then return real(self,...) end
        return fallbackRender(self,...)
    end
end
local events={}
local unsubscribe=ZGV:SubscribePresentation(function(s,reason) events[#events+1]={s,reason};s.goals[1].text="listener mutation" end)
P:Publish();assert(#events==1)
assert(ZGV.CurrentStep.goals[1].text=="Relic")
local snap=ZGV:GetPresentationSnapshot();snap.goals[1].text="changed"
assert(ZGV:GetPresentationSnapshot().goals[1].text=="Relic")
assert(snap.step.label=="stable-1" and snap.goals[1].questId==483)
snap.navigation.x=99
assert(ZGV.Pointer.ArrowFrame.waypoint.x==0.44)
ZGV.Pointer.ArrowFrame.waypoint.x=0.45;P:Publish()
assert(events[#events][2]=="progress")
local previousEvents=#events
P:Publish();assert(#events==previousEvents,"no duplicate events")
ZGV.CurrentStep.goals[1].progress=0.5;P:Publish()
assert(events[#events][2]=="progress")
-- Native visibility/alpha guards: no progress while hidden or transparent.
ZGV.CurrentStep.goals[1].progress=1
ZGV.Frame:Hide();ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1)
ZGV.Frame:Show();ZGV.Frame.alpha=0;ZGV:TryToCompleteStep(true);assert(ZGV.CurrentStepNum==1)
ZGV.Frame.alpha=1
P:Start("live")
assert(ZGV.Frame:IsVisible() and ZGV.Frame:GetAlpha()==1 and not visual:IsShown())
local oldRenderCount=count
ZGV.frameNeedsUpdating=true
ZGV:UpdateFrame(true);ZGV:UpdateFrameCurrent()
assert(not ZGV.frameNeedsUpdating and not ZGV.stepchanged,"render flags consumed")
assert(count==oldRenderCount,"experimental dispatch reached legacy rendering")
ZGV:TryToCompleteStep(true)
assert(ZGV.CurrentStepNum==2 and ZGV.db.char.step==2,"native auto progression")
assert(events[#events][2]=="step" and waypoints>0)
local waypointCount=waypoints
P:Navigate(-1);assert(ZGV.CurrentStepNum==1)
P:Navigate(1);assert(ZGV.CurrentStepNum==2 and waypoints>waypointCount)
local activeGuide,activeStep=ZGV.CurrentGuide,ZGV.CurrentStep
P:Stop()
assert(visual:IsShown() and not hidden:IsShown() and ZGV.CurrentGuide==activeGuide and ZGV.CurrentStep==activeStep)
-- Fixtures do not select a guide, invoke SkipStep or alter native state/cache/db.
local persisted=ZGV.db.char.step
ZGV.SkipStep=function() error("fixture called real SkipStep") end
ZGV.SetGuide=function() error("fixture selected a guide") end
for _,order in ipairs({{1,2,3,4,5},{5,4,2,1,3}}) do
    P:Start("fixture")
    assert(visual:IsShown() and P.mode=="fixture" and P.panel)
    for _,i in ipairs(order) do P:FixtureCommand("goal "..i) end
    for _,g in ipairs(P:Snapshot().goals) do assert(g.status=="complete") end
    assert(not P:Snapshot().story,"objective progress must not earn story")
    P:FixtureCommand("story");assert(P:Snapshot().story)
    P:Navigate(-1);assert(P:Snapshot().step.index==1)
    P:Navigate(1);assert(P:Snapshot().step.index==2)
    assert(ZGV:GetPresentationSnapshot().source=="live")
    local fixture=P:Snapshot();fixture.goals[1].status="bad"
    assert(P:Snapshot().goals[1].status=="complete")
    P:Stop()
    assert(ZGV.CurrentGuide==activeGuide and ZGV.CurrentStep==activeStep and ZGV.db.char.step==persisted)
end
-- New UI: snapshot rows, explicit context, independent scroll and interruption.
P:Start("fixture")
assert(P.panel and P.fixtureHost:GetHeight()==560 and #P.objectives.rows==5)
assert(P.storyOpen and P.storyPanel:IsVisible() and P.storyEntry.id=="oben-request")
assert(P.objectives.rows[5].hint.text:find("Shamans"))
local requestBody=P.storyText.text
P:FixtureCommand("story")
assert(P.storyText.text==requestBody and not P:Snapshot().story,"charm gate")
P:FoldStory(false)
local fixedWidth,fixedHeight=P.panel:GetWidth(),P.panel:GetHeight()
P.objectives:SetVerticalScroll(17)
P.storyPane:SetVerticalScroll(31)
P:FixtureCommand("goal 1")
assert(not P.storyOpen and not P.storyPanel:IsVisible(),"routine progress must stay quiet")
assert(P.objectives.rows[1].text.text:find("1/1") and P.objectives.rows[1].iconIndex==3)
P:Navigate(1)
assert(not P:Snapshot().story and not P.storyOpen,"manual Next cannot unlock or reopen context")
P:ToggleStory();assert(P.storyPanel:IsVisible())
local storyScroll=P.storyPane.offset
P:FoldStory(true)
assert(P.storyCue and not P.storyOpen and P.storyPane.offset==storyScroll)
P:FixtureCommand("peace");assert(not P.storyOpen,"combat exit must not force reading")
P:ToggleStory();assert(P.storyOpen and not P.storyCue)
P:FixtureCommand("goal 5");P:FixtureCommand("story")
assert(P.storyEntry.id=="oben-revelation" and P.storyOpen)
assert(P.objectives.rows[5].text.text=="Release Oben's spirit")
assert(P.panel:GetWidth()==fixedWidth and P.panel:GetHeight()==fixedHeight,"story reflowed guide")
P:FixtureCommand("combat");assert(not P.storyOpen and P.storyCue)
P:FixtureCommand("peace");assert(not P.storyOpen)
P:FixtureCommand("reset");assert(P.storyEntry.id=="oben-request")
-- Exercise real wrapping/scroll calculations with long current-step data.
local long=P:Snapshot()
long.context.body=string.rep("A long already-earned passage. ",400)
for i=6,36 do long.goals[i]={index=i,action="get",text=string.rep("Long objective ",20),status="incomplete"} end
P:Render(long)
assert(P.objectives.range>0 and P.storyPane.range>0,"long text must remain scrollable")
P.objectives:SetVerticalScroll(42);P.storyPane:SetVerticalScroll(63)
P:Render(long)
assert(P.objectives.offset==42 and P.storyPane.offset==63,"progress refresh lost reading positions")
P:FoldStory(false);P:ToggleStory();assert(P.storyPane.offset==63,"fold lost reading position")
P.panel.left=100;P:LayoutPanels()
assert(P.storyPanel.point[1]=="TOPLEFT" and P.storyPanel.point[3]=="TOPRIGHT","use free right side")
P.panel.left=900;P:LayoutPanels()
assert(P.storyPanel.point[1]=="TOPRIGHT" and P.storyPanel.point[3]=="TOPLEFT","prefer free left side")
UIParent:SetWidth(640);P.panel.left=240;P:LayoutPanels()
assert(not P.storyPanel:IsShown() and P.storyEntry,"never cover objectives when neither side fits")
UIParent:SetWidth(1920);P.panel.left=900;P:LayoutPanels()
assert(P.storyPanel:IsVisible(),"retain passage when space returns")
P:Stop()
assert(ZGV.CurrentGuide==activeGuide and ZGV.CurrentStep==activeStep and ZGV.db.char.step==persisted)
-- Explicit passive metadata only; native tooltips remain attached to actions.
ZGV.Parchment={Suspend=function() end,IsPlain=function(_,g) return g.action=="info" and not g.useitemid end}
local nativeGoals=ZGV.CurrentStep.goals
local plain=goal("Inline introduction");plain.action="info"
local contextGoal=goal("Explicit context");contextGoal.action="info";contextGoal.context=true
local interactive=goal("Use something");interactive.action="info";interactive.context=true;interactive.useitemid=1;interactive.tooltip="Attached instruction"
ZGV.CurrentStep.goals={plain,contextGoal,interactive}
local projected=ZGV:GetPresentationSnapshot()
assert(projected.goals[1].role=="objective" and projected.goals[2].role=="context")
assert(projected.goals[3].role=="objective" and projected.goals[3].hint=="Attached instruction")
P:Start("live")
assert(P.storyEntry.body=="Explicit context" and P.objectives.rows[2].text.text=="Use something")
for _,f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_DISABLED") end end
assert(not P.storyOpen and P.storyCue,"native combat interruption")
P:Stop();ZGV.CurrentStep.goals=nativeGoals;ZGV.Parchment=nil
-- Genuine passage rendered through the same snapshot and panel, with simulated
-- quest-cache evidence here; test_banethil_story executes the real cache hooks.
P:Start("live")
assert(not P.storyEntry)
ZGV.completedQuests={[2561]=true} -- manual completion is deliberately insufficient
P:Publish();assert(not P.storyEntry and not ZGV.db.char.banethilStory)
ZGV.BanethilStory:ObserveQuestLog({[2541]={complete=true}})
P:Publish();assert(not P.storyEntry)
local guideStep,guidePause=ZGV.CurrentStepNum,ZGV.pause
ZGV.BanethilStory:ObserveQuestLog({[2561]={complete=false}})
assert(P.storyEntry.id=="KAL-02/oben-charm-revelation" and P.storyOpen)
assert(P.storyTitle.text=="What the charm reveals" and P.storyText.text:find("fallen body"))
assert(ZGV.CurrentStepNum==guideStep and ZGV.pause==guidePause)
P:FoldStory(false);P.storyPane:SetVerticalScroll(math.min(19,P.storyPane.range))
local retainedScroll=P.storyPane.offset
ZGV.CurrentGuideName="another-guide";ZGV.CurrentStepNum=99
P:Publish()
assert(P.storyEntry and not P.storyOpen and P.storyPane.offset==retainedScroll,"navigation disturbed story")
local detached=ZGV:GetPresentationSnapshot();detached.context.body="mutation"
assert(ZGV:GetPresentationSnapshot().context.body~=detached.context.body)
P:ToggleStory();assert(P.storyOpen)
P:FoldStory(true);P:Publish();assert(P.storyCue and not P.storyOpen)
local storyRecord=ZGV.db.char.banethilStory
P:Start("fixture");P:FixtureCommand("goal 5");P:FixtureCommand("story")
assert(ZGV.db.char.banethilStory==storyRecord,"fixture changed live evidence")
P:Stop()
ZGV.db.char={}
P:Start("live");combat=true
ZGV.BanethilStory:ObserveQuestLog({[2561]={}})
assert(P.storyEntry and not P.storyOpen and P.storyCue,"conversation in combat must leave a cue")
combat=false
for _,f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_ENABLED") end end
assert(not P.storyOpen);P:ToggleStory();assert(P.storyOpen)
P:Stop();ZGV.db.char={step=persisted,banethilStory=storyRecord}
-- Module reload preserves only the character's record; reader starts closed.
assert(loadfile(root.."/BanethilStory.lua"))()
P:Start("live")
assert(P.storyEntry and not P.storyOpen and P.storyCue)
P:ToggleStory();assert(P.storyOpen and P.storyText.text:find("fallen body"))
P:Stop()
ZGV.CurrentGuideName="test-guide";ZGV.CurrentStepNum=guideStep
-- A different character cannot inherit this passage.
ZGV.db.char={}
P:Start("live");assert(not P.storyEntry);P:Stop()
ZGV.db.char={step=persisted,banethilStory=storyRecord}
-- Combat fallback is deferred without state loss.
P:Start("live");combat=true;P:Stop();assert(P.pendingStop and P.mode=="live")
combat=false
for _,f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_ENABLED") end end
assert(not P.mode and visual:IsShown())
-- Snapshot evaluator failure also restores the original presentation.
P:Start("live")
local oldStatus=ZGV.CurrentStep.goals[1].GetStatus
ZGV.CurrentStep.goals[1].GetStatus=function() error("deliberate projection fault") end
P:Publish();assert(not P.mode and visual:IsShown())
ZGV.CurrentStep.goals[1].GetStatus=oldStatus
-- Subscriber failures cannot escape into native advancement; restores UI.
P:Start("live")
ZGV:SubscribePresentation(function() error("deliberate observer fault") end)
P.signature=nil;P:Publish();assert(not P.mode and visual:IsShown())
unsubscribe()
-- Simulated addon reload: module-local switches/fixture disappear, db untouched.
assert(loadfile(root.."/Presentation.lua"))()
assert(not ZGV.Presentation.mode and not ZGV.Presentation.fixture and ZGV.db.char.step==persisted)
print("PASS presentation: detached API, native progression, vertical rows/overflow, story gates/fold/recall/scroll/combat/placement, fixture isolation, fallback/fault/reload simulation")
