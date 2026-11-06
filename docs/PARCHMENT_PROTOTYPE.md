# Vertical parchment playable prototype

Current product requirements and next-session status are in [PRODUCT_BRIEF_AND_HANDOFF.md](PRODUCT_BRIEF_AND_HANDOFF.md). This document records the implemented prototype and its checkpoint history; the old split layout is under review against those newer requirements.

Implemented on branch `prototype/vertical-parchment`, based on addon **3.0.255**, revision 255, commit `d2aae8d0f1f3782d964e4179907b215aab484787` (27 October 2026). This is a prototype build of that revision; it does not claim to be a new upstream release.

The latest pass uses a single authored flow, normal primary/secondary font controls, a dedicated reading-size control, and an explicit independent background reader. Start with [PARCHMENT_PLAYTEST.md](PARCHMENT_PLAYTEST.md). Older sections retain checkpoint history, including the previous split experiment. No existing campaign text or route has been changed.

## Install and rollback

1. Exit WoW. Back up `Interface/AddOns/ZygorGuidesViewerRM` and `WTF/Account/<account>/SavedVariables/ZygorGuidesViewerRM.lua` (including its `.bak` if present). The TOC's variable is `ZygorGuidesViewerSettings`; the saved file follows the addon folder name.
2. Replace the addon folder with `ZygorGuidesViewerRM` from the test ZIP. Confirm `Interface/AddOns/ZygorGuidesViewerRM/ZygorGuidesViewerRM.toc` exists directly at that path. The ZIP contains the complete addon, including its bundled Talent Advisor, unchanged guide content and existing assets.
3. Relaunch the **3.3.5a / build 12340** client. The prototype is enabled by default for the **Remaster skin, Guide display mode**. Existing profiles using another skin/display mode retain that viewer. Select Remaster in settings and Guide mode to test this panel. `/zgparchment on` enables the prototype preference and reloads the UI; it does not change your selected skin.
4. For this build, follow [PARCHMENT_PLAYTEST.md](PARCHMENT_PLAYTEST.md): `/zgadventure` opens the new product walkthrough; Tools > Settings opens normal font settings. One authored flow is now default. `/zgparchment split` retains the previous experiment; `/zgparchment flow` restores the new flow. The old split's explicit Read hold applies only in split mode, not to the new separate background window.

The controls/checkpoint notes below are historical unless explicitly restated in the focused playtest.
## What changed

- A fixed-footprint parchment viewer, starting at 340 x 400 logical units with a 320 x 380 minimum. The accepted C direction uses the native gold dialog rim and bronze header controls around a continuous inset paper page. Locale-aware client type is used for essential text: objectives default to 13 (explicit 12–16 setting), supporting directions to 11 (derived from objective size), authored headings to 16, and reading text to 14 (explicit 14–22 setting). Inline prose and Context share reading type without sharing a forced location. No automatic text shrinking.
- Fixed chapter/step titles abbreviate only when needed, with full text on hover; body text always wraps. A fixed header with chapter tooltip, previous/next (including existing right-click fast navigation), step position, Tools and Close. Tools expands to one row inside the existing footprint; the Context disclosure shares a thin divider rule. Its Steps control opens an inline scrollable step browser.
- Separate dynamic action/context row pools and independent scrollbars. Actions normally fit for short steps; large steps can overflow without discarding rows. The native compact viewer's 20-line display cap is not reused here.
- A draggable, persisted split. Expanded Actions retain at least 160 units including their heading; Context retains at least 144 including its heading. At the smallest size with Tools expanded these constraints still fit. Collapse does not move or shrink the outer frame, and restores the saved split.
- Profile persistence through the existing AceDB/SavedVariables: `profile.parchment`, existing `profile.windowlocked`, existing `profile.framescale`, and `profile.parchmentprototype`. Scroll resets on a different parsed step/guide and stays stable on ordinary refreshes. Completed rows remain visible with a check and subdued text.
- The native progression/parser goal objects and `GoalOnClick` paths remain responsible for confirm, branches, quest/map navigation and manual completion. Inline controls reuse native action specifications and secure attribute application. Native diagnostic chat and numeric quest-name fallback prose are suppressed in this viewer.
- Native resizing/chrome are bypassed only while this prototype is active. Its position settings are separate. Optional companion UI placement profiles are not applied while it is active. No campaign prose or progression rules were rewritten.

## Context limitation and compatible solution

