- Read `DECISIONS.md`, `METHOD.md` and `STATUS.md` first. `docs/archive/` is history, not authority.
- Before any change: survey and estimate its size. Stop for approval
  only if it adds a dependency, changes the schema or the
  compiler/UI contract, deletes or archives anything, or exceeds
  ~200 changed lines. Otherwise make the smallest change and report
  its size.
- Spoiler rule: in anything shown to the owner, unplayed content appears as IDs and counts only.

- Our code lives in its own files (e.g. Narration.lua) with a minimal hook into Zygor's files; don't spread changes through original code.
- Target: WoW 3.3.5a client, Lua 5.1 and its API only.

These documents are in the campaign repository, `~/wow-solo-adventure`.
