# Provisional viewer adapter for the compiler preview

**Historical prototype handoff:** the field/hash reconciliation below is superseded
by [Preview Policy Contract 1 alignment](PREVIEW_POLICY_1_ALIGNMENT_2026-11-14.md).
The preview remains provisional and non-installable; production evidence is still
missing. This note records the earlier implementation and its original checks.

Reviewed campaign PR [#5](https://github.com/sriak1515/wow-solo-adventure/pull/5)
at `dfc438c60c95c49eebebccd0729ed12b0dcd77d7`, including the Step 3 and Step 4
handoffs, and PR [#6](https://github.com/sriak1515/wow-solo-adventure/pull/6)
at `0620ec92bd42e7995fe22c6d47c1cb63f43e58a5`.
**Policy contract status: PROVISIONAL.** The exact fields/serialization must be
coordinated with compiler work before packaging or claiming chapter support. The
internal prototype is source/policy-version/hash bound; it is not an agreed new
compiled contract.

All outward reporting here is technical; private source/prose/previews stay outside
this repository. Existing playable guides, campaign sources and the already-played
pilot package are unchanged. No PR is merged and no live state is read or mutated.

## Agreed handoff behavior implemented in the viewer

`CampaignPreview.lua` adds an internal `CampaignData:RegisterPreview(report, policy)`
adapter for `preview_format_version=1`, with status still `BLOCKED_NOT_INSTALLABLE`.
It does not turn an inert preview into a content package or relax the existing
public interface-v1 package validator. Unsupported/malformed mappings reject
before registration; binding failure remains inactive with a static diagnostic.
Omitting policy permits binding inspection only and locks all activation.

Both bounded views retain one logical guide identity, source addresses, exact
narration revisions and shared character admission/history. Additional mappings
cover native arrival, passive collection with independent objective/inventory
proof, object affordances, item use with required consequences, and typed waits.
The existing parser, Goal/Step engine, secure item controls and waypointer remain
in charge. Required consequences stay separate from passive support rows; a click,
use command or unrelated bag count cannot finish the source goal. Binding verifies
support indices, IDs, counts and blocking participation. Condition rows display
ordinary waiting instructions instead of generated predicate code.

Native selection, remembered/direct focus, Previous/Next, automatic advancement,
rendering, snapshots and waypoint updates consult preview guards. Failed entry
preserves the previous active guide. Direct forward selection cannot jump over
unresolved required work. UNKNOWN visibility holds; only a known false typed
condition may exclude a row. Generated false/UNKNOWN visibility is never delegated
to native auto-skip. Roster/evidence loss pauses the preview, hides its actionable
frame and clears guide navigation through the existing waypointer. Fresh valid
observations restore the frame and the previous native pause state.

Only explicitly emitted, unsuppressed goto rows may direct preview navigation.
Suppressed arrivals still use native arrival completion/radius. Support NPC/object
rows cannot invent a replacement arrow. No alternate routing system is added.

The opening's terminal skip is intercepted before native adjacency/finish handling.
Full pause evidence is required to persist a source/roster-bound suspension and
optionally dispatch the existing owner's native guide. Missing owner registration
leaves the view suspended. Suspended/returned openings cannot relaunch. A saved
bookmark alone never admits the continuation. Verified return resolves to the
first unresolved work within that bounded view.

Return accepts exactly one typed owner mode: observed return, or documented safe
fall-through. The latter cannot contain success/observation checkpoints or claim
observations. Missing/contradictory owner data, unknown personal quest states,
changed source, wrong suspension identity, unavailable actors or stale evidence
keep the continuation blocked. Reading never publishes owner scene milestones or
grants dungeon credit.

## Runtime policy/evidence boundary introduced here

This is a viewer integration contract, **not a claim that PR #6 already emits it**
or that a real observation backend exists. It adds no fields to authoring v1.
Policy is plain draft data with `provisional=true`, `policy_version=1` and the
exact `source_sha256`. The viewer computes an opaque deterministic hash over that
source/version and complete policy, and binds evidence, suspension and narrative
scope to it. Serialization/hash interoperability is provisional, not a published
compiler wire format. Unknown policy versions and mismatched hashes stay closed.
The data identifies:

- The exact five expected actor names and the admission minimum level. This is
  not a guessed universal combat threshold.
- Named entry/return gates, their actual owners and proof kinds. Declared external
  predecessor checkpoints must map to specifically identified external-checkpoint
  gates; a generic readiness flag cannot replace them.
- Guarded combat/readiness source boundaries, typed step visibility conditions,
  the terminal pause boundary and existing owner dispatch registration.
- Explicit per-passage producer aliases, activation scopes and reward-only recovery
  allowlists. Acceptance setup is never blanket-backfilled after its reward.

`CampaignPreview:SetEvidenceProvider(callback)` is the bridge to the existing
owners' evidence, not a manual permission checkbox. **No production provider is
installed by this change.** The adapter must reconcile actual owner records and
current observations, never echo a requirements file, bookmark, UNKNOWN result or
request fields as verification. The test provider is explicitly synthetic.

Each request identifies source hash, fresh roster signature, current client session,
policy version/hash and existing suspension ID. A response must bind all these, use a client-time
observation no older than 30 seconds, and supply each required gate as an explicit
verified fact with the expected owner/kind and nonempty provenance. Errors, nil,
truthy strings and stale/foreign responses deny access. Client APIs independently enumerate the actual group layout: all raid units for
a five-character raid (including the player in any raid slot), or the actual party
layout when not in a raid. They check exactly five distinct identities, expected
names, player membership, connectivity and measured levels. Raid slot ordering is
not identity. Missing/unobservable Playerbot data stays blocked; no cached level
grants entry. No group conversion, invitations, kicks or reformation are performed.

The return record additionally names its owner/mode/date/provenance, safe location,
actual five levels and every required actor/quest active/rewarded pair. The leader
pairs must agree with the viewer's fresh quest observations. Observed return must
reference the owner's expected observation checkpoint. Safe fall-through requires
its reason and explicitly unobserved scene status with no success checkpoint.
These checks do not replace the owner's full health/XP/equipment/repair/supplies,
mechanics, performance and divergence assessment. Those facts must actually exist
before its readiness gate can be verified.

Per-character `campaignPreview={version=1,guides=...}` records suspension identity,
source/roster/session, evidence provenance and return disposition. Unknown saved
formats remain closed. An archived return needs fresh owner reconciliation against
the restored suspension; no automatic trust follows a saved record.

## Narrative delivery

Fresh producer observations can admit a passage anchored at a subsequent already-
true wait before normal native progression leaves the producer. Fresh typed
interaction/collection consequences can also create legitimate observations;
clicks, manual marks and mutable native completion caches cannot. View activation
passages require actual guarded admission to that view. A continuation passage
cannot appear merely because its quest guard was already true at pause.

Recovery is explicitly opt-in per passage/view and limited to positive reward
predicates. A source-bound valid view admission plus fresh proof may recover an
undelivered earned passage; it cannot recreate expired active-only setup. Existing
pilot behavior remains unchanged without this preview-specific policy. Source
scope and exact passage revisions prevent old records exposing changed prose.

The existing reader, preferences, first-visible history and recall are reused.
Admitted undelivered text remains discoverable after terminal dispatch/guide exit;
queued facts and history survive character-state restore. Eligibility does not
mark presentation or prove an NPC scene, reading or party credit. No Journal UI
expansion is included.

## Compiler coordination required before packaging

PR #6 currently emits an inert report and a requirements profile, not this policy.
The compiler handoff must agree the policy version/schema and hash representation;
include original typed step conditions; assign each passage's view, actual producer
and activation/recovery scope; and identify existing owner gates and dispatch maps.
Do not silently promote the prototype fields to a stable interface-v1 extension.
The existing public package API remains unchanged and cannot accept this report.
A technical coordination note belongs on PR #6 with this branch/revision; actual
owner observations and Playerbot/raid checks remain separate work.

## Verification and remaining blockers

The normal Lua regression runner and private binding command are recorded beside
this note. All 35 Lua regression scripts passed. Against a clean checkout of
viewer implementation `2c36ee0`, the PR #6 compiler's 16 tests and guide checker's
92 tests also passed, including the optional private preview input. These are
offline/simulated checks; no WoW client or real owner-evidence verification occurred.
Synthetic tests use actual Parser/Goal/Step, registration, SetGuide,
FocusStep, SkipStep, TryToCompleteStep and SetWaypoint functions with client/API
and owner-evidence doubles. They exercise the extended actions, concurrent proof,
partial objective versus bags, hidden arrival, unknown negation/visibility,
raid and party observation, shuffled raid slots, missing/disconnected/unknown actors,
source/policy-version/hash denials, all entry paths, pause/dispatch, both return dispositions,
restore, changed source, producer-to-anchor text, scoped recovery and no duplicate
admission. The existing playable pilot tests remain part of the suite.

The exact private preview binds **two views, 42 source steps and 48 source goals**.
It is registered for offline inspection with policy omitted: every activation
stays blocked and no narrative is admitted. This is binding evidence only. No
future source, generated private text or actor snapshots are checked in.

Release remains blocked by:

1. **Compiler integration metadata:** PR #6 lacks typed step `only_if`, explicit
   producer/activation/recovery policy and complete owner/dispatch mappings. Supply
   source-faithful integration metadata under an agreed compiled contract. The
   viewer will not infer missing typed conditions from generated Lua. Its public
   package API still rejects the unsupported preview package shape.
2. **Real evidence bridge:** exact client bot identity/connectivity/levels must be
   observable; actual predecessor, pause, return, readiness and scene/party owner
   records must be reconciled. No live bridge or full external milestone publisher
   is manufactured here. A schema-valid profile or positive synthetic test is not
   this evidence. Unobservable bot states remain UNKNOWN.
3. **Client and mechanics tests:** actual scripts/items, arrival geometry, bot
   behavior, safe staging, combat assessment, rendered ordering, interruptions,
   reload and secure controls still need the agreed real checks.

No new future-content ZIP or playable replacement is produced. The earlier
already-played pilot remains available at its original revision. This branch is
a tested viewer integration increment, not approval to launch the unplayed trial.
