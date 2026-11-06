# Gameplay presentation and recovery — two-fixture review specification

6 November 2026. Current behavior proposal on prototype/vertical-parchment.
The owner accepted the first concise Iverron treatment as good enough for this
design exercise. Do not expand or polish it during this pass. Ban’ethil remains
the richer reference, with tone open to later refinement.

This document defines a small next prototype to review. It does not claim that
the reader, event gates, recovery, or font integration are implemented or that
the owner has approved every behavior below. No uploaded guide source is included
or changed here. No new parser syntax is established.

## The player-facing experience

One main guide shows essential story and current actions. A small persistent
Recent story control opens recovery. When the author has supplied relevant
optional depth, a descriptive reading link appears below the associated actions.
The separate reading window is shared by optional background and Recent story;
they remain clearly distinguished within it.

Essential text remains visible in the normal authored flow. Closing or ignoring
the reading window never hides motivation, relevant discoveries, or aftermath.
No mandatory reading screen, Next-to-acknowledge step, dwell time, or read detector.
Existing genuinely interactive/confirmation content must remain accessible:
this proposal does not remove all legacy confirm rows.

The first prototype uses a Zygor-managed reader to test behavior. Shared source
ownership and Azeroth Library integration remain deferred.

## View 1: a simple story, no optional entry

These are three player moments, not consecutive guide steps. They repeat the
concise Iverron treatment used in chat. Preserve intervening route actions when
building the fixture rather than treating this as a route rewrite.

After Dirania introduces A Good Friend:

> Iverron usually visits Dirania every day, but today he is several hours late.
> He often explores near the northern cave, where spiders gather. She asks you
> to look for him.
>
> **Find Iverron.**
>
> Follow the waypoint towards the northern cave.
>
> Recent story

After speaking with Iverron and accepting A Friend in Need:

> A spider bit Iverron while he was exploring the cave. Dizzy from the poison,
> he asks you to fetch Dirania—she may know how to help.
>
> **Return to Dirania Silvershine.**
>
> Recent story

After successful antidote delivery, alongside the next task:

> Iverron drinks the antidote and begins to feel better. He will rest here while
> he recovers. With the medicine delivered, you can return to Gilshalan’s search
> for a spider egg.
>
> **Return to Shadowthread Cave.**
>
> Recent story

The egg action requires the egg quest to have been accepted, as in the reviewed
route. It is not a universal post-rescue instruction for every guide.

During the delivery, display the actual current timer and this compact guidance:

> **Deliver Iverron’s Antidote.**
>
> Go straight to Iverron. The medicine remains effective for only five minutes.
>
> Recent story

In the client, show the real remaining time, not a fixed countdown reset on
refresh/reload. The five-minute sentence describes the initial validity period.
In the fixture, use an isolated simulated clock; never wait five real minutes.

There is no optional lore entry for this sample. Recent story is recovery, not
a signal that each quest has a separate article. During timed travel it remains
available without opening automatically or pausing the deadline.

## View 2: richer essential story with a reading invitation

Use the researched content in [the Ban’ethil storyboard](BANETHIL_STORYBOARD.md).
For example, after Athridas’s initial quest introduction:

> Athridas has heard nothing from Gaerolas, the warden protecting Ban’ethil’s
> sleeping druids. Their slumber honours a pact with Ysera, the green dragon
> who watches over the Emerald Dream—a spirit realm beyond the waking world.
> Find Gaerolas in Starbreeze Village and learn whether his charges are safe.
>
> **Find Gaerolas Talvethren in Starbreeze Village.**
>
> **Read: Why do the druids sleep?**
>
> Recent story

This travel action appears when it is the current route action, not over unrelated
intervening objectives. At the initial NPC, keep the actual Talk/Accept actions.
The existing storyboard supplies the later entrance reminder and Oben scenes.

The reading link opens the complete “Why do the druids sleep?” passage in that
storyboard. Do not replace it with a generic placeholder. Its history enriches
the inline explanation; it does not contain the only definition of Ysera or the
Dream. Reuse the same entry at the later relevant reminder, without duplicating
it in the reader. No fresh article for every chest, relic, or NPC.

## View 3: reader open while the task progresses

Main guide remains at the live action, for example:

> **Collect a Shaman Voodoo Charm — 0/1**
>
> Defeat Gnarlpine Shamans in the next room.

Alongside it, the reader can still show:

> **Why do the druids sleep?**
>
> [The full previously selected background passage]
>
> Close

This bracketed line explains layout only; fixture content must use the actual
passage. On collection, the main guide updates according to the native route,
including the next relic stop. Reader title, body, and scroll position do not
change. Opening, scrolling, or closing the reader never controls quest progress.
Closing does not jump to an old guide step.

Start the reader adjacent to the guide with a screen-edge-aware position. Allow
moving it. Do not cover current objectives by default. If two windows cannot fit
legibly at the owner's chosen scale, record a failed layout case; do not shrink
text or replace the objective window silently. Placement is a native-client check,
not established by this document.

