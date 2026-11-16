# Narration reader checks

Offline regression for `ZygorGuidesViewerRM/Narration.lua`:

```sh
lua5.1 tools/narration/test_narration.lua \
  ZygorGuidesViewerRM tools/narration/fixtures/kal01-balance
```

The test loads the real `Goal.lua`, `Step.lua`, `Parser.lua`, and
`Narration.lua`, then executes compiler-generated `Metadata.lua` and `Guide.lua`.
It also extracts and runs the actual `TryToCompleteStep` from
`ZygorGuidesViewer.lua` to confirm the normal viewer completion pass records the
narration anchor.

Coverage: metadata acceptance/rejection/missing consumer, anchor association,
tri-state reveal conditions including class/race API returns, rapid advancement,
combat deferral, once-only delivery and history reopening, reload recovery,
corrupt-state repair, failed-reader recovery, long-passage scrolling with a
Frame scroll child, hook-fault isolation, guide switching, character separation,
and native registration when narration is unavailable.

These are Lua 5.1/Lua-harness checks only. They do not establish real 3.3.5a
frame rendering, addon load order, or client behavior.

## Vellum visual test

Install the addon from this PR branch. No campaign package is needed for the
fixture: `/wsaframe 40`, `/wsaframe 100`, `/wsaframe 150`, or `/wsaframe long`
(600 words) opens the existing reader with neutral placeholder text. Earlier and
Later are disabled for the fixture; real narration keeps its existing navigation.
The command does not register a guide or change narration delivery state.

The title uses the client's Morpheus display font (22), and the body uses its
standard Friz Quadrata serif (16) with line spacing 3, without outlines or text
shadows. Alegreya is deferred until the owner judges the client fonts. The reader
stores position and size per character in the existing addon SavedVariables. Drag the frame to move;
drag the bottom-right `/` grip to resize. The initial size is 520 × 340 UI units,
with limits of 360 × 240 through 1000 × 900.

In-game checks (offline checks cannot establish rendering or DragonUI compatibility):

1. At 3440×1440 and your usual UI scale, judge title/body sharpness and reading comfort for 40, 100 and 150 words.
2. Repeat in a dark zone and a bright zone; the vellum should be opaque once the fade finishes.
3. Check the straight border, subtle inner shade and light shadow, with no decorative edges.
4. With DragonUI visible, check contrast, overlap, close/navigation buttons and the resize grip.
5. Close and reopen: the fade should take about 0.3 seconds and finish fully opaque.
6. Run `/wsaframe long`; scroll to the end, resize narrower/wider, and check wrapping and button placement.
7. Move and resize, close/reopen, then `/reload`; position and size should persist.

The regression harness also checks exact fixture word counts, isolation from
narration delivery state, disabled fixture navigation, restored real navigation,
resize reflow, geometry across module reload and characters, corrupt geometry
fallback, and fade completion/cleanup. It does not simulate the client's font
rasterizer, physical pixels, disk SavedVariables writes, or other addons.