The supplied parser represents both narrative and practical directions as generic `goal.text` or `action == "info"`. Those fields do **not** identify story reliably. Routing all generic text into a collapsible pane by default would hide directions.

The default is therefore conservative: **all untagged rows remain in Actions**. Existing guides show an action-only parchment panel until context is explicitly identified. Unknown actions also remain in Actions.

An optional inline `|context` marker now attaches presentation metadata to an existing row, for example:

```text
step
' Existing passage, unchanged |context
accept Existing Quest##783
```

This example describes syntax only; no such content was added to a shipped guide. The marker does not alter completion. It only moves a plain passive row. A row with an action, quest, coordinates, image, item/spell/script interaction, branch or completion behavior stays actionable even if marked. Multiple confirm choices remain visible in Actions; a single confirm in a story-only step uses the fixed Continue control, preserving its native branch.

For testing untagged guides, **Tools > Settings > Move untagged notes to Context** is an explicit, persisted placement preference. It moves eligible plain/info rows into Context. Because these can include introductions and directions, turn it off to retain their authored position among the objectives. This preference provides a reversible fallback without silently inferring semantics from prose, length or keywords.

**Campaign reference now supplied:** `DruidCalling.lua` v0.6 was attached after the first client checkpoint and inspected read-only. Its 15 steps provide seven reading-only and eight mixed/travel states when the explicit plain-text reading preference is on. The upload is WIP reference material; it is not copied into the public branch or rewritten. See `PARCHMENT_FIXTURES.md` for its measured lengths and the separate repeatable fixture guide.

## Source inspection and real content calibration

Inspected the main viewer's frame creation and compact layout, `ZygorGuidesViewerFrame.lua/.xml`, skin definitions and locale font helper, `Parser.lua`, `Goal.lua`, `Step.lua`, the progression/translation lifecycle, native wheel/step handling, secure overlay/action specifications, and defaults/profile settings in `Options.lua`. There are no `AGENTS.md` files in this checkout. The base revision had no repository CI workflow or dedicated packaging script. The prototype now includes `tools/release/package_addon.py` and `.github/workflows/parchment-prototype.yml`; they follow the README's folder-in-a-ZIP installation layout.

`test_parchment_guides.lua` parsed **16,012 steps** across the shipped legacy Alliance/Horde leveling files and imported Alliance/Horde WOTLK leveling files, with **zero parse failures**. It preserves all nonempty parsed rows under the default partition; empty passive `info` spacer rows carry no passage and are omitted. These counts do not evaluate player-specific visibility or quest progress.

| Representative real step | Parsed rows | Completion objectives | Text bytes* |
| --- | ---: | ---: | ---: |
| Legacy Alliance Human (1-13), step 1 | 3 | 1 | 28 |
| Imported Alliance Zul'Drak (75-77), step 104 | 17 | 1 | 1,222 |
| Imported Horde Howling Fjord (69-71), step 200 | 17 | 14 | 89 |
| Legacy Alliance Human (1-13), step 36, item-use row | 1 | 1 | 27 |
| Legacy Alliance Levels (50-55), step 105, plain reading | 7 | 0 | 293 |

*Byte counts sum available parsed text/info/quest/target/NPC/parameter strings plus tooltips, before localization and generated `GetText` labels. They are content-length observations, not rendered glyph counts. The dense sample's 14 completion-capable rows include thirteen route waypoints; it is not fourteen simultaneous quest tasks. Death Knight maxima also include racial alternatives. These static corpus observations do not establish player-visible counts or future campaign limits. The supplied WIP campaign and the Howling Fjord quest-handoff sample are inspected separately.

## Automated validation

Run with Lua 5.1 directly, or install the test-only Python `lupa` dependency and run:

```sh
python tools/ui/run_checks.py
```

The runner uses `lupa.lua51`, creates a fresh runtime per script, parses all 36 top-level addon Lua files, and runs all 25 Lua test scripts (21 existing and 4 prototype regressions). `git diff --check` and XML well-formedness checks are also run. The ZIP is checked for its TOC and loaded files, and for accidental scratch/test files. The initial recursive TOC/XML audit followed 409 load paths and reported 49 absent paths already referenced by the base revision: optional author slots `Guides/Guide02.lua` through `Guide40.lua`, and `ZygorTalentAdvisor/Builds/build01.lua` through `build10.lua`. These files were not supplied in the repository; no placeholder content was invented. The existing main guides and bundled `ZygorGuidesBuilds.lua` are included. The new `Parchment.lua` load is present.

