# Production campaign evidence provider — 14 November 2026

**Status: implemented and offline-verified for tonight's private KAL-07 playtest.**
Branch `codex/campaign-evidence-provider`, HEAD `836d293`, on top of the Policy
Contract 1 verification (`b893f16`). This closes the "real evidence bridge"
blocker from [the provisional preview handoff](COMPILER_PREVIEW_VIEWER_HANDOFF_2026-11-14.md)
for the KAL-07 opening view; the client and mechanics checks remain a separate
live step.

## What was added

- `ZygorGuidesViewerRM/CampaignEvidence.lua` — the production evidence provider,
  installed via `CampaignPreview:SetEvidenceProvider` at load. It supplies:
  - `prior` (`external-checkpoint` `KAL-06.TOWER_PROLOGUE`): a fresh
    `GetQuestsCompleted()` history observation confirming quests 965/966/967
    rewarded, accepted only when the logged-in player is the checkpoint's
    declared leader (Thaloren). The 3.3.5a table-filling API pattern is the one
    already used by Item-GearFinder.
  - `pause` (`full-pause`): a live group observation — the real five-member
    raid or party layout, every member present, connected, out of combat and
    alive. The viewer's own roster observation (exact five identities, measured
    levels, connectivity) runs before and after every provider call and is
    unchanged.
  - `returned` (`return-and-readiness`): intentionally never verified yet. The
    Blackfathom Deeps interlude (KAL-08) has no playable guide and no owner
    records, so no return record is produced and the continuation view stays
    locked. This is the designed fail-closed state, not a stub to fill later
    by hand.
- Gate identities in the module are byte-identical to the delivered activating
  policy; a mismatch is denied by the viewer's fact validation.
- `files.xml` loads the module after `CampaignPreview.lua`.
- `tools/presentation/test_campaign_evidence_provider.lua` — regression
  coverage: admission on fresh proof, denial on missing proof, denial when the
  checkpoint's declared leader is not the logged-in player, combat/death/
  disconnection blocking the pause, suspension persistence with captured pause
  evidence, no dispatch without an owner registration, continuation closed,
  suspended opening closed, and production identities restored after synthetic
  substitutions.

## Verification

- `python3 tools/presentation/run_checks.py`: static Lua 5.1/XML checks and all
  37 Lua regression scripts passed (36 existing + the new provider suite).
- Compiler interop re-verified against a clean detached checkout of `836d293`:
  `tools/content` 22 tests (1 optional skip requiring the private preview
  input) and `tools/guide-checks` 92 tests passed; the consumer test executed
  this checkout's Lua and confirmed the locked policy identity equality.
- The real regenerated KAL-07 preview (source sha256
  `643bd24178e67194a6bee55817a40f765b281661220779e553d1b727a53ac60e`, compiler
  `ef1ac7f`) bound both views offline with the activating policy, admitted
  entry on the fresh prologue proof with the real five-name roster, and kept
  the continuation fail-closed. Private artifacts and the play package live
  outside Git (campaign-audits area); nothing private is committed here.

## Delivering an activating package

The compiler emits `(report, locked policy)` plus `report.policy_identity` for
the locked draft. To deliver an activating definition, an owner replaces
`report.policy_identity` with the activating policy's own identity (computed by
the frozen `policy_identity.lua` helper) and delivers both tables to
`CampaignData:RegisterPreview` — the viewer revalidates the identity and every
structural rule at registration. A requirements profile or a locked draft never
activates anything.

## Remaining limits

- No WoW client has run this path yet; tonight's playtest is the first client
  verification. The preview fails closed to diagnostics rather than guiding
  wrongly.
- The return path activates only when KAL-08 exists, earns
  `KAL-08.POST_BFD_OBSERVATION`, and the provider learns that checkpoint's
  leader-scoped client-observable proof (the declared policy return quests are
  1198 and 1200, both turn-ins with fixed questgivers per the KAL-08 route).
  Bot quest states are not client-observable; the return reconciliation is
  leader-scoped by design.
- The suspension at the opening's terminal step persists without dispatch until
  KAL-08's registration exists; `dispatch_registration` stays unset on
  purpose.
