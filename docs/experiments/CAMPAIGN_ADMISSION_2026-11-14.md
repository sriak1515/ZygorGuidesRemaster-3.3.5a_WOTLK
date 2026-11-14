# Pilot narrative admission — 14 November 2026

Implemented after the binding foundation, on `codex/adventure-gameplay-usability`.
The compiler, source content and visual redesign remain untouched. This increment
implements internal admission, not Story delivery or Field Journal UI. The public
`RegisterCampaignGuideMetadata` gate remains absent: compiled packages still refuse
installation rather than silently dropping unfinished narrative semantics.

## What qualifies in this pilot

A fresh quest observation must match a mapped action at the currently bound native
step. Focus, guide selection/restore, native completion flags, Previous/Next and
policy skips alone are not encounters. Browsing to an anchor does not permanently
exclude real play: a subsequent genuine matching quest action can qualify it.

- Acceptance: observed absent→active change after an observed baseline.
- Kill: observed numerical progress in that quest/objective, while active in both
  observations. Arrival or an unchanged counter does not qualify.
- Turn-in: observed disappearance of an active, completed quest at the turn-in
  anchor, plus fresh reward confirmation. A previously observed unrewarded baseline
  is required. Disappearance alone is only an unconfirmed candidate; abandonment
  cannot admit prose. Retaking the quest cancels its unconfirmed candidate.

These are conservative, action-based pilot semantics. Initial snapshots are
baselines, not historical events. This does not yet provide pre-action context on
simply entering an anchor. Generic place encounters, expanded native parts and
broader action mappings remain outside this slice. No new authoring trigger fields
or presentation defaults have been introduced.

Fresh evidence enters through the existing QuestTracking log-rebuild and completed-
query hooks, before native callbacks and automatic advancement. The controller
copies only watched quest IDs and objective facts, avoiding pooled cache aliases.
It does not read native mutable completion/accepted caches as narrative proof, and
adds no polling, timers, quest queries, routing or progression logic.

## Reveal and persistence

Typed quest predicates evaluate true/false/unknown. Negation preserves unknown;
only true admits gated prose. Missing `requires` waives the additional reveal
restriction, never the anchor/action proof. Missing objective data stays unknown,
including when the quest is absent. Non-quest predicates (class/race/level/item)
remain unknown until a separate fresh-observation contract is implemented; even
negating them cannot reveal prose. This is another reason the full v1 public gate
stays closed.

Per-character `campaignAdmission={version=1,guides=...}` records only encountered
passage identities, exact revisions, proof facts and eligibility order. It stores
no prose, headings, editorial metadata, presented flags or Journal history.
Pending turn-in candidates and eligible passages survive step advancement/reload.
A fresh delayed reward query can confirm a saved real candidate, but cannot create
one. Unknown saved-state versions are preserved and fail closed. Character changes
reset observation baselines. Revised passages require a new matching encounter;
an old passage ID/revision record cannot expose revised text.

Eligibility is retained once proven, pending delivery. It is not first-visible
presentation or proof of reading. Simultaneously admitted passages use authored
source order; later observations append eligibility order rather than reordering
events globally by source position. Checkpoint proof remains separate and is not
implemented/evaluated by this admission layer.

Definitions stay private. Internal `CollectAdmitted` returns detached, admitted-only
prose with identity/revision/type and order; ordinary presentation snapshots and
status inspections remain unchanged. No leaf cue, auto-opening or recall is wired
in yet. Legacy Banethil recovery is unchanged and is not migrated into this state.

## Verification and limits

`python3 tools/presentation/run_checks.py`: **32 Lua regression scripts passed**,
plus Lua 5.1 parsing and XML ordering. Adjacent log records the result.

The extended compiled-example test runs actual Parser/Goal/Step, native advancement
functions, and actual QuestTracking log/query hooks with simulated client APIs.
Coverage includes action observation before advancement, pooled-object reuse,
partial progress, delayed reward in both event orders, pending and eligible reload,
character/revision isolation, historical/bare restore denial, manual/browse denial,
retake cancellation, missing/negated evidence, newly watched baseline handling,
future saved-state preservation and detached admitted output. Separate truth tables
exercise conjunction/disjunction and unknown under nested negation.

The client leaderboard double uses distinct names per objective so native name-
based count adjustment does not merge two generic fallback targets. This does not
verify the compiler's displayed names or actual client/database objective mapping.
No WoW client, installed guide, character or server was accessed. Actual quest-event
ordering, native rendered arrow behavior, visual presentation and performance
remain unverified. The new records are exercised only in test characters/doubles;
without internal staging, normal gameplay exits the new observation hooks early.
No new test ZIP is useful for this internal slice.

## Next slice

Add minimal delivery through the existing reader, explicit type preferences and
first-visible presentation recording, keeping eligibility separate from history.
Test interruption/reload, revision-safe recall and future-title denial. Non-quest
predicate observation and separate checkpoint semantics also need completion or an
explicitly agreed narrower interface before enabling package acceptance. Keep the
visual mockups and broader redesign deferred.