New checks cover real parsed row preservation; explicit context semantics; short, mixed, action-only and reading states; repeated completion refreshes; long wrapped labels; more than 20 rows; access to the last overflow row; independent wheel offsets; collapse and split extremes through the actual drag handlers; scale preferences; simulated profile/viewer reconstruction; completion symbols; item atlas metadata; secure-holder viewport exclusion; and reuse of the actual native waypoint/manual-completion/confirm/branch dispatcher.

The frame double approximates wrapping and frame behavior. Its profile reconstruction is a simulation, **not a live `/reload` test**. It checks that no secure attribute application is attempted in simulated combat; it does not emulate WoW's taint or protected execution system. Automated tests show the logical content remains reachable. They cannot confirm real client rendering or input clipping.

## Required client checkpoint

**No WoW client was run. No in-game validation or screenshot is claimed.** Before relying on the prototype, test the following in 3.3.5a:

- Short and action-only steps: all objectives, route hints, names and item buttons remain visible or scrollable. Choose a long quest/NPC/item name and check wrapping and readable contrast. Complete and manually uncomplete a row; check that the check/text treatment changes without collapsing it.
- Mixed steps: enable the explicit reading preference on the real Zul'Drak sample, scroll both panes independently to their last row, and verify wheel input over labels, item controls and scrollbars never advances a step. Normal refreshes must retain scroll offsets; a genuinely different step must reset them.
- Story-only: use the real Levels (50-55) plain-text sample with reading enabled. Check fixed title and Continue. When testing campaign content, also exercise native confirm/next branches and multiple choices.
- Divider: drag to both limits at minimum size with Tools open; check both panes retain their minima and no content is inaccessible. Collapse, visit an action-only step, then return to mixed content; restore Context and check its saved split and explicit collapse preference.
- Move, lock and resize: confirm the footprint/anchor stay fixed across steps and completion refreshes. Lock must prevent frame/divider movement without disabling scrolling. Change addon scale and the client's UI scale; test minimum and larger sizes and screen-edge clamping.
- Persistence: move, resize, adjust split, collapse, change reading preference and lock; `/reload`, then log out/in. Confirm each setting and the active guide/step restore. Repeated progress refreshes must not move this window or other UI elements.
- Item/spell/pet controls: test actual use/target/cooldown behavior; scroll controls partly outside a pane and verify no secure click target remains over another region. Enter combat while a button is visible, then scroll/move the viewer. The prototype's secure overlays are deliberately hidden by a combat visibility driver and return after combat; their item/spell actions are unavailable from this panel during lockdown. This is a declared prototype limitation. Check for Lua errors or taint and stale targets on leaving combat, hiding/showing, changing scale, switching modes and reloading.
- Guide selection, inline step browsing, previous/next, right-click fast navigation, automatic progression, waypoint clicks, manual completion and close/reopen still work. Test `/zgparchment off` and `on` rollback.

Return a screenshot of a representative mixed step at your normal UI scale, along with any Lua error or inaccessible row. That is the next design checkpoint; decorative refinement is deferred.

## GitHub Actions download

Push `prototype/vertical-parchment` to run **Parchment prototype package** automatically. It uses Python 3.12, installs the test-only `lupa==2.6`, runs all Lua regression scripts, builds the full addon ZIP and verifies its contents against the checkout. The job uses read-only repository permissions. Manual `workflow_dispatch` is also configured.

Open the successful run under **Actions**, then download its **Zygor-parchment-<commit>** artifact (GitHub sign-in may be required). Extract the artifact first; the installable addon ZIP, source patch, installation/client-test notes, build metadata, license, automated check results and checksums are inside. Artifacts are retained for 14 days. Downloading a build does not merge the prototype or publish a release.

Local packaging: `python tools/release/package_addon.py --output-dir dist`.

## First client error report: startup compatibility fix

The supplied 17-record client log starts with a missing `SetShown` method in `Parchment.lua` during `OnInitialize`. That aborts initialization before `self.reputations` is created; the next three addon errors reference that missing table. The remaining 13 records are recursive Blizzard error-window failures (`cursorOffset` and C stack overflow). The prototype now uses native `Show`/`Hide` for all eight visibility toggles. It does not patch the reputation system or the Blizzard error handler to conceal downstream symptoms.

The frame double now omits `SetShown`. Running it against the previous code reproduced the exact reported line-476 error; the corrected viewer passes that same regression and the full suite. This fix still requires a fresh client login or `/reload` and an in-game retest.

## Repeatable fixture checkpoint

