local root=arg[1] or 'ZygorGuidesViewerRM'
local handler,events,observations,closed=nil,{},0,0
CreateFrame=function()return {RegisterEvent=function(_,e)events[e]=true end,SetScript=function(_,_,f)handler=f end}end
ZygorGuidesViewer={CampaignData={ObservePlayerFacts=function()observations=observations+1 end},
 Parchment={background={entry={campaign=true},IsShown=function()return true end},CloseBackground=function(_,interrupted)assert(interrupted);closed=closed+1 end}}
local ZGV=ZygorGuidesViewer
local counts={[42]=2}
UnitClass=function(unit)assert(unit=='player');return 'Localized','DRUID'end
UnitRace=function(unit)assert(unit=='player');return 'Localized','NightElf'end
UnitLevel=function(unit)assert(unit=='player');return 18 end
GetItemCount=function(id,bank)assert(bank==false);return counts[id] or 0 end
assert(loadfile(root..'/CampaignPlayerFacts.lua'))()
assert(loadfile(root..'/CampaignAdmission.lua'))()
local facts=ZGV.CampaignPlayerFacts:Read({class=true,race=true,level=true,items={[42]=true,[43]=true}})
assert(facts.class=='Druid' and facts.race=='NightElf' and facts.level==18 and facts.items[42]==2 and facts.items[43]==0)
local evaluate=ZGV.CampaignAdmission.Evaluate
assert(evaluate({all={{class_is='Druid'},{race_is='NightElf'},{level_at_least={actor='leader',level=18}},{has_item={item_id=42,count=2}}}},{player=facts})==true)
assert(evaluate({has_item={item_id=43,count=1}},{player=facts})==false)
counts[42]=3;assert(ZGV.CampaignPlayerFacts:Read({items={[42]=true}}).items[42]==3)
UnitRace=function()return 'Localized','Scourge'end
assert(ZGV.CampaignPlayerFacts:Read({race=true}).race=='Undead')
UnitClass=function()error('unavailable')end;UnitRace=function()return nil,nil end
UnitLevel=function()return 0 end;GetItemCount=function()return nil end
facts=ZGV.CampaignPlayerFacts:Read({class=true,race=true,level=true,items={[42]=true}})
for _,predicate in ipairs({{class_is='Druid'},{race_is='NightElf'},{level_at_least={actor='leader',level=1}},{has_item={item_id=42,count=1}}})do
 assert(evaluate(predicate,{player=facts})==nil and evaluate({['not']=predicate},{player=facts})==nil)
end
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_LEVEL_UP','BAG_UPDATE','UNIT_INVENTORY_CHANGED'})do assert(events[event]);handler(nil,event,'player')end
assert(observations==4);handler(nil,'UNIT_INVENTORY_CHANGED','party1');assert(observations==4)
handler(nil,'PLAYER_REGEN_DISABLED');assert(closed==1 and observations==4)
print('PASS player facts: canonical player-only class/race/level, on-person item counts, fresh events, protected API failures and unknown under NOT')
