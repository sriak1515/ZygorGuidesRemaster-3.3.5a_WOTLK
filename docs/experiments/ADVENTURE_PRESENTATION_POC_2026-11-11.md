# Adventure presentation integration PoC — 2026-11-11

**Conclusion: GO WITH CONDITIONS. Developer experiment, not ready for live play.**

The custom presentation can consume detached Zygor snapshots while the existing
engine advances and manual navigation continues in simulation. No new quest or
progression evaluator was built. Real 3.3.5a behavior remains unverified. Do not
install this experiment for the main character or use an ordinary story session
as a debugging session.

## Baseline and authority

- Campaign: `sriak1515/wow-solo-adventure`, experiment branch at
  `632a224`; read AGENTS, CURRENT_STATE, DECISIONS, WORKFLOW, the feasibility
  report and Ban'ethil redesign HTML/JS, model, design direction and review.
- Fork inspected: `136e0251a06b5d8f3c46334e5b5e29b865cc0c0c`,
  `prototype/vertical-parchment`, also verified against its remote branch.
- The earlier feasibility report inspected main at
  `d2aae8d0f1f3782d964e4179907b215aab484787`. Main still points there.
  This experiment intentionally extends the actual checked-out prototype,
  including its existing parchment renderer, rather than pretending it is main.
- Implementation branch: `experiments/adventure-presentation-poc-2026-11-11`.
  The commit containing this report identifies the implementation revision.
- Installed addon lineage/hash, actual client build and player state: **unknown**.
  No deployment, server access, character changes or campaign STORY/ROUTE edits.

## Findings and integration points

All source paths below are under `ZygorGuidesViewerRM/`.

| Source / function | Finding or change |
| --- | --- |
| `ZygorGuidesViewer.lua`: `SetGuide`, `FocusStep`, `SkipStep` | Existing guide, step, persistence, manual pause/skip, requirement checks and waypoint changes remain authoritative. Publish after FocusStep, including quiet changes. |
| `Goal.lua`: `GetStatus`, `GetText`; `Step.lua`: `IsComplete` | Projection uses existing goal evaluations; it does not read or maintain a second quest cache. |
| `QuestTracking.lua`: `QUEST_LOG_UPDATE` | Existing quest refresh and completion calls remain untouched. |
| `ZygorGuidesViewer.lua`: `TryToCompleteStep` | **Visibility guard confirmed before changes**: hidden host or alpha < 0.1 stops completion. Existing skip policies and jumps remain untouched. Publish after normal completion evaluation. Early returns are covered by opt-in polling. |
| `Presentation.lua`: `GetPresentationSnapshot`, `SubscribePresentation`, `Publish` | New version-1 detached data contract, deduplicated notifications, failure containment. |
| `PresentationFixture.lua` | New independent Ban'ethil snapshot fixture. No registered guide, quest events, quest-cache writes, persistence or server calls. Do not confuse with the pre-existing `/zgadventure` walkthrough, which selects a guide. |
| `PresentationUI.lua` | Small scrolling status panel, Previous/Next/Fallback, session-only activation and recovery. No vertical redesign, journal, bindings or live story-unlock evaluator. |
| `ZygorGuidesViewer.lua`: `UpdateFrame`, `UpdateFrameCurrent`; `ZygorGuidesViewerFrame.lua`: `ZygorGuidesViewerFrame_OnUpdate` | In experimental live mode, dispatch to snapshot presentation; consume native render-request flags and retain fast-forward timing. Existing repeating completion timer remains active. |
| `Parchment.lua`: `ParchmentEnabled` | Suppress parchment during live mode so its reading hold cannot pause the engine. Suspend its secure buttons/background before swapping presentation. |
| `ZygorGuidesViewer.lua`: embedded `ActionButtons_Refresh`, `InlineButtonsEnabled`; `TargetPreview.lua`: `TargetPreview_Refresh` | Prevent old action overlays/preview from returning during live mode. Actual loaded action-bar implementation is embedded in the main Lua file; standalone `ActionButtons.lua` is not loaded and was not changed. |
| `files.xml` / TOC | Load adapter, fixture, UI after Goal, frame definitions and Parchment. |
| `Pointer.lua`: `ArrowFrame_OnUpdate`; `Waypoints.lua`: `SetWaypoint` | Unchanged. Pointer's hide-with-guide check sees the same visible engine host. The snapshot copies the current arrow target; it does not set or recalculate one. |

### Visibility and fallback

