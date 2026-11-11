# Adventure vertical presentation slice — 2026-11-11

Experimental implementation, **not released for normal gameplay**.
Branch: `experiments/adventure-vertical-slice-2026-11-11`.
Base: PoC `852f241dc05e84ec21a222eb53ae6554e49697b8`.
The commit containing this report identifies the implementation revision.

## Result and chosen boundary

The status dump is replaced by a fixed objective guide with separate rows,
native action icons/checks, exact native objective text, attached hints, and
independent overflow scrolling. A readable story panel unfolds beside it;
folding, recalling and combat interruption do not move the guide or change
progress. There is no movement/timer dismissal or reading acknowledgement.

This increment tests the core composition and interruption behavior. It does not
implement a journal, persistent story history, live earned-story proofs, cross-step
objective aggregation, new guide syntax, or secure item/spell buttons. Live rows
are a read-only projection; Previous/Next still delegate to Zygor. Use **Existing
UI** for native goal clicks, confirmations, item/spell actions and other controls.
This limitation is one reason the experiment is not a normal gameplay release.

The player reported that the **prior PoC** fixture and live modes open in WoW.
That supersedes the earlier reports' pending-startup status, but does not verify
this revision's layout or real quest updates. No WoW client was run by this agent.

## Investigation and design decision

Read the project AGENTS, CURRENT_STATE, DECISIONS and WORKFLOW from
`sriak1515/wow-solo-adventure` main, plus the UX experiment and presentation
handoff. Its November 8 play-position snapshot is historical; the user's current
instruction authorizes already-played Ban'ethil simulations only.

Design reference: UX branch `experiments/adventure-ux-comparison-2026-11-11`,
commit `632a224b3804f0729f1964d93012608dcfbda641`, especially:

- `experiments/adventure-ux/banethil-ux/DESIGN_DIRECTION_2026-11-11.md`
- `banethil-ux/REDESIGN_REVIEW_2026-11-11.md`, `redesign.js`, `redesign.css`,
  `model.mjs` under that same experiment directory.
- The earlier contextual-adventure README, for the contrasting timed treatment.
- `ZYGOR_PRESENTATION_POC_HANDOFF_2026-11-11.md` on handoff branch `11b7495`.

The later Ban'ethil vertical candidate is the reference: compact fixed guide,
left-hand story, deliberate fold, no movement timeout, combat tuck and recall.
Its journal and persistent earned-history model are deferred. HTML pixel sizes
are not copied literally into WoW's scaled logical units.

Inspected `Parchment.lua`, its partition/fill/scroll routines, background reader,
secure overlays and update lifecycle, the product brief/storyboard, and the PoC
adapter, fixture, dispatch and recovery tests before implementing this slice.

| Existing piece | Decision |
| --- | --- |
| Parchment material, objective icon atlas, locale font selection | Reuse the bundled paper texture for reading, same atlas mapping, and locale font selection. Objective guide uses restrained dark chrome. No new assets/dependency. |
| Parchment native row/secure renderer | Leave intact for fallback. It consumes native goal objects and owns secure overlays, rather than detached snapshots. Do not couple it to this display. |
| Parchment split/full-panel reading | Do not reuse; objectives must retain their position and viewport when story unfolds. |
| Parchment plain-row checks | Reuse `IsPlain` only to qualify explicitly marked `goal.context` rows. Unknown prose and interactive rows stay in the ordered main flow. |
| PoC snapshot and failure handling | Extend additively and retain; no second quest cache or completion evaluator. |
| PoC activation/host/fallback | Retain the visible opaque engine host, geometry, scale, native guards, session-only mode and deferred combat fallback. |

## Behavior and authority

`Presentation.lua` adds optional `role` and `hint` fields to each detached goal.
Only explicit `goal.context` passing Parchment's passive-row check receives
`role="context"`; all other rows remain objectives in original order. This is
current-step authored presentation, **not** a claim that a quest was accepted or
rewarded. Merely selecting another step never backfills earned history. Live
mode normally has no separate story when the guide supplies no explicit context;
untagged introductory prose remains in the main flow.

The fixture supplies `context={id,title,body}` from the already-played Ban'ethil
HTML model, reused verbatim. The starting scene assumes Oben's request has
already been accepted. Four relics and the charm are concurrent, independent
presentation data. They do not prove that the installed real guide groups these
objectives; the older leveling guide distributes them across steps.

