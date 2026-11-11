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
function Frame:GetChildren() return unpack(self.children) end
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:SetSize(w,h) self.w,self.h=w,h end
function Frame:GetWidth() return self.w end
function Frame:SetWidth(w) self.w=w end
function Frame:SetHeight(h) self.h=h end
function Frame:SetText(s) self.text=s end
function Frame:GetStringHeight() return #(self.text or "") end
function Frame:CreateFontString() return frame(self) end
for _,k in ipairs({"SetAllPoints","SetBackdrop","SetBackdropColor","EnableMouse","SetPoint","SetScrollChild","SetJustifyH","RegisterEvent"}) do Frame[k]=function() end end
UIParent=frame()
CreateFrame=function(_,_,parent) return frame(parent) end
SlashCmdList={}
local combat=false
InCombatLockdown=function() return combat end
local ZGV={Frame=frame(UIParent),db={char={guides_history={},guide_progress={}},profile={guidesinhistory=5}},
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
for _,file in ipairs({"Presentation.lua","PresentationFixture.lua","PresentationUI.lua"}) do assert(loadfile(root.."/"..file))() end
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
    assert(visual:IsShown())
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
print("PASS presentation: detached API, notifications, native visibility/auto/manual progression, fixture orders/story, switch/fallback/combat/fault/reload simulation")
