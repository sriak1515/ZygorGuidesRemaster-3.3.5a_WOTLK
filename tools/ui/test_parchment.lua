-- Lua 5.1, no WoW client. Stateful frame double for layout/scroll/refresh logic;
-- font metrics are deliberately approximate and do not establish client rendering.
local root=arg[1] or "ZygorGuidesViewerRM"
local combat=false
local Frame={}
Frame.__index=Frame
local function new(parent) return setmetatable({parent=parent,w=1,h=1,shown=true,scripts={},scale=1,value=0},Frame) end
function Frame:SetSize(w,h)
    assert(w>=0 and h>=0)
    local changed=self.w~=w or self.h~=h
    self.w,self.h=w,h
    if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end
end
function Frame:StartMoving() self.moving=true end
function Frame:StartSizing() self.sizing=true end
function Frame:StopMovingOrSizing() self.moving=false;self.sizing=false end
function Frame:SetWidth(w) self.w=w end
function Frame:SetHeight(h) self.h=h end
function Frame:GetWidth() return self.w end
function Frame:GetHeight() return self.h end
function Frame:ClearAllPoints() self.anchor=nil end
function Frame:SetPoint(a,p,r,x,y)
    if type(p)=="number" then x,y,p,r=p,r,self.parent,a end
    self.anchor={a,p or self.parent,r or a,x or 0,y or 0}
end
local function offset(a,w,h)
    return (a:find("LEFT") and 0 or a:find("RIGHT") and w or w/2),
        (a:find("BOTTOM") and 0 or a:find("TOP") and h or h/2)
end
function Frame:GetLeft()
    if not self.anchor then return self.parent and self.parent:GetLeft() or 0 end
    local a,p,r,x=self.anchor[1],self.anchor[2],self.anchor[3],self.anchor[4]
    local rx=offset(r,p.w,p.h);local ax=offset(a,self.w,self.h)
    return p:GetLeft()+rx+x-ax
end
function Frame:GetBottom()
    if not self.anchor then return (self.parent and self.parent:GetBottom() or 0)-(self.scrollOwner and self.scrollOwner.scroll or 0)*-1 end
    local a,p,r,y=self.anchor[1],self.anchor[2],self.anchor[3],self.anchor[5]
    local _,ry=offset(r,p.w,p.h);local _,ay=offset(a,self.w,self.h)
    return p:GetBottom()+ry+y-ay+(self.scrollOwner and self.scrollOwner.scroll or 0)
