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
tri-state reveal conditions, rapid advancement, combat deferral, once-only
delivery and history reopening, reload recovery, guide switching, character
separation, and native registration when narration is unavailable.

These are Lua 5.1/Lua-harness checks only. They do not establish real 3.3.5a
frame rendering, addon load order, or client behavior.