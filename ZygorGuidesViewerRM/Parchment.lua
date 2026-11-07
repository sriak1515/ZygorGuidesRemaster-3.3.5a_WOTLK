-- First playable vertical viewer. Presentation only: completion and navigation
-- stay in the guide engine. Disable with /zgparchment off (then reloads).
local ZGV = ZygorGuidesViewer
if not ZGV then return end
local P = {}
ZGV.Parchment = P
local white = "Interface\\Buttons\\WHITE8X8"
local ink = {0.188, 0.161, 0.122}
local light = {0.925, 0.875, 0.749}
local completedInk = {0.30, 0.32, 0.28} -- grey-olive, readable on opaque paper
local min, max = math.min, math.max
local CONTEXT_CHROME = 18
local TITLE_HEIGHT = 30
local READER_FOOTER = 30
local MIN_WIDTH, MIN_HEIGHT = 320, 380
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 340, 400
-- Same sixteen-cell objective atlas and action mapping as the original viewer.
local objectiveIcons={accept=5,turnin=6,kill=7,get=8,collect=8,buy=8,
    goal=9,home=10,fpath=11,goto=12,talk=13}
local function clamp(n, lo, hi) return max(lo, min(hi, n)) end

-- Native 3.3.5a frames do not provide SetShown. Avoid depending on a
-- compatibility method attached to some other frame instance.
local function setShown(frame, visible)
    if visible then frame:Show() else frame:Hide() end
end

function ZGV:ParchmentEnabled()
    local p = self.db and self.db.profile
    return p and p.parchmentprototype ~= false and p.skin == "remaster" and p.displaymode == "guide"
end

function P:Settings()
    local profile = ZGV.db.profile
    profile.parchment = profile.parchment or {}
    local s = profile.parchment
    -- Respect explicitly saved native font preferences. Only fill unset values
    -- from the former prototype preset; never overwrite a saved native choice.
    if not s.nativefonts then
        s.legacyobjectivesize=s.objectivesize
        if rawget(profile,"fontsize")==nil then profile.fontsize=tonumber(s.objectivesize) or 13 end
        if rawget(profile,"fontsecsize")==nil then profile.fontsecsize=max(5,(tonumber(s.objectivesize) or 13)-2) end
        s.nativefonts=true
    end
    s.width = max(MIN_WIDTH, tonumber(s.width) or DEFAULT_WIDTH)
    s.height = max(MIN_HEIGHT, tonumber(s.height) or DEFAULT_HEIGHT)
    s.split = clamp(tonumber(s.split) or 0.55, 0, 1)
    s.contextsize = clamp(math.floor((tonumber(s.contextsize) or 14)+0.5),12,24)
    s.objectivesize = clamp(tonumber(profile.fontsize) or 13,7,24)
    s.directionsize = clamp(tonumber(profile.fontsecsize) or 11,5,22)
    return s
end

-- Generic text and info are also used for directions in legacy guides. Only
-- explicit metadata or the user's reading preference may move them to Context.
function P:IsPlain(goal)
    return (not goal.action or goal.action == "" or goal.action == "info")
        and not goal.x and not goal.questid and not goal.next and not goal.image
        and not goal.useitem and not goal.useitemid and not goal.castspell
        and not goal.castspellid and not goal.script and not goal.macro and not goal.petaction
        and not (goal.IsCompleteable and goal:IsCompleteable())
        and not (goal.IsActionable and goal:IsActionable())
end

-- Legacy standalone `info` is an empty spacer, not a reading passage.
-- Preserve every row with prose, decoration, tooltip or interaction payload.
function P:IsEmptyInfo(goal)
    return goal.action=="info" and self:IsPlain(goal)
        and not tostring(goal.info or ""):find("%S")
        and not tostring(goal.text or ""):find("%S")
        and not goal.tooltip and not goal.routesharedtip
        and not goal.icon and not goal.buttonicon and not goal.mapicon
        and not goal.important and not goal.optional
end

