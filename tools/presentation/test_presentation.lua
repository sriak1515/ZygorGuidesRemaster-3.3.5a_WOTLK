-- Lua 5.1. Actual projection/UI plus extracted native progression functions.
-- Frame and quest goal doubles are simulation, NOT a client compatibility test.
local root=arg[1] or "ZygorGuidesViewerRM"
local Frame={};Frame.__index=Frame
local frames={}
local combat=false
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
function Frame:GetParent() return self.parent end
function Frame:GetScript(k) return self.scripts[k] end
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
function Frame:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Frame:GetLeft() return self.left or 900 end
function Frame:GetBottom() return self.bottom or 160 end
function Frame:GetTop() return self.top or self:GetBottom()+self:GetHeight() end
function Frame:GetNumPoints() return self.point and 1 or 0 end
function Frame:GetPoint() return unpack(self.point) end
function Frame:GetMinResize() return unpack(self.minresize or {1,1}) end
function Frame:GetMaxResize() return unpack(self.maxresize or {0,0}) end
function Frame:SetMinResize(w,h) self.minresize={w,h} end
function Frame:SetMaxResize(w,h) self.maxresize={w,h} end
function Frame:StartMoving() self.moving=true end
function Frame:StartSizing() self.sizing=true end
function Frame:StopMovingOrSizing() self.moving=nil;self.sizing=nil end
function Frame:SetAttribute(k,v) assert(not combat,"secure mutation in combat");self.attributes=self.attributes or {};self.attributes[k]=v end
function Frame:SetScale(v) self.scale=v end
function Frame:GetValue() return self.value or 0 end
function Frame:GetFrameStrata() return "MEDIUM" end
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
for _,k in ipairs({"SetStatusBarTexture","SetStatusBarColor","SetDesaturated","RegisterForClicks","RegisterForDrag","SetMovable","SetResizable","SetFrameStrata","SetVertexColor","SetTexCoord","SetFrameLevel","SetAlpha","SetBackdropBorderColor","SetHighlightTexture","SetTexture","SetClampedToScreen","EnableMouseWheel","UpdateScrollChildRect","SetTextColor","SetJustifyV","SetSpacing","SetBackdrop","SetBackdropColor","EnableMouse","SetScrollChild","SetJustifyH","RegisterEvent"}) do Frame[k]=function() end end
UIParent=frame()
UIParent:SetSize(1920,1080)
STANDARD_TEXT_FONT="test-font"
GetItemCooldown=function() return 0,0,0 end
GetSpellCooldown=GetItemCooldown
CooldownFrame_SetTimer=function() end
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
RegisterStateDriver=function(f,_,value) f.driver=value end
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
assert(loadfile(root.."/Parchment.lua"))()
ZGV.GetRemasterFont=function() return "test-font" end
local nativeParchment=ZGV.Parchment
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
local nativeSkip=ZGV.SkipStep
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
assert(P.panel and P.fixtureHost:GetHeight()==360 and #P.objectives.rows==5)
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
ZGV.Parchment=nativeParchment
local nativeGoals=ZGV.CurrentStep.goals
local plain=goal("Inline introduction");plain.action="info";plain.questid=nil;plain.info=plain.text
local contextGoal=goal("Explicit context");contextGoal.action="info";contextGoal.questid=nil;contextGoal.info=contextGoal.text;contextGoal.context=true
local interactive=goal("Use something");interactive.action="info";interactive.info=interactive.text;interactive.context=true;interactive.useitemid=1;interactive.tooltip="Attached instruction"
ZGV.CurrentStep.goals={plain,contextGoal,interactive}
local projected=ZGV:GetPresentationSnapshot()
assert(projected.goals[1].role=="objective" and projected.goals[2].role=="context")
assert(projected.goals[3].role=="objective" and projected.goals[3].hint=="Attached instruction")
P:Start("live")
assert(P.storyEntry.body=="Explicit context" and P.objectives.rows[2].label.text=="Use something")
for _,f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_DISABLED") end end
assert(not P.storyOpen and P.storyCue,"native combat interruption")
P:Stop();ZGV.CurrentStep.goals=nativeGoals
-- Gameplay binding: execute native rows, secure binding and click dispatcher.
ZGV.SkipStep=nativeSkip
local originalInline=ZGV.InlineButtonsEnabled
ZGV.InlineButtonsEnabled=function() return true end
ZGV.GetGoalActionSpec=function(_,g) return g.spec end
local apply=assert(source:match("function me:InlineButtons_ApplySecureOverlaySpec%b()%s*\n.-\n\tend"))
assert(loadstring("local me=...;local AB_WipeAttrs=function(b) for _,k in ipairs({'type','spell','item','macro','macrotext'}) do b:SetAttribute(k,nil) end end;"..apply))(ZGV)
local click=assert(source:match("function me:GoalOnClick%b()%s*\n.-\nend"))
assert(loadstring("local me=...;"..click))(ZGV)
ZGV.recentlyStickiedGoals={};ZGV.recentlyVisitedCoords={};ZGV.questsbyid={}
local item=goal("Use the quest item");item.questid=nil;item.action="use";item.spec={type="item",item="item:123",itemid=123}
local spell=goal("Cast the quest spell");spell.questid=nil;spell.action="cast";spell.spec={type="spell",spell="Test spell",spellid=456}
local confirm=goal("Continue the conversation");confirm.questid=nil;confirm.action="confirm"
ZGV.CurrentStep.goals={item,spell,confirm}
ZGV.Frame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-20,-100)
local nativePoint={ZGV.Frame:GetPoint()}
local nativeMin,nativeMax=ZGV.Frame:GetMinResize(),ZGV.Frame:GetMaxResize()
local beforeGeometry={ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight(),ZGV.Frame:GetLeft(),ZGV.Frame:GetBottom()}
P:Start("live")
assert(P.mode=="live" and P.objectives.child.step==ZGV.CurrentStep)
local snapFrame=assert(source:match("function me:ActionButtons_GetSnapFrame%b()%s*\n.-\n\tend"))
assert(loadstring("local me=...;"..snapFrame))(ZGV)
assert(ZGV:ActionButtons_GetSnapFrame()==P.panel,"native bar snapped to hidden chrome")
for _,name in ipairs({"AlignFrame","ResizeFrame","UpdateLocking","ApplyRemasterSkin"}) do
    local body=assert(source:match("function me:"..name.."%b()%s*\n.-\nend"),name)
    local c=assert(loadstring("local me=...;"..body));c(ZGV)
    ZGV[name](ZGV)
    assert(P.mode=="live","native layout took over adventure: "..name)
