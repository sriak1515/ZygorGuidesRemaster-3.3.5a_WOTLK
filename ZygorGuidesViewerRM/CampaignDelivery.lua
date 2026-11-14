-- Delivery uses admitted data only. It never evaluates quest evidence or steps.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local D={}
ZGV.CampaignDelivery=D
local currentChar,selected,registration,manual,retained
local automatic={}
local types={context=true,moment=true,chapter=true}
local function key(entry) return entry.id..':'..entry.revision end
local function reset()
    currentChar=ZGV.db and ZGV.db.char
    selected,registration,manual,retained=nil,nil,nil,nil;automatic={}
end
local function character()
    local char=ZGV.db and ZGV.db.char
    if char~=currentChar then reset() end
    return char
end
function D:BeginSession() reset() end -- reload/activation never opens a backlog
function D:Mode(kind)
    local profile=ZGV.db and ZGV.db.profile
    local settings=profile and profile.campaignStory
    return types[kind] and type(settings)=='table' and settings[kind]=='open' and 'open' or 'cue'
end
function D:SetMode(kind,value)
    if not types[kind] or (value~='cue' and value~='open') then return false end
    local profile=ZGV.db and ZGV.db.profile
    if not profile then return false end
    if type(profile.campaignStory)~='table' then profile.campaignStory={} end
    profile.campaignStory[kind]=value
    -- Preference edits affect future arrivals, never suddenly open old pending text.
    automatic={}
    return true
end
local function blocked()
    local P=ZGV.Presentation
    if not P or P.mode~='live' or P.fixture or P.storyOpen or P.moving or P.sizing then return true end
    if not ZGV.Frame or not ZGV.Frame:IsVisible() or ZGV.Frame:GetAlpha()<0.1 then return true end
    if InCombatLockdown() then return true end
    if UnitCastingInfo and UnitCastingInfo('player') then return true end
    if UnitChannelInfo and UnitChannelInfo('player') then return true end
    if SpellIsTargeting and SpellIsTargeting() then return true end
    for _,name in ipairs({'QuestFrame','GossipFrame','LootFrame','MerchantFrame','TaxiFrame','TrainerFrame','TradeFrame'}) do
        local frame=_G[name]
        if frame and frame:IsShown() then return true end
    end
    return false
end
function D:OnAdmission(reg,arrival)
    if not character() or reg~=ZGV.CurrentGuideName or not arrival.live or blocked() then return end
    -- Only live arrivals request opening; pending context does not hold a later
    -- significant passage hostage. A visible reader is protected by blocked().
    local entries=ZGV.CampaignData:CollectAdmitted(reg)
    for _,entry in ipairs(entries) do
        if entry.id==arrival.id and entry.revision==arrival.revision and not entry.presented
            and self:Mode(entry.type)=='open' and not automatic[reg] then
            automatic[reg]=key(entry)
            return
        end
    end
end
function D:Context(reg)
    if not character() or not ZGV.CampaignData then return end
    if registration~=reg then
        local request=reg and automatic[reg]
        automatic={};if request then automatic[reg]=request end
        selected,manual,retained=nil,nil,nil;registration=reg
    end
    local entries=ZGV.CampaignData:CollectAdmitted(reg)
    local P=ZGV.Presentation
    if P and P.storyOpen and P.storyEntry and not P.storyEntry.campaign then return end
    local pinned=manual or retained or (P and P.storyOpen and P.storyEntry and P.storyEntry.campaign and P.storyEntry.registration==reg)
    if automatic[reg] and blocked() then automatic[reg]=nil end
    local entry,pending,requested
    for _,candidate in ipairs(entries) do
        if not candidate.presented then pending=pending or candidate end
        if pinned and selected==key(candidate) then entry=candidate end
        if automatic[reg]==key(candidate) then requested=candidate end
    end
    entry=entry or requested or pending
    if not entry then
        local history=ZGV.CampaignData:CollectPresented(reg)
        entry=history[#history]
    end
    if not entry then selected=nil;return end
    selected=key(entry)
    return {campaign=true,registration=reg,id=entry.id,revision=entry.revision,type=entry.type,
        title=entry.title or "Story",body=entry.body,persistent=true,cue=pending~=nil,
        autoOpen=(manual==selected or (automatic[reg]==selected and not blocked())) and true or false}
end
function D:Close(entry,interrupted)
    automatic={};manual=nil
    if not interrupted then selected=nil;retained=nil end
end
function D:RecallPrevious(reg)
    if not character() or InCombatLockdown() then return false end
    local entries=ZGV.CampaignData:CollectPresented(reg)
    if #entries==0 then return false end
    local index=#entries
    if registration==reg then
        for i,entry in ipairs(entries) do if selected==key(entry) then index=(i-2)%#entries+1;break end end
    end
    registration=reg;selected=key(entries[index]);manual=selected;automatic={}
    return true
end
function D:MarkVisible(entry)
    if not character() or registration~=entry.registration or selected~=key(entry) then return false end
    local marked=ZGV.CampaignData:MarkPresented(entry.registration,entry.id,entry.revision)
    if marked then automatic[entry.registration]=nil;manual=nil;retained=selected end
    return marked
end
