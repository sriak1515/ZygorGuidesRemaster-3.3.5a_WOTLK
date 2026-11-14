# Compiled Story reader delivery — 14 November 2026

This increment connects admitted compiled passages to the existing experimental
Story leaf. It adds no compiler, campaign-source, navigation or progression changes.
Visual mockups and the larger redesign remain deferred. No public compiled-package
acceptance API is enabled yet.

## Implemented behavior

The delivery adapter consumes admitted-only data; it does not inspect quest state
or reinterpret passage eligibility. The current compiled guide's admitted passage
can now enter detached presentation snapshots. Future prose/headings and editorial
fields remain private. Ordinary legacy/native story rendering remains available
when there is no admitted compiled passage. The legacy Banethil record is unchanged.

Three shared selects in both existing display settings control `context`, `moment`
and `chapter`: **Quiet cue** or **Open when safe**. Profile persistence uses
`campaignStory`. All default to a quiet cue in this experimental increment; opening
is opt-in. This is a conservative interim implementation, not approval of the
previously proposed type defaults. Preferences apply only to compiled passages.
Editing a preference affects future arrivals and does not open an existing backlog.

An opt-in live arrival may open when the reader is free and the guide visible.
Combat, casting/channeling, spell targeting, guide dragging/resizing and the known
quest/gossip/loot/merchant/taxi/trainer/trade dialogs suppress that attempt. It then
remains available quietly; leaving the interruption does not force it open.
A quiet context backlog does not prevent a later configured moment from opening.
An open reader keeps its current text when more passages arrive. Simultaneous
opening requests keep the first eligible request in authored admission order.
Closing never drains a backlog through automatic openings.

The existing leaf and tab are reused, with no new Journal window or decoration.
Left-click opens/folds the selected pending passage, or the last presented passage
when nothing is pending. Right-click cycles backward through presented passages
for the current compiled guide. Future or merely eligible passages cannot enter
that recall route. Explicit recall can replace the current reader selection;
background arrivals cannot. The tab remains hidden while the leaf is open.

Combat folds the reader, retaining its chosen passage and scroll offset. It does
not reopen at combat exit. Activation/reload begins folded, preserves saved history
and preferences, and does not automatically open already eligible passages. A
pending encounter restored from saved state may resolve after fresh evidence, but
that restoration is not a new automatic opening event.

## First-visible history boundary

Admission and presentation are separate. Eligibility, snapshots, a tab cue, an
opening request, hidden frames, zero opacity and insufficient adjacent space do
not create history. The actual reader reports presentation after successful text
rendering/layout only when the leaf and guide are visible and outside combat.
Repeated layout/ticks deduplicate this report; successful presentation is cached
for the current character/reader identity to avoid repeated state scans each tick.

The existing version-1 per-character admission record gains optional
`presented_order` per passage and `next_presented` per guide. These are first-visible
presentation facts, not proof of reading. Old pending records remain valid; no
state is reset or backfilled. Saved records contain identities/revisions/proof/order,
not prose. Recall resolves only the exact currently bound revision; an old passage
ID cannot authorize revised prose. Presentation order is recorded separately from
eligibility order. Opening/recall does not alter checkpoint proof or native progress.

`CampaignData:CollectPresented` and the delivery adapter provide the small recall
boundary for a later Field Journal. This is presented-only recall, not a general
Journal UI or a catalog of eligible/future titles. Binding diagnostics now report
`delivery="internal-only"`; that is not a claim of full interface-v1 acceptance.

## Verification

`python3 tools/presentation/run_checks.py`: **33 Lua regression scripts passed**,
plus top-level Lua 5.1 parsing and XML ordering. The adjacent log records the run.

Coverage includes the actual fresh quest-cache→admission→delivery notification
path, restored-encounter provenance, opt-in type preferences and their persistence,
quiet backlog behavior, stable reader selection, combat/busy/reload handling,
first-presentation deduplication/order, pending-versus-presented recall and revised
prose denial. Actual presentation code executes against frame/API doubles to verify
render-before-record, fit/visibility/opacity guards, scroll retention, same-passage
recall, fixture isolation and unchanged waypoint refresh counts. Registry marking
also rejects unknown identities, wrong revisions and unadmitted passages. Both
normal settings presentations execute the real shared option callbacks.

The test-only reload simulation resets its retained named-frame registry before
activating the reloaded UI, reflecting that actual WoW reload destroys old frames.
This is not production hot-reload support.

**All verification is simulated.** No WoW client, installed guide, character or
server was accessed. Actual event ordering, rendering/visibility, secure-action
interaction, dialog interruption behavior and performance still need client checks
before calling a compiled pilot ready for ordinary play.

## Remaining package gate

The public `RegisterCampaignGuideMetadata` remains absent. Admission still treats
non-quest predicates as unknown, checkpoint consumption is unimplemented, and the
original-interface fallback does not yet render compiled narration. Those parts
need completion or an explicitly agreed narrower compiled contract before accepting
content packages. This increment does not silently accept a partial interface or
modify the compiler's contract. No new installable ZIP is offered for this gated
internal integration. There is no new compiled gameplay test for the player yet.

The next bounded work is to close those interface gaps, then generate the already-
played pilot and do a real client pass. Broadening authoring, campaign chapters,
Journal features or visual redesign is unnecessary for that verification.
