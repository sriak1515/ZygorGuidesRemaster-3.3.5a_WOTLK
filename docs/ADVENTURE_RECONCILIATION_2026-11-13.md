# Adventure direction reconciliation — 13 November 2026

**Status: review and proposals only. Substantial implementation is paused.**
The runtime remains `80f86096ddb66a5de329a9a35f53f9a3c06f404e` on
`codex/adventure-gameplay-usability`. This review does not approve the proposed
settings, scheduler, compiled interface, Journal or visual treatment for release.

## Reviewed sources and preserved state

- Supplied steering note: `docs/ADVENTURE_DIRECTION_AND_COMPILER_CONTRACT.md`,
  SHA-256 `22608bc4b2cd351bc1d911118b03b7111b40f17af7f8399a9de29900bb8eb75b`.
  It was untracked when received and is left unchanged and untracked.
- Canonical Guide Format v1: campaign repository commit
  `581672132d3f2b023d2415ac7299732a8abd35c0`, including the JSON Schema and both
  matched, already-played examples. The local document/schema/examples are
  byte-identical to this pinned commit, although locally untracked.
- Active campaign checkout: `feature/guide-v1-check-modes`, HEAD
  `efc505083552e52ece8497d4e3d05747c683a283`. Read its AGENTS, CURRENT_STATE,
  DECISIONS and WORKFLOW. Its newer dated decisions differ from origin/main's
  older decisions; they were inspected separately, not silently reconciled.
  Working changes in that repository were not modified or committed here.
- Current addon: Presentation.lua, PresentationUI.lua, BanethilStory.lua,
  QuestTracking observation points, native focus/skip lifecycle, Parchment rows,
  controls/scrolling and previous implementation reports.
- Existing campaign `tools/content/build.py`: legacy Markdown compiler with
  native labels, source-map output, registration variants and build provenance.
  It currently inlines passive narration and flattens line breaks; it is not a
  v1 narration-sidecar implementation. Existing releases remain unchanged.

There was no pending addon implementation diff at the start of this reconciliation.
The recent density/button discussion had produced investigation and proposals,
not uncommitted runtime edits. The working implementation, original interface,
assets, guides, geometry and character data are preserved.

## Agreed direction versus unresolved proposals

The supplied note establishes three complementary experiences: Journey for
immediate actions/progression, Story as a first-class narrative experience,
and Field Journal for previously presented passages derived from existing data.
Presentation must be configurable per passage type: context, moment, chapter.
Immersion, minimal clicking, strict spoiler safety and native Zygor ownership
remain requirements. V1 is the source authority for new v1 authoring; active
legacy STORY/ROUTE releases keep their authority until a separate migration.

The specific presentation defaults and controls, interruption/defer rules,
queue arbitration, presentation-history mechanics, movable-reader fallback,
compiled Lua sidecar shape and edge-control appearance are **proposals** in the
steering note. The rules below are recommendations for reviewing those proposals,
not claims that all have already been agreed or implemented.

The note explicitly asks to preserve the shared parchment treatment. The player's
direct visual feedback in this chat rejects the ornate buttons and favors
moving away from parchment. Preserve the existing material/reader as working
functionality and fallback. A quieter/dark treatment and new edge shapes remain
mockup options; this review changes neither renderer.

## What already fits

| Existing work | Fit and reuse |
| --- | --- |
| Native goal binding, confirmations, item/spell specs, secure overlays and action bar | Retain. Zygor owns completion and secure actions. |
| Native pointer, waypoint backend and step advancement | Retain. Story/Journal must never retarget or rewind them. |
| Independent drawing root and synchronized host visibility, scale and mouse handling | Preserve the client-diagnosed rendering fix. The player now confirms the view works. |
| Saved geometry, fonts, coordinated leaf anchoring, original-viewer fallback | Reuse. Visual refinement can happen after behavior/data reconciliation. |
| Detached snapshot/subscription boundary | Useful UI seam; extend with admitted narrative views rather than full future definitions. |
| Fresh quest-log and completed-query observation hooks | Reuse as evidence inputs. Capture immutable observations before mutable native caches can change. |
| Fold/recall, combat tuck, independent reader scrolling | Useful lifecycle primitives without a reading-completion requirement. |
| Legacy labels, source map and provenance from the existing content builder | Reuse the approach and build pipeline; add an explicit v1 interface rather than parse YAML in the addon. |

