# Vertical parchment playable prototype

Implemented on branch `prototype/vertical-parchment`, based on addon **3.0.255**, revision 255, commit `d2aae8d0f1f3782d964e4179907b215aab484787` (27 October 2026). This is a prototype build of that revision; it does not claim to be a new upstream release.

## Install and rollback

1. Exit WoW. Back up `Interface/AddOns/ZygorGuidesViewerRM` and `WTF/Account/<account>/SavedVariables/ZygorGuidesViewerRM.lua` (including its `.bak` if present). The TOC's variable is `ZygorGuidesViewerSettings`; the saved file follows the addon folder name.
2. Replace the addon folder with `ZygorGuidesViewerRM` from the test ZIP. Confirm `Interface/AddOns/ZygorGuidesViewerRM/ZygorGuidesViewerRM.toc` exists directly at that path. The ZIP contains the complete addon, including its bundled Talent Advisor, unchanged guide content and existing assets.
3. Relaunch the **3.3.5a / build 12340** client. The prototype is enabled by default for the **Remaster skin, Guide display mode**. Existing profiles using another skin/display mode retain that viewer. Select Remaster in settings and Guide mode to test this panel. `/zgparchment on` enables the prototype preference and reloads the UI; it does not change your selected skin.
4. Drag the header to move. Tools exposes Guides, Steps, Lock/Unlock, Settings and the plain-text reading preference. The lower-right grip resizes the window. Lock prevents movement, resize and divider dragging; scrolling and objective clicks remain available.
5. The divider's open area to the right of the Context button is draggable. Context +/- explicitly collapses/restores the reading pane. A step without context gives the space to Actions. A story-only step uses one reading pane, with a fixed Continue button and fixed header navigation.

Quick rollback: `/zgparchment off` immediately reloads into the native viewer. `/zgparchment on` reloads back. `/zgparchment reset` resets only this prototype's position, size, split and reading preferences. Full rollback: exit WoW and restore the backed-up addon folder; restore the saved file too if you want the exact earlier settings. Upstream ignores the extra prototype profile fields.

Source rollback: return to `d2aae8d0f1f3782d964e4179907b215aab484787` on a separate branch, or reverse the supplied patch in a clean checkout. No upstream branch was changed or published.

## What changed

- A fixed-footprint parchment viewer, initially 380 x 520 logical units, minimum 340 x 440, with opaque parchment, dark ink, muted brass edges and a dark green header. It reuses the addon's locale-aware bundled/client font selection at 16 for body text and 18 for headings. No automatic text shrinking.
- Fixed chapter/step titles abbreviate only when needed, with full text on hover; body text always wraps. A fixed header with chapter tooltip, previous/next (including existing right-click fast navigation), step position, Tools and Close. Tools expands inside the existing footprint. Its Steps control opens an inline scrollable step browser.
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

For testing untagged guides, **Tools > Plain text in Context: on** is an explicit, persisted reading preference. It moves eligible plain/info rows into Context. Because some of these are directions, turn it off to return them to Actions. This preference provides a reversible plain-view fallback without silently inferring semantics from prose, length or keywords.

**Missing campaign input:** no file or registered guide identified as the **WoW Solo Adventure campaign** was found in the supplied checkout. Its exact `.lua` guide file(s), or the exported guide text from SavedVariables if it is installed as a custom guide, are needed for campaign-specific validation. The addon source itself is present and was modified; the examples below are actual shipped leveling steps, not invented campaign writing.

## Source inspection and real content calibration

Inspected the main viewer's frame creation and compact layout, `ZygorGuidesViewerFrame.lua/.xml`, skin definitions and locale font helper, `Parser.lua`, `Goal.lua`, `Step.lua`, the progression/translation lifecycle, native wheel/step handling, secure overlay/action specifications, and defaults/profile settings in `Options.lua`. There are no `AGENTS.md` files in this checkout. The base revision had no repository CI workflow or dedicated packaging script. The prototype now includes `tools/release/package_addon.py` and `.github/workflows/parchment-prototype.yml`; they follow the README's folder-in-a-ZIP installation layout.

`test_parchment_guides.lua` parsed **16,012 steps** across the shipped legacy Alliance/Horde leveling files and imported Alliance/Horde WOTLK leveling files, with **zero parse failures**. It preserves all parsed rows under the default partition. These counts do not evaluate player-specific visibility or quest progress.

| Representative real step | Parsed rows | Completion objectives | Text bytes* |
| --- | ---: | ---: | ---: |
| Legacy Alliance Human (1-13), step 1 | 3 | 1 | 28 |
| Imported Alliance Zul'Drak (75-77), step 104 | 17 | 1 | 1,222 |
| Imported Horde Howling Fjord (69-71), step 200 | 17 | 14 | 89 |
| Legacy Alliance Human (1-13), step 36, item-use row | 1 | 1 | 27 |
| Legacy Alliance Levels (50-55), step 105, plain reading | 7 | 0 | 293 |

*Byte counts sum available parsed text/info/quest/target/NPC/parameter strings plus tooltips, before localization and generated `GetText` labels. They are content-length observations, not rendered glyph counts. The dense sample has short labels; it does not represent a long story. These observations do not establish typical lengths for the missing campaign.

## Automated validation

Run with Lua 5.1 directly, or install the test-only Python `lupa` dependency and run:

```sh
python tools/ui/run_checks.py
```

The runner uses `lupa.lua51`, creates a fresh runtime per script, parses all 36 top-level addon Lua files, and runs all 24 Lua test scripts (21 existing and 3 prototype regressions). `git diff --check` and XML well-formedness checks are also run. The ZIP is checked for its TOC and loaded files, and for accidental scratch/test files. The recursive TOC/XML audit follows 409 load paths and reports 49 absent paths already referenced by the base revision: optional author slots `Guides/Guide02.lua` through `Guide40.lua`, and `ZygorTalentAdvisor/Builds/build01.lua` through `build10.lua`. These files were not supplied in the repository; no placeholder content was invented. The existing main guides and bundled `ZygorGuidesBuilds.lua` are included. The new `Parchment.lua` load is present.

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
