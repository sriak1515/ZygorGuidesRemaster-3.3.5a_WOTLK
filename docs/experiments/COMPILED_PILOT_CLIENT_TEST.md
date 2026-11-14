# Experimental compiled v1 pilot — WoW 3.3.5a

This ZIP contains the complete committed ZygorGuidesViewerRM addon and a separate
WoWSoloAdventureV1Pilot content addon. It is a client-test build, not a replacement
campaign release. It contains only the already-played first Balance of Nature
example. BUILD.json identifies viewer/compiler/source revisions and hashes.

## Install without resetting progress

Exit WoW. Keep the existing WTF/SavedVariables files. Copy the two addon folders
from this ZIP into Interface/AddOns, replacing the existing viewer files. Do not
nest the folders inside another directory. Enable both addons at character select.
This package does not select a guide, reset progress, alter existing campaign
content, or change the server. The pilot remains a separate entry in Guides.

For the full quest-event test use an eligible Night Elf test character who has not
yet completed quest 456. The current main character has already passed this example;
selecting it there should skip completed work without backfilling story. Do not
abandon quests, reset SavedVariables or rewind the active campaign to make this test
run. It is fine to defer the fresh-character test.

## Ordinary gameplay check

1. Select `WoW Solo Adventure V1\EXAMPLE-KAL-01-BALANCE-ONE` through Guides. If it
   does not appear or an error is printed, stop and report the error; do not reset
   saved data. Use the existing interface or `/zgpoc live` for the adventure guide.
2. Accept the first Balance of Nature quest normally. The acceptance step should
   advance automatically, with context available beside the guide. Default story
   behavior is a quiet cue; click it to read. No developer fixture is required.
3. Progress both objectives. Partial progress must not finish the combined step.
   Observe count text, target names, native interactions, arrow target/distance and
   normal step advancement. The compiler's generic-name fallback still needs a
   client readability check.
4. Turn in normally. The reward-gated moment may wait for the existing completed-
   quest query, normally up to about ten seconds. It should then remain available
   despite the guide advancing to its finish step. Completing objectives alone,
   manually marking a goal or browsing ahead must not reveal that moment.
5. Try reading, folding, movement/resizing and ordinary combat. Combat folds the
   reader; leaving combat should not force it open. The chosen text/scroll should
   remain available. Story operations must not change the waypoint or guide step.
6. In display settings, Context passages, Story moments and Chapter passages each
   offer Quiet cue / Open when safe. Opening is opt-in and applies to new live
   arrivals. An open reader must keep its text when another passage becomes ready.
7. Fold the reader and right-click its cue to revisit a previously presented
   passage. Only passages actually shown should be recalled. Reload should start
   folded, retain presentation history/preferences and preserve native progress.
8. Switch off the adventure UI with `/zgpoc off`. A Story button beside the original
   guide should provide the same admitted passages through Parchment's existing
   movable reader. Left-click opens/closes; right-click recalls presented passages.
   Check its close, scroll, combat tuck and arrow continuity.

The pilot checkpoint is tracked from its explicit fresh proof, separately from
reading and guide display. There is no checkpoint popup or Journal expansion.
Historical reward confirmation may prove that milestone; it must not create old
story presentations. No second quest or navigation engine is installed.

## What to report

Report any Lua error and the ordinary action just performed; whether the expected
story appeared early, was lost, or reopened unexpectedly; and any arrow, objective
interaction, progress or layout regression. Include whether the test used a fresh
eligible character or the already-progressed main. BUILD.json identifies this ZIP.

Automated checks use simulated client APIs. This build has not been tested in WoW.
Actual event ordering, rendering, secure actions, combat behavior and performance
remain client checks. The package deliberately does not broaden the compiler's
supported actions, cross-guide entry gates or native step expansions.
