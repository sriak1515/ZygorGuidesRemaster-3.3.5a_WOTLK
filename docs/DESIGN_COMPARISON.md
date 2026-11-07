# Guide hierarchy and appearance comparison

Review material, 7 November 2026. No new live skin or reader behavior in this pass.

## Bolder alternative: a field journal

After liking A+, the owner requested one more adventurous comparison. See
[journal-comparison.html](design/journal-comparison.html) and its
[static overview](design/journal-comparison.png): A+ alongside C, a stitched
leather-bound field journal with a chapter ribbon and a loose-sheet reader.
A+ remains the current favoured reference; C is an alternative for review.

Both use the identical fixture and text sizes at 340 x 400. The binding consumes
some reading width, so C wraps the introduction onto an additional line. The
representative guide still fits without scrolling. Paper, leather, stitching,
and ribbon are illustrative browser materials; existing addon icons are reused.
The ribbon is decoration, not a new feature or chapter-navigation commitment.
Native client materials and behavior remain unimplemented by these previews.
Browser checks passed for sizes, guide fit, toggle, resize and manual-next closure.

## Current comparison: A and developed A

The owner found A more stylish and B too plain to communicate parchment. The
current comparison is [parchment-refinement.html](design/parchment-refinement.html)
and its [static overview](design/parchment-refinement.png). Both use the same
340 x 400 footprint and identical fixture text/text sizes. A remains the baseline;
A+ adds visible paper grain, warmer shaded edges, inset sheet depth, a restrained
title ornament, matching reader treatment, and objective icons.

The gold corner pieces and objective markers come from the addon's existing
Skin/popup_border.tga and Skin/icons.tga. The toolbar also references the existing
Skin/remaster/leavesofsteel_top.tga. Browser previews embed converted PNG data;
source assets are unchanged. No DragonUI assets were used.

Paper grain is an illustrative SVG material built for the preview. A standalone
native parchment image is not bundled in this repository; the client quest-paper
texture already referenced by Parchment.lua needs an actual client comparison
before claiming an exact material match. This pass changes no live viewer code.

Browser checks confirm matching sizes, guide content fit, reader toggling,
resizing, and manual-next closure in the HTML demonstration. This is evidence
about the preview, not native client behavior.

## Earlier A/B comparison


Open [guide-comparison.html](design/guide-comparison.html) after downloading it,
or view [the static comparison](design/guide-comparison.png). Both files are also
included in the package artifact; no addon installation is needed to compare.

Both guide windows start at 340 x 400. They use the same content, primary objective
size 13, direction size 11, and story size 14. Browser fonts, line metrics and
CSS materials are approximations, not proof of native WoW rendering.

- **A: refined Warcraft frame.** Dark green toolbar, restrained metallic edge,
  matching reader, and a ruled separation before optional reading.
- **B: parchment page.** Paper-led toolbar, fine gold rules, quiet edge and page
  gutter, with a reader treated as a matching second page.

Shared hierarchy: small location breadcrumb, one readable scene title, essential
story, identifiable objectives, smaller directions attached to those objectives,
and optional reading immediately after relevant content. A completed row stays
readable but subdued, while pending actions are more prominent. Progress and resize
handles stay out of the content. Long reading scrolls rather than shrinking text.

The HTML demonstrates Read toggling the reader, reader resizing, and closure on
manual Next. It does not settle automatic-step closure or implement guide-change
behavior. It is not a replacement web app or a new guide format. Native textures,
icons, fonts, spacing and screen-edge placement must be adapted and checked after
the visual direction is chosen. No assets from DragonUI were copied.

The matching native content fixture is `/zgadventure 6`. Three objectives include
one fixed completed state and two pending states with directions. Optional depth
uses the same authored background as scene 4. It is test material based on the
public Ban'ethil quest sequence and previously inspected guide chest directions;
not a new playable route. The private uploaded Shadowglen source is untouched.

Review the composition, not the quest wording: which treatment better fits the
Warcraft companion, and are task/direction/reading roles clear at this footprint?
Then apply the chosen direction to guide and reader together, including the agreed
reader controls, and check a short scene plus overflow using the existing cases.