## Progression and recovery rules

- Completion remains authoritative in the native quest/guide engine. Presentation
  does not grant credit, consume items, or mark reading complete.
- Story availability uses explicit authored associations and progress evidence.
  Arriving at an NPC or selecting a guide step is not proof that a conversation
  or consequence happened.
- A native step can contain both turn-in and acceptance. Refresh story on the
  relevant event even when the step number does not change.
- Show aftermath beside the next actual action after its event. If automatic
  progression is immediate, retain the passage in Recent story without a delay
  or required click. A longer-lived inline treatment remains reviewable if the
  recovery case proves insufficient.
- When returning to an interrupted story, use an authored reminder, as at the
  Ban’ethil entrance. Do not automatically carry old story text onto unrelated
  quests or generate a recap from untagged paragraphs.
- Preserve unknown legacy rows and their order. Do not infer that all plain text,
  or every existing context row, is optional.

Recent story opens a list of essential passages unlocked in the walkthrough.
Selecting an entry opens that passage in the separate reader; it does not rewind
the main guide or its waypoint. Available background entries have a separate
Background list so they remain discoverable after their inline link leaves view.

History is scoped to character, guide, and walkthrough; persists across reload;
and records each stable passage ID once. Preserve chronological unlock order,
with authored order as a tie-breaker for events observed together. No Read/Unread
badges: eligibility is known, reading is not. Future-step browsing must not unlock
entries. Unknown historical progress is not proof that all prior story happened.
For these fixtures, event evidence is explicit; general campaign backfill and
history retention beyond a chapter remain separate decisions.

Reader starts closed after reload. Reopening a passage restores its position
during the same session; restoring scroll positions across reload is not required.

## Minimum fixtures and acceptance evidence

Build separate product fixtures; preserve all 11 existing technical fixture
indices. Fixture event controls belong to the test harness, not ordinary play.

| Fixture | Simulated sequence | Required result |
|---|---|---|
| Iverron: ordinary progression | Quest introductions → ingredients → prepared delivery → successful turn-in | Concise context with actions; no optional link; farewell after success only |
| Iverron: timed travel | Start delivery; advance simulated time; reload; expire or succeed | Remaining time preserved; no reading hold; expiry cannot produce rescue aftermath |
| Iverron: fast completion | Complete delivery and advance immediately | Main guide shows next action; farewell recoverable once without rewinding |
| Ban’ethil: background | Unlock introduction; open full background; advance route | Actions usable; same passage/scroll retained; close preserves current task |
| Ban’ethil: interleaving | Two relics → Oben → charm → relic → exchange → body/charm → relic → farewell | Source route retained; motive still understandable at each significant transition |
| Ban’ethil: event gates | Refresh/repeat events; kill without charm; browse future step | No duplicate history; kill alone cannot release spirit; no premature farewell |
| Both: reload and layout | Reload at known state; test compact/minimum frame and normal scales | Eligibility/history preserved; objectives reachable; no clipped text or secure-action loss |

Each fixture has Reset, ordinary progression, and direct snapshot controls.
Reset affects only fixture state/history, not campaign progress or unrelated
window settings. Direct snapshots cannot substitute for transition checks.
Use simulated inventory, objectives, and timer in fixtures; no real rewards,
consumption, or live quest changes. A real-route client checkpoint is still needed
for cave navigation and secure item behavior.

## Presentation implementation boundary

Story uses reading typography, objectives the normal primary text control,
directions the normal secondary control, and reader text a dedicated reading-size
control in the same settings interface. Keep source text intact; no truncation,
automatic rewriting, universal prose budget, or mandatory frame enlargement.
Scroll when necessary; use the compact and long-content cases to evaluate whether
current actions remain practical. No new skin round is part of this work.

The next code pass must establish an explicit minimal content/event contract for
fixtures before implementing persistence. No parser redesign or campaign
conversion is authorized merely by this document.

## Current status

| Item | Evidence/status |
|---|---|
| Concise Iverron content | Accepted as sufficient for this design exercise; preserve |
| Ban’ethil content | Useful reference; tone refinements deferred |
| Shared main-guide presentation | Specified here; native layout unverified |
| Separate reader and Recent story | Proposed behavior; unimplemented |
| Fixture transitions and reload | Acceptance cases specified; not run |
| Normal font control integration | Planned; unimplemented |
| Uploaded Shadowglen source | Unchanged; not copied into repository |
| Campaign routing and library integration | No changes |

One focused review question for the next build:
Can the owner follow both adventures without opening background, keep playing
with the reader open, and recover a missed passage without losing the live task?

Sources: public quest dialogue for [A Good Friend](https://wotlkdb.com/?quest=4495),
[A Friend in Need](https://wotlkdb.com/?quest=3519), and
[Iverron’s Antidote](https://wotlkdb.com/?quest=3522); researched Ban’ethil sources
and the public reference route are recorded in BANETHIL_STORYBOARD.md.
