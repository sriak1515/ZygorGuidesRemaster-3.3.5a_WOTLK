# Agreed adventure flow and fixture specification

Accepted by the owner on 6 November 2026 after reviewing PRODUCT_BRIEF_AND_HANDOFF.md.
This records the next behavior contract. It does not implement a reader, history,
event model, parser syntax, or font integration.

## Main guide contract

Essential context appears in the normal authored flow before its relevant action.
Objectives remain compact, completion-aware, and paired with their directions.
Consequences become eligible only after explicit authored progress signals.
Each current state must make sense even if the preceding state advanced quickly.
Optional reading is never necessary to understand the adventure.

The following is synthetic test material, not Warcraft lore or campaign prose.
Do not copy it into the WIP campaign.

| State | Essential passage | Actions and navigation | Transition |
|---|---|---|---|
| Arrival | Keeper Mara needs the missing training records before the next lesson. She asks you to retrieve them from the upper room. | Talk to Mara; accept Missing Records. Waypoint targets Mara. | Accept confirmed |
| Retrieval | Retrieve the records for Mara's next lesson. | Enter the tower; reach the upper room; collect Training Records 0/1. Separate useful waypoints for entrance and upper room; directions attached to their actions. | Collection confirmed |
| Return | You have the records. Bring them back to Mara so she can prepare the lesson. | Return to Mara; turn in Missing Records. Waypoint targets Mara. | Turn-in confirmed |
| Aftermath | With the records returned, Mara can prepare the lesson. She asks you to meet the other students in the courtyard. | Go to the courtyard. Waypoint targets the meeting place. | Courtyard arrival confirmed |

Collection alone must not reveal the turn-in consequence.
Waypoint coordinates must be verified in the selected test location during fixture
implementation; synthetic names must be labelled as fixture targets. No invented
coordinates or distant arrows standing in for intermediate destinations.

## Optional reader

Prototype a separate Zygor-managed reader first. Defer Azeroth Library integration
and shared content ownership until those sources are inspected.

A discoverable "Read: The training records" entry opens background that is safe
at the current progress state. A separately authored follow-up becomes eligible
after turn-in. Actions remain visible and usable while the reader is open.
Automatic progression continues. The reader preserves the selected passage and
scroll position; it does not replace its contents when the live step changes.
Closing the reader leaves the live guide on its current task.

## Continuity

Recent story exposes eligible essential passages in authored order, using the same
reader. Record each passage once when its explicit progress condition becomes
eligible; do not infer reading from elapsed time, scrolling, or completion.
Retain the current chapter's passages across fast progression and reload, scoped
to character and guide. Reviewing history must not move the live guide backward.

Browsing an uncompleted future step must not unlock consequences or add them to
history. Already-completed states on loading a guide need explicit eligibility
reconciliation, rather than replaying rewards or assuming every preceding step
occurred. Unknown progress must not unlock aftermath.

## Fixture revision

Keep the existing 11 fixtures and their indices as technical regressions. Preserve
overflow, long names, fixed completion, legacy rows, split behavior, refresh,
scale, inline actions, and the optional real-item case. Existing split expectations
describe current behavior and do not establish the future product architecture.

Add a separately selectable adventure walkthrough with deterministic fixture events:
accept, collect, turn in, and arrive. Core flow must not depend on real quests,
inventory, faction, class, or campaign changes. These controls are test-harness
controls, not proposed player-facing troubleshooting.

| Case | Setup/action | Expected evidence |
|---|---|---|
| Arrival | Reset walkthrough | Who/why precedes talk and accept; destination is clear; optional reader closed |
| Retrieval | Emit accept | Essential purpose remains understandable; entrance then upper-room waypoints; attached directions; collect 0/1 |
| Return | Emit collect | Collect completes; return action appears; turn-in consequence and follow-up remain unavailable |
| Aftermath | Emit turn-in | Consequence appears alongside courtyard action; follow-up reading becomes eligible |
| Reader open | Open background during retrieval; emit collect | Current return action remains usable; selected passage and reading offset stay unchanged; closing preserves live task |
| Fast progression/reload | Emit accept, collect, turn-in rapidly; reload | Current courtyard task is understandable; prior eligible passages recoverable once, in order; no future revelation |
| Future browsing | Browse aftermath before turn-in | No consequence unlock or history entry |
| Repeat refresh/events | Repeat current event and refresh | No duplicate history or unintended transition |
| Reset | Reset fixture run | Fixture progress/history cleared without changing campaign progress or unrelated preferences |

Each case must have an explicit initial state and reset path. Snapshot cases may
select a state for inspection, but progression tests must execute the transitions.
Retain native click/completion behavior; fixture-only events must not grant items,
consume inventory, or alter real quest state.

## Focused review and ledger

First client question: Can the owner complete this sequence without opening
optional reading, understand why each task matters, and recover a passage after
it advances quickly?

| Item | State | Next evidence |
|---|---|---|
| Experience contract | Agreed | Implement the walkthrough against this document |
| Separate Zygor reader | Agreed prototype direction; unimplemented | Open/close and progression case |
| Recent story | Agreed prototype direction; unimplemented | Fast progression/reload, deduplication, future browsing |
| Event-gated aftermath | Agreed; unimplemented for this walkthrough | Collection vs turn-in case |
| Adventure fixtures | Specified; unimplemented | Deterministic state and transition checks |
| Existing technical cases | Retain | Regression checks appropriate to implementation changes |
| Normal font controls | Next implementation pass | Primary/secondary controls plus reading-size setting and preference migration |
| Native client validation | Pending | One focused walkthrough result, with failures/not-tested recorded |
| Library sharing and skin refinements | Deferred | Inspect content projects / settle behavior first |

No parser tags or classification of untagged prose are established here.
Preserve unknown rows and existing content access. Owner retains campaign writing,
format, timing decisions, and content budgets. Automated checks do not establish
native rendering, waypoint usefulness, or secure-input behavior.