The screenshots show the native arrow and usable rendering. They do not establish
all secure clicks, quest-story event delivery or reload/history semantics. The
reported excess wrapping has concrete current causes: an extra title line and
18 fewer logical units of body width than Parchment at equal outer width. Saved
outer dimensions also differ in the comparison screenshots. Do not silently shrink
fonts or rewrite prose to hide that problem.

## What needs adjustment

1. **Typed, explicit narrative input.** Legacy passive `|context` and a hardcoded
   passage do not identify v1 types or policies. Keep legacy compatibility; do
   not infer type/purpose from wording, length or plain goal rows.
2. **Placement, eligibility, presentation and history need separate state.**
   `at_step` is an authored location; `requires` is a reveal predicate; `type`
   describes significance. Purpose/thread metadata is not a trigger. My earlier
   shorthand that context is simply available with a displayed step was too loose:
   browsing a future step is not a legitimate narrative encounter.
3. **Remove singleton dominance for v1.** The one retained legacy passage currently
   wins over current-step context. A general controller must hold several passages,
   preserve authored order and maintain a deliberate reader selection. New arrivals
   must not replace text mid-read or repeatedly open a backlog.
4. **Per-type settings.** Current step context often auto-opens, and the hardcoded
   passage controls its own auto-open flag. Neither implements per-type settings.
   Proposed starting choices are discreet Journey context, Story when safe, or
   a manual cue, configured separately for context/moment/chapter. Exact choices,
   defaults and which safety behaviors are shared still need agreement.
5. **First presentation is not eligibility.** The current per-character record
   stores observed quest evidence, not a record that prose was actually displayed.
   Proposed Journal entries should follow first visible presentation, ordered and
   deduplicated by logical guide, passage and passage revision. No reading timer,
   acknowledgement or comprehension claim. Eligible-but-deferred items stay separate.
6. **Safe persistence and upgrades.** Retain the existing single-passage record and
   its recovery behavior as a legacy exception until migration is agreed. Do not
   convert it to a Journal presentation fact or backfill new history from completed
   quests. An old passage ID must not expose revised, newly added prose.
7. **Scheduling and space fallbacks.** Proposed behavior adds known timed-task and
   interaction deferral, stable manual recall, pending-state persistence and a
   movable reader when adjacent space is insufficient. Current code only tucks for
   combat and asks the player to make room; it does not implement these additions.
8. **Field Journal.** Earlier scope excluded expanding a journal. The new agreed
   direction includes it. Start with an ordered list of presented entries using
   the existing reader; derive it from the same passages. No separately authored
   recap, generated summary, glossary expansion or second narrative corpus.

## Proposed compiled addon interface

**Proposal for agreement with compiler ownership; no loader/API exists yet.**
Deliver native Zygor Lua and a versioned, declarative Lua sidecar as one verified
package. V1 authoring fields remain unchanged. UI preferences are addon settings,
not new source fields or compiler-enforced presentation policy.

| Interface area | Minimum information the addon needs |
| --- | --- |
| Envelope | Sidecar contract version, source format version, source revision/file hashes, compiler version, native payload digest, required capabilities. |
| Guide identity | Stable logical guide ID and explicit native registration/view mappings, including resume views of the same logical guide. |
| Step mapping | Source step ID to ordered native parts/labels, including one-to-many expansions and explicit absorbed/omitted aliases. Resolve/validate against parsed native objects; do not assume display indices are source IDs. |
| Goal mapping | Authored goal ID when present, plus source step/goal position and revision for diagnostics when no authored goal ID exists. No invented stable semantic identity for an anonymous goal. |
| Passage | Exact title if supplied, exact text with paragraphs, guide-local passage ID, context/moment/chapter type, source anchor, typed requires AST if supplied, optional purpose/thread ID, source order and passage revision. |
| Checkpoint | Stable ID, source-step boundary, typed proof, referenced cross-guide dependencies. Keep it separate from story/history; validate supported mappings rather than invent a completion engine. |
| Provenance | Source file and relevant source keys/locations so a generated mapping or reveal can be traced without displaying technical IDs in ordinary play. |

Illustrative table fragment, **not an approved schema or runnable registration**:

```lua
return {
  contract_version = 1,
  source_format_version = 1,
  package_revision = "<content digest>",
  provenance = {source_revision="<commit>", compiler_version="<version>"},
  requires_capabilities = {"native-label-map-v1", "quest-reward-proof-v1"},
  guide = {id="DEMO-JOURNEY"},
  native_views = {
    {registration="Demo/Journey", payload_digest="<native Lua digest>",
     steps={
       {source_step_id="DEMO/report",
        native_parts={"demo-report-approach", "demo-report-action"}}
     }}
  },
  narration = {
    {id="report-result", revision="<passage digest>", source_order=1,
     type="moment", at_step="DEMO/report",
     requires={quest_rewarded=456},
     title="<exact authored title, if supplied>", text="<exact authored text>"}
  },
  checkpoints = {
    {id="DEMO.REPORTED", at_step="DEMO/report", proof={quest_rewarded=456}}
  }
}
```

The IDs/labels above illustrate the interface; no campaign claim or new quest is
introduced. Field names, digest rules, native-part boundary semantics and capability
names are proposed. In particular, `native_parts` is not itself an encounter event.
A concrete compiler example must demonstrate how approach and action parts bind.

The existing source-map JSON is build evidence outside the installed addon. Extend
and package the necessary resolved information; do not treat its mere existence
as a working runtime protocol. Compiling narration only as legacy `only if` prose
would still leave significance, stable identity and presentation history unavailable.
For the v1 slice, avoid duplicate ungated narration in native goal arrays: Journey,
Story and the original reader should obtain admitted narration from the controller.
Existing untagged legacy prose remains untouched and ordered.

The loader should validate package/mapping compatibility and refuse unsupported
narrative capabilities with a diagnostic, without leaking future titles or changing
native progression. Do not silently substitute a confirmation for unsupported
optional roles, independent alternatives, sticky scope, arrival tolerance or
observable action results. A v1 claim requires demonstrated mappings, not matching
names. Unsupported guides fail validation; supported native gameplay remains the
engine's responsibility. The full vocabulary need not be implemented in the first
slice, but unsupported cases must be explicit.

## Proposed runtime admission and persistence boundary

- Definitions stay private to the narrative controller. Normal presentation
  snapshots expose current admitted context, the selected admitted passage and
  safe pending cues. Journal browsing/search receives only presented records;
  future headings, body text and editorial thread summaries are excluded.
- Evaluate typed conditions as true/false/unknown. Missing `requires` adds no
  reveal restriction, but does not bypass anchor rules. `not unknown` remains
  unknown; all/any preserve uncertainty appropriately. Missing or stale evidence
  never authorizes disclosure. Reuse fresh native observations, not mutable
  completedQuests, manually marked goals or a second quest cache.
- Define a legitimate live anchor encounter explicitly. Extend the native
  lifecycle with observation notifications and origin/reason information; a
  generic FocusStep publication or `quiet` flag is insufficient. Browsing, restore,
  obsolete/already-satisfied skips and unknown-origin calls cannot manufacture
  encounters. Native completion logic itself stays authoritative and unchanged.
- Capture a qualified anchor/evidence ticket before immediate advancement can
  lose the source-step association. A recorded real encounter may wait for delayed
  fresh evidence; a late completed-quest query cannot invent a past encounter.
  The entry/exit timing and exact skip classifications need review with a concrete
  compiled example before implementation.
- A proposal for first presentation is actual visible body content in a Journey
  or reader viewport, with visibility/clipping accounted for; an offscreen row,
  hidden leaf or title-only cue is insufficient. There is no minimum reading time.
- Store encountered/pending and presented facts separately per character, scoped
  to logical identity and relevant revisions. A presented record needs an immutable
  copy of displayed text/title or a resolvable revision archive, so a later package
  cannot make an old history entry display previously unseen replacement prose.
  Storage bounds and update/recovery policy remain decisions; preserve old data.
- Manual recall uses the current selected record. Scheduling can cue new arrivals
  without replacing that selection. Normal advancement never drains a queue through
  repeated forced openings. Folded/reload recovery does not imply reading.

## Smallest recommended next slice — proposal

Agree the interface and encounter semantics first, using the matched, already-played
v1 example. Then implement one bounded vertical slice, without a campaign migration:

1. Emit its native gameplay plus a sidecar; retain existing source-map/provenance
   practices and add a real source-step expansion/registration validation case.
2. Consume a context and reward-gated moment through the existing quest observation
   hooks and an explicitly qualified native-anchor notification. Include a synthetic
   competing passage/chapter in tests to prove ordering and policy selection.
3. Add minimal per-type presentation preferences, a pending queue and a small Field
   Journal list of first-presented entries that opens the existing reader. No new
   journal authoring, generated recaps, search project or new routing engine.
