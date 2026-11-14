# Experimental compiled v1 consumer and client-test package

This increment closes the remaining pilot gates identified in the reader delivery
note. It enables the public `RegisterCampaignGuideMetadata` entry point, adds fresh
player predicates and independent checkpoint proof, and exposes admitted story in
the original interface. It does not broaden the compiler, migrate active chapters,
modify live gameplay/server state or perform the deferred visual redesign.

## Public consumer and scope

The metadata-first content addon can now stage its definitions through the real
consumer. Missing runtime components, unsupported versions/shapes, malformed data
and duplicate definitions reject registration. Actual native registration still
checks raw bytes, then deferred parsing validates labels, goals, contact IDs and
completion participation. Unsupported native step/goal controls or blocking guidance
remain inactive. A static diagnostic reports binding failure without future prose.
Status inspection reports `experimental-v1`.

Supported native shapes remain exactly the compiler pilot: one view, one native
part per source step, required nonsticky accept/kill/turn-in goals and passive
navigation/contact rows. No capability negotiation, arbitrary condition Lua, route
engine, cross-guide entry enforcement or unproven native expansion is added.
Other compiler actions still reject explicitly. Provenance target-viewer SHA is
not a compatibility lock; payload and parsed mappings remain the execution checks.

## Player predicates and checkpoint separation

Fresh protected client API reads cover the remaining predicates: canonical class
and race from player tags, player level and referenced item counts. `leader` means
the controlled player, never a companion/party inference. Inventory uses native
GetItemCount(id, false), excluding bank storage. Missing APIs, exceptions, missing
tags, invalid level/count values remain unknown, including under negation.

Only referenced observations are read. Existing fresh quest callbacks also refresh
these observations; bag, player inventory, level and world-entry events re-evaluate
pending proof without new quest queries or timers. The original native quest
cache/polling/progression remains authoritative. Saved native manual completion
flags are never narrative evidence.

Checkpoint proof is evaluated separately from story eligibility and presentation.
The source contract makes `at_step` a journey boundary, not proof. A true fresh
explicit predicate may verify a checkpoint, including historical reward evidence;
it cannot create a story encounter or presented history. Reading, skipping and
opening a guide cannot prove it.

Per-character `campaignCheckpoints={version=1,guides=...}` stores checkpoint proof
revision and verification only. Revisions hash guide/checkpoint identities, boundary
and typed proof; summaries are excluded. Changed proofs do not inherit old
verification. Hashes are cached per immutable loaded definition. Unknown saved-state
versions are retained and fail closed. No milestone popup, Journal extension or
cross-guide unlock behavior is added.

## Original-interface fallback

A small Story button above the original guide opens Parchment's existing movable,
resizable authored-prose reader. Left-click opens/closes; right-click recalls only
presented revisions. The same per-type settings and admitted-only data apply.
It is subscribed only once a compiled package is accepted, using the existing
presentation notifier. No extra polling is introduced.

A reader already in use retains its text. Combat and hidden-guide interruption
fold the fallback without forcing reopening. Semantic passage identity preserves
scroll on reread despite detached snapshot objects. Actual visible fallback
presentation records the same first-visible history as the adventure leaf, with
no waypoint/progression changes. Switching to the adventure interface hides the
fallback cue and suspends the background reader through the existing Parchment path.
Legacy authored background controls retain their behavior.

## Verification

`python3 tools/presentation/run_checks.py`: **34 Lua regression scripts pass**,
plus top-level Lua 5.1 parsing and XML ordering. Adjacent check log records the run.
Tests cover actual compiler Metadata.lua/Guide.lua loading through the public gate,
real registration/parser bindings, duplicate/rejected-package isolation, independent
checkpoint proof/revision changes, unavailable observations under NOT, player-only
fact events, inventory-gated pending story, real Parchment fallback, scroll/combat/
recall/history and native waypoint refresh continuity. Client APIs remain doubles.

Compiler source remains pinned at `65becb43d3948e4238b5a576240b394e96a5d26b` in a
separate clean temporary worktree. It is run without edits against the committed
viewer, using only the already-played narrated example. No active campaign checkout
or source is changed. Actual compiler files generated against clean `a51a854` are
also retained as loader fixtures; their older target SHA deliberately exercises
provenance-versus-interface separation.

The focused packaging tool bundles the committed viewer plus the compiler's content
addon, verifies content manifest hashes and every ZIP member, and writes BUILD.json
and SHA256SUMS alongside the artifact. It includes no SavedVariables, character
snapshots, server files or developer source maps. The exact artifact commit, source/
compiler provenance and ZIP hash are recorded in that build output. The full
[client-test instructions](COMPILED_PILOT_CLIENT_TEST.md) are included in the ZIP.

**No WoW client verification has run.** The result is an installable experimental
client-test candidate, not a claim of normal-play readiness. Real quest ordering,
counts/names, secure controls, rendered arrow motion, reader interruption/visibility
and performance require a client pass. The main character has already passed this
example; no automatic story backfill is expected. Use an eligible Night Elf test
character for fresh acceptance/progress/reward events; never reset or abandon the
main character's progress to force the test.
