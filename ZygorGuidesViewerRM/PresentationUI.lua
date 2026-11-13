-- Experimental adventure viewer. Native Parchment rows; Zygor owns progression.
local ZGV=ZygorGuidesViewer
local P=ZGV.Presentation
local white="Interface\\Buttons\\WHITE8X8"
local ink={0.19,0.17,0.13}
local pale={0.91,0.87,0.76}
local gold={0.84,0.73,0.51}
-- Same bundled objective atlas/mapping as Parchment; no new icon assets.
local icons={accept=5,turnin=6,kill=7,get=8,collect=8,buy=8,
    goal=9,home=10,fpath=11,goto=12,talk=13}
local function clean(value)
    return tostring(value or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local function shown(frame,value) if value then frame:Show() else frame:Hide() end end
local function label(parent,size,color)
    local fs=parent:CreateFontString(nil,"ARTWORK")
    local font=GameFontNormal and GameFontNormal:GetFont() or STANDARD_TEXT_FONT
    if not fs:SetFont(font,size) then fs:SetFont(STANDARD_TEXT_FONT,size) end
    fs:SetJustifyH("LEFT");fs:SetJustifyV("TOP");fs:SetSpacing(3)
    fs:SetTextColor(unpack(color or pale))
    return fs
end
local function button(parent,value,width,callback)
    local b=CreateFrame("Button",nil,parent)
    b:SetSize(width,22)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b.label=label(b,12,gold);b.label:SetPoint("CENTER");b.label:SetText(value)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetScript("OnClick",callback)
    return b
end
local function tooltip(control,value)
    control:SetScript("OnEnter",function(frame)
        GameTooltip:SetOwner(frame,"ANCHOR_TOPRIGHT")
        GameTooltip:SetText(type(value)=="function" and value() or value,nil,nil,nil,nil,true)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
local function surface(frame,paper)
    frame:SetBackdrop({bgFile=white,edgeFile=ZGV.DIR.."\\Skin\\popup_border",edgeSize=12,
        insets={left=3,right=3,top=3,bottom=3}})
    if paper then
        frame:SetBackdropColor(0.86,0.81,0.69,1)
        frame.paper=frame:CreateTexture(nil,"BACKGROUND")
        frame.paper:SetTexture(ZGV.DIR.."\\Skin\\ParchmentPage.tga")
        frame.paper:SetPoint("TOPLEFT",4,-4);frame.paper:SetPoint("BOTTOMRIGHT",-4,4)
    else
        frame:SetBackdropColor(0.08,0.11,0.09,1)
        frame.grain=frame:CreateTexture(nil,"BACKGROUND")
        frame.grain:SetAllPoints(frame)
        frame.grain:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        frame.grain:SetVertexColor(0.44,0.49,0.36,0.22)
    end
    frame:SetBackdropBorderColor(0.55,0.47,0.32,1)
    frame:EnableMouse(true)
end

-- Independent scroll regions. Unique template names are required by Wrath.
local function pane(parent,serial,suffix)
    local f=CreateFrame("ScrollFrame","ZGVAdventure"..suffix..serial,parent,"UIPanelScrollFrameTemplate")
    f.child=CreateFrame("Frame",nil,f);f.child:SetSize(1,1);f:SetScrollChild(f.child)
    f.offset=0;f.range=0
    f:SetScript("OnVerticalScroll",function(_,offset) f.offset=offset end)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel",function(_,delta)
        local bar=_G[f:GetName().."ScrollBar"]
        bar:SetValue(math.max(0,math.min(f.range,f.offset-delta*36)))
    end)
    return f
end
local function finishPane(f,bottom,reset)
    local offset=reset and 0 or f.offset
    f.child:SetHeight(math.max(1,bottom))
    f:UpdateScrollChildRect()
    f.range=math.max(0,bottom-f:GetHeight())
    local bar=_G[f:GetName().."ScrollBar"]
    bar:SetMinMaxValues(0,f.range)
    bar:SetValue(math.min(offset,f.range))
    f:SetVerticalScroll(math.min(offset,f.range))
    shown(bar,f.range>0)
end

-- Geometry is a separate profile preference; native layout/progress is never saved here.
local function clamp(value,lo,hi) return math.max(lo,math.min(hi,value)) end
function P:Settings()
    local profile=ZGV.db.profile
    if self.fixture then
        self.fixtureSettings=self.fixtureSettings or self.Copy(profile.adventure or {width=300,height=360})
        return self.fixtureSettings
    end
    profile.adventure=profile.adventure or {}
    local s=profile.adventure
    s.width=clamp(tonumber(s.width) or 300,280,560)
    s.height=clamp(tonumber(s.height) or 360,280,720)
    return s
end
function P:SaveGeometry()
    local host=self.host
    if not host then return end
    local s=self:Settings()
    s.width,s.height=host:GetWidth(),host:GetHeight()
    -- Fractions survive UI scale/resolution changes; the frame is also clamped.
    local scale=host:GetEffectiveScale()/UIParent:GetEffectiveScale()
    s.x=clamp((host:GetLeft() or 0)*scale/UIParent:GetWidth(),0,1)
    s.y=clamp((host:GetBottom() or 0)*scale/UIParent:GetHeight(),0,1)
end
function P:ConstrainGeometry(host)
    local scale=UIParent:GetEffectiveScale()/host:GetEffectiveScale()
    local width=math.max(280,math.min(560,UIParent:GetWidth()*scale-16))
    local height=math.max(280,math.min(720,UIParent:GetHeight()*scale-16))
    host:SetMinResize(280,280);host:SetMaxResize(width,height)
    local w,h=clamp(host:GetWidth(),280,width),clamp(host:GetHeight(),280,height)
    if w~=host:GetWidth() or h~=host:GetHeight() then host:SetSize(w,h) end
end
function P:ApplyGeometry(host)
    local s=self:Settings()
    host:SetMovable(true);host:SetResizable(true);host:SetClampedToScreen(true)
    host:SetMinResize(280,280);host:SetMaxResize(560,720)
    host:SetSize(s.width,s.height)
    self:ConstrainGeometry(host)
    host:ClearAllPoints()
    if tonumber(s.x) and tonumber(s.y) then
        local scale=UIParent:GetEffectiveScale()/host:GetEffectiveScale()
        host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",clamp(s.x,0,1)*UIParent:GetWidth()*scale,clamp(s.y,0,1)*UIParent:GetHeight()*scale)
    else host:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-40,160) end
