-- Experimental vertical slice. Detached display; Zygor owns all progression.
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
    b:SetSize(width,24)
    b.label=label(b,12,gold);b.label:SetPoint("CENTER");b.label:SetText(value)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetScript("OnClick",callback)
    return b
end
local function surface(frame,paper)
    frame:SetBackdrop({bgFile=white,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
        insets={left=3,right=3,top=3,bottom=3}})
    if paper then
        frame:SetBackdropColor(0.86,0.81,0.69,1)
        frame.paper=frame:CreateTexture(nil,"BACKGROUND")
        frame.paper:SetTexture(ZGV.DIR.."\\Skin\\ParchmentPage.tga")
        frame.paper:SetPoint("TOPLEFT",4,-4);frame.paper:SetPoint("BOTTOMRIGHT",-4,4)
    else frame:SetBackdropColor(0.08,0.11,0.09,1) end
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

-- Story presentation state never changes objective evidence or native pause.
function P:ToggleStory()
    if not self.storyEntry then return end
    self.storyOpen=not self.storyOpen
    if self.storyOpen then self.storyCue=false end
    self:LayoutPanels()
end
function P:FoldStory(interrupted)
    if self.storyOpen and interrupted then self.storyCue=true end
    self.storyOpen=false
    self:LayoutPanels()
end
function P:LayoutPanels()
    if not self.panel or not self.lastSnapshot then return end
    local panel=self.panel
    local w,h=panel:GetWidth(),panel:GetHeight()
    self.objectives.child:SetWidth(math.max(100,w-58))
    -- Story appears beside the fixed guide; never reflows its objectives.
    -- Choose a side using scaled screen space, without moving the engine host.
    local scale=panel:GetEffectiveScale()
    local screen=UIParent:GetWidth()*UIParent:GetEffectiveScale()/scale
    local left=panel:GetLeft() or 0
    local right=screen-left-w
    local space=math.max(left,right)-12
    local width=math.min(470,space)
    local fits=width>=280
    self.storyPanel:ClearAllPoints()
    self.storyPanel:SetSize(math.max(280,width),math.max(300,h))
    if left>=right then self.storyPanel:SetPoint("TOPRIGHT",panel,"TOPLEFT",-12,0)
    else self.storyPanel:SetPoint("TOPLEFT",panel,"TOPRIGHT",12,0) end
    self.storyPane.child:SetWidth(math.max(100,width-66))
    shown(self.storyPanel,self.storyEntry and self.storyOpen and fits)
    self.storyToggle.label:SetText(not self.storyEntry and "Story" or
        (not fits and "Story (make room)" or (self.storyCue and "Story *" or (self.storyOpen and "Fold story" or "Story"))))
    self.storyToggle:SetAlpha(self.storyEntry and 1 or 0.4)