The visual brief remains in force. Use `/zgfixture baseline` for a normalized content/layout starting point and `/zgfixture 1` through `11` to inspect short, long mixed, action-only, reading-only, completion, long names, 32-row overflow, legacy fallback and inline controls. Fixtures are clearly labeled synthetic UI test copy and never selected automatically. The token action is harmless; the real inventory item case is optional and separate. Details and screenshot protocol are in `docs/PARCHMENT_FIXTURES.md`. Actions and Context take priority over utility chrome: Tools has one row, the reading preference lives in Settings, and the compact Context disclosure sits beside a thin draggable rule.

## Compact native-UI pass after fixture screenshots

The full-screen F01/F02/F04 captures exposed excessive minimum height, a broad flat border, boxed controls and mismatched typography. The allowed minimum is now 320 x 380 logical units; `/zgparchment compact` and the fixture baseline use 340 x 400. The renderer accounts for the fixed title inside its action/reading allocation rather than stacking excess title space above it. The 160-unit Action and 144-unit expanded Context minima remain protected with Tools open and the split at either limit. The outer size still does not change automatically between steps.

This pass reuses the tooltip frame edge already shipped throughout the addon, native client font selection, slim scrollbar tracks and text controls with a hover cue. The 16-point primary body is unchanged. Route/NPC direction tips now use a separate, fixed 14-point secondary font and are included fully in row-height and scroll calculations. Existing client/addon scale and persisted window sizes are not migrated automatically. No new material artwork or campaign content is added.

The full fixture guide is rendered through the frame harness at 320 x 380 with Tools open, 340 x 400 with Tools closed, and 410 x 600 with Tools open. Tests check actual region bounds/minima, the final reachable row and direction-tip bounds. Appearance and real input still need the next in-game comparison.

## Objective and material pass

The next F01/F07 client captures showed a blank objective gutter and weak scroll affordances. Pending objectives now use the existing addon's sixteen-cell objective atlas and native action mapping; completed objectives use its check symbol. Plain directions and Context paragraphs have no symbol. Secure item/spell/script icons take priority over the pending marker. The objective gutter is narrower, with enough space retained for the 22-unit interactive icon. Regression checks cover pending/completed/reopened transitions, plain directions and item-icon priority.