4. Verify immediate advancement, duplicate evidence, combat/interaction deferral,
   manual recall while a new passage arrives, fold, reload and revision changes.
   Negative cases: future browsing, restore/obsolete skip, manual marks, unknown
   predicates (especially negation), wrong package mappings and deferred items
   appearing in history before presentation.

This slice intentionally proves Journey + Story + Field Journal together before a
large skin pass. It must continue to expose native objectives, secure actions,
arrow/waypoints, guide selection and original-viewer fallback. Scheduled narrative
must never become a prerequisite for advancement. Simulations and later real-client
observations are separate evidence; no quest replay on the main character, future
campaign text, GM operations or server mutation is needed for this review.

## Toggle study — proposal only

The player's nearly full-height, roughly half-transparent control is worth
comparing with a narrower recessed spine. Both should attach to the leaf-facing
edge, keep Journey geometry stable, show an intelligible Story cue and preserve
recall. Start with translucent fill and opaque text; hover strengthens the fill.
A transparent appearance still catches clicks: limit the active width and evaluate
world-click interference, movement/resize conflicts and screen-edge flips.

Open-state behavior (seam toggle versus disappearing handle plus leaf X), exact
shape, opacity and width are unapproved design choices. The accompanying control
study uses synthetic text only and is not evidence of WoW rendering or hit testing.
Preserve current reader/material functionality while reviewing these visual options.

## Verification of this review

Canonical v1 files were compared byte-for-byte with the pinned commit. The supplied
steering note was hashed and left intact. No addon or campaign runtime files were
changed and no WoW/server operations ran; existing addon regressions were not rerun
for this documentation-only review. The illustrative Lua table parses under Lua 5.1
without execution. The control study passed structural checks and JavaScript
open/close, seam folding, opacity and state-restoration checks with DOM doubles.
There is no browser in this executor, so layout has not been visually inspected;
this is a concept comparison, not proof of browser or WoW appearance/hit testing.

## Discussion follow-up — compiler sequence and edge control

**Agreed edge behavior, from the owner's follow-up:** retain the general tall,
attached shape, make it much more subtle, and hide it completely while the Story
leaf is open. The existing leaf close action restores the folded handle. This
supersedes the earlier open-seam toggle alternative. Exact shape, opacity, width,
hover response and any new-arrival accent remain visual proposals. The revised
study starts with a 12% fill and 20-pixel edge as comparison values, not addon
settings or approved native dimensions. Its text/content is synthetic.

**Compiler clarification:** there is no Guide Format v1 compiler yet. The legacy
Markdown content builder reviewed above is reusable infrastructure, not a working
v1 translator or a completed narrative interface.

**Recommended sequence, still a proposal:**

1. Agree the minimum sidecar contract and native anchor/mapping semantics with the
   addon consumer. Reuse the v1 source format without adding fields for UI policy.
2. Build a small compiler pilot for the matched route-only/narrated examples:
   validate source and references, translate their supported gameplay into native
   Zygor Lua, emit a declarative sidecar and provenance, and explicitly reject
   unsupported mappings. Adding narration must not change executable gameplay.
3. Develop the minimal addon consumer against those exact outputs: real evidence
   adapters, qualified anchors, per-type presentation, pending versus presented
   persistence, and first-presented Journal recall through the existing reader.
   A small synthetic competing-passage case exercises ordering before expansion.
4. Expand compiler coverage only after the native parser/goal behavior and narrative
   lifecycle tests pass. A full compiler built independently of its consumer would
   leave important mapping and timing assumptions untested.

Starting with this compiler/consumer handshake is recommended. It does not require
waiting for a complete compiler, finishing the visual redesign first, replacing
Zygor, converting active chapters or resetting the player's current guide.

**Work ownership clarification:** the owner explicitly instructed that compiler
implementation must not be created in this chat. Compiler work belongs elsewhere;
this chat supplies addon requirements/interface feedback and UX studies. No compiler
or addon runtime code was added or changed. The revised edge interaction passed
DOM-double checks for subtle defaults, hiding while open, close/recall, focus,
opacity and state restoration. Browser/WoW appearance remains unverified.

## Subsequent compiler review

The owner subsequently authorized a subagent to review the completed compiler and
run it for representative output. See [the actual output review](COMPILER_OUTPUT_REVIEW_2026-11-13.md).
The emitted campaign-owned interface uses one interface_version=1 without capability
negotiation, superseding this note's earlier speculative capability-list fields.
Compiler/source code was not changed. The main remaining work is the addon metadata
consumer and verified native binding/anchor lifecycle; generated output alone does
not demonstrate a playable client integration.