end
function P:Render(snapshot)
    if not self.panel then return end
    self.lastSnapshot=snapshot
    self:LayoutPanels()
    local stepKey=snapshot.source..":"..tostring(snapshot.guide.id)..":"..tostring(snapshot.step.index)
    local newStep=stepKey~=self.renderStepKey
    self.renderStepKey=stepKey
    self.guideTitle:SetText(clean(snapshot.guide.title or "Choose a guide"))
    self.stepTitle:SetText(clean(snapshot.step.title or "Current objectives"))
    self.modeLabel:SetText(snapshot.source=="fixture" and "ADVENTURE / SIMULATION" or "ADVENTURE / EXPERIMENT")
    self.position:SetText(tostring(snapshot.step.index or 0).." / "..tostring(snapshot.step.total or 0)..(snapshot.paused and "  Paused" or ""))
    self.bearing:SetText(clean(snapshot.navigation.title or "Follow the existing navigation arrow"))
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
        self.storyCue=entry and true or false
        self.storyOpen=entry and (not entry.persistent or entry.autoOpen) and not (InCombatLockdown() or self.fixtureCombat) or false
    end
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
    self.empty:SetText(snapshot.available and "No current objectives." or "Choose a guide in the existing interface.")
    shown(self.empty,#rows==0)
    finishPane(self.objectives,y,newStep)
    if entry then
        self.storyTitle:SetText(clean(entry.title))
        local reading=ZGV.db.profile.parchment and ZGV.db.profile.parchment.contextsize
        self.storyText:SetFont(self.storyText:GetFont(),math.max(12,math.min(24,tonumber(reading) or 16)))
        self.storyText:SetText(clean(entry.body))
        self.storyText:SetWidth(self.storyPane.child:GetWidth());self.storyText:SetHeight(0)
        finishPane(self.storyPane,self.storyText:GetStringHeight()+12,changed)
    end
    self:LayoutPanels()
end

function P:CreatePanel(parent)
    local panel=CreateFrame("Frame",nil,parent)
    self.panel=panel -- available to recovery after partial construction
    panel:SetAllPoints(parent);panel:SetFrameLevel(parent:GetFrameLevel()+10)
    surface(panel,false)
    self.panelSerial=(self.panelSerial or 0)+1
    self.modeLabel=label(panel,10,gold);self.modeLabel:SetPoint("TOPLEFT",16,-14)
    self.guideTitle=label(panel,17);self.guideTitle:SetPoint("TOPLEFT",16,-36)
    self.guideTitle:SetPoint("RIGHT",panel,"RIGHT",-16,0);self.guideTitle:SetHeight(44)
    self.stepTitle=label(panel,14,gold);self.stepTitle:SetPoint("TOPLEFT",16,-84)
    self.stepTitle:SetPoint("RIGHT",panel,"RIGHT",-16,0);self.stepTitle:SetHeight(40)
    self.bearing=label(panel,11,{0.69,0.72,0.66});self.bearing:SetPoint("TOPLEFT",16,-128)
    self.bearing:SetPoint("RIGHT",panel,"RIGHT",-16,0);self.bearing:SetHeight(32)
    self.objectives=pane(panel,self.panelSerial,"Objectives")
    self.objectives:SetPoint("TOPLEFT",16,-170);self.objectives:SetPoint("BOTTOMRIGHT",-34,72)
    self.empty=label(panel,13);self.empty:SetPoint("TOPLEFT",16,-172)
    self.empty:SetPoint("RIGHT",panel,"RIGHT",-36,0)
    self.position=label(panel,10,gold);self.position:SetPoint("BOTTOMLEFT",16,47)
    self.storyToggle=button(panel,"Story",120,function() self:ToggleStory() end)
    self.storyToggle:SetPoint("BOTTOMRIGHT",-14,40)
    for i,spec in ipairs({{"<",function() self:Navigate(-1) end},
        {">",function() self:Navigate(1) end},{"Existing UI",function() self:Stop() end}}) do
        local b=button(panel,spec[1],i==3 and 100 or 38,spec[2])
        b:SetPoint("BOTTOMLEFT",12+(i-1)*44,10)
    end
    local story=CreateFrame("Frame",nil,panel)
    self.storyPanel=story;surface(story,true)
    self.storyTitle=label(story,20,ink);self.storyTitle:SetPoint("TOPLEFT",22,-22)
    self.storyTitle:SetPoint("RIGHT",story,"RIGHT",-22,0);self.storyTitle:SetHeight(64)
    self.storyPane=pane(story,self.panelSerial,"Story")
    self.storyPane:SetPoint("TOPLEFT",24,-98);self.storyPane:SetPoint("BOTTOMRIGHT",-36,54)
    self.storyText=label(self.storyPane.child,16,ink);self.storyText:SetPoint("TOPLEFT")
    self.storyText:SetSpacing(6)
    local fold=button(story,"Back to play",130,function() self:FoldStory(false) end)
    fold.label:SetTextColor(unpack(ink));fold:SetPoint("BOTTOMRIGHT",-18,14)
    story:Hide()
    self.renderCallback=function(snapshot) self:Render(snapshot) end
    panel:SetScript("OnSizeChanged",function() if self.lastSnapshot then self:Render(self.lastSnapshot) end end)
end

function P:Navigate(delta)
    if self.fixture then self:FixtureCommand(delta>0 and "next" or "prev")
    elseif self.mode=="live" then
        if InCombatLockdown() then return end
        ZGV:SkipStep(delta) -- same manual pause, requirements, guide transitions
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
        self.fixtureHost:SetSize(360,560)
        self.fixtureHost:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-40,160)
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
        -- These two optional surfaces are parented to UIParent in this fork.
        for _,name in ipairs({"ActionButtonBar","TargetPreviewPane"}) do
            local child=ZGV[name]
            if child then self.children[child]=child:IsShown();child:Hide() end
        end
        self:CreatePanel(ZGV.Frame)
        -- Host stays shown, opaque, in place: all engine visibility guards and
        -- pointer hide-with-guide semantics retain their original meaning.
    end
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
    self.mode=nil;self.pendingStop=nil;self.fixture=nil;self.fixtureCombat=nil
    self.storyEntry=nil;self.storyIdentity=nil;self.storyOpen=false;self.storyCue=false
    self.lastSnapshot=nil;self.renderStepKey=nil
    if self.unsubscribe then self.unsubscribe();self.unsubscribe=nil end
    if self.panel then self.panel:Hide();self.panel=nil end
    if self.fixtureHost then self.fixtureHost:Hide();self.fixtureHost=nil end
    for child,shown in pairs(self.children or {}) do if shown then child:Show() end end
    self.children=nil
    if mode=="live" then ZGV:UpdateFrame(true) end
    self:Publish()
end

function P:Refresh()
    self:Publish()
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
    if ZGV.fastforward then
        ZGV.completionelapsed=ZGV.completionelapsed+elapsed
        if ZGV.completionelapsed>=ZGV.completioninterval then ZGV:TryToCompleteStep(true) end
    end
end
local recovery=CreateFrame("Frame")
recovery:RegisterEvent("PLAYER_REGEN_ENABLED")
recovery:RegisterEvent("PLAYER_REGEN_DISABLED")
recovery:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_DISABLED" then P:FoldStory(true)
    elseif P.pendingStop then P:Stop() end
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