The opaque paper base now carries a subtle crop of `Interface\\QuestFrame\\UI-QuestGreeting-TopLeft`. That asset and its paper inset were checked against the [Wrath quest frame templates](https://github.com/wowgaming/3.3.5-interface-files/blob/main/QuestFrameTemplates.xml). The title uses the client's `QuestTitleFont` at a fixed 18 points when available, otherwise the existing 16-point fallback. Six-unit inset scroll tracks and solid thumbs replace the tiny knob; the existing draggable rule has a small grip, hidden when Context is collapsed. No artwork files or package dependencies were added.

Position, size, scale and split are retained. Short steps can leave blank reserved action space: this pass preserves the protected minima and stable saved division rather than changing the split on progression. The user's captures establish that the F07 ending can be reached; they do not establish every interaction or scale case. Native texture appearance, font metrics and mouse input still require an in-game check of this build.

## Consolidated C build and reading controls

The user chose the richer C direction after a three-way comparison. This build interprets it using existing assets: `UI-DialogBox-Gold-Border` for the rim (verified in the [Wrath loot-frame source](https://github.com/wowgaming/3.3.5-interface-files/blob/main/LootFrame.lua)), the addon's `Skin/popup_border` for inset header controls, and low-opacity quest paper over the opaque base. It does not ship generated mockup art or reproduce the mockup's exact corner plates. Essential titles now use readable locale-aware client type rather than the ornate quest-title font. Completed objective and hint text use grey-olive ink plus the existing check; icons/cooldowns retain full strength. Context remains normal ink independently of objective completion. Native progress counts remain in the text; blocked/obsolete objective markers are desaturated.

Mixed steps expose a compact Read control beside the existing Context rule. The reading session temporarily uses the body for Context and provides a fixed Back to actions control. It preserves the saved window, split and collapse preference, and never changes `pause` or the author's completion/branch rules. The native automatic completion entry point waits during the session; manual previous/next remains available. Leaving the session releases that hold, so a completed step may then advance normally. Selecting a different step exits the session. No timed narrative behavior or prose classification was introduced.

Context size is saved in `profile.parchment.contextsize`, with explicit 16/18/20/22 choices. A-/A+ in story/expanded reading and Tools > Settings > Context text size use the same setting. Reflow follows the current paragraph and relative position where the available scroll range permits. A reading preview left untouched restores its entry position when returning; deliberate scrolling retains the new position. Font changes and different viewport sizes can clamp offsets to their valid range. Ordinary same-layout progress refreshes preserve the exact scroll offset. Story-only Continue and the font controls stay outside the reading viewport.

Automation now exercises all eleven fixtures at all four Context sizes at the minimum, baseline and larger geometries. It checks final-line access, protected normal allocations, fixed footer bounds, paragraph anchoring, completion/reopening styles, reading-mode entry/exit, new-step exit, saved collapsed/split/font preferences, independent wheels and hidden-action secure overlays. The real native progression entry point is checked for reading hold/release; existing tests retain normal objective/confirm interactions and parse 16,012 real steps. These frame doubles do not establish real client rendering, secure execution or live SavedVariables reload behavior.

Client checkpoint: F01/F02/F05 assess normal size, hints, texture and completed ink; F02 Read > A+ > scroll > Back checks reading and restored division; F04/F08 check fixed Continue and reading through the final line; F07 checks independent overflow. Repeat with Context collapsed, Tools open, both split extremes and changed UI/addon scale. F10 checks item/script target disappearance in reading mode and return/combat behavior. Reload after selecting 20 or 22 and confirm font, position, split, lock and collapse persist. Return to a real campaign section to judge visual integration and reading comfort. This build has not been run in-game by the implementer.

## Compact Actions and inline reading pass

The user's original-Zygor and Druid Calling comparisons showed two problems: four short fixture objectives already required scrolling, and relocating an introduction below its tasks weakened the authored flow. This pass defaults objectives to 13 with derived 11-point hints, uses tighter objective gaps/minima while retaining full item-button bounds, and leaves more generous paragraph spacing for neutral inline prose and Context. A saved independent objective-size control supplements the existing reading control. Changing either size retains a content anchor; changing reading size also reflows inline prose. Reflow at scroll zero now stays at zero. Content sizes remain explicit, even when overflow results.

Authored step titles remain fixed at 16; untitled steps no longer spend a line on a generated Actions/Reading heading. The step browser retains its own heading. A thin paper edge, lighter opaque face and quieter grain sit inside the existing metal frame without moving the outer window or reducing text width. The 160/144 normal split minima remain protected. There is no new role inference, guide syntax, narrative timing, lore-library integration or campaign rewrite. The neutral plain-text fallback keeps its original position; the placement preference remains an explicit override.

`profile.parchment.objectivesize` defaults to 13 and accepts 12–16. `contextsize` retains compatibility, now accepts 14–22 in steps of two, and controls all reading prose. Existing saved reading sizes, window dimensions, anchor, split and collapse remain unchanged. `/zgfixture baseline` explicitly selects 13/14; it is the normalized comparison preset, not a migration applied on load.

The frame harness now checks all eleven fixtures at minimum/baseline/larger geometry, five reading sizes and objective sizes 12, 13 and 16. F05 must fit its four short objectives at the compact sizes; F07 must still expose the last row without reducing the chosen font. It also parses the actual Alliance Howling Fjord guide and renders step 178 with shipped English goal formatters: talk to Silvermoon Harry, turn in Scoodles, accept four quests, including the full final quest name. This real sample fits without scrolling at baseline in the model. Its quest visibility is held passive and live name-cache translation is skipped; this checks presentation, not server quest progression.

An optional local-only run sets `ZYGOR_CAMPAIGN_SAMPLE=/path/to/DruidCalling.lua` before running `tools/ui/run_checks.py`. It reads the supplied WIP, parses step 3, formats the actual prose/talk/accept rows, checks baseline access and both placement modes, and never copies the source into the repository/package. This local check passed. Standard CI uses the public Howling Fjord sample and synthetic fixtures only. No new in-game validation is claimed.

For the next client comparison, run `/zgfixture baseline`, then F05 for routine density and F02/F08 for reading. Return to Druid Calling step 3 through Guides > Recent; leave Move untagged notes to Context off to retain its introduction above the actions. A screenshot at the same UI scale will establish whether 13/14 feels right. Check the new Objective/Reading size settings, final-line access at their largest values, collapse/Read/Back, item actions and reload persistence. The source sample is [Alliance Howling Fjord step 178](../ZygorGuidesViewerRM/Guides/Retail/Leveling/ZygorLevelingAllianceWOTLK.lua#L1560).
