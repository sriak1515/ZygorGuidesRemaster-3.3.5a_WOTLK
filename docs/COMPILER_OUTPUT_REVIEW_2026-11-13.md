# Compiler output review — 13 November 2026

**Scope:** delegated read-only compiler review and generation of representative
output, explicitly authorized by the owner. No compiler, campaign source, addon
runtime, installed guide, server or character state was changed.

## Reviewed implementation and output

Compiler: `feature/guide-v1-compiler`, clean worktree
`/tmp/wow-guide-v1-compiler`, commit
`65becb43d3948e4238b5a576240b394e96a5d26b`.
Entry point: `tools/content/compile_v1.py`; contract:
`tools/content/COMPILED_INTERFACE_V1.md`; invocation/evidence limits:
`tools/content/V1_COMPILER.md`.

Target viewer: clean `/tmp/wow-guide-v1-viewer`, revision
`840376de42057863cacd1cb2f776898fcc50d131`. This viewer revision has no
`RegisterCampaignGuideMetadata` consumer. The main campaign authoring checkout
and concurrent changes there were left untouched; no branches were switched.

The compiler worktree's canonical Guide Format v1 document and schema are
byte-identical to pinned `581672132d3f2b023d2415ac7299732a8abd35c0`.
The provenance field `source_contract_sha256` hashes the shared validation module
`tools/guide_format_v1.py`, not the Markdown specification. They are different
artifacts; their differing hashes do not demonstrate source-format drift.

Generated output root:

`/home/ubuntu/wow-solo-adventure/build/compiler-interface-review-2026-11-13-65becb4`

Both `route-only/` and `narrated/` contain the content addon directory
`WoWSoloAdventureV1Pilot/` with Metadata.lua, Guide.lua, TOC and BUILD.json,
plus source-map.json, ZIP and SHA256SUMS. Only matched, already-played v1 examples
were used. The two Guide.lua files are byte-identical; their SHA-256 is
`b75cc5f67bd0114f752e18ed8b050ecbef9482ae7b286bd43ed70e265f11f597`.
Native mappings are identical. Narrated output carries three source/native steps,
four mapped gameplay goals, two passages and one separate checkpoint.
The parent review independently checked Guide.lua equality and artifact hashes.
These packages are integration candidates, not playable client releases.

## Verification executed by the subagent

Working directory `/tmp/wow-guide-v1-compiler`:

```sh
PYTHONDONTWRITEBYTECODE=1 GUIDE_V1_TEST_FORK=/tmp/wow-guide-v1-viewer \
  python3 -m unittest discover -s tools/content -v
PYTHONDONTWRITEBYTECODE=1 \
  python3 -m unittest discover -s tools/guide-checks -q
```

**Passed: 9 compiler tests and 92 checker tests.** The compiler suite uses the
pinned real Parser.lua, Goal.lua and Step.lua with client API and metadata doubles.
Literal prose, rejection cases, manifests and deterministic archives are covered.
This is simulated verification, not a native client result.

Generation, once for each matched example:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/content/compile_v1.py \
  --guide campaign/guide-format/examples/kal01-balance-route-only/GUIDE.yaml \
  --fork /tmp/wow-guide-v1-viewer \
  --output /home/ubuntu/wow-solo-adventure/build/compiler-interface-review-2026-11-13-65becb4/route-only
PYTHONDONTWRITEBYTECODE=1 python3 tools/content/compile_v1.py \
  --guide campaign/guide-format/examples/kal01-balance-with-narration/GUIDE.yaml \
  --fork /tmp/wow-guide-v1-viewer \
  --output /home/ubuntu/wow-solo-adventure/build/compiler-interface-review-2026-11-13-65becb4/narrated