Live mode replaces visual children **inside the existing visible, opaque host**.
It does not hide, move offscreen, make transparent, replace or reparent that host.
Activation requires the host already be visible with alpha >= 0.1 and requires
being out of combat. Its dimensions, anchor and scale are retained. The guard
itself is unchanged. Thus there is no new interpretation of hidden-guide pause
or hide-with-guide arrow behavior.

Original children and the optional UIParent action-bar/preview surfaces are
hidden with their previous shown states recorded in memory. Fallback restores
them and asks the existing renderer to rebuild using the **current** engine state.
This restores the configured baseline presentation (including parchment when
enabled), rather than rewinding guide progress made during the experiment.
No mode, fixture or snapshot is written to SavedVariables. Native live progression
and manual Next/Previous still save normally through the original engine.

`/zgpoc off` and the Fallback button exit. In combat fallback is queued until
`PLAYER_REGEN_ENABLED`, avoiding protected-frame restoration in combat. Reload
always exits the experiment because activation is session-only. Listener or
projection failures restore fallback outside combat or queue that restoration.
A snapshot failure drops subscriptions; consumers must subscribe again after
repair. Widget-creation failures also attempt immediate fallback. Actual secure
frame behavior still needs a client test; simulated recovery is not certification.

### Snapshot contract

- `ZGV:GetPresentationSnapshot()` **always returns live**, fresh detached tables:
  `version=1`, `source`, `available`, guide ID/title, step index/total/optional
  authored label/title, visible current-step goals, paused flag and navigation.
- Goals retain original indices; include action, quest ID, objective index,
  native status, native progress detail, rendered text, route-group flag and
  authored coordinates. Progress is the native optional value, not a newly
  inferred count. Consumers must tolerate nil and nonnumeric detail.
- `navigation` copies scalar continent/zone, normalized x/y, type and title from
  `Pointer.ArrowFrame.waypoint`. Authored goal x/y use guide coordinates, normally
  percentages. Neither is floor-aware. Missing target is an empty table.
- `ZGV:SubscribePresentation(callback)` returns an idempotent unsubscribe closure.
  Callback receives `(snapshot, reason)`, where reason is `step` for identity/source
  change and `progress` for other data changes, including navigation/text.
  Each callback receives its own copy. Consumers obtain initial state explicitly.
- `ZGV.Presentation:Snapshot()` selects live or the opt-in fixture source for the
  developer display/notifications. Notifications include `source`; consumers
  requiring live-only observations must reject `source ~= "live"`.
- Native FocusStep/completion hooks publish when subscribed; a 0.2-second poll
  catches navigation/text changes and native early-return paths. No subscriptions
  means no snapshot polling/evaluation. This is a small experimental facade,
  not a promise that all internal fields are stable or all intermediate engine
  transitions are atomic.
- Live snapshots have **no story-unlock claim**. Fixture `story` is explicitly
  simulated. Future earned story requires actual accept/reward proof and authored
  markers; current step or manual Next is insufficient proof.

### Concurrent objectives

Multiple goals of the **current step** are available now. Native route groups
select among goals within that step; sticky completion is not an arbitrary
geographic index across a guide. Parsed other steps may be accessible internally,
but they include future and conditional work and are not safe to aggregate blindly.

Concrete already-played example: `Guides/Leveling/ZygorGuidesAlliance.lua`, steps
75–82 (around lines 1090–1124), splits the relics and charm across different steps.
The existing test walkthrough also separates several Ban'ethil scenes. No compiled
campaign KAL-02 route was identified in this checkout. The five-goal new fixture
proves display concurrency only; it does **not** prove the installed route groups
those goals. A later bounded authoring/compilation change must express co-active
work in an engine-supported step, or establish an explicit, spoiler-safe authored
selection contract. No cross-step aggregator or guide edits are included here.

## Evidence levels

| Level | Actual result |
| --- | --- |
| Static | All top-level addon Lua parses under installed native Lua 5.1; existing BOMs stripped in memory as in the repository checker. TOC/XML adapter loading order and single inclusion verified. `git diff --check` passed. |
| Simulated | **29/29** repository Lua test scripts pass, including the new presentation test and existing parser, goal, navigation, guide and UI regressions. Frame and goal doubles do not model WoW's secure execution or real quest events. |
| New simulation coverage | Detached snapshot and listener copies; authored label and goal IDs; objective and waypoint notifications; unchanged-data deduplication; actual source-extracted `TryToCompleteStep`, `FocusStep`, `FocusStepQuiet`, `SkipStep`; actual renderer dispatch guards; hidden/alpha guard failure; visible experimental auto-advance and persistence; manual Previous/Next and waypoint calls; two objective orders; story independent from objective completion; fixture commands never invoke SetGuide/SkipStep or change native guide/step/db; switching, combat-deferred fallback; evaluator/listener failure recovery; module reinitialization discards mode/fixture. |
| Real client | **User-reported fixture startup FAILURE** on the initial PoC; see follow-up below. No agent-accessible WoW client environment was identified. Corrected startup, actual quest-log updates, automatic progression, pointer routing/arrival, secure buttons/combat, visual layout, logout/reload persistence and native fallback remain unverified. |

