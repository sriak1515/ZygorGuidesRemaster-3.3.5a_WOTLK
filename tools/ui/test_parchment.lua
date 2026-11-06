-- Lua 5.1, no WoW client. Stateful frame double for layout/scroll/refresh logic;
-- font metrics are deliberately approximate and do not establish client rendering.
local root=arg[1] or "ZygorGuidesViewerRM"
local combat=false
local Frame={}
Frame.__index=Frame
local function new(parent) return setmetatable({parent=parent,w=1,h=1,shown=true,scripts={},scale=1,value=0},Frame) end
function Frame:SetSize(w,h) assert(w>=0 and h>=0);self.w,self.h=w,h end
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
function Frame:RegisterEvent() end
for _,name in ipairs({"SetVertexColor","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetTextColor","SetJustifyH","SetJustifyV","RegisterForClicks","RegisterForDrag","EnableMouseWheel","EnableMouse","SetOrientation","SetValueStep","SetFrameStrata","SetHighlightTexture","SetTexCoord","SetMovable","SetResizable","SetMinResize","SetClampedToScreen","SetClampRectInsets","SetAlpha"}) do Frame[name]=function() end end
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
local profile={skin="remaster",displaymode="guide",framescale=1}
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
local closedBody=P.actionHeight+P.contextHeight
P:Settings().tools=true;ZGV:UpdateParchment()
local openBody=P.actionHeight+P.contextHeight
assert(closedBody-openBody<=P.utility:GetHeight()+4,"tools consume more than their single row")
local savedWidth,savedHeight=ZGV.Frame:GetWidth(),ZGV.Frame:GetHeight()
ZGV:OpenQuickMenu(P.settings)
local readingOption=assert(openedMenu[1])
assert(readingOption.text=="Read untagged text in Context")
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
-- Test clipping with explicit holder positions, independent of the frame double's font metrics.
local row=P.action.rows[1]
local realTop,realBottom=row.actionHolder.GetTop,row.actionHolder.GetBottom
row.actionHolder.GetTop=function() return P.action:GetTop()-2 end
row.actionHolder.GetBottom=function() return P.action:GetTop()-24 end
assert(P:HolderVisible(row,P.action))
P:SecureButtons();assert(P.secure.buttons[1]:IsShown())
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
P.anchored=nil;ZGV:UpdateParchment()
assert(ZGV.Frame:GetLeft()==222 and ZGV.Frame:GetBottom()==333)
P.root=nil;P.initialized=nil;P.anchored=nil;ZGV:UpdateParchment()
assert(ZGV.Frame:GetWidth()==410 and ZGV.Frame:GetHeight()==600 and P:Settings().split==0.73)
assert(not P.context:IsShown() and P.utility:IsShown())
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
for _,geometry in ipairs({{320,380,true},{340,400,false},{410,600,true}}) do
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
end

end -- compact / minimum / expanded fixture geometries
P:Suspend();assert(not P.root:IsShown())
print("PASS: parchment partitions, dynamic rows, protected allocations, scroll isolation, progress stability, story confirms, item atlas, clipped secure targets, lockdown, scale, profile round trip and browsing")
