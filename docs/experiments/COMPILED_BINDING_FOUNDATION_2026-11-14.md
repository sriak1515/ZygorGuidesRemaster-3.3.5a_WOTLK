# Compiled binding foundation — 14 November 2026

This increment starts the addon work recommended in the compiler review. It does
not change the compiler, campaign content, visual design, presentation defaults,
legacy Banethil integration or character saved-state format.

## Implemented boundary

`CampaignData.lua` provides internal detached staging of the reviewed compiled
interface v1 data. It validates plain literal data, supported versions, references,
unique identities/mappings, typed predicates, provenance and bounded pilot shapes.
Definitions remain private. Native guide registration checks exact raw-payload
SHA-256; deferred parsing binds real step labels and actual goal indices, actions,
quest IDs, NPC IDs, objective indices and counts. Missing, duplicate or mismatched
bindings remain inactive with static inspection codes. Reparse after cache eviction
binds the replacement native objects. Native parsing/advancement remains authoritative.

The initial binder supports the compiler pilot's one view and one native part per
source step. Broader expansion semantics are unimplemented, not inferred.
Target-viewer revision is provenance, not a compatibility lock.

A narrow observation hook runs immediately before the ordinary native automatic
`SkipStep` call. It captures the old bound source step before advancement, labels
policy skips separately and flags native manual marks. Detached callbacks are
protected against exceptions. These are **transition candidates, not legitimate
encounters or reveal evidence**. Browsing/restore/Previous/Next do not emit them.
Jump/repeat paths are outside this pilot and do not emit a candidate here.

`GetCampaignGuideStatus(registration)` returns detached static state/code and
`delivery="not-implemented"`. It exposes no narrative definitions, passage titles,
prose or counts. No narrative history, encounters or checkpoints are persisted yet.

## Deliberate installation gate

**The public `RegisterCampaignGuideMetadata` API remains absent.** Only the internal
`CampaignData:Stage` foundation exists. The campaign contract requires support for
narrative semantics before accepting a package; accepting now would install native
work while silently omitting story. Generated packages therefore still refuse
installation through their existing metadata-first guard. Do not replace that guard
with a fake accepting API in normal gameplay.

This is a narrower first increment than exposing the accepting consumer immediately.
It preserves the agreed single-version contract; it adds no capability negotiation.
No new gameplay test ZIP is offered for this internal foundation.

## Advancement coverage explained

The earlier compiler harness checked `Step:IsComplete()`. That establishes completion
semantics but not whether the actual advancement driver selects another step,
updates saved progress/waypoints or discards a story anchor before observation.
It was a coverage gap, not evidence that the compiler's supported translation fails.

The new test uses the actual Parser, Goal and Step implementations and extracts the
exact native RegisterGuide, EnsureGuideParsed, FocusStep, FocusStepQuiet, SkipStep
and TryToCompleteStep functions. Client APIs, frame visibility and waypoint rendering
are doubles; assertions concern real native state transitions and refresh calls.

Covered: acceptance 1→2, concurrent partial kills staying on 2, completed kills 2→3,
active quest preventing turn-in even with a completed-cache entry, actual reward
3→native finish, saved guide progress, waypoint refresh calls, pause/visibility/reading
guards, anchor capture before transition, policy-skip classification, manual marks,
browsing separation, observer exception/isolation, and detached public snapshots.

Both compiler variants bind against their identical native payload. Negative cases
cover malformed/cyclic/metatable/function data, unsupported versions/predicates,
duplicate definitions, wrong payload, duplicate labels, wrong goal index/quest/count/
contact and unmapped gameplay goals. Native parsing still succeeds on binding failure.
SHA-256 known vectors include empty input, `abc` and a multi-block payload.

Test inputs are generated from the reviewed compiler commit, using only the already-
played opening example. See `tools/presentation/fixtures/v1/README.md` for provenance.
The temporary review worktree was unavailable after environment restoration; files
were recovered read-only from the existing campaign Git object into `/tmp`, without
switching or changing the campaign checkout. No compiler changes were made.

Validation: `python3 tools/presentation/run_checks.py` passes all 31 Lua regression
scripts plus Lua 5.1 parsing and XML load-order checks. See adjacent check log.
**All verification is simulated.** No WoW client, character, installed guide or server
was touched. This does not verify the native bit-library fast path, rendered arrow
motion, actual quest events, narrative delivery or presentation across transitions.

## Next slice — recommendation

Implement the narrow evidence/anchor controller before opening the public package
gate. Reuse fresh quest observation hooks; distinguish real encounters from restore,
browsing, manual completion and obsolete skips. Preserve unknown under negation,
require both qualified placement and reveal proof, retain pending state across an
immediate transition and never create history from eligibility alone. Add tests for
delayed evidence and denial paths. Delivery/type settings and minimal presented-only
recall must then satisfy the agreed narrative semantics before package acceptance.
No visual redesign or new presentation defaults are approved by this increment.
