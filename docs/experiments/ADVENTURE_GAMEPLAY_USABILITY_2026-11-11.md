# Adventure gameplay usability experiment — 2026-11-11

Branch: `codex/adventure-gameplay-usability`.
Base: `f8b8a2a` on `experiments/adventure-vertical-slice-2026-11-11`, fetched before branching.
Experimental test build for WoW 3.3.5a, not a stable release. Package BUILD.txt
identifies its exact source commit. No campaign content or server changes.

## Use during ordinary gameplay

Show Zygor, then enable **Experimental adventure guide** in the existing addon
appearance settings, or use `/zgpoc live`. No fixture is required. Activation is
session-only; after reload, enable it again. Size, position and fonts persist.

- **Guides** opens Zygor's guide menu; right-click opens its guide manager.
- Objective rows use native clicks, tooltips, confirmations and action icons.
  Item/spell buttons follow the existing inline-action preferences. The native
  action bar and its bindings remain available according to existing settings.
- **< / >** use native Previous/Next; right-click uses native fast navigation.
  Counts, completion checks, step position, a progress strip and pause status
  remain visible. Automatic advancement continues through Zygor.
- Drag the title to move. Drag the bottom-right corner to resize. The existing
  window lock prevents both. Default is 300 × 360 logical units; minimum is
  280 × 280, with scrolling for all objectives. Maximum is 560 × 720, further
  bounded by scaled screen space. Controls stay outside the scroll area.
- **Settings** opens normal addon settings. Primary font controls guide text;
  secondary font controls hints; Reading text size controls story. Existing
  window scale applies to both panels. No separate configuration screen.
- **Story**, with a book icon, opens/folds the attached panel. **New story** is
  the discreet recall cue after a passage arrives while folded or combat tucks
  it away. No timer or movement dismissal. Combat exit does not force reading.
- **Existing UI**, `/zgpoc off`, or reload returns to the original configured
  viewer. A requested fallback during combat waits until combat ends.

The story normally opens left. It flips right if left cannot accommodate it,
adapts its width and follows the guide's height/scale. If neither side has 260
logical units free, it stays folded with **Story (make room)**: move the guide
near an edge or reduce window scale to reread. Folding never moves the guide.

## Reuse and ownership

Inspected repository product/presentation/recovery specifications, campaign
AGENTS/CURRENT_STATE/DECISIONS/WORKFLOW and requirements, and the latest vertical
UX direction/feedback. The user's current client observations supersede older
reports' pending-startup status. Historical play-position snapshots were not
used as live character state; no future campaign content was rewritten.

`PresentationUI.lua` now binds live objectives to the current native goals using
`Parchment:Fill`, including its row hierarchy, native click/hover handlers,
completion styling, action specs and cooldown display. Parchment's existing
secure-overlay lifecycle accepts a presentation owner; both viewers share the
same implementation. Only fully visible action holders get secure click targets.
The existing state driver hides inline overlays in combat; they rebind afterward.
The native action bar retains its own combat policy and snap behavior, using the
visible adventure panel as its snap frame. No new secure action implementation.

The native `Pointer.ArrowFrame` is parented to `UIParent`, separately movable,
and controlled by Pointer's existing update frame. It honors arrow visibility,
hide-with-guide, instance/corpse/travel behavior and the selected waypoint backend.
Live activation asks native `SetWaypoint()` to establish its current target.
Native FocusStep/TryToCompleteStep and goal-click paths continue to update it;
layout/font/story refreshes never create or retarget waypoints. No routing or
quest engine was added, and Pointer/Waypoints implementations were not changed.

The engine frame remains visible/opaque, preserving advancement and arrow guards.
Its original anchors, dimensions and resize limits are restored on fallback.
Native layout/skin/size/lock and border refresh entry points respect the active
adventure viewer. Explicit native refresh requests redraw even when the detached
snapshot is unchanged, covering font preferences and item availability.

Geometry lives in `db.profile.adventure`, separate from native/Parchment geometry;
position is normalized to screen dimensions. Existing primary/secondary/reading
font preferences remain authoritative. No guide progress or story record migration.
The fixture still uses isolated simulated rows/state and does not save geometry.
The existing per-character quest-state story observer and retained passage are
unchanged. No journal, campaign rewrite or broader story coverage was added.

## Verification and remaining client observations

`python3 tools/presentation/run_checks.py`: Lua 5.1 parsing, XML/TOC load order
and all **30 existing Lua regression scripts pass**. `git diff --check` passes.
Recorded output: `ADVENTURE_GAMEPLAY_CHECKS_2026-11-11.txt`.

Expanded tests execute the real presentation/Parchment code and native functions
with frame/quest API doubles. Coverage includes item/spell specs and secure
attributes, clipping, combat mutation guards, native confirms, guide-menu anchor
and manager access, guide replacement clearing stale targets, font changes with
unchanged snapshots, native action-bar refresh, drag/resize/lock/scale bounds,
saved settings/module reload, original geometry/secure-target cleanup, arrow
visibility guards, native automatic/manual advancement, and story/fault recovery.
Explicit viewport coordinates and approximate font metrics are simulations;
state-driver registration is not proof of actual secure execution.

**Client evidence from the player for the preceding build:** vertical panels
render, the fixture works and real steps advance automatically in WoW 3.3.5a.
**This revision has not been run in WoW.** Pixel fit, secure execution/taint,
real menu selection, arrow continuity and physical SavedVariables writes remain
client checks. The real quest-event story trigger remains unverified; simulated
quest-state tests are not a substitute.

Observe these naturally during a normal session, without replaying story:

1. Follow the existing arrow through several objectives, including a sub-goal
   update and automatic step change; drag/resize the guide while traveling.
2. Switch guides, use an available item/spell action and a native confirmation,
   and try Previous/Next. Observe action-bar/keybinding behavior if configured.
3. Tune fonts/scale, try the minimum size and screen edges, then reload and
   reactivate: geometry/fonts should return; original-interface fallback should
   preserve current progress and restore its own layout.
4. When eligible story is available, fold/recall it, resize/move the guide and
   enter combat. Observe the quiet recall cue and restored actions after combat.
   A genuine future story event is separate evidence from historical recall.

Install the test ZIP's `ZygorGuidesViewerRM` folder into `Interface/AddOns` with
WoW closed, retaining a copy of the previously working addon. Keep the existing
`WTF`/SavedVariables files; the package contains no character data or resets.
BUILD.txt records source lineage and checks; the adjacent SHA-256 identifies the
ZIP. Returning to the prior addon restores its presentation with native progress
left current.