`goal 1` through `goal 5` toggle simulated counters. `story` represents a separate
simulated quest exchange, requires the simulated charm, and changes context to
the existing revelation passage plus the practical follow-up objective. Neither
all-complete counts nor Next/Previous manufactures that event. Once supplied,
manual fixture navigation does not revoke it. This is a bounded scene harness,
not a quest-state validator or real quest event injection.

Routine progress updates refresh rows without reopening a folded passage or
resetting its reading position. A changed context identity opens automatically
outside combat; inside combat it leaves a recall cue. Combat tucks an open
passage, retaining its scroll and cue; combat exit does not force it open. Story
can be deliberately recalled, including during combat. Folding/recalling never
sets pause, grants credit, or records comprehension. Reload exits the experiment;
no story history or reading positions persist across reload in this increment.

The fixture guide is 360 × 560 logical units at the lower right. Live mode keeps
the existing host's dimensions, anchor and scale, so its guide may be shorter.
Story width is at most 470 logical units and uses whichever side has room. If
neither side has 280 units available, the passage remains available and the
control says `Story (make room)`; it never covers the objectives. Native viewport,
scale, HUD overlap and small-screen behavior still require visual verification.
Primary/secondary font preferences and the existing parchment reading-size
preference are consumed without profile writes, with display bounds for legibility.

**Existing UI**, `/zgpoc off`, or reload restores the configured original viewer
(including Parchment when enabled). Native progress made during live mode stays
current; returning does not rewind it. Combat restoration remains deferred to
combat exit. Fixture commands do not select a guide, write SavedVariables,
change the native guide/step, send quest events, or access the server.

## Evidence and reproduction

Run from the repository root:

```sh
python3 tools/presentation/run_checks.py
git diff --check
```

**Passed:** top-level addon Lua parses under Lua 5.1, XML/TOC load ordering, all
29 repository Lua regression scripts, and whitespace validation. Recorded output:
`ADVENTURE_VERTICAL_CHECKS_2026-11-11.txt` alongside this report.

The expanded presentation test runs the actual adapter/UI with frame/goal doubles
and source-extracted native advancement/navigation functions. It covers detached
snapshots, native visibility/alpha guards, auto/manual advancement and persistence,
fixture isolation, exact counters/hints/complete icons, quiet refresh, explicit
context classification, charm/story gate, Next without story proof, new context,
fold/recall, long text overflow, independent scroll retention, left/right placement,
insufficient room, simulated/native-event combat tuck, switch/fallback, deferred
combat restoration, listener/evaluator faults and module-reset session state.

These are **simulations**, not evidence of native pixel layout, real quest-log
updates, real secure execution, or actual client reload behavior. The prior PoC's
startup confirmation is the only client evidence supplied in this session.

## Smallest next client checkpoint

Use an isolated test addon/profile with the known-good setup retained. No ordinary
story session, Ban'ethil replay, server changes or campaign edits are needed.

1. `/zgpoc fixture`: inspect five rows and the separate request panel. Fold/recall
   with the UI. Toggle `/zgpoc goal 1`; verify the folded panel stays folded.
2. `/zgpoc goal 5`, then `/zgpoc story`: inspect the new passage and follow-up while
   the guide stays fixed. `/zgpoc combat`, `/zgpoc peace`: verify tuck, cue and
   deliberate recall. These commands simulate presentation interruption only.
3. Check both scroll areas, minimum host size, normal UI scale/HUD fit, **Existing
   UI**, reactivation and reload. Record this experimental commit and client build.
4. Separately, on a disposable character with an already-known available quest,
   compare one genuine partial quest update and completion in `/zgpoc live` with
   the existing interface. Verify automatic advancement, arrow behavior and
   fallback, including a real combat interruption. Stop at the first discrepancy.

After that checkpoint, address the demonstrated layout failure, if any. The next
functional increment should restore native objective interactions/secure actions
through a guarded binding to the current engine goal. Earned-story persistence
needs an explicit authored signal/proof contract; do not infer it from selected
steps or expand into a journal before that contract is established.

No canonical STORY/ROUTE or compiled campaign content, existing Parchment behavior,
server state, default branch, release metadata or deployment was changed.