end
function Frame:GetTop() return self:GetBottom()+self.h end
function Frame:SetAllPoints(p) self.w,self.h=p.w,p.h;self:SetPoint("TOPLEFT",p,"TOPLEFT",0,0) end
function Frame:GetParent() return self.parent end
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:HookScript(k,v) local old=self.scripts[k];self.scripts[k]=function(...) if old then old(...) end;v(...) end end
function Frame:GetScript(k) return self.scripts[k] end
function Frame:Show() self.shown=true end
function Frame:Hide() self.shown=false end
-- Deliberately omit SetShown: it is unavailable on native 3.3.5a frames.
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:SetScale(v) self.scale=v end
function Frame:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:SetFrameLevel(n) self.level=n end
function Frame:GetFrameStrata() return "MEDIUM" end
function Frame:GetAlpha() return 1 end
function Frame:SetFont(path,size) self.font=path;self.fontSize=size;return true end
function Frame:SetText(s) self.valueText=tostring(s or "") end
function Frame:SetSpacing(n) self.spacing=n end
function Frame:GetStringWidth() return #(self.valueText or "")*(self.fontSize or 16)*0.52 end
function Frame:GetStringHeight()
    local total=0
    for line in ((self.valueText or "").."\n"):gmatch("(.-)\n") do
        total=total+math.max(1,math.ceil(#line*(self.fontSize or 16)*0.52/math.max(self.w,1)))
    end
    return total*((self.fontSize or 16)+(self.spacing or 0))
end
function Frame:SetTexture(value) assert(type(value)~="table","texture atlas must be unpacked");self.texture=value end
function Frame:SetThumbTexture(_) self.thumb=new(self) end
function Frame:GetThumbTexture() return self.thumb end
function Frame:SetValue(v)
    v=math.max(self.lo or 0,math.min(self.hi or math.huge,v));local changed=self.value~=v;self.value=v
    if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
end
function Frame:GetValue() return self.value end
function Frame:SetMinMaxValues(lo,hi) self.lo,self.hi=lo,hi end
function Frame:SetScrollChild(child) child.scrollOwner=self end
function Frame:SetVerticalScroll(v) self.scroll=v end
function Frame:CreateTexture() return new(self) end
function Frame:CreateFontString() return new(self) end
function Frame:SetAttribute(k,v) assert(not combat,"secure mutation in combat");self[k]=v end
function Frame:SetDesaturated(value) self.desaturated=value end
function Frame:SetTextColor(...) self.color={...} end
function Frame:RegisterEvent() end
for _,name in ipairs({"SetVertexColor","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","SetJustifyV","RegisterForClicks","RegisterForDrag","EnableMouseWheel","EnableMouse","SetOrientation","SetValueStep","SetFrameStrata","SetHighlightTexture","SetTexCoord","SetMovable","SetResizable","SetMinResize","SetClampedToScreen","SetClampRectInsets","SetAlpha"}) do Frame[name]=function() end end
UIParent=new();UIParent:SetSize(1920,1080)
CreateFrame=function(_,name,parent) local f=new(parent or UIParent);if name then _G[name]=f end;return f end
RegisterStateDriver=function(f,k,value) f.driver=value end
STANDARD_TEXT_FONT="client-font"
SlashCmdList={}
GameTooltip=setmetatable({},{__index=function() return function() end end})
InCombatLockdown=function() return combat end
CooldownFrame_SetTimer=function() end
GetItemCooldown=function() return 0,0,0 end
GetSpellCooldown=GetItemCooldown
local profile={skin="remaster",displaymode="guide",framescale=1,parchment={layout="split"}}
ZygorGuidesViewer={db={profile=profile},Frame=new(UIParent),stepframes={}}
local ZGV=ZygorGuidesViewer
function ZGV:GetRemasterFont() return "client-font" end
function ZGV:GetQuestName() return nil end
function ZGV:InlineButtonsEnabled() return true end
function ZGV:GetGoalActionSpec(g) return g.spec end
function ZGV:GoalOnClick(clicker,b) self.clicked=clicker:GetParent().goal;self.clickButton=b end
function ZGV:InlineButtons_ApplySecureOverlaySpec(b,s,h) assert(not combat);b.actionSpec=s;b:Show() end
assert(loadfile(root.."/Parchment.lua"))()
local P=ZGV.Parchment
ZGV.DIR="Interface\\AddOns\\ZygorGuidesViewerRM"
assert(CreateFrame("Frame").SetShown==nil,"client double must not invent SetShown")
local nativeSource=assert(io.open(root.."/ZygorGuidesViewer.lua","rb")):read("*a")
local menuStart=assert(nativeSource:find("function me:OpenQuickMenu(anchor)",1,true))
local menuEnd=assert(nativeSource:find("function me:OpenQuickSteps()",menuStart,true))
local menuChunk=assert(loadstring(nativeSource:sub(menuStart,menuEnd-1)))
local openedMenu
setfenv(menuChunk,setmetatable({me=ZGV,ZGV=ZGV,L=setmetatable({},{__index=function(_,k) return k end}),
    UIDropDownMenu_SetAnchor=function() end,
    EasyMenu=function(menu) openedMenu=menu end},{__index=_G}))
menuChunk()
function ZGV:UpdateFrame() return self:UpdateParchment() end
local function goal(value,action,extra)
    local g=extra or {};g.text=value;g.action=action
    function g:GetStatus() return self.complete and "complete" or "passive" end
    function g:GetText() return self.text end
    function g:IsCompleteable() return self.action and self.action~="info" end
    function g:IsActionable() return self.spec~=nil end
    return g
end
local function show(goals)
    local step={goals=goals,Translate=function() end}
    ZGV.CurrentStep=step;ZGV.CurrentStepNum=(ZGV.CurrentStepNum or 0)+1
    ZGV.CurrentGuide=ZGV.CurrentGuide or {title_short="A long chapter name",steps={}}
    ZGV.CurrentGuide.steps[ZGV.CurrentStepNum]=step
    ZGV:UpdateParchment();return step
end
local numeric=goal(nil,"accept",{questid=783,quest="783"})
assert(not P:GoalText(numeric):find("783",1,true),"numeric quest fallback leaked")
local counted=goal("Defeat 8 wolves (3/8)","kill",{questid=783})
assert(P:GoalText(counted):find("3/8",1,true),"unknown quest title replaced objective counts")
local emptyInfo=goal("","info",{info="",context=true})
local short=goal("Talk to Deputy Willem","talk")
show({short,emptyInfo})
assert(P.action:IsShown() and not P.context:IsShown(),"empty info created an empty reading region")
local w,h=ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight()
local unknown=goal("An unfamiliar row must survive","future-action",{context=true})
local direction=goal("Stay on the west road")
local context=goal(string.rep("A long passage with words. ",150),nil,{context=true})
local mixed=show({short,direction,unknown,context})
assert(#P.action.rows>=3 and P.action.rows[3].goal==unknown)
assert(P.action.rows[2].goal==direction,"untagged directions moved out of Actions")
assert(P.context:IsShown() and P.context.range>0)
assert(not P.reading,"placement preference must not consume a viewer row")
assert(P.context.rows[1].label:GetWidth()==P.context.child:GetWidth(),"reading text retained an unused icon gutter")
assert(P.action.rows[1].marker:IsShown(),"pending objective has no marker")
assert(not P.action.rows[2].marker:IsShown(),"plain direction was marked as an objective")
local closedBody=P.actionHeight+P.contextHeight
P:Settings().tools=true;ZGV:UpdateParchment()
local openBody=P.actionHeight+P.contextHeight
assert(closedBody-openBody<=P.utility:GetHeight()+4,"tools consume more than their single row")
local savedWidth,savedHeight=ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight()
ZGV:OpenQuickMenu(P.settings)
local readingOption=assert(openedMenu[1])
assert(readingOption.text=="Move untagged notes to Context")
readingOption.func();assert(readingOption.checked())
readingOption.func();assert(not readingOption.checked())
assert(ZGV.Frame:GetWidth()==savedWidth and ZGV.Frame:GetHeight()==savedHeight,"preference moved the window")
P:Settings().tools=false;ZGV:UpdateParchment()
local oldAction=P.action.scroll
P.context.wheel(nil,-3)
assert(P.context.scroll>0 and P.action.scroll==oldAction,"mouse wheel leaked to actions")
-- Exercise actual divider handlers with cursor coordinates at both extremes.
local settings=P:Settings()
local beforeW,beforeH=ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight()
for _,cursor in ipairs({-100000,100000}) do
    GetCursorPosition=function() return 0,cursor end
    P.divider:GetScript("OnDragStart")()
    ZGV:ParchmentTick(0.1)
    P.divider:GetScript("OnDragStop")()
    assert(settings.split>=0 and settings.split<=1)
    assert(P.actionHeight>=160 and P.contextHeight+P.divider:GetHeight()>=144)
    assert(ZGV.Frame:GetWidth()==beforeW and ZGV.Frame:GetHeight()==beforeH)
end
profile.windowlocked=true
P.divider:GetScript("OnDragStart")()
assert(not P.splitting,"lock did not prevent divider dragging")
profile.windowlocked=false
settings.split=0.55;ZGV:UpdateParchment()
local scroll=P.context.scroll
for i=1,30 do short.complete=i%2==0;ZGV:UpdateParchment() end
assert(P.context.scroll==scroll,"ordinary refresh reset story scroll")
assert(ZGV.Frame:GetWidth()==w and ZGV.Frame:GetHeight()==h,"progress changed footprint")
assert(P.action.rows[1].completion:IsShown(),"completed objective lacks symbol")
assert(not P.action.rows[1].marker:IsShown(),"completion left the pending symbol visible")
short.complete=false;ZGV:UpdateParchment()
assert(P.action.rows[1].marker:IsShown() and not P.action.rows[1].completion:IsShown(),"reopened objective did not restore pending symbol")
local pendingColor=table.concat(P.action.rows[1].label.color,",")
local contextColor=table.concat(P.context.rows[1].label.color,",")
local pendingHeight=P.action.rows[1]:GetHeight()
short.complete=true;ZGV:UpdateParchment()
assert(table.concat(P.action.rows[1].label.color,",")~=pendingColor,"completed text lacks subdued treatment")
assert(table.concat(P.context.rows[1].label.color,",")==contextColor,"completion faded unrelated Context")
assert(P.action.rows[1]:GetHeight()==pendingHeight,"completion changed row geometry")
short.complete=false;ZGV:UpdateParchment()
assert(table.concat(P.action.rows[1].label.color,",")==pendingColor,"reopened objective retained completed text styling")

-- Actual settings callbacks reflow Context alone, retaining the reading paragraph.
ZGV:OpenQuickMenu(P.settings)
local sizeMenu=assert(openedMenu[2].menuList)
local paragraph2=goal(string.rep("Second paragraph for reading anchors. ",80),nil,{context=true})
show({short,context,paragraph2})
P.context.bar:SetValue(P.context.rows[2].contentY+30)
local anchor=P:ScrollAnchor(P.context)
sizeMenu[#sizeMenu].func()
assert(sizeMenu[#sizeMenu].checked() and P:Settings().contextsize==22)
local changed=P:ScrollAnchor(P.context)
assert(changed.goal==anchor.goal and math.abs(changed.fraction-anchor.fraction)<0.001,"font reflow lost reading paragraph")
assert(P.context.rows[1].label.fontSize>P.action.rows[1].label.fontSize,"Context font control changed no reading text")
local enlarged=P.context.child:GetHeight()
sizeMenu[1].func()
assert(P.context.child:GetHeight()<enlarged and P.action.rows[1].label.fontSize==13,"Context size changed objectives")
P:SetContextSize(-10);assert(P:Settings().contextsize==12)
P:SetContextSize(100);assert(P:Settings().contextsize==24)
show({short,direction,unknown,context})
local split,collapsed=P:Settings().split,P:Settings().collapsed
local frameLeft,frameBottom=ZGV.Frame:GetLeft(),ZGV.Frame:GetBottom()
P.context.bar:SetValue(P.context.range)
local contextBefore=P.context.scroll
P.read:GetScript("OnClick")()
assert(P:ReadingActive() and not P.action:IsShown() and P.context:IsShown())
assert(not P.divider:IsShown() and P.readerFooter:IsShown() and P.back:IsShown())
assert(P.context:GetBottom()>=P.readerFooter:GetTop(),"reader passage overlaps fixed controls")
assert(P:Settings().split==split and P:Settings().collapsed==collapsed)
for i=1,15 do ZGV:UpdateParchment() end
assert(P:ReadingActive(),"progress refresh closed explicit reading mode")
P.back:GetScript("OnClick")()
assert(not P:ReadingActive() and P.action:IsShown() and P.context.scroll==contextBefore,"reading preview failed to restore its layout/offset")
assert(ZGV.Frame:GetLeft()==frameLeft and ZGV.Frame:GetBottom()==frameBottom,"reading mode moved the window")
P.read:GetScript("OnClick")()
P.context.wheel(nil,1)
local moved=P.context.scroll
P.back:GetScript("OnClick")()
assert(P.context.scroll==moved,"return discarded deliberate reading scroll")

-- Run the actual native progression entry point: explicit reading waits before
-- completion evaluation; exiting allows normal evaluation without changing pause.
local completionStart=assert(nativeSource:find("function me:TryToCompleteStep(force)",1,true))
local completionEnd=assert(nativeSource:find("\nfunction me:",completionStart+1,true))
local completionChunk=assert(loadstring(nativeSource:sub(completionStart,completionEnd-1)))
setfenv(completionChunk,setmetatable({me=ZGV},{__index=_G}));completionChunk()
local completionQueries=0
ZGV.CurrentStep.IsComplete=function() completionQueries=completionQueries+1;error("completion-evaluated") end
ZGV.completionelapsed,ZGV.completioninterval=0,0
local oldPause=ZGV.pause
P.read:GetScript("OnClick")()
assert(pcall(ZGV.TryToCompleteStep,ZGV,true) and completionQueries==0,"reader allowed automatic progression")
local oldSkip=ZGV.SkipStep
ZGV.SkipStep=function(_,delta) ZGV.manualDelta=delta end
P.next:GetScript("OnClick")(P.next,"LeftButton")
assert(ZGV.manualDelta==1,"reading mode disabled manual navigation")
ZGV.SkipStep=oldSkip
P.back:GetScript("OnClick")()
local ok,err=pcall(ZGV.TryToCompleteStep,ZGV,true)
assert(not ok and tostring(err):find("completion%-evaluated") and completionQueries==1,"return did not release normal progression")
assert(ZGV.pause==oldPause,"reading mode rewrote progression preference")
P:SetContextSize(14)
-- Typography controls keep semantic roles independent, without relocating prose.
ZGV:OpenQuickMenu(P.settings)
local objectiveMenu=assert(openedMenu[3].menuList)
local intro=goal(string.rep("An introduction before the task. ",8))
local after=goal("A passage after the task stays here.")
show({intro,short,after,context})
local readingSize=P.context.rows[1].label.fontSize
objectiveMenu[#objectiveMenu].func()
assert(objectiveMenu[#objectiveMenu].checked() and P.action.rows[2].label.fontSize==16)
assert(P.action.rows[1].label.fontSize==readingSize and P.context.rows[1].label.fontSize==readingSize,"objective setting changed reading text")
assert(P.context.scroll==0,"unchanged reading pane jumped at its top")
objectiveMenu[1].func();assert(P:Settings().objectivesize==12)
objectiveMenu[2].func();assert(P:Settings().objectivesize==13)
P:SetContextSize(22)
assert(P.action.rows[1].label.fontSize==P.context.rows[1].label.fontSize and P.action.rows[2].label.fontSize==13,"inline prose did not use independent reading type")
assert(P.action.rows[1].goal==intro and P.action.rows[2].goal==short and P.action.rows[3].goal==after,"font changes reordered authored prose")
P:SetContextSize(14)
P.read:GetScript("OnClick")()
show({short,direction,unknown,context})
assert(not P:ReadingActive() and P.action:IsShown() and P.context.scroll==0,"new step inherited hidden Actions")
scroll=P.context.scroll
local s=P:Settings();local savedSplit=s.split;s.collapsed=true;ZGV:UpdateParchment()
assert(not P.context:IsShown() and P.divider:IsShown() and not P.context.bar:IsShown())
s.collapsed=false;ZGV:UpdateParchment();assert(s.split==savedSplit and P.context.scroll==scroll)
for _,height in ipairs({380,400,440,520,700}) do
 for _,tools in ipairs({false,true}) do
  for _,split in ipairs({0,0.01,0.5,0.99,1}) do
   s.width,s.height,s.tools,s.split=320,height,tools,split
   ZGV:UpdateParchment()
   local a,c,top=P:Allocation(height,tools,true,false,false,split)
   assert(a>=160 and c+P.divider:GetHeight()>=144 and a+c+P.divider:GetHeight()+top<=height,"split violated protected allocation")
   local actualAction=P.action:GetHeight()+P.headingHit:GetTop()-P.action:GetTop()
   assert(actualAction>=160 and P.context:GetHeight()+P.divider:GetHeight()>=144,"rendered minimum regions are squeezed")
   assert(P.context:GetBottom()>=ZGV.Frame:GetBottom(),"context extends beyond compact window")
   assert(P.action:GetTop()<=P.headingHit:GetBottom(),"action viewport covers its fixed heading")
  end
 end
end
s.width,s.height,s.tools,s.split=w,h,false,savedSplit
ZGV:UpdateParchment()
-- Explicit compact command preserves anchor, chosen split and client/addon scale.
local oldX,oldY,oldSplit,oldScale=s.x,s.y,s.split,profile.framescale
s.width,s.height,s.tools=440,600,true
SlashCmdList.ZGVPARCHMENT("compact")
assert(s.width<w+1 and s.height<600 and not s.tools)
assert(s.x==oldX and s.y==oldY and s.split==oldSplit and profile.framescale==oldScale)
s.width,s.height=w,h;ZGV:UpdateParchment()
local goals={}
for i=1,45 do goals[i]=goal(string.rep("A deliberately long name ",8)..i,"kill") end
show(goals)
assert(P.action.rows[45].goal==goals[45] and P.action.rows[45]:IsShown(),"row pool lost content after 20 rows")
assert(P.action.range>0)
P.action.bar:SetValue(P.action.range)
assert(P.action.rows[45]:GetBottom()>=P.action:GetBottom() and P.action.rows[45]:GetTop()<=P.action:GetTop(),"last objective unreachable at end of scroll")
ZGV:UpdateParchment();assert(P.action.scroll==P.action.range)
show({context})
assert(P.context:IsShown() and not P.action:IsShown() and P.continue:IsShown())
assert(P.context.scroll==0,"genuine step transition retained scroll")
local confirm=goal("Read on","confirm")
show({context,confirm});P.continue:GetScript("OnClick")()
assert(ZGV.clicked==confirm,"story Continue bypassed confirm branching")
local other=goal("Choose another route","confirm")
show({context,confirm,other})
assert(P.action:IsShown() and P.action.rows[2].goal==other,"multiple choices lost")
s.plaincontext=true
show({direction});assert(P.context:IsShown() and not P.action:IsShown())
s.plaincontext=false
local item=goal("Use the very long item name","use",{spec={type="item",itemid=123,icon={file="atlas",coords={0,1,0,1}}}})
show({item,context})
assert(P.action.rows[1].inlineActionSpec==item.spec)
assert(P.action.rows[1].actionHolder.icon.texture=="atlas")
assert(not P.action.rows[1].marker:IsShown(),"objective symbol obscures an inline item button")
-- Test clipping with explicit holder positions, independent of the frame double's font metrics.
local row=P.action.rows[1]
local realTop,realBottom=row.actionHolder.GetTop,row.actionHolder.GetBottom
row.actionHolder.GetTop=function() return P.action:GetTop()-2 end
row.actionHolder.GetBottom=function() return P.action:GetTop()-24 end
assert(P:HolderVisible(row,P.action))
P:SecureButtons();assert(P.secure.buttons[1]:IsShown())
local actionOffset=P.action.scroll
P.read:GetScript("OnClick")()
assert(not P.secure.buttons[1]:IsShown(),"reading mode left an item target over hidden Actions")
local hiddenActionScroll=P.action.scroll
P.context.wheel(nil,-1)
assert(P.action.scroll==hiddenActionScroll,"reading wheel moved hidden Actions")
P.back:GetScript("OnClick")()
assert(P.secure.buttons[1]:IsShown() and P.action.scroll==actionOffset,"return failed to restore item interaction")
row.actionHolder.GetTop=function() return P.action:GetTop()+1 end
assert(not P:HolderVisible(row,P.action));P:SecureButtons();assert(not P.secure.buttons[1]:IsShown())
combat=true;P:SecureButtons();ZGV:UpdateParchment() -- any attribute mutation errors in the double
combat=false
row.actionHolder.GetTop,row.actionHolder.GetBottom=realTop,realBottom
for _,scale in ipairs({0.75,1,1.5}) do profile.framescale=scale;ZGV:UpdateParchment();assert(ZGV.Frame:GetWidth()==w) end
-- Match the native settings path, which calls SetScale without UpdateFrame.
ZGV:ParchmentTick(0.1)
local rebound=0
local secure=P.SecureButtons
P.SecureButtons=function(self) rebound=rebound+1;return secure(self) end
ZGV.Frame:SetScale(1.2);ZGV:ParchmentTick(0.1)
assert(rebound>0,"direct scale change left secure targets at old coordinates")
P.SecureButtons=secure
-- SavedVariables round trip: reconstruct viewer state while keeping the actual profile table.
s.width,s.height,s.split,s.x,s.y,s.collapsed,s.tools=410,600,0.73,222,333,true,true
s.contextsize=22
profile.fontsize=15
P.anchored=nil;ZGV:UpdateParchment()
assert(ZGV.Frame:GetLeft()==222 and ZGV.Frame:GetBottom()==333)
P.root=nil;P.initialized=nil;P.anchored=nil;ZGV:UpdateParchment()
assert(ZGV.Frame:GetWidth()==410 and ZGV.Frame:GetHeight()==600 and P:Settings().split==0.73)
assert(not P.context:IsShown() and P.utility:IsShown())
assert(P:Settings().contextsize==22 and P.context.rows[1].label.fontSize==22,"Context size did not survive profile round trip")
assert(P:Settings().objectivesize==15 and P.action.rows[1].label.fontSize==15,"objective size did not survive profile round trip")
P.read:GetScript("OnClick")()
assert(P.context:IsShown() and P:Settings().collapsed,"reading mode changed the saved collapsed preference")
P.back:GetScript("OnClick")()
assert(not P.context:IsShown() and P:Settings().split==0.73,"reading return lost collapsed layout")
P.browsing=true;ZGV:UpdateParchment()
assert(P.action.rows[1].goal.browse==1)
P.browsing=false;ZGV:UpdateParchment()
P.action.rows[1].clicker:GetScript("OnClick")(P.action.rows[1].clicker,"RightButton")
assert(ZGV.clicked==item and ZGV.clickButton=="RightButton","browsing replaced normal goal interactions")
-- Drive the same shipped fixture through the full viewer in this frame double.
ZGV.L=setmetatable({coords="%s,%s",stepgoal_use="Use %s"},{__index=function(_,k) return k end})
ZGV.LM={};ZGV.db.char={};ZGV.BZL={};ZGV.BSZL={};ZGV.BFL={}
ZGV.StandingNamesEngRev={};ZGV.dailyQuests={};ZGV.instantQuests={}
ZGV.recentlyCompletedGoals={};ZGV.recentlyStickiedGoals={}
ZGV.completedQuests={};ZGV.questsbyid={}
tinsert,tremove=table.insert,table.remove
function TableKeys(t) local result={} for k in pairs(t or {}) do result[#result+1]=k end return result end
function ZygorGuidesViewer_L() return ZGV.L end
QUEST_MONSTERS_KILLED="%s slain: %d/%d"
UnitLevel=function() return 10 end
UnitRace=function() return "Night Elf","NightElf" end
UnitClass=function() return "Druid","DRUID" end
UnitFactionGroup=function() return "Alliance" end
GetRealZoneText=function() return "Darnassus" end
GetItemCount=function() return 0 end
function ZGV:GetItemData() return "Refreshing Spring Water" end
function ZGV:RaceClassMatch() return true end
function ZGV:GetGoalActionSpec(g)
    if g.script then return {type="macro",macrotext="/run "..g.script,icon="fixture-icon"} end
end
local fixtureSource
function ZGV:RegisterGuide(_,raw) fixtureSource=raw end
assert(loadfile(root.."/Goal.lua"))()
assert(loadfile(root.."/Step.lua"))()
assert(loadfile(root.."/Parser.lua"))()
assert(loadfile(root.."/Guides/Tests/ParchmentFixtures.lua"))()
local fixtureGuide=assert(ZGV:ParseEntry(fixtureSource))
s.split,s.collapsed,s.plaincontext=0.55,false,false
profile.fontsize=13
for _,geometry in ipairs({{320,380,true},{340,400,false},{410,600,true}}) do
for _,objectiveSize in ipairs({12,13,16}) do
profile.fontsize=objectiveSize
for _,size in ipairs({14,16,18,20,22}) do
s.contextsize=size
s.width,s.height,s.tools=geometry[1],geometry[2],geometry[3]
ZGV.CurrentGuide=fixtureGuide
for n,step in ipairs(fixtureGuide.steps) do
    ZGV.CurrentStep=step;ZGV.CurrentStepNum=n
    ZGV:UpdateParchment()
    assert(P.action.scroll==0 and P.context.scroll==0,"fixture transition did not reset scrolling")
    local actions,context,story=P:Partition(step,false)
    for _,entry in ipairs({{P.action,actions},{P.context,context}}) do
        local pane,goals=entry[1],entry[2]
        for i,g in ipairs(goals) do
            assert(pane.rows[i].goal==g and pane.rows[i]:IsShown(),"fixture lost rendered row")
            assert(pane.rows[i].label:GetHeight()>=pane.rows[i].label:GetStringHeight(),"fixture text was capped")
            if pane.rows[i].tip:IsShown() then
                assert(pane.rows[i].tip:GetBottom()>=pane.rows[i]:GetBottom(),"direction tip was not included in row height")
            end
        end
        if pane:IsShown() and #goals>0 then
            pane.bar:SetValue(pane.range)
            local last=pane.rows[#goals]
            assert(last:GetBottom()>=pane:GetBottom(),"final fixture line inaccessible")
            local offset=pane.scroll
            ZGV:UpdateParchment()
            assert(pane.scroll==offset,"fixture progress refresh reset scrolling")
        end
    end
    if n==2 then assert(P.context.range>0,"long mixed fixture did not overflow Context") end
    if n==7 then assert(P.action.range>0 and P.action.rows[32].goal==step.goals[32],"32-row fixture failed") end
    if n==8 then assert(story and P.context.range>0 and P.continue:IsShown(),"long reading state failed") end
    if n==5 and objectiveSize<=13 then assert(P.action.range==0,"four short fixture objectives still need routine scrolling") end
    if n==7 then assert(P.action.rows[32].label.fontSize==objectiveSize,"overflow shrank the selected objective type") end
    if story then
        assert(P.context:GetBottom()>=P.readerFooter:GetTop(),"story pane covered fixed Continue/font controls")
        local footerTop=P.readerFooter:GetTop()
        P.context.wheel(nil,1)
        assert(P.readerFooter:GetTop()==footerTop,"reading scroll moved its fixed controls")
    elseif #context>0 then
        local chosenSplit=s.split
        P.read:GetScript("OnClick")()
        assert(P:ReadingActive() and not P.action:IsShown() and not P.divider:IsShown())
        P.context.bar:SetValue(P.context.range)
        assert(P.context.rows[#context]:GetBottom()>=P.context:GetBottom(),"last reading line inaccessible")
        P.back:GetScript("OnClick")()
        assert(s.split==chosenSplit and P.action:IsShown(),"fixture reading mode lost saved split")
    end
end
end -- explicit Context font sizes
end -- objective size limits and baseline
end -- compact / minimum / expanded fixture geometries
assert(loadfile(root.."/../tools/ui/real_step_samples.lua"))()(root,ZGV)
P:Suspend();assert(not P.root:IsShown())
print("PASS: parchment partitions, dynamic rows, protected allocations, independent scrolling, completion styles, Context reflow/anchors, explicit reading/auto-progress hold, fixed reader controls, item targets, lockdown, scale, profile round trip and browsing")

-- New default flow: even explicit legacy Context remains in authored order.
profile.parchment.layout=nil
profile.parchment.plaincontext=true
profile.parchment.collapsed=true
profile.fontsize,profile.fontsecsize=18,8
P:SetContextSize(17)
local introduction=goal("Why this task matters.",nil,{context=true})
local task=goal("Go to the next room.","goto",{tooltip="Use the upper bridge."})
local ending=goal("Keep this unfamiliar row.","unknown",{context=true})
show({introduction,task,ending})
assert(P.action:IsShown() and not P.context:IsShown() and not P.divider:IsShown())
assert(P.action.rows[1].goal==introduction and P.action.rows[2].goal==task and P.action.rows[3].goal==ending,
    "flow hid or reordered essential/unknown content")
assert(P.action.rows[1].label.fontSize==17 and P.action.rows[2].label.fontSize==18 and P.action.rows[2].tip.fontSize==8,
    "normal primary/secondary and reading sizes are not independent")
local flowOffset=P.action.scroll
profile.fontsize,profile.fontsecsize=20,13
ZGV:UpdateParchment()
assert(P.action.rows[2].label.fontSize==20 and P.action.rows[2].tip.fontSize==13)
assert(not P:ReadingActive(),"flow should not hold automatic progression")

-- The reader is explicitly associated, independent, and does not steal actions.
local background={title="A researched background",body=string.rep("Background text with a useful explanation. ",300)}
ZGV.CurrentStep.parchmentBackground=background
ZGV:UpdateParchment()
assert(P.backgroundLink:IsShown() and P.backgroundLink.label.valueText:find(background.title,1,true))
P.backgroundLink:GetScript("OnClick")()
assert(P.background:IsShown() and P.action:IsShown() and not P:ReadingActive())
assert(P.background.pane.reading and P.background.pane.range>0)
P.background.pane.bar:SetValue(72)
local readingOffset=P.background.pane.scroll
show({goal("Next live task.","talk")})
assert(not P.backgroundLink:IsShown() and P.background:IsShown())
assert(P.background.entry==background and P.background.pane.scroll==readingOffset,
    "automatic step refresh replaced or scrolled the selected background")
P.background.close:GetScript("OnClick")()
local current=ZGV.CurrentStep
assert(not P.background:IsShown() and ZGV.CurrentStep==current)
P:OpenBackground(background)
assert(P.background.pane.scroll==readingOffset,"reopening same passage lost position")
P:Suspend()
assert(not P.background:IsShown(),"reader survived leaving parchment mode")

-- Migration never overwrites an explicitly saved native size or reading size.
local savedProfile=ZGV.db.profile
ZGV.db.profile={fontsize=10,fontsecsize=7,parchment={objectivesize=16,contextsize=19}}
local migrated=P:Settings()
assert(ZGV.db.profile.fontsize==10 and ZGV.db.profile.fontsecsize==7 and migrated.contextsize==19)
assert(migrated.legacyobjectivesize==16,"previous prototype size was not retained for reference")
ZGV.db.profile={parchment={objectivesize=15}}
assert(P:Settings().objectivesize==15 and ZGV.db.profile.fontsecsize==13)
ZGV.db.profile=savedProfile
print("PASS: unified authored flow, native font controls, safe migration, explicit independent background reader, and progression without reading hold")
assert(P.background.pane.rows[1].clicker:GetScript("OnClick")==nil,"background retained native goal interaction")
-- Check the product excerpts at each supported geometry in the frame harness.
local adventureSource
function ZGV:RegisterGuide(title,raw) adventureSource=raw end
assert(loadfile(root.."/Guides/Tests/AdventureFixture.lua"))()
local adventureGuide=assert(ZGV:ParseEntry(adventureSource));adventureGuide.title=ZGV.AdventureFixtureTitle
ZGV.CurrentGuide=adventureGuide
profile.fontsize,profile.fontsecsize=13,11
local preset=P:Settings();preset.contextsize=14;preset.layout="flow"
for _,geometry in ipairs({{320,380},{340,400},{410,600}}) do
    preset.width,preset.height=geometry[1],geometry[2]
    for i,step in ipairs(adventureGuide.steps) do
        ZGV.CurrentStep,ZGV.CurrentStepNum=step,i
        ZGV:UpdateParchment()
        assert(P.action:IsShown() and not P.context:IsShown())
        assert(P.action.range==0,"product excerpt requires scrolling at compact baseline")
        assert(P.action.rows[2].goal==step.goals[2])
        assert(P.backgroundLink:IsShown()==(i==4 or i==6))
        local bottom=P.action.rows[2]:GetBottom()
        assert(bottom>=P.action:GetBottom(),"product action clipped by viewport")
    end
end
print("PASS: all six product excerpts fit the 320x380 minimum, 340x400 baseline and larger geometry in approximate frame metrics")

-- A+ reader lifecycle: explicit toggle/manual navigation, automatic progress,
-- guide replacement even when the current step object is unchanged, and resize.
ZGV.CurrentGuide=adventureGuide
ZGV.CurrentStep=adventureGuide.steps[6];ZGV.CurrentStepNum=6
ZGV:UpdateParchment()
local reading=ZGV:AdventureFixtureBackground(ZGV.CurrentStep)
P.backgroundLink:GetScript("OnClick")()
assert(P.background:IsShown())
P.backgroundLink:GetScript("OnClick")()
assert(not P.background:IsShown(),"Read did not toggle the same passage closed")
P.backgroundLink:GetScript("OnClick")()
assert(P.background:IsShown())
local mainWidth,mainHeight=ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight()
P.background.pane.bar:SetValue(50)
local beforeResize=P:ScrollAnchor(P.background.pane)
P.background:SetSize(410,520)
local afterResize=P:ScrollAnchor(P.background.pane)
assert(P.background.pane:GetWidth()==378 and P.background.pane:GetHeight()>300)
if beforeResize and afterResize and P.background.pane.range>0 then
    assert(math.abs(beforeResize.fraction-afterResize.fraction)<0.001,"resize lost reading anchor")
end
assert(ZGV.Frame:GetWidth()==mainWidth and ZGV.Frame:GetHeight()==mainHeight,"reader resized main guide")
P.background.grip:GetScript("OnMouseUp")()
assert(preset.readerwidth==410 and preset.readerheight==520 and preset.readerx and preset.readery)
profile.windowlocked=true;ZGV:UpdateParchment()
assert(not P.background.grip:IsShown())
P.background.grip:GetScript("OnMouseDown")(P.background.grip,"LeftButton")
assert(not P.background.sizing,"lock allowed reader resizing")
profile.windowlocked=false;ZGV:UpdateParchment()
P.background.grip:GetScript("OnMouseDown")(P.background.grip,"LeftButton")
assert(P.background.sizing,"reader resize grip did not start sizing")
P.background:SetSize(320,300)
P.background.grip:GetScript("OnMouseUp")()
assert(P.background.pane:GetBottom()>=P.background:GetBottom(),"minimum reader extends beyond its frame")
assert(P.background.title:GetBottom()>P.background.pane:GetTop(),"reader title overlaps its text")
local last=ZGV.CurrentStep.goals[#ZGV.CurrentStep.goals]
local lastRow=P.action.rows[#ZGV.CurrentStep.goals]
assert(P.backgroundLink:GetTop()<lastRow:GetBottom(),"Read overlaps the last objective")
assert(lastRow:GetBottom()-P.backgroundLink:GetTop()<25,"Read remains detached at bottom of the window")
-- Simulated automatic progression: no manual navigation API is called.
ZGV.CurrentStep=adventureGuide.steps[5];ZGV.CurrentStepNum=5
ZGV:UpdateParchment()
assert(P.background:IsShown() and P.background.entry==reading and not P:ReadingActive())
local previousSkip=ZGV.SkipStep
ZGV.SkipStep=function(_,delta,fast) ZGV.manualDelta=delta;ZGV.manualFast=fast end
P.next:GetScript("OnClick")(P.next,"LeftButton")
assert(not P.background:IsShown() and ZGV.manualDelta==1,"manual Next did not close reader")
P:OpenBackground(reading)
P.prev:GetScript("OnClick")(P.prev,"RightButton")
assert(not P.background:IsShown() and ZGV.manualDelta==-1 and ZGV.manualFast)
ZGV.SkipStep=previousSkip
P:OpenBackground(reading)
local oldGuide=ZGV.CurrentGuide
ZGV.CurrentGuide={title="Another guide",steps=oldGuide.steps}
ZGV:UpdateParchment()
assert(not P.background:IsShown(),"guide change kept stale reader open")
ZGV.CurrentGuide=oldGuide;ZGV:UpdateParchment()
assert(not P.background:IsShown(),"return to a guide unexpectedly reopened reader")
assert(P.root.paper.texture:find("ParchmentPage.tga",1,true) and P.background.paper.texture==P.root.paper.texture,
    "guide and reader do not share the bundled A+ paper")
print("PASS: A+ reader toggle, manual-next/previous closure, automatic-progress retention, guide-change closure, resize/lock/persistence, and adjacent reading link")
-- Reconstruct the reader as on a new session: saved geometry, closed by default.
P:CloseBackground()
local previousReader=P.background
local expectedWidth,expectedHeight=preset.readerwidth,preset.readerheight
local expectedX,expectedY=preset.readerx,preset.readery
P.background=nil
P:OpenBackground(reading)
assert(P.background~=previousReader and P.background:GetWidth()==expectedWidth and P.background:GetHeight()==expectedHeight)
assert(P.background:GetLeft()==expectedX and P.background:GetBottom()==expectedY,"saved reader position was not restored")
P.background.pane.bar:SetValue(math.min(30,P.background.pane.range))
local fontAnchor=P:ScrollAnchor(P.background.pane)
P:SetContextSize(23)
local reflowed=P:ScrollAnchor(P.background.pane)
if fontAnchor and reflowed and P.background.pane.range>0 then
    assert(math.abs(fontAnchor.fraction-reflowed.fraction)<0.001,"reading-size change lost the reader anchor")
end
ZGV.Frame:GetScript("OnHide")()
assert(not P.background:IsShown(),"hiding the main guide retained the reader")
print("PASS: reader geometry reconstructs across sessions, reading-size reflow preserves position, and main-guide hide closes the reader")
P:OpenBackground(reading)
P.background:SetSize(500,500)
assert(P.background.rule.ornament:GetWidth()==16 and P.background.rule.ornament:GetHeight()==12,
    "reader resize stretched the title ornament")
P.background.grip:GetScript("OnMouseDown")(P.background.grip,"LeftButton")
assert(P.background.sizing)
P:CloseBackground()
assert(not P.background.sizing and not P.background:IsShown(),"reader close left an active resize")