end
function P:SecureButtons()
    if ZGV.Parchment then ZGV.Parchment:SecureButtons(self) end
end
function P:Relayout()
    if self.layingOut or not self.panel then return end
    self.layingOut=true
    self:SyncHostVisibility()
    local ok,err=true,nil
    if self.lastSnapshot then ok,err=pcall(self.Render,self,self.lastSnapshot) end
    self.layingOut=nil
    if not ok then
        self:Stop()
        ZGV:Print("Adventure layout failed; restored fallback. "..tostring(err))
    end
end

-- Story presentation state never changes objective evidence or native pause.
function P:ToggleStory()
    if not self.storyEntry then return end
    self.storyOpen=not self.storyOpen
    self.storyCue=false
    self:LayoutPanels()
end
function P:FoldStory(interrupted)
    if interrupted and self.storyOpen then self.storyCue=true
    elseif not interrupted then self.storyCue=false end
    self.storyOpen=false
    self:LayoutPanels()
end
function P:LayoutPanels()
    if not self.panel or not self.lastSnapshot then return end
    local panel=self.panel
    local w,h=panel:GetWidth(),panel:GetHeight()
    -- Utilities borrow one line only when requested; normal play has no footer.
    shown(self.toolsRow,self.toolsOpen)
    self.lock.label:SetText(ZGV.db.profile.windowlocked and "Unlock" or "Lock")
    local top=self.toolsOpen and 88 or 62
    self.stepTitle:ClearAllPoints();self.stepTitle:SetPoint("TOPLEFT",12,-top)
    self.stepTitle:SetWidth(w-24);self.stepTitle:SetHeight(0)
    local titleHeight=clamp(self.stepTitle:GetStringHeight(),14,32)
    self.stepTitle:SetHeight(titleHeight)
    top=top+titleHeight+5
    local bearing=clean(self.lastSnapshot.navigation.title)
    local hasBearing=bearing~="" and bearing~=clean(self.lastSnapshot.step.title)
    shown(self.bearing,hasBearing)
    if hasBearing then
        self.bearing:ClearAllPoints();self.bearing:SetPoint("TOPLEFT",12,-top)
        self.bearing:SetWidth(w-24);self.bearing:SetHeight(0)
        local height=clamp(self.bearing:GetStringHeight(),12,28)
        self.bearing:SetHeight(height);top=top+height+6
    end
    self.objectiveTop=top
    self.objectives:ClearAllPoints()
    self.objectives:SetPoint("TOPLEFT",12,-top);self.objectives:SetPoint("BOTTOMRIGHT",-30,12)
    self.empty:ClearAllPoints();self.empty:SetPoint("TOPLEFT",12,-top)
    self.empty:SetWidth(w-42)
    if self.fixture then self.objectives.child:SetWidth(math.max(100,w-58)) end

    local scale=panel:GetEffectiveScale()
    local screen=UIParent:GetWidth()*UIParent:GetEffectiveScale()/scale
    local left=panel:GetLeft() or 0
    local right=screen-left-w
    local gap=4
    local space=math.max(left,right)-gap
    local width=math.min(clamp(w+40,300,400),space)
    local fits=width>=260
    local onLeft=left>=width+gap
    self.storyFits=fits
    self.storyPanel:ClearAllPoints()
    if onLeft then self.storyPanel:SetPoint("TOPRIGHT",panel,"TOPLEFT",-gap,0)
    else self.storyPanel:SetPoint("TOPLEFT",panel,"TOPRIGHT",gap,0) end
    width=math.max(260,width)
    self.storyTitle:SetWidth(width-64);self.storyTitle:SetHeight(0)
    local storyTitleHeight=math.max(20,self.storyTitle:GetStringHeight())
    self.storyTitle:SetHeight(storyTitleHeight)
    self.storyRule:ClearAllPoints();self.storyRule:SetPoint("TOPLEFT",18,-(22+storyTitleHeight))
    self.storyRule:SetSize(width-36,12)
    local storyTop=storyTitleHeight+40
    self.storyText:SetWidth(width-52);self.storyPane.child:SetWidth(width-52)
    self.storyText:SetHeight(0)
    -- Short passages fit their content; long passages retain a bounded reader.
    local height=clamp(storyTop+self.storyText:GetStringHeight()+30,160,h)
    self.storyPanel:SetSize(width,height)
    self.storyPane:ClearAllPoints()
    self.storyPane:SetPoint("TOPLEFT",18,-storyTop);self.storyPane:SetPoint("BOTTOMRIGHT",-34,14)
    shown(self.storyPanel,self.storyEntry and self.storyOpen and fits)
    self.storyToggle:ClearAllPoints()
    if onLeft then self.storyToggle:SetPoint("TOPRIGHT",panel,"TOPLEFT",0,-34)
    else self.storyToggle:SetPoint("TOPLEFT",panel,"TOPRIGHT",0,-34) end
    self.storyToggle.label:SetText(self.storyCue and "!" or "")
    shown(self.storyToggle,self.storyEntry and not (self.storyOpen and fits))
    shown(self.grip,not ZGV.db.profile.windowlocked)
    self:SecureButtons()
