# One Ban'ethil story moment — 2026-11-11

Implemented on `experiments/adventure-vertical-slice-2026-11-11`, continuing
`b598f8f`. The commit containing this report identifies this increment.
Experimental addon code; no campaign route, journal, interface layout, server,
release version or installed client changes.

## Source and reveal condition

Source repository: `sriak1515/wow-solo-adventure`, pinned revision
`11b7495466eef41ac3d87db145b48da1253a671f`.

- Canonical campaign intent: [KAL-02 STORY, section III](https://github.com/sriak1515/wow-solo-adventure/blob/11b7495466eef41ac3d87db145b48da1253a671f/campaign/Arcs/KAL-02-dolanaar-and-the-sleeping-druids/STORY.md#iii-beneath-banethil).
  Oben's conversation supplies the meaning before the final action; his task is
  distinct from collecting the four relics. This source deliberately withholds
  the details in its general chapter prose.
- Canonical actionable timing: [KAL-02 ROUTE](https://github.com/sriak1515/wow-solo-adventure/blob/11b7495466eef41ac3d87db145b48da1253a671f/campaign/Arcs/KAL-02-dolanaar-and-the-sleeping-druids/ROUTE.md),
  stable step `KAL-02/accept-druid-of-the-claw`: accept **2561** after returning
  **2541**. The following steps distinguish defeating the body from using the
  provided charm. The earlier collected charm alone does not establish this
  conversation.
- Panel prose is copied verbatim from the [authored Ban'ethil editorial benchmark,
  section 4](https://github.com/sriak1515/wow-solo-adventure/blob/11b7495466eef41ac3d87db145b48da1253a671f/experiments/adventure-ux/BANETHIL_NARRATIVE_UX_BENCHMARK_2026-11-11.md),
  **The answer Oben discovers**, also used by `banethil-ux/model.mjs` as
  `revelation`. This is the experiment's authored rendering of the campaign
  moment, not a quotation from STORY or Blizzard quest dialogue. Its published
  source remains an editorial draft; this implementation adopts only this one
  passage and condition. No later outcome appears in the passage.

Player-facing title: **What the charm reveals**. Stable passage ID:
`KAL-02/oben-charm-revelation`. The prototype title and body match the existing
browser study; no new campaign prose is authored here.

Reveal condition: quest **2561 present in a freshly rebuilt player quest log**.
Acceptance is conservative evidence that the player has had the conversation.
Offered dialogue, proximity, charm possession, quest 2541 completion, relic
collection, killing the body, selected step, navigation and manual goal marks
are never substitutes.

For a character who already played the quest, **2561 present in the client's
fresh completed-quest response** is sufficient historical evidence of that same
conversation. It does not infer other story moments or either quest chain's
ending. No replay is required. If the response has not arrived, or the existing
maintenance setting disables the query, absence means unknown: show no passage
until real evidence is received or a prior story record exists.

## Bounded integration

`BanethilStory.lua` holds one passage and one per-character SavedVariables record,
`db.char.banethilStory={version=1,id=...,evidence=...}`. AceDB's existing character
scope supplies character/realm separation. It stores evidence, not read status,
quest progression, reading position or another quest cache.

Two calls in existing `QuestTracking.lua` supply evidence:

1. `QuestTracking_CacheQuestLog` observes the freshly rebuilt `questsbyid` map,
   before native new/lost quest callbacks. Existing log events and the existing
   two-second safety poll both use this path; no new event registration or timer.
2. `QUEST_QUERY_COMPLETE_QuestTracking` observes `GetQuestsCompleted()` immediately
   after retrieval. It never consults the mutable completion table later:
   Zygor's manual goal controls can write to that table.

Capture works even with the experiment off or no guide selected. The first
record persists; repeated notifications, quest disappearance, abandoning the
quest or selecting another guide do not erase an observed conversation.
The observer does not call progression, create waypoints, pause gameplay or
modify quest state.

`GetPresentationSnapshot().context` projects a detached passage from that
record. The current renderer uses its existing story panel, fold/recall controls,
combat tuck and space constraints. The genuine passage takes precedence over
step-local context while retained. Its identity excludes guide and step, so
manual browsing and automatic advancement cannot replace it, reopen a folded
panel or reset its reading position. Existing objective rows remain native
projections. The fixture continues to use its own simulated context and cannot
write this record.

First observation of the accepted quest while live mode is active unfolds the
passage outside combat; inside combat it leaves the existing Story cue. Combat
exit never forces the panel open. Historical recovery and reload leave it
closed with the Story control available. Reload still exits the experimental
UI: `/zgpoc live`, then **Story** (or `/zgpoc recall`) rereads the retained passage.
This single-passage example needs no journal or additional selection interface.
SavedVariables survive a normal client reload/logout; abrupt process termination
before WoW saves them has the usual client limitation.

## Validation and limits

Run `python3 tools/presentation/run_checks.py` and `git diff --check` from the
repository root. Recorded output is in `BANETHIL_STORY_CHECKS_2026-11-11.txt`.
All 30 repository Lua regression scripts pass, along with Lua 5.1 parsing and
XML/TOC load-order checks.

`test_banethil_story.lua` executes the actual `QuestTracking.lua` log refresh,
query callback and safety poll with client API doubles. It covers absent and
unrelated states, 2541 objective completion, manual completion flags, arbitrary
step selection, 2561 acceptance before objective credit, duplicate notifications,
abandonment, per-character isolation, historical recovery and module reload
with the character record retained.

`test_presentation.lua` executes the actual snapshot and UI code with frame
doubles and extracted native progression functions. Added checks cover the real
passage reaching the panel, detached data, fold/recall, navigation retention,
combat at the moment of observation, fixture isolation, closed reload recovery
and a different character. Existing progression, overflow and failure recovery
checks remain in the same run.

These are **simulations**, including SavedVariables retention and combat events.
They do not verify native quest-event delivery, on-disk SavedVariables writes,
or rendering in WoW. The player reported before this increment that the vertical
interface displays correctly and real Zygor steps advance automatically in
3.3.5a. Live story triggering remains **unverified**; no client was run for this
change and no quest replay is requested.

A read-only client check, whenever convenient on a character who previously
completed 2561, can confirm historical recovery: after the normal completed-quest
query, activate `/zgpoc live`, select **Story**, fold it, browse another step,
then reload and activate/recall again. An unplayed character should have no such
passage. A future observation of genuine acceptance can verify automatic
appearance; it is separate from the historical-recovery check. Neither requires
altering the main character or replaying Ban'ethil for development.

## Following passages

Reuse these existing fresh quest-log/query observation points, stable authored
passage IDs and per-character evidence. Each passage needs a source reference
and a conservative quest-state trigger matched to what its prose reveals.
Acceptance can establish a conversation; a later outcome needs its own confirmed
turn-in evidence. Do not derive either from step numbers, manual completion or
time on screen. Verify negative states and reload recovery with the same harness.
The current module intentionally retains one passage; selecting among multiple
retained passages is a separate bounded change, not implemented by overwriting
this record or extending the journal here.