end
local frameSource=assert(io.open(root.."/ZygorGuidesViewerFrame.lua")):read("*a")
for _,name in ipairs({"RefreshAutoHideBorderState","ForceHideBorderNow"}) do
    local body=assert(frameSource:match("function ZGV:"..name.."%b()%s*\n.-\nend"),name)
    assert(loadstring("local ZGV=...;"..body))(ZGV)
    ZGV[name](ZGV) -- must return without touching hidden native chrome
end
local row=P.objectives.rows[1]
assert(row.goal==item and row.inlineActionSpec==item.spec)
-- Supply viewport/holder coordinates explicitly; this double does not lay out anchors.
P.objectives.top=600;P.objectives.bottom=200
row.actionHolder.top=590;row.actionHolder.bottom=568
P.objectives.rows[2].actionHolder.top=560;P.objectives.rows[2].actionHolder.bottom=538
P:SecureButtons()
assert(P.secure.driver=="[combat] hide; show")
assert(P.secure.buttons[1].attributes.type=="item" and P.secure.buttons[1].attributes.item=="item:123")
assert(P.secure.buttons[2].attributes.type=="spell" and P.secure.buttons[2].attributes.spell=="Test spell")
ZGV.Frame:Hide();P.panel.scripts.OnHide()
assert(not P.secure.buttons[1]:IsShown(),"hidden guide retained an item target")
ZGV.Frame:Show();P:SecureButtons()
assert(P.secure.buttons[1]:IsShown())
row.actionHolder.top=620;row.actionHolder.bottom=598
P:SecureButtons()
assert(P.secure.buttons[1].actionSpec==spell.spec and not P.secure.buttons[2]:IsShown(),"clipped item retained a target")
row.actionHolder.top=590;row.actionHolder.bottom=568
P:SecureButtons()
combat=true;P:Render(P:Snapshot());P:SecureButtons() -- SetAttribute asserts on mutation
combat=false;P:SecureButtons()
P.objectives.rows[3].clicker.scripts.OnClick(P.objectives.rows[3].clicker,"LeftButton")
assert(ZGV.recentlyStickiedGoals[confirm],"native confirm binding lost")
-- Refresh action availability even if quest text/status did not change.
item.spec={type="item",item="item:789",itemid=789}
ZGV:UpdateFrame()
assert(P.objectives.rows[1].inlineActionSpec==item.spec)
assert(P.secure.buttons[1].attributes.item=="item:789")
ZGV.Parchment:SetContextSize(21)
assert(P.objectives.rows[1].label.fontsize==ZGV.db.profile.fontsize)
local currentGuide,currentStep,currentStepNum=ZGV.CurrentGuide,ZGV.CurrentStep,ZGV.CurrentStepNum
local switched=goal("Another guide objective");switched.questid=nil
ZGV.CurrentGuide={title="Another guide",steps={{goals={switched}}}}
ZGV.CurrentStep=ZGV.CurrentGuide.steps[1];ZGV.CurrentStepNum=1
P:Publish()
assert(P.guideTitle.text=="Another guide" and P.objectives.rows[1].goal==switched)
assert(P.objectives.child.step==ZGV.CurrentStep and not P.secure.buttons[1]:IsShown(),"guide switch left an old item target")
ZGV.CurrentGuide,ZGV.CurrentStep,ZGV.CurrentStepNum=currentGuide,currentStep,currentStepNum
P:Publish()
local oldWaypoint=ZGV.Pointer.ArrowFrame.waypoint
local callsBeforeMove=waypoints
P.header.scripts.OnDragStart();assert(ZGV.Frame.moving)
ZGV.Frame.left=500;ZGV.Frame.bottom=210
P.header.scripts.OnDragStop();assert(not ZGV.Frame.moving)
assert(P:Settings().x==500/1920 and P:Settings().y==210/1080)
ZGV.db.profile.windowlocked=true
P.header.scripts.OnDragStart();P.grip.scripts.OnMouseDown(nil,"LeftButton")
assert(not ZGV.Frame.moving and not ZGV.Frame.sizing)
ZGV.db.profile.windowlocked=false
P.grip.scripts.OnMouseDown(nil,"LeftButton");assert(ZGV.Frame.sizing)
ZGV.Frame:SetSize(280,280);P.grip.scripts.OnMouseUp();assert(not ZGV.Frame.sizing)
assert(P:Settings().width==280 and P:Settings().height==280)
ZGV.Frame:SetSize(560,720);ZGV.Frame:SetScale(2)
P:Tick(0.05)
assert(ZGV.Frame:GetHeight()==524,"large guide must fit scaled screen")
ZGV.Frame:SetScale(1);ZGV.Frame:SetSize(280,280);P:Relayout()
assert(P.controls[5]:IsVisible() and P.objectives:IsVisible())
-- Existing font settings re-render native row labels; story uses reading size.
ZGV.db.profile.fontsize=19;ZGV.db.profile.fontsecsize=15
P:Relayout();assert(P.objectives.rows[1].label.fontsize==19)
assert(waypoints==callsBeforeMove and ZGV.Pointer.ArrowFrame.waypoint==oldWaypoint,"layout retargeted navigation")
-- The exact native guide menu function must anchor to the visible header.
local menuBody=assert(source:match("function me:OpenGuideMenu%b()%s*\n.-\nend"))
local menuAnchor,opened
local chunk=assert(loadstring(menuBody))
setfenv(chunk,setmetatable({me=ZGV,tinsert=table.insert,L={menu_last="Recent"},
    group_to_array=function() return {{text="Test guide",func=function() opened=true end}} end,
    insert_guides=function() end,clamp_guide_menu_lists=function() end,
    UIDropDownMenu_SetAnchor=function(_,_,_,_,anchor) menuAnchor=anchor end,
    UIDropDownMenu_SetWidth=function() end,EasyMenu=function(menu) menu[1].func() end},{__index=_G}))
