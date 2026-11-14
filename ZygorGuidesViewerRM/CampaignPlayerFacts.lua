-- Observe only referenced player predicates. No queries, polling or companion data.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local F={}
ZGV.CampaignPlayerFacts=F
local classes={WARRIOR='Warrior',PALADIN='Paladin',HUNTER='Hunter',ROGUE='Rogue',PRIEST='Priest',
 DEATHKNIGHT='DeathKnight',SHAMAN='Shaman',MAGE='Mage',WARLOCK='Warlock',DRUID='Druid'}
local races={Human='Human',Orc='Orc',Dwarf='Dwarf',NightElf='NightElf',Undead='Undead',Scourge='Undead',
 Tauren='Tauren',Gnome='Gnome',Troll='Troll',BloodElf='BloodElf',Draenei='Draenei'}
local function call(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
function F:Read(requested)
    local facts={items={}}
    if requested.class then local _,tag=call(UnitClass,'player');facts.class=classes[tag] end
    if requested.race then local _,tag=call(UnitRace,'player');facts.race=races[tag] end
    if requested.level then
        local n=call(UnitLevel,'player')
        if type(n)=='number' and n>=1 and n<=80 and n==math.floor(n) then facts.level=n end
    end
    for id in pairs(requested.items or {}) do
        local count=call(GetItemCount,id,false) -- same on-person inventory scope as native goals
        if type(count)=='number' and count>=0 and count<2147483648 and count==math.floor(count) then facts.items[id]=count end
    end
    return facts
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_LEVEL_UP','BAG_UPDATE','UNIT_INVENTORY_CHANGED','PLAYER_REGEN_DISABLED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event,unit)
    if event=='PLAYER_REGEN_DISABLED' then
        local reader=ZGV.Parchment and ZGV.Parchment.background
        if reader and reader.entry and reader.entry.campaign and reader:IsShown() then ZGV.Parchment:CloseBackground(true) end
        return
    end
    if event=='UNIT_INVENTORY_CHANGED' and unit~='player' then return end
    if ZGV.CampaignData then ZGV.CampaignData:ObservePlayerFacts() end
end)
