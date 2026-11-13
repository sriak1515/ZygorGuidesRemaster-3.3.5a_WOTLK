# Adventure live rendering fix and compact controls — 2026-11-13

Experimental follow-up on `codex/adventure-gameplay-usability`, based on
`798e889ee582e7fbd679d9add30632b91d25425e`. BUILD.txt in the test ZIP identifies
the precise new source commit. No guide, campaign, story trigger or server edits.

## Client finding and correction

The player reported `/zgpoc live` briefly working, then repeatedly displaying
only the panel background, step title, bearing, step count and resize hint,
including after restart. Fixtures displayed correctly. A read-only client query
returned these values (shown, visible, alpha, level, strata):

```text
panel       1 1 1 151 MEDIUM
header      1 1 1 128 MEDIUM
objectives  1 1 1 128 MEDIUM
grip        1 1 1 128 MEDIUM
```

This is direct client evidence of an ordering fault: the child controls are
shown but behind their opaque parent. The old code assigned the panel the live
engine frame's level plus 10, implying a host level of 141 in this instance.
The fixture uses a separate low-level host, explaining why it did not expose
the same condition. The precise mechanism that originally elevated the native
host was not established; no claim is made about a universal Wrath frame limit.

The adventure drawing root is now a UIParent child at a low level, anchored to
all four edges of the original engine host. It no longer inherits that host's
high draw levels. Movement, resizing, saved geometry, pause and advancement
still belong to the existing host/engine. The invisible native host temporarily
stops accepting mouse input so its higher level cannot intercept the new controls;
its prior mouse setting is restored on fallback. Explicit scale and native show/hide
synchronization preserve the behavior previously inherited through parenting.
Inline secure overlays use the adventure drawing root's hierarchy; the original
Parchment secure-overlay level preference is retained. Pointer and Waypoints
code remain unchanged. No SavedVariables reset, progress migration or forced
resume is required. A pre-existing **Paused** state remains the engine's state.

A regression model assigns the reported high parent/child levels. It failed
against the previous implementation with `header behind opaque panel`, then
passed after the drawing root was separated. The test also raises the engine
host further and checks that the display ordering stays unchanged. The earlier
frame double returned a constant level and discarded SetFrameLevel, so it could
not have detected this failure; it now records levels and models the observed
child-level behavior. This models the report, not every aspect of Wrath rendering.

## Requested UI refinement

- The two panels have a four-unit gutter instead of twelve.
- Previous/Next, step position, pause status, Tools and a guide-close control sit
  in the top bar; the progress strip sits directly below it.
- Tools folds out one row with Guides, Settings, Existing UI and Lock/Unlock.
  Normal play has no permanent utilities/footer row or resize instruction.
  The corner grip has a tooltip. Objective scrolling uses the reclaimed space.
- Empty/duplicate navigation captions no longer reserve a second heading line.
- Story reuses Parchment's existing material, inset edge, title rule and button
  treatment. Short passages fit their text; long passages scroll within the
  guide's height. Typography remains governed by existing font preferences.
- A small X folds story. A book tab appears on the story-facing edge whenever
  retained story is folded, disappears while that panel is shown, and returns
  after closing. A small exclamation cue indicates new/interrupted story. It
  remains available for rereading after first presentation.
- Combat still tucks story without forcing it open afterward. Folding/recall
  preserves the current passage and scroll. Neither changes native progress.

## Verification and what to observe

`python3 tools/presentation/run_checks.py` passes: top-level Lua 5.1 parsing,
XML/TOC order and all 30 regression scripts. `git diff --check` passes. Output is
recorded in `ADVENTURE_LIVE_FIX_CHECKS_2026-11-13.txt`.

Expanded simulation coverage includes the reported draw-level mismatch, further
native-host promotion, scale synchronization, execution of native frame show/hide
callbacks, secure overlay ordering/cleanup, Tools folding and Lock, top-bar
navigation delegation, reduced objective padding, narrow story gap, shared paper
material, short-story sizing, story X/tab recall, and the existing navigation,
advancement, quest-state story, fallback, combat and persistence checks.

**The diagnosis uses the player's real client output. The new fix and visual
changes have only been verified in simulations, not in WoW.** Native layout,
click/taint behavior and actual quest-event story delivery remain client checks.

After installing, use `/zgpoc live` on the current guide. Header, controls and
native objective rows should all appear. Observe them after clicking/dragging the
guide, hiding/showing it with Zygor's normal toggle, switching guides and a normal
restart. If needed, repeat the prior read-only level query: the header/objective
controls should be above the panel, and native host elevation should not affect
that ordering. No quest replay or progress reset is needed.

During ordinary play, also observe arrow continuity across objectives, item/spell
clicks, Tools access, font/scale changes, story X/book-tab recall and combat
recovery. A real future quest event is still separate evidence from fixture or
historical story recall.

## Installing this increment

The test ZIP is a **viewer-only update for the installed 798e889 experimental
build**. With WoW closed, extract its `ZygorGuidesViewerRM` directory **over the
existing addon directory**, replacing the included files. Keep all other files.
It contains the three changed runtime Lua files plus BUILD.txt; it does not
contain or replace guides, assets, TOC, campaign data or SavedVariables.

Keep the previous working addon copy. Do not delete the addon directory or the
`WTF` files. This avoids replacing locally installed campaign guide content.
Restart, then `/zgpoc live` or enable the existing Experimental adventure guide
setting. Existing geometry/fonts are retained; activation remains session-only.
`/zgpoc off` or Tools → Existing UI restores the configured original viewer;
a combat fallback remains deferred until combat ends.