end

function P:Render(snapshot)
    if not self.panel then return end
    self.lastSnapshot=snapshot
    local stepKey=snapshot.source..":"..tostring(snapshot.guide.id)..":"..tostring(snapshot.step.index)
    local newStep=stepKey~=self.renderStepKey
    self.renderStepKey=stepKey
    self.guideTitle:SetText((snapshot.source=="fixture" and "[Simulation] " or "")..clean(snapshot.guide.title or "Choose a guide"))
    self.stepTitle:SetText(clean(snapshot.step.title or "Current objectives"))
    self.position:SetText(tostring(snapshot.step.index or 0).." / "..tostring(snapshot.step.total or 0)..(snapshot.paused and "  Paused" or ""))
    self.progress:SetMinMaxValues(0,math.max(1,snapshot.step.total or 0))
    self.progress:SetValue(snapshot.step.index or 0)
    self.bearing:SetText(clean(snapshot.navigation.title))
    local rows,context={},{}
    for _,goal in ipairs(snapshot.goals) do
        if goal.role=="context" then
            context[#context+1]=clean(goal.text)
            if goal.hint then context[#context+1]=clean(goal.hint) end
        else rows[#rows+1]=goal end
    end
    local entry=snapshot.context
    if not entry and #context>0 then
        -- Explicit current-step context remains a fallback for other passages.
        entry={id=stepKey,title=snapshot.step.title or "Current context",body=table.concat(context,"\n\n")}
    end
    local identity=entry and (snapshot.source..":"..(entry.persistent and "story" or tostring(snapshot.guide.id))..":"..entry.id)
    local changed=identity~=self.storyIdentity
    self.storyEntry,self.storyIdentity=entry,identity
    if changed then
        self.storyOpen=entry and (not entry.persistent or entry.autoOpen) and not (InCombatLockdown() or self.fixtureCombat) or false
        self.storyCue=entry and not self.storyOpen or false
    end
    if entry then
        self.storyTitle:SetText(clean(entry.title))
        local reading=ZGV.db.profile.parchment and ZGV.db.profile.parchment.contextsize
        self.storyText:SetFont(self.storyText:GetFont(),math.max(12,math.min(24,tonumber(reading) or 16)))
        self.storyText:SetText(clean(entry.body))
    end
    self:LayoutPanels()
    if snapshot.source=="live" then
        local native={}
        for _,goal in ipairs(rows) do
            local current=ZGV.CurrentStep and ZGV.CurrentStep.goals[goal.index]
            if current then native[#native+1]=current end
        end
        ZGV.Parchment:Fill(self.objectives,native,self.objectives:GetWidth(),self.objectives:GetHeight(),ZGV.CurrentStep,newStep)
        if ZGV.ActionButtons_Refresh then ZGV:ActionButtons_Refresh() end
    else
        self.objectives.rows=self.objectives.rows or {}
        local y=0
        local size=math.max(11,math.min(20,tonumber(ZGV.db.profile.fontsize) or 13))
        for i,goal in ipairs(rows) do
            local row=self.objectives.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self.objectives.child)
                row.mark=row:CreateTexture(nil,"ARTWORK");row.mark:SetPoint("TOPLEFT",0,0)
                row.mark:SetSize(16,16);row.mark:SetTexture(ZGV.DIR.."\\Skin\\icons")
                row.text=label(row,size);row.text:SetPoint("TOPLEFT",22,0)
                row.hint=label(row,11,{0.69,0.72,0.66})
                self.objectives.rows[i]=row
            end
            row:ClearAllPoints();row:SetPoint("TOPLEFT",self.objectives.child,"TOPLEFT",0,-y)
            row:SetWidth(self.objectives.child:GetWidth())
            local complete=goal.status=="complete"
            local passive=not goal.action or goal.action=="" or goal.action=="info"
            row.iconIndex=complete and 3 or (icons[goal.action] or 4)
            row.mark:SetTexCoord((row.iconIndex-1)/16,row.iconIndex/16,0,1)
            shown(row.mark,not passive)
            row.text:SetFont(row.text:GetFont(),size)
            row.text:SetTextColor(unpack(complete and {0.56,0.65,0.56} or pale))
            row.text:SetWidth(row:GetWidth()-22);row.text:SetHeight(0)
            row.text:SetText(clean(goal.text)) -- Native text already contains exact counts.
            local textHeight=math.max(size,row.text:GetStringHeight())
            row.text:SetHeight(textHeight)
            row.hint:ClearAllPoints();row.hint:SetPoint("TOPLEFT",22,-textHeight-5)
            row.hint:SetWidth(row:GetWidth()-22);row.hint:SetHeight(0)
            row.hint:SetFont(row.hint:GetFont(),math.max(9,math.min(18,tonumber(ZGV.db.profile.fontsecsize) or 11)))
            row.hint:SetText(clean(goal.hint))
            shown(row.hint,goal.hint and goal.hint~="")
            local height=textHeight+(goal.hint and goal.hint~="" and row.hint:GetStringHeight()+5 or 0)+18
            row:SetHeight(height);row:Show();y=y+height
        end
        for i=#rows+1,#self.objectives.rows do self.objectives.rows[i]:Hide() end
        finishPane(self.objectives,y,newStep)
    end -- fixture rows
    self.empty:SetText(snapshot.available and "No current objectives." or "Select Guides to choose an adventure.")
    shown(self.empty,#rows==0)

    if entry then finishPane(self.storyPane,self.storyText:GetStringHeight()+12,changed) end
    self:LayoutPanels()
end

function P:SyncHostVisibility()
    if not self.panel or not self.host or not self.mode then return end
    shown(self.panel,self.host:IsVisible())
    self.panel:SetAlpha(self.host:GetAlpha())
    local scale=self.host:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if scale~=self.displayScale then self.displayScale=scale;self.panel:SetScale(scale) end
end

function P:CreatePanel(parent)
    -- Wrath can give new children level 128 even when their parent is >128.
    -- The live panel was observed at 151 with its children at 128, behind
    -- its opaque backdrop. Keep drawing independent of that
    -- hierarchy, while anchoring all geometry to the unchanged engine host.
    local panel=CreateFrame("Frame",nil,UIParent)
    self.panel=panel;self.root=panel;self.host=parent
    panel:SetAllPoints(parent);panel:SetFrameStrata(parent:GetFrameStrata());panel:SetFrameLevel(10)
    panel:SetScale(parent:GetEffectiveScale()/UIParent:GetEffectiveScale())
    surface(panel,false)
    self.panelSerial=(self.panelSerial or 0)+1
    self.toolsOpen=false
    self.header=CreateFrame("Frame",nil,panel)
    self.header:SetPoint("TOPLEFT",4,-4);self.header:SetPoint("TOPRIGHT",-4,-4);self.header:SetHeight(52)
    self.header:SetBackdrop({bgFile=white})
    self.header:SetBackdropColor(0.16,0.19,0.14,0.9)
    tooltip(self.header,function() return clean(self.lastSnapshot and self.lastSnapshot.guide.title).."\n"..clean(self.lastSnapshot and self.lastSnapshot.step.title).."\nDrag to move the adventure guide." end)
    self.header:EnableMouse(true);self.header:RegisterForDrag("LeftButton")
    self.header:SetScript("OnDragStart",function()
        if InCombatLockdown() or ZGV.db.profile.windowlocked then return end
        parent:StartMoving();self.moving=true
        ZGV.Parchment:ClearSecureButtons(self)
    end)
    self.header:SetScript("OnDragStop",function()
        parent:StopMovingOrSizing();self.moving=nil
        self:SaveGeometry();self:Relayout()
    end)
    self.controls={}
    for i,value in ipairs({"<",">"}) do
        local b=button(self.header,value,22,function(_,mouse) self:Navigate(i==1 and -1 or 1,mouse=="RightButton") end)
        b:SetPoint("TOPLEFT",4+(i-1)*24,-2);self.controls[i]=b
        ZGV.Parchment:StyleButton(b)
    end
    self.position=label(self.header,10,gold);self.position:SetPoint("TOPLEFT",58,-8)
    self.toolsToggle=button(self.header,"Tools",42,function() self.toolsOpen=not self.toolsOpen;self:Relayout() end)
    self.toolsToggle:SetPoint("TOPRIGHT",-28,-2);ZGV.Parchment:StyleButton(self.toolsToggle)
    self.closeGuide=button(self.header,"X",20,function()
        if self.fixture then self:Stop() else ZGV:ToggleFrame() end
    end)
    self.closeGuide:SetPoint("TOPRIGHT",-4,-2);ZGV.Parchment:StyleButton(self.closeGuide,true)
    tooltip(self.closeGuide,"Hide guide. Use the usual Zygor toggle to show it again.")
    self.guideTitle=label(self.header,12);self.guideTitle:SetPoint("TOPLEFT",8,-30)
    self.guideTitle:SetPoint("RIGHT",-8,0);self.guideTitle:SetHeight(18)
    self.progress=CreateFrame("StatusBar",nil,panel)
    self.progress:SetFrameLevel(self.header:GetFrameLevel()+1)
    self.progress:SetPoint("TOPLEFT",8,-28);self.progress:SetPoint("TOPRIGHT",-8,-28)
    self.progress:SetHeight(2);self.progress:SetStatusBarTexture(white);self.progress:SetStatusBarColor(unpack(gold))
    self.toolsRow=CreateFrame("Frame",nil,panel)
    self.toolsRow:SetPoint("TOPLEFT",8,-59);self.toolsRow:SetPoint("TOPRIGHT",-8,-59);self.toolsRow:SetHeight(24)
    for i,spec in ipairs({{"Guides",56,function(_,b)
            if self.fixture or InCombatLockdown() then return end
            if b=="RightButton" then ZGV:ToggleGuideManagerFrame("home") else ZGV:OpenGuideMenu() end
        end},
        {"Settings",60,function() ZGV:OpenOptions() end},
        {"Existing UI",76,function() self:Stop() end}}) do
        local b=button(self.toolsRow,spec[1],spec[2],spec[3]);self.controls[i+2]=b
        b:SetPoint("TOPLEFT",i==1 and 0 or (i==2 and 58 or 120),0)
    end
    self.lock=button(self.toolsRow,"Lock",54,function() ZGV:ToggleWindowLock() end)
    self.lock:SetPoint("TOPLEFT",198,0)
    for i,value in ipairs({"Previous step. Right-click: fast backward.","Next step. Right-click: fast forward.",
        "Choose a guide. Right-click: guide manager.","Guide font, reading size, scale and window lock.","Return to the original interface. Progress is retained."}) do
        tooltip(self.controls[i],value)
    end
    self.toolsRow:Hide()
    self.stepTitle=label(panel,12,gold)
    self.bearing=label(panel,10,{0.69,0.72,0.66})
    self.objectives=pane(panel,self.panelSerial,"Objectives");self.action=self.objectives
    self.objectives.adventure=true;self.objectives.rows={}
    self.objectives.bar=_G[self.objectives:GetName().."ScrollBar"]
    self.objectives.wheel=self.objectives:GetScript("OnMouseWheel")
    self.objectives:SetScript("OnVerticalScroll",function(_,offset)
        self.objectives.offset=offset;self:SecureButtons()
    end)
    self.empty=label(panel,12)
    self.storyToggle=button(panel,"",24,function() self:ToggleStory() end)
    self.storyToggle:SetHeight(30);ZGV.Parchment:StyleButton(self.storyToggle)
    self.storyToggle.label:ClearAllPoints();self.storyToggle.label:SetPoint("BOTTOMRIGHT",-1,1)
    self.storyToggle.icon=self.storyToggle:CreateTexture(nil,"ARTWORK")
    self.storyToggle.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    self.storyToggle.icon:SetSize(16,16);self.storyToggle.icon:SetPoint("CENTER",0,1)
    tooltip(self.storyToggle,function()
        return not self.storyFits and "Story: move the guide nearer an edge to make room." or (self.storyCue and "New story. Click to read." or "Story. Click to reread.")
    end)
    self.grip=button(panel,"/",18,function() end);self.grip:SetPoint("BOTTOMRIGHT",-3,2)
    tooltip(self.grip,"Drag to resize the guide and attached story panel.")
    self.grip:SetScript("OnMouseDown",function(_,b)
        if b~="LeftButton" or InCombatLockdown() or ZGV.db.profile.windowlocked then return end
        ZGV.Parchment:ClearSecureButtons(self)
        parent:StartSizing("BOTTOMRIGHT");self.sizing=true
    end)
    self.grip:SetScript("OnMouseUp",function()
        parent:StopMovingOrSizing();self.sizing=nil;self:SaveGeometry();self:Relayout()
    end)
    local story=CreateFrame("Frame",nil,panel)
    self.storyPanel=story
    ZGV.Parchment:DecoratePage(story,4)
    story:EnableMouse(true)
    self.storyTitle=label(story,16,ink);self.storyTitle:SetPoint("TOPLEFT",18,-18)
    self.storyRule=ZGV.Parchment:TitleRule(story)
    self.closeStory=button(story,"X",20,function() self:FoldStory(false) end)
    self.closeStory:SetPoint("TOPRIGHT",-8,-8);ZGV.Parchment:StyleButton(self.closeStory,true)
    tooltip(self.closeStory,"Fold story. The book tab keeps it available to reread.")
    self.storyPane=pane(story,self.panelSerial,"Story")
    self.storyText=label(self.storyPane.child,14,ink);self.storyText:SetPoint("TOPLEFT")
    self.storyText:SetSpacing(4)
    story:Hide()
    self.renderCallback=function(snapshot) self:Render(snapshot) end
    panel:SetScript("OnSizeChanged",function() self:Relayout() end)
    panel:SetScript("OnHide",function() ZGV.Parchment:ClearSecureButtons(self) end)
end

function P:Navigate(delta,fast)
    if self.fixture then self:FixtureCommand(delta>0 and "next" or "prev")
    elseif self.mode=="live" then
        if InCombatLockdown() then return end
        ZGV:SkipStep(delta,fast) -- same manual pause, requirements, guide transitions
        self:Publish()
    end
end

function P:Activate(mode)
    if InCombatLockdown() then ZGV:Print("Run /zgpoc outside combat.");return end
    if self.mode then self:Stop() end
    if mode=="live" and (not ZGV.Frame or not ZGV.Frame:IsVisible() or ZGV.Frame:GetAlpha()<0.1) then
        ZGV:Print("Show the existing guide before /zgpoc live.");return
    end
    self.mode=mode
    if mode=="fixture" then
        self.fixture={step=1,done={}}
        -- Independent surface: original engine, visibility and guide untouched.
        self.fixtureHost=CreateFrame("Frame",nil,UIParent)
        self:ApplyGeometry(self.fixtureHost)

        self.fixtureHost:SetClampedToScreen(true)
        self:CreatePanel(self.fixtureHost)
    else
        -- Suspend reading/secure overlays before removing visual children.
        if ZGV.Parchment then ZGV.Parchment:Suspend() end
        if ZGV.InlineButtons_SuspendSecureOverlays then ZGV:InlineButtons_SuspendSecureOverlays() end
        self.children={}
        for _,child in ipairs({ZGV.Frame:GetChildren()}) do
            self.children[child]=child:IsShown()
            child:Hide()
        end
        -- Keep the native action bar (and its keybindings) available.
        for _,name in ipairs({"TargetPreviewPane"}) do
            local child=ZGV[name]
            if child then self.children[child]=child:IsShown();child:Hide() end
        end
        local host=ZGV.Frame
        self.hostGeometry={width=host:GetWidth(),height=host:GetHeight(),mouse=host:IsMouseEnabled(),points={}}
        for i=1,host:GetNumPoints() do self.hostGeometry.points[i]={host:GetPoint(i)} end
        self.hostGeometry.min={host:GetMinResize()};self.hostGeometry.max={host:GetMaxResize()}
        self:ApplyGeometry(host)
        -- The higher-level native host must not intercept clicks over the
        -- independent drawing surface. The header still moves this same host.
        host:EnableMouse(false)
        self:CreatePanel(host)
        -- Host stays shown and opaque: all engine visibility guards and
        -- pointer hide-with-guide semantics retain their original meaning.
    end
    if mode=="live" then ZGV:SetWaypoint() end -- ask the existing navigator to restore its current target
    self:SyncHostVisibility()
    self.signature=nil
    self.unsubscribe=ZGV:SubscribePresentation(self.renderCallback)
    self:Publish()
end

function P:Start(mode)
    local ok,err=pcall(self.Activate,self,mode)
    if not ok then
        self:Stop()
        ZGV:Print("Presentation activation failed; restored fallback. "..tostring(err))
    end
end

function P:Stop()
    if InCombatLockdown() then
        self.pendingStop=true
        ZGV:Print("Fallback queued until combat ends; reload also exits the PoC.")
        return
    end
    local mode=self.mode
    if self.panel then
        self.host:StopMovingOrSizing()
        self:SaveGeometry()
        ZGV.Parchment:ClearSecureButtons(self)
    end
    self.mode=nil;self.pendingStop=nil;self.fixture=nil;self.fixtureCombat=nil;self.fixtureSettings=nil
    self.storyEntry=nil;self.storyIdentity=nil;self.storyOpen=false;self.storyCue=false
    self.lastSnapshot=nil;self.renderStepKey=nil
    if self.unsubscribe then self.unsubscribe();self.unsubscribe=nil end
    if self.panel then
        self.panel:SetScript("OnSizeChanged",nil);self.panel:SetScript("OnHide",nil)
        self.panel:Hide();self.panel=nil
    end
    if self.fixtureHost then self.fixtureHost:Hide();self.fixtureHost=nil end
    for child,shown in pairs(self.children or {}) do if shown then child:Show() end end
    self.children=nil
    self.root=nil;self.action=nil;self.host=nil;self.displayScale=nil;self.moving=nil;self.sizing=nil
    if mode=="live" then
        local g=self.hostGeometry
        self.hostGeometry=nil
        if g then
            ZGV.Frame:ClearAllPoints()
            for _,point in ipairs(g.points) do ZGV.Frame:SetPoint(unpack(point)) end
            if g.min then ZGV.Frame:SetMinResize(unpack(g.min)) end
            if g.max then ZGV.Frame:SetMaxResize(unpack(g.max)) end
            ZGV.Frame:SetSize(g.width,g.height)
        end
        ZGV:UpdateFrame(true)
        if g then ZGV.Frame:EnableMouse(g.mouse) end
    end
    self:Publish()
end

function P:Refresh()
    local rendered=self.lastSnapshot
    self:Publish()
    -- Native render requests also cover fonts, bag contents and action settings
    -- that need no change to detached quest text/status.
    if self.mode=="live" and self.lastSnapshot==rendered then self:Relayout() end
    if self.mode=="live" then
        -- Consume native render requests as the existing parchment renderer does.
        -- Leaving frameNeedsUpdating set would repeatedly re-target the arrow.
        ZGV.frameNeedsUpdating=nil
        ZGV.frameNeedsResizing=0
        ZGV.stepchanged=false
        ZGV.delayFlash=0
    end
end

function P:Tick(elapsed)
    self:SyncHostVisibility()
    self.layoutElapsed=(self.layoutElapsed or 0)+elapsed
    if self.layoutElapsed>=0.05 then
        self.layoutElapsed=0
        local f=self.panel
        if f then
            local key=table.concat({f:GetEffectiveScale(),f:GetLeft() or 0,f:GetBottom() or 0,f:GetWidth(),f:GetHeight(),UIParent:GetWidth(),UIParent:GetHeight(),UIParent:GetEffectiveScale()},":")
            if key~=self.geometryKey then
                self.geometryKey=key;self:ConstrainGeometry(self.host);self:Relayout()
                if not InCombatLockdown() and ZGV.ActionButtons_ApplyAnchor then ZGV:ActionButtons_ApplyAnchor() end
            end
            if ZGV.frameNeedsUpdating then self:Refresh() end
            ZGV:ParchmentCooldowns(self)
            if ZGV.ActionButtons_UpdateCooldowns then ZGV:ActionButtons_UpdateCooldowns() end
        end
    end
    if ZGV.fastforward then
        ZGV.completionelapsed=ZGV.completionelapsed+elapsed
        if ZGV.completionelapsed>=ZGV.completioninterval then ZGV:TryToCompleteStep(true) end
    end
end
local recovery=CreateFrame("Frame")
recovery:RegisterEvent("PLAYER_REGEN_ENABLED")
recovery:RegisterEvent("PLAYER_REGEN_DISABLED")
recovery:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_DISABLED" then
        if P.panel and (P.moving or P.sizing) then
            P.host:StopMovingOrSizing();P.moving=nil;P.sizing=nil;P:SaveGeometry()
        end
        P:FoldStory(true)
    elseif P.pendingStop then P:Stop()
    elseif P.mode then
        P:SecureButtons()
        if P.mode=="live" and ZGV.ActionButtons_Refresh then ZGV:ActionButtons_Refresh(true) end
    end
end)
SLASH_ZGVPRESENTATIONPOC1="/zgpoc"
SlashCmdList.ZGVPRESENTATIONPOC=function(command)
    command=(command or ""):lower():match("^%s*(.-)%s*$")
    if command=="off" then P:Stop()
    elseif command=="live" or command=="fixture" then P:Start(command)
    elseif command=="recall" then P:ToggleStory()
    elseif command=="fold" then P:FoldStory(false)
    elseif P.fixture then P:FixtureCommand(command)
    else ZGV:Print("Experiment: /zgpoc live | fixture | off | recall | fold; fixture only: goal 1-5 | story | next | prev | reset | combat | peace. Reload exits.") end
end