The existing Python/Lupa checker could not run because Lupa is absent. The new
dependency-free runner executes the same repository Lua test scripts using
installed `lua5.1`, with the required addon-directory argument. This is the evidence
behind the results above; no packages were installed to obtain it.

## Reproduce without replaying content

Offline, from the experimental checkout:

```sh
python3 tools/presentation/run_checks.py
lua5.1 tools/presentation/test_presentation.lua ZygorGuidesViewerRM
```

The offline harness loads the actual new modules with frame/goal doubles and
extracts native engine functions from source, so it checks coexistence beyond
merely drawing sample rows. It does not load the entire WoW addon in a client.

For later **controlled client testing only**, use a separate test installation
and test character with separate WTF/SavedVariables; retain the known-good addon.
Record the experimental commit, package hash, client build and pre-test active
guide/step/waypoint. Do not copy this experiment into the main character's setup.

1. Out of combat, `/zgpoc fixture`. Run `goal 5`, then `goal 1` through `goal 4`
   (prefix each with `/zgpoc`). Reset and reverse the order. No story appears
   merely from collecting all five. `story` shows simulated context;
   Previous/Next change only the fixture. The old guide remains usable.
2. `/zgpoc off`; check the original active guide/step/arrow are unchanged by
   fixture commands. Repeat fixture activation, then `/reload`: experimental
   UI and fixture must be gone, with normal engine persistence retained.
3. With an already-known disposable quest and existing matching guide on a test
   character, record initial state, show the original guide, then `/zgpoc live`.
   Use normal quest actions only; verify quest-log partial updates and completion
   advance the same engine. No Ban'ethil replay or synthetic server state needed.
4. Check Previous/Next manual semantics, automatic skipping, travel target/arrival,
   and arrow hide-with-guide settings. Compare live snapshots to the original UI.
5. Test Fallback, `/zgpoc off`, combat-deferred fallback and `/reload`; verify current
   guide/step/navigation persist. Repeat once with the baseline's conventional
   renderer in a separate test profile if it differs from the configured parchment
   renderer. Do not modify the main profile to obtain this coverage.
6. Record actual observations and client errors. Stop at a mismatch and return
   to the known-good test addon. No ordinary gameplay diagnosis is required.

## Conditions and next milestone

GO for a **small controlled client capability check**, not a full UI build.
First verify installed/package lineage and run the client-only checks above on a
test character. Then author one bounded concurrent-goal test step using supported
syntax, without changing campaign story. Only after those gates should this
versioned projection feed the already-established vertical design. Live earned-story
markers, persistent presentation history and any journal remain separate work.

## Client startup correction — 2026-11-11

The user reported `/zgpoc fixture` failing at 17:04:18 in
`UIPanelTemplates.lua:255` / `ScrollFrame_OnLoad`, called by
`PresentationUI.lua:26`. This is actual client evidence of a **failed initial
fixture startup**, not a passed client test. The addon list/client report does
not establish which character or installation was used; no assumption is made.

The PoC created an anonymous frame inheriting `UIPanelScrollFrameTemplate`.
Wrath's template expects a frame name when resolving its scrollbar children.
`PresentationUI.lua` now supplies a unique `ZGVPresentationPOCScroll<N>` name
for each activation, avoiding reuse of frame names after fallback/switching.
No progression, quest state or persistence behavior was changed.

The frame double now models the template's name concatenation and rejects
reused names. It reproduced the initial error before the production fix, then
passed with the fix, including repeated live/fixture switches. All 29 repository
Lua scripts and static checks passed again. **The correction has not been
verified in the actual client.**

For a narrow retest in the isolated test setup, update `PresentationUI.lua` from
the commit containing this correction, `/reload`, then `/zgpoc fixture`. Verify
that the panel opens without the reported error. Exit with `/zgpoc off`, reopen
once to check repeated activation, and exit again. Stop there if another error
appears; no story replay or real quest action is required for this startup test.
