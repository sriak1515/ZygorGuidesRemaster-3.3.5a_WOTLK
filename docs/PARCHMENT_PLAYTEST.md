# One-flow guide: focused client checkpoint

This build applies the selected A+ parchment design and reader controls. It changes the viewer, not your campaign writing or route. Your uploaded
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
   Click Read again to close it, then reopen it. Drag its lower-right grip to resize.
   Leave it open and click the main action's icon: automatic progression moves to
   Oben's request while the reader stays on your passage. Manual Next/Previous or
   choosing a different guide closes it. The final scene stays pending.
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
- A+ now uses bundled paper grain and warm edge shading, inset page depth, a
  title ornament, and the addon's existing gold edge. The guide and reader share
  this treatment. Their native fonts and main window footprint are preserved.
- A small independent reader opens only for an explicitly associated background.
  It does not stop automatic progression. Its content/scroll stays on the selected
  passage as the guide advances, and reopening the same passage retains position
  within the session. It is movable, screen-clamped, and resizable (minimum 320 x 300).
  Read toggles the same passage. Manual Next/Previous, step selection, guide
  changes, leaving parchment mode, and hiding the guide close it. Automatic
  progression within the same guide leaves it open. Reader size and position
  persist across reload; the reading window itself starts closed. Lock prevents
  dragging and resizing. Short objective lists place the Read entry immediately
  below their content; overflow keeps it in a reachable footer.
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
Those flags and the open passage reset on reload; reader geometry persists. Real campaign progress is untouched.

Optional background is attached by the test fixture's explicit provider. It is
not inferred from plain text or `|context`, and the fixture is never selected as
a race/class default. Guide selection alone does not open the reader.

All 28 Lua 5.1 regression scripts pass, including real parser/completion checks,
normal option callbacks, row order, reader independence, font migration, and
approximate minimum/baseline geometry for the product excerpts. Packaging verifies
the complete ZIP against source. Native rendering, secure input, navigation,
native texture appearance, reader overlap at your resolution, and in-game progression remain untested by
the implementation agent.

Rollback: `/zgparchment off` reloads to the native viewer. Back up the previous
addon folder and SavedVariables for complete rollback.

## The representative page

`/zgadventure 6` combines short essential story, three objectives (one completed),
two attached directions, and optional background. It stays open for inspection;
existing scene indices are unchanged. Check the A+ material and title rule here,
then open and resize the reader and confirm the normal font controls still work.

The HTML/PNG comparisons in the artifact record the design exploration. A+ was
selected; the field-journal alternative was not. Those browser mockups are not
screenshots of this native implementation. The paper and title-rule assets used
by this build are reproducible with tools/ui/build_parchment_assets.cjs and are
bundled as uncompressed, power-of-two TGA files for the 3.3.5a client.