chunk()
P.controls[3].scripts.OnClick(nil,"LeftButton")
assert(menuAnchor==P.header and opened,"guide selection did not use native menu")
ZGV.ToggleGuideManagerFrame=function(_,section) opened=section end
P.controls[3].scripts.OnClick(nil,"RightButton");assert(opened=="home")
ZGV.OpenOptions=function() opened="settings" end
P.controls[4].scripts.OnClick();assert(opened=="settings")
local saved=ZGV.db.profile.adventure
P:Stop()
assert(ZGV.Frame:GetWidth()==beforeGeometry[1] and ZGV.Frame:GetHeight()==beforeGeometry[2],"fallback failed to restore dimensions")
for _,b in ipairs(P.secure.buttons) do assert(not b:IsShown(),"fallback left an action target") end
assert(ZGV.Frame:GetPoint()==nativePoint[1] and ZGV.Frame.point[2]==nativePoint[2] and ZGV.Frame.point[4]==nativePoint[4])
assert(ZGV.Frame:GetMinResize()==nativeMin and ZGV.Frame:GetMaxResize()==nativeMax)
P:Start("live");assert(ZGV.Frame:GetWidth()==280 and ZGV.Frame:GetHeight()==280)
P:Stop();assert(ZGV.db.profile.adventure==saved)
ZGV.CurrentStep.goals=nativeGoals;ZGV.InlineButtonsEnabled=originalInline
-- Run the exact native action-bar refresh in adventure mode; native combat
-- mismatch handling remains responsible for hiding a stale binding.
local barRefresh=assert(source:match("function me:ActionButtons_Refresh%b()%s*\n.-\n\tend"))
local barZ={Presentation={mode="live"},db={profile={actionbuttonbar_enabled=true}},Frame=ZGV.Frame,
    ActionButtonBar={buttons={{},{}}}}
