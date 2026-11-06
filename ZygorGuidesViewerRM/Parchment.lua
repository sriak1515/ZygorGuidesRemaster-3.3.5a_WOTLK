-- First playable vertical viewer. Presentation only: completion and navigation
-- stay in the guide engine. Disable with /zgparchment off (then reloads).
local ZGV = ZygorGuidesViewer
if not ZGV then return end
local P = {}
ZGV.Parchment = P
local white = "Interface\\Buttons\\WHITE8X8"
local ink = {0.188, 0.161, 0.122}
local light = {0.925, 0.875, 0.749}
local min, max = math.min, math.max
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
    s.width = max(340, tonumber(s.width) or 380)
    s.height = max(440, tonumber(s.height) or 520)
    s.split = clamp(tonumber(s.split) or 0.55, 0, 1)
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

function P:Partition(step, plaincontext)
    local actions, context, confirms = {}, {}, {}
    for _, goal in ipairs(step and step.goals or {}) do
        if goal:GetStatus() ~= "hidden" then
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
            if goal:GetStatus() ~= "hidden" and not ((goal.context or plaincontext) and self:IsPlain(goal)) then
                actions[#actions+1] = goal
            end
        end
    end
    return actions, context, story, confirms
end

function P:Allocation(height, tools, mixed, collapsed, story, split)
    local top = tools and 112 or 58 -- fixed header, tools, and step heading
    local body = max(0, height - top - 14)
    if story then return 0, body, top end
    if not mixed then return body, 0, top end
    if collapsed then return body - 28, 0, top end
    local available = body - 28 -- visible context heading and divider
    local action = clamp(available * split, 160, available - 116)
    return action, available - action, top -- context total minimum: 116 + 28
end

local function backdrop(frame, r,g,b, edge)
    frame:SetBackdrop({bgFile=white, edgeFile=white, edgeSize=edge or 1,
        insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(r,g,b,1)
    frame:SetBackdropBorderColor(0.533,0.447,0.286,1)
end
local function text(parent, size, color)
    local fs = parent:CreateFontString(nil,"ARTWORK")
    local font = ZGV:GetRemasterFont(size >= 18 and "section" or "body")
    if not fs:SetFont(font, size) then fs:SetFont(STANDARD_TEXT_FONT, size) end
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
    backdrop(b,0.188,0.216,0.173)
    b.label = text(b,12,light)
    b.label:SetPoint("CENTER",b,"CENTER",0,0)
    b.label:SetText(label)
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
    pane.bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    pane.bar:GetThumbTexture():SetSize(10,26)
    backdrop(pane.bar,0.70,0.63,0.48)
    pane.bar:SetValueStep(1)
    pane.bar:SetScript("OnValueChanged",function(_,value)
        pane:SetVerticalScroll(value)
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

function P:Create()
    if self.root then return end
    local frame = ZGV.Frame
    local root = CreateFrame("Frame",nil,frame)
    root:SetAllPoints(frame)
    root:SetFrameLevel(frame:GetFrameLevel()+10)
    backdrop(root,0.847,0.788,0.651,3)
    self.root = root
    self.header = CreateFrame("Frame",nil,root)
    backdrop(self.header,0.188,0.216,0.173)
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
    self.chapter = text(self.header,13,{0.890,0.780,0.569})
    self.chapter:SetPoint("TOPLEFT",self.header,"TOPLEFT",8,-5)
    self.chapter:SetHeight(16)
    tooltip(self.header,function() return (self.fullTitle or "Zygor Guides Remaster")..(ZGV.CurrentStep and ZGV.CurrentStep.title and ("\n"..clean(ZGV.CurrentStep.title)) or "") end)
    self.prev = button(self.header,"<",22,function(_,b) ZGV:SkipStep(-1,b=="RightButton") end)
    self.next = button(self.header,">",22,function(_,b) ZGV:SkipStep(1,b=="RightButton") end)
    tooltip(self.prev,"Previous step. Right-click: fast backward.")
    tooltip(self.next,"Next / Continue. Right-click: fast forward.")
    self.position = text(self.header,12,light)
    self.tools = button(self.header,"Tools",42,function()
        local s=P:Settings(); s.tools=not s.tools; ZGV:UpdateParchment()
    end)
    self.close = button(self.header,"X",22,function() ZGV:ToggleFrame() end)
    self.utility = CreateFrame("Frame",nil,root)
    self.guides = button(self.utility,"Guides",60,function(_,b)
        if b=="RightButton" then ZGV:ToggleGuideManagerFrame("home") else ZGV:OpenGuideMenu() end
    end)
    self.steps = button(self.utility,"Steps",54,function()
        P.browsing=not P.browsing; ZGV:UpdateParchment()
    end)
    self.lock = button(self.utility,"Lock",58,function() ZGV:ToggleWindowLock() end)
    self.settings = button(self.utility,"Settings",68,function(_,b)
        if b=="RightButton" then ZGV:ToggleGuideManagerFrame("options") else ZGV:OpenQuickMenu(P.settings) end
    end)
    self.reading = button(self.utility,"Read plain text as context",210,function()
        local s=P:Settings(); s.plaincontext=not s.plaincontext; ZGV:UpdateParchment()
    end)
    tooltip(self.reading,"Explicit reading preference: moves plain text and info into Context. Turn off to keep untagged directions with Actions.")
    self.heading = text(root,18)
    self.heading:SetHeight(24)
    self.headingHit=CreateFrame("Frame",nil,root)
    self.headingHit:EnableMouse(true)
    tooltip(self.headingHit,function() return P.stepTitle or "Actions" end)
    self.action = self:CreatePane(root)
    self.context = self:CreatePane(root)
    self.divider = CreateFrame("Frame",nil,root)
    self.divider:EnableMouse(true)
    self.divider:RegisterForDrag("LeftButton")
    backdrop(self.divider,0.776,0.710,0.557)
    self.collapse = button(self.divider,"Context -",106,function()
        local s=P:Settings(); s.collapsed=not s.collapsed; ZGV:UpdateParchment()
    end)
    self.divider:SetScript("OnDragStart",function()
        if not ZGV.db.profile.windowlocked and not P:Settings().collapsed then P.splitting=true end
    end)
    self.divider:SetScript("OnDragStop",function() P.splitting=nil end)
    tooltip(self.divider,"Drag to divide Actions and Context. Lock prevents dragging. Click Context to collapse or restore.")
    self.continue = button(root,"Continue >",98,function()
        local confirms=P.confirms or {}
        if #confirms>0 then
            -- Use the actual goal click path, retaining confirm/next branching.
            local proxy={goal=confirms[1],GetParent=function() return {step=ZGV.CurrentStep} end}
            ZGV:GoalOnClick({GetParent=function() return proxy end},"LeftButton")
        else ZGV:SkipStep(1) end
    end)
    tooltip(self.continue,function() return P.confirms and P.confirms[1] and P:GoalText(P.confirms[1]) or "Continue to the next step" end)
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
    frame:HookScript("OnHide",function() P:ClearSecureButtons() end)
    self.events=CreateFrame("Frame")
    self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.events:SetScript("OnEvent",function() ZGV.parchmentDirty=true; P:ClearSecureButtons() end)
    self.initialized=true
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
    row.label:SetSpacing(6)
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
    row.completion=CreateFrame("Frame",nil,row)
    row.completion:SetFrameLevel(row.actionHolder:GetFrameLevel()+2)
    row.completion:SetSize(16,16)
    row.completion.icon=row.completion:CreateTexture(nil,"OVERLAY")
    row.completion.icon:SetAllPoints(row.completion)
    row.completion.icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
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
    local y=4
    for i,goal in ipairs(goals) do
        local row=self:Row(pane,i)
        row.goal=goal; row.inlineActionSpec=nil
        row.clicker:SetScript("OnClick",function(self,b)
            if InCombatLockdown() and row.inlineActionSpec and MouseIsOver(row.actionHolder) then return end
            ZGV:GoalOnClick(self,b)
        end)
        point(row,pane.child,0,y,width-14,22)
        row.label:SetWidth(width-42)
        row.label:SetHeight(0) -- unconstrained wrapping; never cap paragraph height
        local value=self:GoalText(goal)
        local tip=goal.tooltip or goal.routesharedtip
        goal._display_tooltip=tip
        if tip and tip~="" then value=value.."\n"..clean(tip) end
        local complete=goal:GetStatus()=="complete"
        row.label:SetText(value)
        setShown(row.completion,complete)
        row.completion:ClearAllPoints()
        row.completion:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
        local h=max(22,row.label:GetStringHeight())
        row.label:SetHeight(h)
        row:SetHeight(h)
        row.label:SetTextColor(unpack(complete and {0.28,0.34,0.22} or ink))
        local spec=ZGV:InlineButtonsEnabled() and ZGV:GetGoalActionSpec(goal)
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
        y=y+h+10
    end
    for i=#goals+1,#pane.rows do
        pane.rows[i].goal=nil; pane.rows[i].inlineActionSpec=nil; pane.rows[i]:Hide()
    end
    pane.child:SetHeight(max(height,y+4))
    pane.range=max(0,y+4-height)
    pane.bar:SetMinMaxValues(0,pane.range)
    pane.bar:SetValue(newStep and 0 or clamp(pane.bar:GetValue() or 0,0,pane.range))
    pane:SetVerticalScroll(pane.bar:GetValue())
    setShown(pane.bar,pane.range>0 and pane:IsShown())
end

function P:Suspend()
    if not self.active then return end
    self.root:Hide()
    self:ClearSecureButtons()
    self.active=false; self.anchored=nil
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
    frame:SetResizable(true); frame:SetMinResize(340,440)
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
    local newStep=P.step~=step or P.guide~=self.CurrentGuide
    if newStep then P.browsing=false end
    P.step,P.guide=step,self.CurrentGuide
    if step then step:Translate() end
    local actions,context,story,confirms=P:Partition(step,s.plaincontext)
    P.confirms=confirms
    local mixed=#context>0 and not story
    local ah,ch,top=P:Allocation(h,s.tools,mixed,s.collapsed,story,s.split)
    P.actionHeight,P.contextHeight=ah,ch
    P.available=ah+ch
    P.bodyTop=top
    point(P.header,P.root,3,3,w-6,38)
    P.fullTitle=self.CurrentGuide and (self.CurrentGuide.title_short or self.CurrentGuide.title) or "Zygor Guides Remaster"
    fitLabel(P.chapter,clean(P.fullTitle),w-250)
    point(P.prev,P.header,w-235,7,22,24)
    P.position:ClearAllPoints();P.position:SetPoint("TOPLEFT",P.header,"TOPLEFT",w-208,-13)
    P.position:SetWidth(74)
    P.position:SetText(tostring(self.CurrentStepNum or 0).." / "..tostring(self.CurrentGuide and self.CurrentGuide.steps and #self.CurrentGuide.steps or 0))
    point(P.next,P.header,w-129,7,22,24)
    point(P.tools,P.header,w-100,7,58,24)
    point(P.close,P.header,w-34,7,22,24)
    point(P.utility,P.root,12,44,w-24,50)
    setShown(P.utility,not not s.tools)
    point(P.guides,P.utility,0,0,60,24); point(P.steps,P.utility,64,0,54,24)
    point(P.lock,P.utility,122,0,66,24); point(P.settings,P.utility,192,0,68,24)
    point(P.reading,P.utility,0,26,w-24,24)
    P.reading.label:SetText(s.plaincontext and "Plain text in Context: on" or "Plain text in Context: off")
    P.lock.label:SetText(self.db.profile.windowlocked and "Unlock" or "Lock")
    P.heading:ClearAllPoints(); P.heading:SetPoint("TOPLEFT",P.root,"TOPLEFT",12,-(top-14))
    P.stepTitle=clean(step and step.title or (story and "Reading" or "Actions"))
    fitLabel(P.heading,P.stepTitle,w-(story and 132 or 24))
    point(P.headingHit,P.root,12,top-14,w-(story and 132 or 24),24)
    setShown(P.continue,story)
    point(P.continue,P.root,w-116,top-20,98,24)
    local paneTop=top+16
    -- Both minima include their heading; the actual scroll viewport is below it.
    ah=max(0,ah-16); ch=story and max(0,ch-16) or ch
    point(P.action,P.root,12,paneTop,w-24,max(1,ah))
    setShown(P.action,not story)
    setShown(P.divider,mixed)
    local dividerTop=paneTop+ah
    point(P.divider,P.root,12,dividerTop,w-24,28)
    point(P.collapse,P.divider,4,2,116,24)
    P.collapse.label:SetText(s.collapsed and "Context +" or "Context -")
    local ct=story and paneTop or dividerTop+28
    point(P.context,P.root,12,ct,w-24,max(1,ch))
    setShown(P.context,story or (mixed and not s.collapsed))
    for _,pane in ipairs({P.action,P.context}) do
        pane.bar:ClearAllPoints()
        pane.bar:SetPoint("TOPRIGHT",pane,"TOPRIGHT",0,0)
        pane.bar:SetPoint("BOTTOMRIGHT",pane,"BOTTOMRIGHT",0,0)
    end
    if not step then actions={{GetStatus=function() return "passive" end, GetText=function() return "Choose a guide using Tools > Guides." end}} end
    if P.browsing then P:Browse(w-24,paneTop,h-paneTop-18)
    else
        P:Fill(P.action,actions,w-24,max(1,ah),step,newStep or P.wasBrowsing)
        P:Fill(P.context,context,w-24,max(1,ch),step,newStep)
        P.wasBrowsing=nil
    end
    point(P.grip,P.root,w-19,h-13,16,12)
    setShown(P.grip,not self.db.profile.windowlocked)
    self.delayFlash=0;self.frameNeedsResizing=0;self.stepchanged=false
    self.parchmentDirty=nil
    P:SecureButtons()
    self:ParchmentCooldowns()
    P.updating=nil
end

function P:Browse(width,top,height)
    self.action:Show();self.context:Hide();self.context.bar:Hide();self.divider:Hide();self.continue:Hide()
    self.heading:SetText("Choose a step")
    point(self.action,self.root,12,top,width,height)
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
    if cmd=="off" or cmd=="on" then
        ZGV.db.profile.parchmentprototype=cmd=="on"
        ReloadUI() -- explicit mode switch restores the untouched native layout
    elseif cmd=="reset" then
        ZGV.db.profile.parchment=nil;P.anchored=nil;ZGV:UpdateFrame(true)
    else ZGV:Print("/zgparchment on | off (reload); reset (position, size and reading preferences)") end
end
