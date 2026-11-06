-- Synthetic viewer fixtures v1. Not campaign content; never selected automatically.
-- All core states are independent of player race, class, quests and inventory.
local ZGV = ZygorGuidesViewer
if not ZGV then return end
local TITLE = "Ares' Guide Authoring\\UI Tests\\Parchment Fixtures v1"
ZGV.ParchmentFixtureTitle = TITLE
ZGV.ParchmentFixtureTokenUsed = false

-- Explicitly clicked, harmless secure-script control. No inventory or UI changes.
function ZGV:ParchmentFixtureUseToken()
    self.ParchmentFixtureTokenUsed = true
    self:UpdateFrame()
end

SLASH_ZGVPARCHMENTFIXTURE1 = "/zgfixture"
SlashCmdList.ZGVPARCHMENTFIXTURE = function(value)
    local command = (value or ""):match("^%s*(.-)%s*$"):lower()
    local step = tonumber(command)
    if command == "baseline" then
        -- Explicit preset: change only this viewer's layout preferences.
        -- Preserve position, lock, addon scale and the client's UI scale.
        local settings=ZGV.Parchment:Settings()
        settings.width,settings.height,settings.split=340,400,0.55
        settings.tools,settings.collapsed,settings.plaincontext=false,false,false
        settings.contextsize=14
        ZGV.db.profile.fontsize,ZGV.db.profile.fontsecsize=13,11
        settings.layout="split"
        ZGV.Parchment.expandedReading=false
        ZGV.Parchment.readingOrigin=nil
        ZGV.Parchment.contextAnchor=nil
        ZGV.Parchment.actionAnchor=nil
    end
    if command == "reset" or command == "baseline" or command == "" then
        ZGV.ParchmentFixtureTokenUsed = false
        step = 1
    end
    if not step or step ~= math.floor(step) or step < 1 or step > 11 then
        ZGV:Print("/zgfixture 1-11; /zgfixture baseline; /zgfixture reset. Synthetic viewer tests; return through Guides > Recent.")
        return
    end
    ZGV:SetGuide(TITLE, step)
    if ZGV.Frame and not ZGV.Frame:IsShown() then ZGV:ToggleFrame() end
end

