-- Product walkthrough: public quest-derived prose, isolated simulated actions.
-- No uploaded campaign source, real quests, navigation, items or rewards.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local TITLE="Ares' Guide Authoring\\UI Tests\\Adventure walkthrough"
ZGV.AdventureFixtureTitle=TITLE
ZGV.AdventureFixtureFlags={}
local background={title="Why do the druids sleep?",body="The slumber beneath Ban'ethil belongs to an ancient bargain. After the War of the Ancients, Ysera linked Nordrassil, the World Tree at Mount Hyjal, to her realm: the Emerald Dream. The night elf druids agreed to sleep for centuries while their spirits travelled its paths.\n\nTheir hibernation was a commitment, not simply a long rest. While their spirits journeyed beyond the waking world, their bodies remained behind. Protectors such as Gaerolas kept watch over the sleepers.\n\nThat is the duty behind Athridas's concern. The missing report comes from someone entrusted with people who cannot simply rise to defend themselves."}
function ZGV:AdventureFixtureBackground(step)
    local guide=self.CurrentGuide
    if guide and guide.title==TITLE and guide.steps and (step==guide.steps[4] or step==guide.steps[6]) then return background end
end
function ZGV:AdventureFixtureComplete(index)
    -- An old test button must not mutate another guide or a different scene.
    if not self.CurrentGuide or self.CurrentGuide.title~=TITLE or self.CurrentStepNum~=index then return end
    self.AdventureFixtureFlags[index]=true
    self:UpdateFrame()
end
SLASH_ZGVADVENTURE1="/zgadventure"
SlashCmdList.ZGVADVENTURE=function(value)
    local text=(value or ""):match("^%s*(.-)%s*$"):lower()
    local n=(text=="" or text=="reset") and 1 or tonumber(text)
    if not n or n~=math.floor(n) or n<1 or n>6 then
        ZGV:Print("/zgadventure [1-6|reset]: simulated walkthrough; return through Guides > Recent.")
        return
    end
    ZGV.AdventureFixtureFlags={}
    for i=1,n-1 do ZGV.AdventureFixtureFlags[i]=true end
    local settings=ZGV.Parchment:Settings()
    settings.layout="flow"
    ZGV:SetGuide(TITLE,n)
    if ZGV.Frame and not ZGV.Frame:IsShown() then ZGV:ToggleFrame() end
end
ZGV:RegisterGuide(TITLE,[[
author Zygor Remaster prototype
type leveling
startlevel 1
description Simulated product walkthrough. Select /zgadventure. Click the action icon to simulate each event; automatic guide progression stays native. No real quest, timer, movement, item or reward. Scenes 1-3 show Iverron; scenes 4-5 show optional Ban'ethil reading. Scene 6 combines story, three objectives, directions and background for layout review. These are excerpts, not a playable route.
step
title Iverron: a missing friend
.'Iverron usually visits Dirania every day, but today he is several hours late. He often explores near the northern cave, where spiders gather. She asks you to look for him.
.'Find Iverron. |tip Follow the waypoint towards the northern cave. |script ZygorGuidesViewer:AdventureFixtureComplete(1) |buttonicon Interface\Icons\INV_Misc_Map_01 |condition _G.ZygorGuidesViewer.AdventureFixtureFlags[1], true
step
title Iverron: bring help
.'A spider bit Iverron while he was exploring the cave. Dizzy from the poison, he asks you to fetch Dirania - she may know how to help.
.'Return to Dirania Silvershine. |script ZygorGuidesViewer:AdventureFixtureComplete(2) |buttonicon Interface\Icons\INV_Misc_Map_01 |condition _G.ZygorGuidesViewer.AdventureFixtureFlags[2], true
step
title Iverron: after the rescue
.'Iverron drinks the antidote and begins to feel better. He will rest here while he recovers. With the medicine delivered, you can return to Gilshalan's search for a spider egg.
.'Return to Shadowthread Cave. |script ZygorGuidesViewer:AdventureFixtureComplete(3) |buttonicon Interface\Icons\INV_Misc_Map_01 |condition _G.ZygorGuidesViewer.AdventureFixtureFlags[3], true
step
title Ban'ethil: the sleeping druids
.'Athridas has heard nothing from Gaerolas, the warden protecting Ban'ethil's sleeping druids. Their slumber honours a pact with Ysera, the green dragon who watches over the Emerald Dream - a spirit realm beyond the waking world. Find Gaerolas in Starbreeze Village and learn whether his charges are safe.
.'Find Gaerolas Talvethren in Starbreeze Village. |script ZygorGuidesViewer:AdventureFixtureComplete(4) |buttonicon Interface\Icons\INV_Misc_Map_01 |condition _G.ZygorGuidesViewer.AdventureFixtureFlags[4], true
step
title Ban'ethil: Oben's request
.'Oben's spirit is trapped in the Emerald Dream. The Gnarlpine shamans have taken control of his sleeping body and use it to attack intruders. Bring him one of their charms so he can examine the enchantment.
.'Collect a Shaman Voodoo Charm (0/1). |tip Defeat Gnarlpine Shamans in the next room. |condition false, true
step
title Ban'ethil: relics of wakening
.'Athridas needs four sacred relics to prepare the sleeping druids' awakening. Search the chests within Ban'ethil and bring the relics back to him.
.'Black Feather Quill (1/1). |condition true, true
.'Collect the Rune of Nesting (0/1). |tip Upper floor: cross the middle bridge. The chest is on the right in the small room. |condition false, true
.'Collect the Raven Claw Talisman (0/1). |tip At the bottom of the den, cross the bridge to the chest on the ledge. |condition false, true
]])
