-- Bounded developer UI. Session-only switches; reload always exits this PoC.
local ZGV=ZygorGuidesViewer
local P=ZGV.Presentation

function P:Render(snapshot)
    if not self.panel then return end
    local lines={"EXPERIMENTAL / "..snapshot.source:upper(),snapshot.guide.title or "No guide",
        "Step "..tostring(snapshot.step.index or 0).." / "..snapshot.step.total,
        snapshot.step.title or ""}
    for _,goal in ipairs(snapshot.goals) do
        lines[#lines+1]="["..goal.status.."] "..goal.text..
            (type(goal.progress)=="number" and " ("..math.floor(goal.progress*100).."%)" or "")
    end
    if snapshot.navigation.title then lines[#lines+1]="Navigation: "..snapshot.navigation.title end
    if snapshot.story then lines[#lines+1]="\n"..snapshot.story end
    self.text:SetText(table.concat(lines,"\n\n"))
end

function P:CreatePanel(parent)
    local panel=CreateFrame("Frame",nil,parent)
    self.panel=panel -- available to recovery even if later widget creation fails
    panel:SetAllPoints(parent)
    panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    panel:SetBackdropColor(0.06,0.07,0.08,1)
    panel:EnableMouse(true)
    -- Wrath's template OnLoad looks up children via GetName().."ScrollBar".
    -- Give each activation a unique name; WoW frames survive Hide()/fallback.
    self.panelSerial=(self.panelSerial or 0)+1
    local scroll=CreateFrame("ScrollFrame","ZGVPresentationPOCScroll"..self.panelSerial,panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",12,-12);scroll:SetPoint("BOTTOMRIGHT",-30,42)
    local content=CreateFrame("Frame",nil,scroll)
    content:SetSize(math.max(100,parent:GetWidth()-50),1)
    scroll:SetScrollChild(content)
    local text=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    text:SetPoint("TOPLEFT");text:SetWidth(content:GetWidth());text:SetJustifyH("LEFT")
    self.text=text
    local oldRender=self.Render
    -- The actual UI callback adjusts scroll range after updating text.
    self.renderCallback=function(snapshot)
        oldRender(self,snapshot)
        content:SetHeight(math.max(1,text:GetStringHeight()+12))
    end
    for i,spec in ipairs({{"Previous",function() self:Navigate(-1) end},
        {"Next",function() self:Navigate(1) end},{"Fallback",function() self:Stop() end}}) do
        local button=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
        button:SetSize(78,24);button:SetPoint("BOTTOMLEFT",10+(i-1)*82,8)
        button:SetText(spec[1]);button:SetScript("OnClick",spec[2])
    end
    self.panel=panel
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
        self.fixtureHost:SetSize(360,440)
        self.fixtureHost:SetPoint("CENTER",UIParent,"CENTER",0,0)
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
    self.mode=nil;self.pendingStop=nil;self.fixture=nil
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
recovery:SetScript("OnEvent",function() if P.pendingStop then P:Stop() end end)
SLASH_ZGVPRESENTATIONPOC1="/zgpoc"
SlashCmdList.ZGVPRESENTATIONPOC=function(command)
    command=(command or ""):lower():match("^%s*(.-)%s*$")
    if command=="off" then P:Stop()
    elseif command=="live" or command=="fixture" then P:Start(command)
    elseif P.fixture then P:FixtureCommand(command)
    else ZGV:Print("Developer PoC: /zgpoc live | fixture | off; fixture only: goal 1-5 | story | next | prev | reset. Reload exits.") end
end
