- Read `DECISIONS.md`, `METHOD.md` and `STATUS.md` first. `docs/archive/` is history, not authority.
- Before any change: survey and estimate its size. Stop for approval
Change size:
- If the prompt gives a size budget, that budget is the approval. Proceed without asking up to about 1.5x the budget; stop and ask only beyond that.
- Count only non-test code. Tests, docs, fixtures and generated files don't count toward the budget.
- If the prompt gives no budget, ask before going beyond ~200 changed lines of non-test code.
- Unchanged: always stop and ask before schema changes, server config changes, DB writes outside the stated scope, or changes to another repo.
- Spoiler rule: in anything shown to the owner, unplayed content appears as IDs and counts only.

- Our code lives in its own files (e.g. Narration.lua) with a minimal hook into Zygor's files; don't spread changes through original code.
- Target: WoW 3.3.5a client, Lua 5.1 and its API only.

These documents are in the campaign repository, `~/wow-solo-adventure`.
