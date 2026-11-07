# One-flow guide: focused client checkpoint

This build changes the viewer, not your campaign writing or route. Your uploaded
Shadowglen source is not included. The new fixture uses public quest-derived prose
from the reviewed samples; it is a simulation, not a playable quest route.

## Try this first

Install the complete addon ZIP with the normal backup/rollback procedure in
INSTALL-AND-TEST.md. Use the Remaster skin and Guide display mode.

1. Enter `/zgadventure`. Read the introduction, then click the action's map icon
   to simulate finding Iverron. With normal automatic progression enabled, the
   native guide engine advances; otherwise use its normal next control. Continue
   through the rescue excerpts. No character movement, quests, items or timer
   are involved.
2. In the Ban'ethil introduction, click **Read: Why do the druids sleep?**.
   Leave it open and click the main action's icon. The live guide moves to Oben's
   request while the background stays on the passage you opened. Scroll and close
   the reader; current actions remain available. The final scene stays pending.
3. Open **Tools > Settings**. Adjust the normal primary and secondary font sliders,
   then **Reading text size**. Primary controls objective text; secondary controls
   attached directions; reading controls story paragraphs and optional background.
   Try the same settings on a short portion of your actual campaign, selected
   through Guides > Recent. That is the navigation/real-interaction check.

One review question: **Can you read the story comfortably, find the next action
immediately, and keep playing without friction, including with background open?**
Report the first scene that feels awkward, plus a screenshot if useful. There is
no need to replay the complete technical fixture list for this checkpoint.

## What changed

- Single authored flow is now the default. Ordinary and explicit `|context` rows
  remain visible in source order; essential story cannot be hidden by saved
  Context collapse or the old broad placement preference.
- A small independent reader opens only for an explicitly associated background.
  It does not stop automatic progression. Its content/scroll stays on the selected
  passage as the guide advances, and reopening the same passage retains position
  within the session. It is movable, screen-clamped, and closes with the guide.
- **Tools > Settings** opens normal settings. Existing primary font choices and
  secondary choices are authoritative, with ranges 7–24 and 5–22. A dedicated
  reading-size control offers 12–24 in increments of one, in both settings views.
- Explicitly saved native font values and reading sizes remain intact. When native
  values are absent, the former prototype objective value supplies the initial
  primary/derived secondary value. The old objective preference is retained as
  `legacyobjectivesize` for reference, not a competing control. AceDB-supplied
  native values are respected too; use the sliders if the initial size differs
  from your previous prototype appearance. Position, size, lock and scale persist.
- The old layout is retained for comparison with `/zgparchment split`.
  `/zgparchment flow` restores the new flow. `/zgfixture baseline` deliberately
  selects the old split and its 13/11/14 preset, preserving position/scale.
- Existing legacy confirmations and native item/click/completion behavior remain.
  Their secure inline actions retain the existing combat-lockdown limitations.

## Boundaries and evidence

No Recent story/history, reader integration with Azeroth Library, parser redesign,
new campaign syntax, broad skin redesign, or real timed-quest simulation is added.
The six excerpts omit intervening errands deliberately; they demonstrate layout
and transitions, not event coverage for every quest. `/zgadventure 1` through `6`
select a scene; `/zgadventure reset` clears only its volatile simulated flags.
Those flags and reader state reset on reload; real campaign progress is untouched.

Optional background is attached by the test fixture's explicit provider. It is
not inferred from plain text or `|context`, and the fixture is never selected as
a race/class default. Guide selection alone does not open the reader.

All 27 Lua 5.1 regression scripts pass, including real parser/completion checks,
normal option callbacks, row order, reader independence, font migration, and
approximate minimum/baseline geometry for the product excerpts. Packaging verifies
the complete ZIP against source. Native rendering, secure input, navigation,
reader overlap at your resolution, and in-game progression remain untested by
the implementation agent.

Rollback: `/zgparchment off` reloads to the native viewer. Back up the previous
addon folder and SavedVariables for complete rollback.

## Visual comparison before another viewer revision

`/zgadventure 6` is the representative layout fixture: short essential story,
three objectives (one completed), two attached directions, and background. It
uses fixed simulated statuses and stays open for comparison. Existing scene
indices are unchanged.

Open guide-comparison.html from the downloaded artifact for two browser mockups
of the same fixture at 340 x 400, with matching reader treatments. The PNG is a
static overview. No installation is needed to compare them. The reader toggle,
resizing, and manual-next closure in that HTML are proposed interactions, not
changes to the live addon yet. Guide-change closure and automatic-step behavior
will be settled in the combined viewer revision.