function barZ:ActionButtons_CreateBar() return self.ActionButtonBar end
function barZ:GetCurrentStepActionSpecs() return {item.spec,spell.spec} end
function barZ:ActionButtons_SetPendingCombatState(value) self.blocked=value end
function barZ:ActionButtons_ApplyButtonSpec(b,spec) b.actionSpec=spec end
function barZ:ActionButtons_BarMatchesSpecs() return false end
for _,k in ipairs({"ActionButtons_ApplyAnchor","ActionButtons_Layout","ActionButtons_UpdateDragState","ActionButtons_UpdateCooldowns"}) do barZ[k]=function() end end
barZ.ActionButtonBar.Show=function(self) self.shown=true end
barZ.ActionButtonBar.Hide=function(self) self.shown=false end
assert(loadstring("local me=...;local ACTION_BAR_MAX_BUTTONS=2;"..barRefresh))(barZ)
barZ:ActionButtons_Refresh()
assert(barZ.ActionButtonBar.shown and barZ.ActionButtonBar.buttons[1].actionSpec==item.spec)
combat=true;barZ:ActionButtons_Refresh();assert(barZ.blocked)
combat=false;barZ:ActionButtons_Refresh();assert(not barZ.blocked)
-- The native arrow remains independent of geometry and honors visibility options.
local pointerSource=assert(io.open(root.."/Pointer.lua")):read("*a")
local guards=assert(pointerSource:match("function Pointer.ArrowFrame_OnUpdate%(self,elapsed%)(.-)local dist,x,y"))
local profile={hidearrowwithguide=true,arrowshow=true}
local guardChunk=assert(loadstring("return function(self) "..guards.."return true end"))
setfenv(guardChunk,setmetatable({profile=profile,ZGV=ZGV,IsInInstance=function() return false end},{__index=_G}))
local permitted=guardChunk()
local arrow=frame(UIParent);arrow.waypoint=oldWaypoint
assert(permitted(arrow))
ZGV.Frame:Hide();assert(not permitted(arrow) and not arrow:IsShown())
ZGV.Frame:Show();profile.arrowshow=false;assert(not permitted(arrow))
profile.arrowshow=true;assert(permitted(arrow))
assert(arrow:GetParent()==UIParent and arrow.waypoint==oldWaypoint)
print("PASS gameplay simulation: native item/spell/confirm/menu bindings, secure clipping/combat policy, movement/resize/lock/fonts/persistence/fallback and arrow guards")
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
ZGV.Parchment:SetContextSize(22)
assert(P.storyText.fontsize==22,"unchanged snapshot ignored reading-size update")
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
assert(loadfile(root.."/PresentationUI.lua"))()
assert(ZGV.Presentation:Settings().width==saved.width and ZGV.Presentation:Settings().height==saved.height)
assert(ZGV.db.profile.fontsize==19 and ZGV.db.profile.fontsecsize==15,"reload lost font settings")
print("PASS presentation: detached API, native progression, vertical rows/overflow, story gates/fold/recall/scroll/combat/placement, fixture isolation, fallback/fault/reload simulation")