function P:Partition(step, plaincontext)
    local actions, context, confirms = {}, {}, {}
    for _, goal in ipairs(step and step.goals or {}) do
        if goal:GetStatus() ~= "hidden" and not self:IsEmptyInfo(goal) then
            if (goal.context or plaincontext) and self:IsPlain(goal) then
                context[#context+1] = goal
            elseif goal.action == "confirm" then
                confirms[#confirms+1] = goal
            else
                actions[#actions+1] = goal
            end
        end
    end
    local story = #actions == 0 and #context > 0 and #confirms <= 1
    if not story then
        -- Preserve author order, including confirm rows amongst objectives.
        actions = {}
        for _, goal in ipairs(step and step.goals or {}) do
            if goal:GetStatus() ~= "hidden" and not self:IsEmptyInfo(goal) and not ((goal.context or plaincontext) and self:IsPlain(goal)) then
                actions[#actions+1] = goal
            end
        end
    end
    return actions, context, story, confirms
end

function P:Allocation(height, tools, mixed, collapsed, story, split)
    local top = tools and 64 or 42 -- body begins below the header / optional tools
    local body = max(0, height - top - 10)
    if story then return 0, body, top end
    if not mixed then return body, 0, top end
    if collapsed then return body - CONTEXT_CHROME, 0, top end
    local available = body - CONTEXT_CHROME
    local contextMinimum = 144 - CONTEXT_CHROME
    local action = clamp(available * split, 160, available - contextMinimum)
    return action, available - action, top
end

local function setFont(fs, size)
    local font = STANDARD_TEXT_FONT
    if GameFontNormal and GameFontNormal.GetFont then
        font = GameFontNormal:GetFont() or font
    end
    if not fs:SetFont(font, size) then fs:SetFont(STANDARD_TEXT_FONT, size) end
end
local function text(parent, size, color)
    local fs = parent:CreateFontString(nil,"ARTWORK")
    setFont(fs,size)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetTextColor(unpack(color or ink))
    return fs
end
local function tooltip(frame, value)
    frame:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOPRIGHT")
        GameTooltip:SetText(type(value)=="function" and value() or value, nil,nil,nil,nil,true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
local function button(parent, label, width, callback)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width,24)
    -- Small text controls with a quiet hover cue, rather than nested boxes.
    b.label = text(b,12)
    b.label:SetPoint("CENTER",b,"CENTER",0,0)
    b.label:SetText(label)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick", callback)
    return b
end
local function point(frame, parent, x,y,w,h)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    frame:SetSize(w,h)
end
local function fitLabel(label, value, width)
    label:SetWidth(width)
    label:SetText(value)
    -- Abbreviate fixed chrome only, never objective or context paragraphs.
    -- Strip a whole UTF-8 code point at a time, without reducing the font.
    if label.GetStringWidth then
        local shortened=value
        while label:GetStringWidth()>width and #shortened>0 do
            local trimmed=shortened:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
            shortened=trimmed~=shortened and trimmed or shortened:sub(1,-2)
            label:SetText(shortened.."...")
        end
    end
end
local function clean(value)
    -- Native GetText uses bright colors intended for dark skins. Keep links,
    -- textures, counts and all prose; let parchment supply the text contrast.
    return tostring(value or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

function P:ScrollAnchor(pane)
    if not pane then return end
    local value=pane.bar:GetValue() or 0
    for _,row in ipairs(pane.rows) do
        if row.goal and (row.contentY or 0)+row:GetHeight()>value then
            return {goal=row.goal,fraction=max(0,value-(row.contentY or 0))/max(1,row:GetHeight()),value=value,atTop=value==0}
        end
    end
end

function P:SetContextSize(size)
    local s=self:Settings()
    local size=clamp(math.floor((tonumber(size) or s.contextsize)+0.5),12,24)
    if size==s.contextsize then return end
    self.contextAnchor=self:ScrollAnchor(self.context)
    self.actionAnchor=self:ScrollAnchor(self.action) -- inline prose shares reading type
    if self.background then self.background.pane.readingAnchor=self:ScrollAnchor(self.background.pane) end
    s.contextsize=size
    ZGV:UpdateFrame()
end

function P:SetObjectiveSize(size)
    local s=self:Settings()
    local size=clamp(math.floor((tonumber(size) or s.objectivesize)+0.5),7,24)
    if size==s.objectivesize then return end
    self.actionAnchor=self:ScrollAnchor(self.action)
    ZGV.db.profile.fontsize=size
    ZGV:UpdateFrame()
end

function P:ReadingActive()
    return self.active and self.expandedReading and not self.browsing
        and self.step==ZGV.CurrentStep and self.guide==ZGV.CurrentGuide
end

function P:ToggleReading()
    if self.expandedReading then
        self.expandedReading=false
        -- A larger viewport may clamp the offset. An untouched reading preview
        -- should return to the original position, not silently scroll the pane.
        if not self.readerMoved then self.contextAnchor=self.readingOrigin end
        self.readingOrigin=nil
    elseif self.hasContext and self.mixed then
        self.expandedReading=true;self.browsing=false
        self.readingOrigin=self:ScrollAnchor(self.context);self.readerMoved=false
    else return end
    self.splitting=nil
    ZGV:UpdateFrame()
end

local function metalButton(control, close)
    control:SetBackdrop({bgFile=white,edgeFile=ZGV.DIR.."\\Skin\\popup_border",
        edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
    control:SetBackdropColor(unpack(close and {0.27,0.10,0.07,1} or {0.12,0.15,0.10,1}))
    control:SetBackdropBorderColor(0.88,0.77,0.52,1)
end

function P:CreatePane(parent)
    local pane = CreateFrame("ScrollFrame",nil,parent)
    pane:EnableMouse(true)
    pane:EnableMouseWheel(true)
    pane.child = CreateFrame("Frame",nil,pane)
    pane.child:SetSize(1,1)
    pane:SetScrollChild(pane.child)
    pane.child:SetPoint("TOPLEFT",pane,"TOPLEFT",0,0)
    pane.rows = {}
    pane.bar = CreateFrame("Slider",nil,parent)
    pane.bar:SetOrientation("VERTICAL")
    pane.bar:SetWidth(10)
    pane.bar:SetThumbTexture(white)
    pane.bar:GetThumbTexture():SetSize(6,28)
    pane.bar:GetThumbTexture():SetVertexColor(0.38,0.32,0.21,1)
    pane.bar.track=pane.bar:CreateTexture(nil,"BACKGROUND")
    pane.bar.track:SetTexture(white)
    pane.bar.track:SetVertexColor(0.40,0.32,0.20,0.18)
    pane.bar.track:SetWidth(6)
    pane.bar.track:SetPoint("TOP",pane.bar,"TOP",0,0)
    pane.bar.track:SetPoint("BOTTOM",pane.bar,"BOTTOM",0,0)
    pane.bar:SetValueStep(1)
    pane.bar:SetScript("OnValueChanged",function(_,value)
        pane:SetVerticalScroll(value)
        if pane==P.context and P.expandedReading and not P.updating then P.readerMoved=true end
        P:SecureButtons()
    end)
    local function wheel(_, delta)
        pane.bar:SetValue(clamp((pane.bar:GetValue() or 0)-delta*36,0,pane.range or 0))
    end
    pane.wheel = wheel
    pane.bar:EnableMouseWheel(true)
    pane.bar:SetScript("OnMouseWheel",wheel)
    pane:SetScript("OnMouseWheel",wheel)
    return pane
end

-- Shared A+ material: authored paper texture, inset depth, existing gold edge.
function P:DecoratePage(frame,top)
    frame:SetBackdrop({bgFile=white,edgeFile=ZGV.DIR.."\\Skin\\popup_border",edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(0.36,0.30,0.19,1)
    frame:SetBackdropBorderColor(0.90,0.82,0.62,1)
    frame.pageEdge=frame:CreateTexture(nil,"BACKGROUND")
    frame.pageEdge:SetTexture(white); frame.pageEdge:SetVertexColor(0.42,0.33,0.18,1)
    frame.pageEdge:SetPoint("TOPLEFT",frame,"TOPLEFT",7,-(top-1))
    frame.pageEdge:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-7,7)
    frame.paper=frame:CreateTexture(nil,"BORDER")
    frame.paper:SetTexture(ZGV.DIR.."\\Skin\\ParchmentPage.tga")
    frame.paper:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-top)
    frame.paper:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-8,8)
    -- Keep the fine native gold edge above the paper and child backgrounds.
    frame.rim=CreateFrame("Frame",nil,frame)
    frame.rim:SetAllPoints(frame); frame.rim:SetFrameLevel(frame:GetFrameLevel()+20)
    frame.rim:SetBackdrop({edgeFile=ZGV.DIR.."\\Skin\\popup_border",edgeSize=16})
    frame.rim:SetBackdropBorderColor(0.90,0.82,0.62,1)
end

function P:TitleRule(parent)
    local rule=CreateFrame("Frame",nil,parent)
    rule.ornament=rule:CreateTexture(nil,"ARTWORK")
    rule.ornament:SetTexture(ZGV.DIR.."\\Skin\\ParchmentRule.tga")
    rule.ornament:SetTexCoord(56/128,72/128,0,1)
    rule.ornament:SetSize(16,12)
    rule.ornament:SetPoint("CENTER",rule,"CENTER",0,0)
    -- Extend the rules, not the diamond, when either window is resized.
    for _,side in ipairs({"LEFT","RIGHT"}) do
        local line=rule:CreateTexture(nil,"ARTWORK")
        line:SetTexture(white); line:SetVertexColor(0.66,0.54,0.32,0.6)
        line:SetHeight(1)
        if side=="LEFT" then
            line:SetPoint("LEFT",rule,"LEFT",0,0)
            line:SetPoint("RIGHT",rule.ornament,"LEFT",-3,0)
        else
            line:SetPoint("LEFT",rule.ornament,"RIGHT",3,0)
            line:SetPoint("RIGHT",rule,"RIGHT",0,0)
        end
    end
    return rule
end

function P:Create()
    if self.root then return end
    local frame = ZGV.Frame
    local root = CreateFrame("Frame",nil,frame)
    root:SetAllPoints(frame)
    root:SetFrameLevel(frame:GetFrameLevel()+10)
    root:SetBackdrop({bgFile=white,insets={left=5,right=5,top=5,bottom=5}})
    root:SetBackdropColor(0.847,0.788,0.651,1)
    root:SetBackdropBorderColor(0.48,0.40,0.26,1)
    self.root = root
    self:DecoratePage(root,35)
    self.header = CreateFrame("Frame",nil,root)
    self.header:SetBackdrop({bgFile=white})
    self.header:SetBackdropColor(0.16,0.19,0.14,1)
    self.header.grain=self.header:CreateTexture(nil,"BACKGROUND")
    self.header.grain:SetAllPoints(self.header)
    self.header.grain:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    self.header.grain:SetVertexColor(0.50,0.55,0.40,0.24)
    self.header.rule=self.header:CreateTexture(nil,"BORDER")
    self.header.rule:SetTexture(white)
    self.header.rule:SetVertexColor(0.48,0.40,0.26,0.8)
    self.header.rule:SetHeight(1)
    self.header.rule:SetPoint("BOTTOMLEFT",self.header,"BOTTOMLEFT",0,0)
    self.header.rule:SetPoint("BOTTOMRIGHT",self.header,"BOTTOMRIGHT",0,0)
    self.header:EnableMouse(true)
    self.header:RegisterForDrag("LeftButton")
    self.header:SetScript("OnDragStart",function()
        if ZGV.db.profile.windowlocked then return end
        frame:StartMoving()
        ZGV.framemoving=true
    end)
    self.header:SetScript("OnDragStop",function()
        frame:StopMovingOrSizing()
        ZGV.framemoving=nil
        local left, bottom = frame:GetLeft(), frame:GetBottom()
        if left and bottom then
            local s = P:Settings()
            s.x,s.y = left,bottom
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",left,bottom)
        end
        P:SecureButtons()
    end)
    self.chapterPlate=CreateFrame("Frame",nil,self.header)
    self.chapter = text(self.chapterPlate,13,{0.890,0.780,0.569})
    self.chapter:SetPoint("TOPLEFT",self.header,"TOPLEFT",8,-7)
    self.chapter:SetHeight(16)
    tooltip(self.header,function() return (self.fullTitle or "Zygor Guides Remaster")..(ZGV.CurrentStep and ZGV.CurrentStep.title and ("\n"..clean(ZGV.CurrentStep.title)) or "") end)
    self.prev = button(self.header,"<",22,function(_,b) P:ManualNavigate(-1,b=="RightButton") end)
    self.next = button(self.header,">",22,function(_,b) P:ManualNavigate(1,b=="RightButton") end)
    tooltip(self.prev,"Previous step. Right-click: fast backward.")
    tooltip(self.next,"Next / Continue. Right-click: fast forward.")
    self.position = text(self.header,12,light)
    self.tools = button(self.header,"Tools",42,function()
        local s=P:Settings(); s.tools=not s.tools; ZGV:UpdateParchment()
    end)
    self.close = button(self.header,"X",22,function() ZGV:ToggleFrame() end)
    for _,control in ipairs({self.prev,self.next,self.tools,self.close}) do
        control.label:SetTextColor(unpack(light))
        metalButton(control,control==self.close)
    end
    self.utility = CreateFrame("Frame",nil,root)
    self.guides = button(self.utility,"Guides",60,function(_,b)
        if b=="RightButton" then ZGV:ToggleGuideManagerFrame("home") else ZGV:OpenGuideMenu() end
    end)
    self.steps = button(self.utility,"Steps",54,function()
        P.browsing=not P.browsing; ZGV:UpdateParchment()
    end)
    self.lock = button(self.utility,"Lock",58,function() ZGV:ToggleWindowLock() end)
    self.settings = button(self.utility,"Settings",68,function(_,b)
        if b=="RightButton" then ZGV:ToggleGuideManagerFrame("options") else ZGV:OpenOptions() end
    end)
    self.heading = text(root,16) -- essential titles use readable locale client type
    self.heading:SetHeight(22)
    self.headingRule=self:TitleRule(root)
    self.headingHit=CreateFrame("Frame",nil,root)
    self.headingHit:EnableMouse(true)
    tooltip(self.headingHit,function() return P.stepTitle or "Actions" end)
    self.action = self:CreatePane(root)
    self.context = self:CreatePane(root)
    self.backgroundLink=button(root,"",300,function()
        local entry=P.backgroundEntry
        if entry then P:ToggleBackground(entry) end
    end)
    self.backgroundLink.label:ClearAllPoints()
    self.backgroundLink.label:SetPoint("LEFT",self.backgroundLink,"LEFT",0,0)
    self.backgroundLink.label:SetHeight(18)
    self.backgroundLink.label:SetTextColor(0.40,0.27,0.09,1)
    tooltip(self.backgroundLink,function() return P.backgroundEntry and P.backgroundEntry.title or "Background" end)
    self.backgroundLink.rule=self.backgroundLink:CreateTexture(nil,"ARTWORK")
    self.backgroundLink.rule:SetTexture(white); self.backgroundLink.rule:SetVertexColor(0.66,0.54,0.31,0.6)
    self.backgroundLink.rule:SetHeight(1)
    self.backgroundLink.rule:SetPoint("TOPLEFT",self.backgroundLink,"TOPLEFT",0,2)
    self.backgroundLink.rule:SetPoint("TOPRIGHT",self.backgroundLink,"TOPRIGHT",0,2)

    self.divider = CreateFrame("Frame",nil,root)
    self.divider:EnableMouse(true)
    self.divider:RegisterForDrag("LeftButton")
    self.collapse = CreateFrame("Button",nil,self.divider)
    self.collapse.label = text(self.collapse,12)
    self.collapse.label:SetPoint("LEFT",self.collapse,"LEFT",0,0)
    self.collapse:SetScript("OnClick",function()
        local s=P:Settings(); s.collapsed=not s.collapsed; ZGV:UpdateParchment()
    end)
    tooltip(self.collapse,"Collapse or restore Context. The saved split is retained.")
    self.read = button(self.divider,"Read",40,function() P:ToggleReading() end)
    tooltip(self.read,"Read Context in the full panel. Automatic progression waits until you return to Actions or navigate manually.")
    self.divider.rule = self.divider:CreateTexture(nil,"BORDER")
    self.divider.rule:SetTexture(white)
    self.divider.rule:SetVertexColor(0.533,0.447,0.286,1)
    self.divider.rule:SetHeight(1)
    self.divider.rule:SetPoint("LEFT",self.collapse,"RIGHT",6,0)
    self.divider.rule:SetPoint("RIGHT",self.divider,"RIGHT",-46,0)
    self.divider.grab=self.divider:CreateTexture(nil,"OVERLAY")
    self.divider.grab:SetTexture(white)
    self.divider.grab:SetVertexColor(0.43,0.35,0.22,1)
    self.divider.grab:SetSize(18,3)
    self.divider.grab:SetPoint("CENTER",self.divider.rule,"CENTER",0,0)
    self.divider:SetScript("OnDragStart",function()
        if not ZGV.db.profile.windowlocked and not P:Settings().collapsed and not P.expandedReading then P.splitting=true end
    end)
    self.divider:SetScript("OnDragStop",function() P.splitting=nil end)
    tooltip(self.divider,"Drag to divide Actions and Context. Lock prevents dragging. Click Context to collapse or restore.")
    self.continue = button(root,"Continue >",98,function()
        P:CloseBackground()
        local confirms=P.confirms or {}
        if #confirms>0 then
            -- Use the actual goal click path, retaining confirm/next branching.
            local proxy={goal=confirms[1],GetParent=function() return {step=ZGV.CurrentStep} end}
            ZGV:GoalOnClick({GetParent=function() return proxy end},"LeftButton")
        else P:ManualNavigate(1) end
    end)
    tooltip(self.continue,function() return P.confirms and P.confirms[1] and P:GoalText(P.confirms[1]) or "Continue to the next step" end)
    self.readerFooter=CreateFrame("Frame",nil,root)
    self.readerFooter.rule=self.readerFooter:CreateTexture(nil,"BORDER")
    self.readerFooter.rule:SetTexture(white)
    self.readerFooter.rule:SetVertexColor(0.53,0.44,0.28,0.8)
    self.readerFooter.rule:SetHeight(1)
    self.readerFooter.rule:SetPoint("TOPLEFT",self.readerFooter,"TOPLEFT",0,0)
    self.readerFooter.rule:SetPoint("TOPRIGHT",self.readerFooter,"TOPRIGHT",0,0)
    self.smaller=button(self.readerFooter,"A-",28,function() P:SetContextSize(P:Settings().contextsize-2) end)
    self.larger=button(self.readerFooter,"A+",28,function() P:SetContextSize(P:Settings().contextsize+2) end)
    self.fontSize=text(self.readerFooter,12)
    tooltip(self.smaller,"Smaller reading text (minimum 12). Applies to story and background; objective text is unchanged.")
    tooltip(self.larger,"Larger reading text (maximum 24). Applies to story and background; objective text is unchanged.")
    self.back=button(self.readerFooter,"Back to actions",112,function() P:ToggleReading() end)
    self.grip = button(root,"/",18,function() end)
    self.grip:SetScript("OnMouseDown",function(_,b)
        if b=="LeftButton" and not ZGV.db.profile.windowlocked then
            frame:StartSizing("BOTTOMRIGHT"); P.sizing=true
        end
    end)
    self.grip:SetScript("OnMouseUp",function()
        if not P.sizing then return end
        frame:StopMovingOrSizing(); P.sizing=nil
        local s=P:Settings(); s.width,s.height=frame:GetWidth(),frame:GetHeight()
        s.x,s.y=frame:GetLeft(),frame:GetBottom()
        ZGV:UpdateParchment()
    end)
    frame:HookScript("OnHide",function()
        P:ClearSecureButtons()
        P:CloseBackground()
    end)
    self.events=CreateFrame("Frame")
    self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.events:SetScript("OnEvent",function() ZGV.parchmentDirty=true; P:ClearSecureButtons() end)
    self.initialized=true
end

-- Explicit authored payload only; neither plain text nor |context is classified
-- as optional background. This small API is used by the product fixture, not a
-- new guide grammar. The reader never sets expandedReading or pauses the engine.
function P:CloseBackground()
    if self.background then self.background:StopMovingOrSizing(); self.background:Hide() end
end

function P:ManualNavigate(delta,fast)
    self:CloseBackground()
    ZGV:SkipStep(delta,fast)
end

function P:ToggleBackground(entry)
    local f=self.background
    if f and f:IsShown() and f.entry==entry and f.ownerGuide==ZGV.CurrentGuide then
        self:CloseBackground()
    else self:OpenBackground(entry) end
end

function P:SaveBackgroundGeometry()
    local f=self.background
    local s=self:Settings()
    s.readerwidth,s.readerheight=f:GetWidth(),f:GetHeight()
    s.readerx,s.readery=f:GetLeft(),f:GetBottom()
    f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",s.readerx,s.readery)
end

function P:LayoutBackground(changed)
    local f=self.background
    if not f or not f.entry or f.layingOut then return end
    f.layingOut=true
    if not changed and not f.pane.readingAnchor then f.pane.readingAnchor=self:ScrollAnchor(f.pane) end
    local w,h=f:GetWidth(),f:GetHeight()
    point(f.header,f,6,5,w-12,29)
    point(f.caption,f.header,7,7,w-52,18)
    point(f.close,f.header,w-38,3,22,22)
    f.title:SetWidth(w-32); f.title:SetHeight(0); f.title:SetText(f.entry.title)
    local titleHeight=max(22,f.title:GetStringHeight())
    point(f.title,f,16,44,w-32,titleHeight)
    point(f.rule,f,16,44+titleHeight+1,w-32,8)
    local top=44+titleHeight+16
    local height=max(1,h-top-20)
    point(f.pane,f,16,top,w-32,height)
    point(f.grip,f,w-23,h-19,18,16)
    setShown(f.grip,not ZGV.db.profile.windowlocked)
    self:Fill(f.pane,{f.goal},w-32,height,nil,changed)
    -- Reference prose never participates in native goal completion/clicks.
    local clicker=f.pane.rows[1].clicker
    clicker:SetScript("OnClick",nil); clicker:SetScript("OnEnter",nil)
    clicker:SetScript("OnLeave",nil); clicker:EnableMouse(false)
    f.layingOut=nil
end

function P:OpenBackground(entry)
    if not entry or type(entry.title)~="string" or type(entry.body)~="string" then return end
    if not self.background then
        local f=CreateFrame("Frame",nil,UIParent)
        local settings=self:Settings()
        f:SetSize(max(320,tonumber(settings.readerwidth) or 340),max(300,tonumber(settings.readerheight) or 400))
        f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
        f:SetMovable(true); f:SetResizable(true); f:SetMinResize(320,300); f:EnableMouse(true)
        self:DecoratePage(f,35)
        f.header=CreateFrame("Frame",nil,f)
        f.header:SetBackdrop({bgFile=white})
        f.header:SetBackdropColor(0.16,0.19,0.14,1)
        f.header:EnableMouse(true); f.header:RegisterForDrag("LeftButton")
        f.header:SetScript("OnDragStart",function() if not ZGV.db.profile.windowlocked then f:StartMoving() end end)
        f.header:SetScript("OnDragStop",function() f:StopMovingOrSizing(); P:SaveBackgroundGeometry() end)
        f.caption=text(f.header,12,light); f.caption:SetText("Background")
        f.close=button(f.header,"X",22,function() P:CloseBackground() end)
        f.close.label:SetTextColor(unpack(light)); metalButton(f.close,true)
        f.title=text(f,18)
        f.rule=self:TitleRule(f)
        f.pane=self:CreatePane(f); f.pane.reading=true
        f.pane.bar:SetPoint("TOPRIGHT",f.pane,"TOPRIGHT",0,0)
        f.pane.bar:SetPoint("BOTTOMRIGHT",f.pane,"BOTTOMRIGHT",0,0)
        f.grip=button(f,"/",18,function() end)
        f.grip:SetScript("OnMouseDown",function(_,b)
            if b=="LeftButton" and not ZGV.db.profile.windowlocked then f:StartSizing("BOTTOMRIGHT") end
        end)
        f.grip:SetScript("OnMouseUp",function()
            f:StopMovingOrSizing(); P:SaveBackgroundGeometry(); P:LayoutBackground()
        end)
        f:SetScript("OnSizeChanged",function() P:LayoutBackground() end)
        self.background=f
    end
    local f=self.background
    local changed=f.entry~=entry or f.ownerGuide~=ZGV.CurrentGuide
    if changed then
        f.entry=entry; f.ownerGuide=ZGV.CurrentGuide; f.pane.readingAnchor=nil
        f.goal={text=entry.body,GetStatus=function() return "passive" end}
        function f.goal:GetText() return self.text end
    end
    f:SetScale(ZGV.db.profile.framescale or 1)
    if not f.placed then
        local settings=self:Settings()
        if settings.readerx and settings.readery then
            f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",settings.readerx,settings.readery)
        else
            local scale=ZGV.Frame:GetEffectiveScale()
            local right=(ZGV.Frame:GetLeft()+ZGV.Frame:GetWidth()+f:GetWidth()+12)*scale
            if right>UIParent:GetWidth()*UIParent:GetEffectiveScale() then
                f:SetPoint("TOPRIGHT",ZGV.Frame,"TOPLEFT",-12,0)
            else f:SetPoint("TOPLEFT",ZGV.Frame,"TOPRIGHT",12,0) end
        end
        f.placed=true
    end
    f:Show(); self:LayoutBackground(changed)
end

function P:ClearSecureButtons()
    if InCombatLockdown() or not self.secure then return end
    for _,b in ipairs(self.secure.buttons) do b:Hide(); b.actionSpec=nil end
end

function P:HolderVisible(row, pane)
    if not row:IsVisible() or not pane:IsVisible() then return false end
    local holder=row.actionHolder
    local t,b,pt,pb=holder:GetTop(),holder:GetBottom(),pane:GetTop(),pane:GetBottom()
    return t and b and pt and pb and t<=pt and b>=pb
end

function P:SecureButtons()
    if InCombatLockdown() then return end
    if not self.root or not self.root:IsVisible() then self:ClearSecureButtons(); return end
    if not self.secure then
        self.secure=CreateFrame("Frame","ZGVParchmentSecureRoot",UIParent,"SecureHandlerStateTemplate")
        self.secure:SetAllPoints(UIParent)
        self.secure:SetFrameStrata(ZGV.Frame:GetFrameStrata())
        self.secure:SetFrameLevel(ZGV.Frame:GetFrameLevel()+80)
        self.secure.buttons={}
        -- Never leave absolute-coordinate click targets over a scrolling viewer
        -- during lockdown. No secure attributes or anchors are changed in combat.
        RegisterStateDriver(self.secure,"visibility","[combat] hide; show")
    end
    self:ClearSecureButtons()
    local n=0
    for _,pane in ipairs({self.action,self.context}) do
        for _,row in ipairs(pane.rows) do
            if row.inlineActionSpec and self:HolderVisible(row,pane) then
                n=n+1
                local b=self.secure.buttons[n]
                if not b then
                    b=CreateFrame("CheckButton",nil,self.secure,"SecureActionButtonTemplate")
                    b:RegisterForClicks("AnyUp")
                    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
                    b:SetScript("OnEnter",function(self) ZGV:ShowActionButtonTooltip(self) end)
                    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
                    b:SetScript("PostClick",function(self) ZGV:ActionButtons_HandlePostClick(self) end)
                    b:EnableMouseWheel(true); b:SetScript("OnMouseWheel",pane.wheel)
                    self.secure.buttons[n]=b
                end
                b:SetScript("OnMouseWheel",pane.wheel)
                ZGV:InlineButtons_ApplySecureOverlaySpec(b,row.inlineActionSpec,row.actionHolder,self.secure)
            end
        end
    end
end

function P:Row(pane,index)
    if pane.rows[index] then return pane.rows[index] end
    local row=CreateFrame("Frame",nil,pane.child)
    row.label=text(row,16)
    row.label:SetSpacing(5)
    row.tip=text(row,14,{0.32,0.27,0.19})
    row.tip:SetSpacing(3)
    row.label:SetPoint("TOPLEFT",row,"TOPLEFT",28,0)
    row.clicker=CreateFrame("Button",nil,row)
    row.clicker:SetAllPoints(row)
    row.clicker:RegisterForClicks("LeftButtonUp","RightButtonUp")
    row.clicker:SetScript("OnClick",function(self,b) ZGV:GoalOnClick(self,b) end)
    row.clicker:SetScript("OnEnter",function(self) ZGV:GoalOnEnter(self) end)
    row.clicker:SetScript("OnLeave",function(self) ZGV:GoalOnLeave(self) end)
    row.clicker:EnableMouseWheel(true); row.clicker:SetScript("OnMouseWheel",pane.wheel)
    row.actionHolder=CreateFrame("Frame",nil,row)
    row.actionHolder:SetSize(22,22)
    row.actionHolder:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    row.actionHolder.icon=row.actionHolder:CreateTexture(nil,"ARTWORK")
    row.actionHolder.icon:SetAllPoints(row.actionHolder)
    row.marker=row:CreateTexture(nil,"ARTWORK")
    row.marker:SetSize(16,16)
    row.marker:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    row.marker:SetTexture(ZGV.DIR.."\\Skin\\icons")
    row.completion=CreateFrame("Frame",nil,row)
    row.completion:SetFrameLevel(row.actionHolder:GetFrameLevel()+2)
    row.completion:SetSize(16,16)
    row.completion.icon=row.completion:CreateTexture(nil,"OVERLAY")
    row.completion.icon:SetAllPoints(row.completion)
    row.completion.icon:SetTexture(ZGV.DIR.."\\Skin\\icons")
    row.completion.icon:SetTexCoord(2/16,3/16,0,1)
    row.cooldown=CreateFrame("Cooldown",nil,row.actionHolder,"CooldownFrameTemplate")
    row.cooldown:SetAllPoints(row.actionHolder)
    pane.rows[index]=row
    return row
end

function P:GoalText(goal)
    local value
    -- Suppress only known native numeric fallback tokens, not arbitrary numbers
    -- in author prose, route coordinates or objective counts.
    if not goal.text then
        if (goal.action=="accept" or goal.action=="turnin") and goal.questid
            and (not goal.quest or goal.quest==tostring(goal.questid))
            and not ZGV:GetQuestName(goal.questid) then
            value = (goal.action=="turnin" and "Turn in quest" or "Quest").." (name loading)"
        elseif goal.action=="use" and not goal.useitem then value="Use item (name loading)"
        elseif goal.action=="cast" and not goal.castspell then value="Cast spell (name loading)" end
    end
    if not value then value = goal.action=="info" and goal.info or goal:GetText(true) end
    return clean(value)
end

function P:Fill(pane,goals,width,height,step,newStep)
    pane.child.step=step -- GoalOnClick expects row -> step parent identity.
    pane.child:SetWidth(width-14)
    local y,bottom=4,4
    local reading=pane==self.context or pane.reading
    local settings=self:Settings()
    for i,goal in ipairs(goals) do
        local row=self:Row(pane,i)
        row.goal=goal; row.inlineActionSpec=nil
        row.clicker:SetScript("OnClick",function(self,b)
            if InCombatLockdown() and row.inlineActionSpec and MouseIsOver(row.actionHolder) then return end
            ZGV:GoalOnClick(self,b)
        end)
        point(row,pane.child,0,y,width-14,22)
        row.contentY=y
        local plain=self:IsPlain(goal)
        local size=(reading or plain) and settings.contextsize or settings.objectivesize
        local spec=ZGV:InlineButtonsEnabled() and ZGV:GetGoalActionSpec(goal)
        local interactive=spec or goal.useitemid or goal.useitem or goal.castspellid
            or goal.castspell or goal.script or goal.macro or goal.petaction
        setFont(row.label,size)
        row.label:SetSpacing(math.floor(size*((reading or plain) and 0.33 or 0.23)+0.5))
        setFont(row.tip,settings.directionsize)
        row.tip:SetSpacing(2)
        -- Plain reading text has no icon gutter. Reserve a stable gutter for
        -- rows that can gain an action icon or completion check on refresh.
        local indent=plain and 0 or (interactive and 28 or 20)
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT",row,"TOPLEFT",indent,0)
        row.label:SetWidth(width-14-indent)
        row.label:SetHeight(0) -- unconstrained wrapping; never cap paragraph height
        local value=self:GoalText(goal)
        local tip=goal.tooltip or goal.routesharedtip
        goal._display_tooltip=tip

        local status=goal:GetStatus()
        row.status=status
        local complete=not reading and status=="complete"
        row.label:SetText(value)
        setShown(row.completion,complete)
        row.completion:ClearAllPoints()
        row.completion:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
        local textHeight=max(size,row.label:GetStringHeight())
        row.label:SetHeight(textHeight)
        local h=max(interactive and 22 or 16,textHeight)
        setShown(row.tip,tip and tip~="")
        if tip and tip~="" then
            row.tip:ClearAllPoints()
            row.tip:SetPoint("TOPLEFT",row,"TOPLEFT",indent,-textHeight-3)
            row.tip:SetWidth(width-14-indent)
            row.tip:SetHeight(0)
            row.tip:SetText(clean(tip))
            local tipHeight=row.tip:GetStringHeight()
            row.tip:SetHeight(tipHeight)
            h=max(h,textHeight+3+tipHeight)
        end
        row:SetHeight(h)
        row.label:SetTextColor(unpack(complete and completedInk or ink))
        row.tip:SetTextColor(unpack(complete and completedInk or {0.32,0.27,0.19}))
        -- A pending objective must not look like a paragraph with a blank gutter.
        -- Item/spell/script buttons occupy this same gutter and retain priority.
        local iconIndex=objectiveIcons[goal.action] or 4
        row.marker:SetTexCoord((iconIndex-1)/16,iconIndex/16,0,1)
        row.marker:SetDesaturated(status=="impossible" or status=="obsolete")
        setShown(row.marker,not plain and not complete and not spec)
        row.actionHolder:Hide()
        if spec then
            if goal.buttonicon then spec.icon=goal.buttonicon end
            row.inlineActionSpec=spec
            local icon=spec.icon or spec.fallbackicon or "Interface\\Icons\\INV_Misc_QuestionMark"
            row.actionHolder.icon:SetTexture(type(icon)=="table" and icon.file or icon)
            if type(icon)=="table" and icon.coords then row.actionHolder.icon:SetTexCoord(unpack(icon.coords))
            else row.actionHolder.icon:SetTexCoord(0,1,0,1) end
            row.actionHolder:Show()
            row.completion:SetPoint("TOPLEFT",row,"TOPLEFT",8,-8)
        end
        row:Show()
        bottom=y+h
        y=bottom+((reading or plain) and 10 or 4)
    end
    for i=#goals+1,#pane.rows do
        pane.rows[i].goal=nil; pane.rows[i].inlineActionSpec=nil; pane.rows[i]:Hide()
    end
    pane.contentBottom=bottom+4
    pane.child:SetHeight(max(height,bottom+4))
    pane.range=max(0,bottom+4-height)
    pane.bar:SetMinMaxValues(0,pane.range)
    local value=pane.bar:GetValue() or 0
    local anchor=pane.readingAnchor or (pane==self.context and self.contextAnchor) or (pane==self.action and self.actionAnchor)
    if anchor then
        value=anchor.value
        for i,goal in ipairs(goals) do
            if goal==anchor.goal then
                local row=pane.rows[i]
                value=anchor.atTop and 0 or row.contentY+anchor.fraction*row:GetHeight()
                break
            end
        end
        if pane==self.context then self.contextAnchor=nil elseif pane==self.action then self.actionAnchor=nil end
        pane.readingAnchor=nil
    end
    pane.bar:SetValue(newStep and 0 or clamp(value,0,pane.range))
    pane:SetVerticalScroll(pane.bar:GetValue())
    setShown(pane.bar,pane.range>0 and pane:IsShown())
end

function P:Suspend()
    if not self.active then return end
    self.root:Hide()
    self:CloseBackground()
    self:ClearSecureButtons()
    self.active=false; self.anchored=nil
    self.expandedReading=false;self.readingOrigin=nil;self.contextAnchor=nil;self.actionAnchor=nil
end

function ZGV:UpdateParchment()
    if not self.Frame or P.updating then return end
    P.updating=true
    P:Create()
    P.root:Show()
    P.active=true
    local s=P:Settings()
    local frame=self.Frame
    -- Native frames are retained for rollback but never participate in layout.
    for _,name in ipairs({"ZygorGuidesViewerFrame_Border","ZygorGuidesViewerFrame_Skipper","ZygorGuidesViewerFrameScroll","ZygorGuidesViewerFrame_MissingText","ZygorGuidesViewerFrame_ThinFlash","ZygorGuidesViewerFrame_ResizerLeft","ZygorGuidesViewerFrame_ResizerRight","ZygorGuidesViewerFrame_ResizerBottom","ZygorGuidesViewerFrame_ResizerBottomLeft","ZygorGuidesViewerFrame_ResizerBottomRight"}) do
        if _G[name] then _G[name]:Hide() end
    end
    if self.RemasterFrames and self.RemasterFrames.root then self.RemasterFrames.root:Hide() end
    if self.GuideProgressBar then self.GuideProgressBar:Hide() end
    for _,st in ipairs(self.stepframes or {}) do st:Hide() end
    frame:SetMovable(true); frame:EnableMouse(true)
    frame:SetResizable(true); frame:SetMinResize(MIN_WIDTH,MIN_HEIGHT)
    frame:SetClampedToScreen(true); frame:SetClampRectInsets(0,0,0,0)
    frame:SetScale(self.db.profile.framescale or 1)
    frame:SetAlpha(1)
    if not P.sizing then frame:SetSize(s.width,s.height) end
    if not P.anchored then
        frame:ClearAllPoints()
        if s.x and s.y then frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",s.x,s.y)
        else frame:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-40,160) end
        P.anchored=true
    end
    local w,h=frame:GetWidth(),frame:GetHeight()
    local step=self.CurrentStep
    if P.background and P.background.ownerGuide~=self.CurrentGuide then P:CloseBackground() end
    local newStep=P.step~=step or P.guide~=self.CurrentGuide
    if newStep then
        P.browsing=false;P.expandedReading=false;P.readingOrigin=nil;P.contextAnchor=nil;P.actionAnchor=nil
    end
    P.step,P.guide=step,self.CurrentGuide
    if step then step:Translate() end
    local actions,context,story,confirms=P:Partition(step,s.plaincontext)
    if s.layout~="split" then
        actions={}
        for _,goal in ipairs(step and step.goals or {}) do
            if goal:GetStatus()~="hidden" and not P:IsEmptyInfo(goal) then actions[#actions+1]=goal end
        end
        context,story={},false
        P.expandedReading=false; P.splitting=nil
    end
    P.confirms=confirms
    local mixed=#context>0 and not story
    P.hasContext,P.mixed=#context>0,mixed
    if not mixed then P.expandedReading=false;P.readingOrigin=nil end
    local reader=story or P.expandedReading
    local ah,ch,top=P:Allocation(h,s.tools,mixed,s.collapsed,reader,s.split)
    P.actionHeight,P.contextHeight=ah,ch
    P.available=ah+ch
    P.bodyTop=top
    point(P.header,P.root,6,5,w-12,29)
    P.fullTitle=self.CurrentGuide and (self.CurrentGuide.title_short or self.CurrentGuide.title) or "Zygor Guides Remaster"
    local headerWidth=w-12
    point(P.chapterPlate,P.header,2,1,headerWidth-199,26)
    fitLabel(P.chapter,clean(P.fullTitle),headerWidth-211)
    point(P.prev,P.header,headerWidth-191,3,22,22)
    P.position:ClearAllPoints();P.position:SetPoint("TOPLEFT",P.header,"TOPLEFT",headerWidth-163,-8)
    P.position:SetWidth(57)
    P.position:SetText(tostring(self.CurrentStepNum or 0).." / "..tostring(self.CurrentGuide and self.CurrentGuide.steps and #self.CurrentGuide.steps or 0))
    point(P.next,P.header,headerWidth-100,3,22,22)
    point(P.tools,P.header,headerWidth-72,3,40,22)
    point(P.close,P.header,headerWidth-26,3,20,22)
    point(P.utility,P.root,12,37,w-24,20)
    setShown(P.utility,not not s.tools)
    point(P.guides,P.utility,0,0,58,20); point(P.steps,P.utility,62,0,50,20)
    point(P.lock,P.utility,116,0,62,20); point(P.settings,P.utility,182,0,68,20)
    P.lock.label:SetText(self.db.profile.windowlocked and "Unlock" or "Lock")
    P.heading:ClearAllPoints(); P.heading:SetPoint("TOPLEFT",P.root,"TOPLEFT",12,-top)
    P.stepTitle=clean(step and step.title or (story and "Reading" or "Actions"))
    local titleHeight=step and step.title and step.title~="" and TITLE_HEIGHT or 0
    setShown(P.heading,titleHeight>0)
    setShown(P.headingHit,titleHeight>0)
    fitLabel(P.heading,P.stepTitle,w-24)
    point(P.headingHit,P.root,12,top,w-24,titleHeight)
    point(P.headingRule,P.root,12,top+21,w-24,8)
    setShown(P.headingRule,titleHeight>0)
    setShown(P.continue,story)
    point(P.continue,P.root,w-118,h-35,98,22)
    point(P.readerFooter,P.root,12,h-READER_FOOTER-10,w-24,READER_FOOTER)
    setShown(P.readerFooter,reader)
    point(P.smaller,P.readerFooter,0,5,28,22)
    point(P.larger,P.readerFooter,54,5,28,22)
    P.fontSize:ClearAllPoints();P.fontSize:SetPoint("TOPLEFT",P.readerFooter,"TOPLEFT",32,-10)
    P.fontSize:SetWidth(22);P.fontSize:SetHeight(16);P.fontSize:SetText(s.contextsize)
    P.smaller:SetAlpha(s.contextsize>12 and 1 or 0.45)
    P.larger:SetAlpha(s.contextsize<24 and 1 or 0.45)
    point(P.back,P.readerFooter,w-136,5,112,22)
    setShown(P.back,P.expandedReading)
    local paneTop=top+titleHeight
    -- Both minima include their heading; the actual scroll viewport is below it.
    local background=not P.browsing and step and (step.parchmentBackground
        or (self.AdventureFixtureBackground and self:AdventureFixtureBackground(step)))
    P.backgroundEntry=background
    local backgroundHeight=background and 28 or 0
    ah=max(0,ah-titleHeight-backgroundHeight); ch=reader and max(0,ch-titleHeight-READER_FOOTER-4-backgroundHeight) or ch
    point(P.backgroundLink,P.root,12,h-38,w-38,24)
    setShown(P.backgroundLink,not not background)
    if background then fitLabel(P.backgroundLink.label,"Read: "..background.title,w-38) end
    point(P.action,P.root,12,paneTop,w-24,max(1,ah))
    setShown(P.action,not reader)
    setShown(P.divider,mixed and not reader)
    local dividerTop=paneTop+ah
    point(P.divider,P.root,12,dividerTop,w-24,CONTEXT_CHROME)
    point(P.collapse,P.divider,0,0,82,CONTEXT_CHROME)
    point(P.read,P.divider,w-64,0,40,CONTEXT_CHROME)
    P.collapse.label:SetText(s.collapsed and "Context +" or "Context -")
    setShown(P.divider.grab,not s.collapsed)
    local ct=reader and paneTop or dividerTop+CONTEXT_CHROME
    point(P.context,P.root,12,ct,w-24,max(1,ch))
    setShown(P.context,reader or (mixed and not s.collapsed))
    for _,pane in ipairs({P.action,P.context}) do
        pane.bar:ClearAllPoints()
        pane.bar:SetPoint("TOPRIGHT",pane,"TOPRIGHT",0,0)
        pane.bar:SetPoint("BOTTOMRIGHT",pane,"BOTTOMRIGHT",0,0)
    end
    if not step then actions={{GetStatus=function() return "passive" end, GetText=function() return "Choose a guide using Tools > Guides." end}} end
    if P.browsing then P:Browse(w-24,top,h-top-18)
    else
        P:Fill(P.action,actions,w-24,max(1,ah),step,newStep or P.wasBrowsing)
        P:Fill(P.context,context,w-24,max(1,ch),step,newStep)
        P.wasBrowsing=nil
        if background and s.layout~="split" then
            local linkY=min(h-38,paneTop+(P.action.contentBottom or ah)+6)
            point(P.backgroundLink,P.root,12,linkY,w-38,24)
        end
    end
    point(P.grip,P.root,w-19,h-13,16,12)
    setShown(P.grip,not self.db.profile.windowlocked)
    self.delayFlash=0;self.frameNeedsResizing=0;self.stepchanged=false
    self.parchmentDirty=nil
    P:SecureButtons()
    self:ParchmentCooldowns()
    if P.background and P.background:IsShown() then P:OpenBackground(P.background.entry) end
    P.updating=nil
end

function P:Browse(width,top,height)
    self.action:Show();self.context:Hide();self.context.bar:Hide();self.divider:Hide();self.continue:Hide()
    self.heading:SetText("Choose a step")
    self.heading:Show();self.headingHit:Hide()
    self.readerFooter:Hide()
    point(self.action,self.root,12,top+TITLE_HEIGHT,width,max(1,height-TITLE_HEIGHT))
    local rows={}
    for n,step in ipairs(ZGV.CurrentGuide and ZGV.CurrentGuide.steps or {}) do
        local index=n
        rows[#rows+1]={GetStatus=function() return "passive" end,
            GetText=function() return tostring(index)..". "..clean(step.title or (step.goals[1] and (step.goals[1].info or step.goals[1].text)) or "Step") end,
            browse=index}
    end
    self:Fill(self.action,rows,width,height,ZGV.CurrentStep,not self.wasBrowsing)
    for i,goal in ipairs(rows) do
        self.action.rows[i].clicker:SetScript("OnClick",function()
            if ZGV.CurrentGuide.steps[goal.browse]:AreRequirementsMet() then
                self:CloseBackground()
                self.browsing=false;ZGV.pause=true;ZGV:FocusStep(goal.browse)
            end
        end)
    end
    self.wasBrowsing=true
end

function ZGV:ParchmentCooldowns()
    if not P.root then return end
    for _,pane in ipairs({P.action,P.context}) do
        for _,row in ipairs(pane.rows) do
            local spec=row.inlineActionSpec
            if spec then
                local start,duration,enabled=0,0,0
                if spec.type=="item" and spec.itemid then start,duration,enabled=GetItemCooldown(spec.itemid)
                elseif spec.type=="spell" then start,duration,enabled=GetSpellCooldown(spec.spellid or spec.spell) end
                CooldownFrame_SetTimer(row.cooldown,start or 0,duration or 0,enabled or 0)
            else row.cooldown:Hide() end
        end
    end
end

function ZGV:ParchmentTick(elapsed)
    P.elapsed=(P.elapsed or 0)+elapsed
    if P.elapsed<0.05 then return end
    elapsed=P.elapsed;P.elapsed=0
    if P.splitting and not self.db.profile.windowlocked and P.available and P.available>0 then
        local _,cy=GetCursorPosition()
        local top=self.Frame:GetTop()-P.bodyTop
        local localY=cy/self.Frame:GetEffectiveScale()
        P:Settings().split=clamp((top-localY)/P.available,0,1)
        self.parchmentDirty=true
    end
    if self.frameNeedsUpdating or self.parchmentDirty or P.sizing then
        self.frameNeedsUpdating=nil
        self:UpdateParchment()
    end
    -- Settings can change SetScale directly, and UIParent scale can change
    -- without rebuilding rows. Absolute secure overlays must follow both.
    local scale,left,bottom=self.Frame:GetEffectiveScale(),self.Frame:GetLeft(),self.Frame:GetBottom()
    if self.framemoving or scale~=P.lastScale or left~=P.lastLeft or bottom~=P.lastBottom then
        P:SecureButtons()
        if P.background then P.background:SetScale(self.db.profile.framescale or 1) end
        P.lastScale,P.lastLeft,P.lastBottom=scale,left,bottom
    end
    if self.fastforward then
        self.completionelapsed=self.completionelapsed+elapsed
        if self.completionelapsed>=self.completioninterval then self:TryToCompleteStep(true) end
    end
end

SLASH_ZGVPARCHMENT1="/zgparchment"
SlashCmdList.ZGVPARCHMENT=function(cmd)
    cmd=(cmd or ""):lower():match("^%s*(.-)%s*$")
    if cmd=="flow" or cmd=="split" then
        P:Settings().layout=cmd; P.expandedReading=false; P.actionAnchor=nil; P.contextAnchor=nil
        ZGV:UpdateFrame(true)
    elseif cmd=="off" or cmd=="on" then
        ZGV.db.profile.parchmentprototype=cmd=="on"
        ReloadUI() -- explicit mode switch restores the untouched native layout
    elseif cmd=="compact" then
        local settings=P:Settings()
        settings.width,settings.height=DEFAULT_WIDTH,DEFAULT_HEIGHT
        settings.tools=false
        ZGV:UpdateFrame(true)
    elseif cmd=="reset" then
        ZGV.db.profile.parchment=nil;P.anchored=nil;ZGV:UpdateFrame(true)
    else ZGV:Print("/zgparchment flow | split; on | off (reload); compact; reset") end
end