ZGV:RegisterGuide(TITLE,[[
author Zygor Remaster prototype
type leveling
startlevel 1
description Synthetic viewer fixtures v1. Select explicitly with /zgfixture; no campaign changes or rewards. Core cases use fixed completion states. Case 11 alone uses a real inventory item.
step
label fixture_short
title F01 Short mixed
.'Speak with the trainer. |condition false, true
.'Accept the next lesson. |tip Take the spiral ramp to the middle landing. |condition false, true
.'The trainer belongs to a circle of teachers who preserve the lessons of earlier generations. This short passage provides background while the practical directions remain above. |context

step
label fixture_long_mixed
title F02 Long mixed
.'Speak with the teacher on the middle landing. |condition false, true
.'Read the inscription beside the eastern doorway. |tip Follow the balcony around the central tree; the entrance is on the upper side. |condition false, true
.'Collect the training token (2/8). |condition false, true
.'Return to the meeting place with your companions. |condition false, true
.'This deliberately extended passage tests overflow. It is synthetic interface copy, not a proposed campaign scene. The action list should remain reachable while the reading pane scrolls independently. |context
.'The first paragraph establishes the place and the people gathered there. A newcomer should be able to read it without losing the practical task above or needing a smaller font. |context
.'The second part explains why the lesson matters. Earlier teachers left a record for those who would follow them, and the present teacher asks the learner to consider that history before continuing. |context
.'A third passage adds enough detail to wrap across several lines. The layout must preserve the ends of words, punctuation, and the last line of each paragraph at both narrow and expanded window sizes. |context
.'Another paragraph keeps the reading area occupied while objectives change state. Mark a visible action complete, then verify that the reading offset stays where you left it. |context
.'The penultimate passage is intentionally ordinary prose. It should not acquire objective icons, coordinates, quest numbers, or a separate panel merely because it is longer than the earlier paragraphs. |context
.'Final mixed passage: this entire sentence must be reachable at the bottom of Context. Scrolling here must not move the action list or select another step. |context

step
label fixture_actions
title F03 Action only
.'Follow the western road to the meeting place. |tip Remain on the main road when it passes the small clearing. |condition false, true
.'Speak with the teacher beside the doorway. |condition false, true
.'Read the notice on the left-hand wall. |condition false, true
.'Return to your companions. |condition false, true

step
label fixture_story
title F04 Story only
.'This is a reading-only fixture. The viewer should use the available body for a single reading pane, keep the title outside the passage, and retain a fixed Continue control. |context
.'The outer window stays in place when entering or leaving this step. There is no invented objective list to fill space above the passage. |context
.'Continue to the completion fixture. |confirm

step
label fixture_completion
title F05 Completion states
.'The first lesson has been completed. |condition true, true
.'The second lesson remains pending. |condition false, true
.'The third lesson has been completed. |condition true, true
.'The final lesson remains pending. |condition false, true
.'Two actions start complete and two remain pending. A check and subdued text identify completion. Mark a pending action complete with the native right-click interaction; the row must remain present. |context

step
label fixture_names
title F06 Long names and directions
.'Speak with Senior Instructor of the Circle of Ancient Woodland Guardians. |condition false, true
.'Accept 'The Long and Winding Journey to the Sanctuary Beyond the Northern Mountains'. |condition false, true
.'Use the weathered ceremonial token entrusted to the keeper of the eastern observatory. |tip Climb the spiral ramp, cross the narrow bridge beside the hanging lanterns, and stop at the doorway on the middle landing. |condition false, true
.'This fixture uses long synthetic NPC, quest, and item labels to exercise wrapping without relying on server names or localization caches. Every word and the final line of each instruction must remain reachable. |context

step
label fixture_action_overflow
title F07 Action overflow, 32 rows
.'Objective 01: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 02: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 03: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 04: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 05: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 06: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 07: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 08: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 09: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 10: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 11: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 12: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 13: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 14: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 15: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 16: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 17: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 18: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 19: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 20: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 21: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 22: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 23: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 24: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 25: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 26: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 27: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 28: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 29: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 30: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 31: inspect the training marker and retain this complete instruction. |condition false, true
.'Objective 32: inspect the training marker and retain this complete instruction. |condition false, true
.'This case deliberately exceeds the former twenty-row display limit. Use the action scrollbar to reach Objective 32. This reading passage must retain its own space and independent scroll position. |context
.'Return to the top of Actions, scroll Context instead, and check that neither pane changes the other pane or advances the guide. |context

step
label fixture_long_story
title F08 Long story only
.'Reading paragraph 01. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 02. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 03. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 04. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 05. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 06. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 07. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 08. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 09. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 10. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 11. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Reading paragraph 12. This synthetic passage is repeated at a fixed length to make screenshots and scroll tests comparable. The title and Continue control must stay fixed while the passage moves through the reading viewport. |context
.'Final reading line: confirm that these words remain accessible at the bottom of the reading pane. |context
.'Continue to the legacy-text fixture. |confirm

step
label fixture_legacy
title F09 Legacy text and empty info
info
.'This untagged note is deliberately ambiguous. With plain-text reading off it stays in Actions; with the preference on it moves to Context.
.'Follow these actionable directions; they must stay in Actions in either reading mode. |condition false, true
.'This paragraph is explicitly marked as context. The empty info row above reproduces the legacy spacer pattern found in the supplied WIP guide; it contains no story text. |context

step
label fixture_inline
title F10 Harmless inline action
.'Activate the fixture token. |script ZygorGuidesViewer:ParchmentFixtureUseToken() |buttonicon Interface\Icons\INV_Misc_Rune_01 |condition _G.ZygorGuidesViewer.ParchmentFixtureTokenUsed, true
.'Keep this second action pending while inspecting the token control. |condition false, true
.'Clicking the inline icon only changes a volatile fixture flag and refreshes the viewer. It consumes nothing, grants nothing, moves no windows, and changes no campaign data. The first row gains a completion check. Use /zgfixture reset to clear the flag. |context
.'This tests the existing secure script-button path, not a real item or cooldown. Enter combat and verify the declared prototype limitation: secure inline actions are unavailable during lockdown and return afterward. |context

step
label fixture_real_item
title F11 Optional real item row
use Refreshing Spring Water##159
.'Keep this fixture open while inspecting the optional item control. |condition false, true
.'This is the only inventory-dependent fixture. The water icon is available only if the character carries Refreshing Spring Water and inline actions are enabled. Activating it uses that real item. If the character has none, record this interaction as not tested; do not change inventory for the core visual comparisons. |context
]])