```

## Actual interface supersedes earlier proposals

The campaign-owned compiled contract deliberately uses **one interface_version=1**,
with explicit acceptance/rejection and no capability negotiation. This supersedes
this chat's earlier speculative capability-list fields; do not implement that old
proposal as an additional compatibility scheme. Compiler version, source hashes
and target viewer revision remain provenance.

Actual top-level metadata: interface_version, source_format_version, guide,
native_views, narration, checkpoints, source_locations, provenance.
Native views carry registration, raw-payload SHA-256, source-step/native-label
mappings and parsed goal indices. Authored goal IDs are optional; anonymous array
positions are diagnostic paths. Narration preserves exact source fields/paragraphs
and adds source order/path and a revision hash of the complete authored passage.
Editorial thread summaries are excluded. Checkpoint proof remains separate.

Metadata.lua calls `ZGV:RegisterCampaignGuideMetadata(metadata)` before Guide.lua.
Only an exact true permits native registration through the shared addon namespace.
Missing, nil/false-returning or throwing consumers leave registration disabled,
even when subsequent files load after a Lua error. An accepting test double is
not a real consumer, binding layer or narrative scheduler.

## Findings and responsibilities

1. **Main integration blocker: missing addon consumer.** No confirmed compiler
   defect was demonstrated within the supported pilot subset. Current addon code
   cannot accept the package. See compile_v1.py:187–196 and the compiled interface
   document:27–44. Do not mistake generated ZIP success for client compatibility.
2. **Acceptance stages data; binding comes afterward.** The addon must validate
   version/definitions, then verify actual native registration/raw digest and
   resolve parsed labels and goal indices before enabling narration. Definitions
   arrive before native guide objects. Mismatch remains inactive with a safe
   diagnostic, rather than leaking titles or silently dropping story. The current
   harness validates mappings with a fake accepting API, not this full lifecycle.
3. **Verification wording is overstated.** V1_COMPILER.md:40–45 claims normal native
   advancement. tests/content/v1_runtime.lua:119,126 only call Step:IsComplete();
   no TryToCompleteStep, FocusStep or CurrentStepNum transition is exercised.
   Narrow the claim or add an actual advancement/anchor integration test. This
   is a documentation/coverage finding, not evidence of broken progression.
   The parent review independently inspected these assertions.
4. **Compiler coverage is intentionally small.** Required, nonsticky accept/kill/
   turn-in goals support the examples. Other actions, visibility/jumps,
   alternatives, optional/informational roles, sticky behavior and external
   dependencies fail explicitly. Multiple native parts are representable but
   unexercised: the pilot emits one native step per source step. Broader v1 or
   campaign-release readiness is not established. See compile_v1.py:74–84,
   111–117 and the compiled interface document:69–71,120–147.
5. **Narrative semantics belong to the addon.** The compiler correctly preserves
   at_step, typed requires, type, purpose/thread, revisions and separate checkpoint
   proofs, and keeps prose out of native rows. Fresh evidence, three-valued
   evaluation, qualified anchor encounters, scheduling, type settings and history
   are runtime work. Existing FocusStep publications cannot distinguish live play
   from browsing/restore/skips; add explicit observational origin information.
   Missing requires still does not waive a legitimate anchor.
6. **External-input provenance has a documented limit.** source_revision describes
   the compiler worktree HEAD; an external YAML's exact source hash identifies its
   bytes but does not prove membership in that Git commit. Clarify input origin
   before broader release-lineage claims. See compile_v1.py:174–182 and
   V1_COMPILER.md:28–32.

## Recommended next addon slice — proposal, not implemented

Start with a private staging implementation of RegisterCampaignGuideMetadata for
this exact interface, followed by actual payload/mapping validation. Consume the
two generated examples in integration tests, including missing/rejected metadata,
duplicate definitions, wrong hashes/labels/indices and delayed native parsing.
Do not expose definitions through public UI snapshots.

Next add a narrow evidence/anchor controller using the existing fresh quest hooks
and explicit transition-origin notifications. Exercise actual automatic advancement
before broadening the UI: capture legitimate proof before leaving an anchor,
allow delayed evidence only for a recorded real encounter, and reject browsing,
manual marks, bare restore and unknown evidence, including under negation.
Keep pending facts distinct from first-visible-presentation history.

Per-type preferences, queue arbitration and minimal Journal recall should consume
that verified binding. Keep the current renderer, legacy single-passage behavior,
native actions, arrow/progression, geometry and original-interface fallback intact
initially. No compiler implementation or visual redesign was performed here.
