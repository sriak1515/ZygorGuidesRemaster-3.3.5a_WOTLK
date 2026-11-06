# Ban’ethil adventure storyboard — review draft

6 November 2026. Content and behavior study for prototype/vertical-parchment.
This replaces the training-record example as the working review reference.
It is not an implemented UI, final campaign prose, approved reader architecture,
or a change to any playable guide. Narrative tone remains open to refinement.

## What to review

Read the main-guide examples without opening optional reading. They should make
the adventure understandable and enjoyable. Then read the optional passage:
does it add enough to be worth opening? Finally, inspect the fast-progression
example: can a missed discovery be recovered without moving the live guide?

This is an experience storyboard, not a pixel layout. Indented directions belong
to their objective. Story paragraphs have reading typography, objectives have
compact action typography, and neither depends on the old Context split.
Objective counts below are illustrative fixture states.

## Route evidence and boundaries

Reference route: ZygorGuidesViewerRM/Guides/Leveling/ZygorGuidesAlliance.lua,
blob cdd0435891a9213860f0d9549b20fad0136ec95e on this branch, source labels
//49–//86 and //140–//142. Labels identify source blocks, not guaranteed runtime
step numbers. This older route contains both quest lines. Do not substitute the
Retail-derived guide: its coverage differs. Selection/loading of this legacy
guide has not been validated in the client.

The route below preserves source order. Coordinates and cave descriptions are
existing source evidence, not newly verified navigation. In particular, vertical
rooms can share map positions: useful entrance/bridge/junction waypoints need
client verification. No coordinate is presented here as a tested route.

| Source labels | Existing route | Storyboard treatment |
|---|---|---|
| 49 | Athridas: accept A Troubling Breeze | Establish the missing warden |
| 50–55 | Other tasks; travel east | No repeated story paragraph on every task |
| 56 | Gaerolas: turn in; accept Gnarlpine Corruption | Reveal the warning after the conversation |
| 57–58 | Other tasks | Preserve route |
| 59 | Athridas: turn in; accept The Relics of Wakening | Establish the rescue and relics |
| 60–73 | Other tasks and Road to Darnassus | Preserve route; motivate a later reminder |
| 74 | Enter Ban’ethil | Remind player why this den matters |
| 75–76 | Black Feather Quill; Rune of Nesting | Compact chest actions and attached directions |
| 77–78 | Meet Oben; obtain Shaman Voodoo Charm | Introduce his predicament, then action |
| 79 | Raven Claw Talisman | Continue relic work without premature Oben resolution |
| 80–81 | Return charm; accept Druid of the Claw; defeat body and use charm | Reveal solution after examination |
| 82 | Sapphire of Sky | Keep Oben outcome unrevealed until return conversation |
| 83 | Report to Oben | Reveal his final words |
| 84–86 | Level check; hearth; relic turn-in and Ursal acceptance | Distinguish preparation from successful awakening |
| 87–139 | Other tasks, with conditional class steps | Preserve route; remind at Ursal |
| 140–142 | Kill Ursal; other turn-in; report to Athridas | Close the remaining task without inventing a visible awakening |

This route is the evidence for the storyboard, not a decision that this is the
best route for the owner's adventure. No route optimization or content omission
has been silently approved.

## Main-guide scenes

### A. An overdue report

State: Athridas has introduced A Troubling Breeze. Its offered/accepted dialogue
provides this information. Do not reveal the Gnarlpine attack yet.

> Athridas has heard nothing from Gaerolas, the warden protecting Ban’ethil’s
> sleeping druids. Their slumber honours a pact with Ysera, the green dragon
> who watches over the Emerald Dream—a spirit realm beyond the waking world.
> Find Gaerolas in Starbreeze Village and learn whether his charges are safe.
>
> **Find Gaerolas Talvethren in Starbreeze Village.**
>
> *Read: Why do the druids sleep?*
>
> Recent story

At Athridas, the actual action is Talk / Accept; the travel objective above belongs
to the later travel state, after acceptance and the intervening source tasks.
The same passage need not be repeated at each state. A short travel reminder,
“Find the missing warden in Starbreeze Village,” is enough.

Navigation: source target Gaerolas at 66.3,58.5. A verified building entrance and
upstairs direction should precede the NPC target; source 56 alone does not
establish those route legs. The quest dialogue grounds his role and destination.
The historical source supports the brief Dream/Ysera explanation.

### B. The warning

Before the conversation, show only the search reminder and Talk / Turn in.
After Gaerolas reveals Gnarlpine Corruption:

> Gaerolas was ambushed by the Gnarlpine. Once peaceful, the furbolgs have been
> driven mad through their chieftain Ursal’s use of Fel Moss. Wounded, Gaerolas
> cannot carry the warning himself. Bring his news to Athridas—the sleeping
> druids may be in danger.
>
> **Return to Athridas Bearmantle in Dolanaar.**

Unlock: explicit offered/accepted Gnarlpine Corruption dialogue state. Accept
confirmed is a conservative fixture signal. Arrival at Gaerolas alone is not.
Target: source Athridas at 56.0,57.3; intervening source tasks remain.

### C. The rescue, and the later reminder

After Athridas introduces The Relics of Wakening:

> The Gnarlpine have reached Ban’ethil. The druids’ hibernation cannot be broken
> without four sacred relics stored inside the den. Recover them so Athridas
> can prepare the awakening ritual.
>
> **Accept “The Relics of Wakening”.**

Availability requires the relevant quest offer/dialogue; fixture uses accept
confirmed before advancing. Merely entering source block 59 is insufficient.

Much later, at the source 74 entrance:

> This is Ban’ethil, where Gaerolas’s charges lie sleeping. Recover the four
> relics Athridas needs for their awakening.
>
> **Enter Ban’ethil Barrow Den.**
>
> *Read: Why do the druids sleep?*
>
> Recent story

Entrance target from source: 44.4,57.8. This deliberate reminder supplies
continuity after the intervening quests. It does not claim the ritual is complete.

### D. Practical relic collection

After entering, source 75:

> **Open the Chest of the Black Feather.**
>
> Upper floor: cross the bridge to the right and search the small room.
>
> **Black Feather Quill — 0/1**
>
> Recent story

Then source 76:

> **Open the Chest of Nesting.**
>
> Upper floor: cross the middle bridge; the chest is on the right in the small room.
>
> **Rune of Nesting — 0/1**

No new lore paragraph is necessary for each chest. These instructions paraphrase
the existing route and still require in-client verification. Counts complete
normally; collection is not treated as a discovery about Oben. The optional
background remains accessible through Recent story/reader navigation without
requiring the link on every objective.

### E. Oben’s predicament

Source 77 initially shows “Go downstairs / Talk to Oben Rageclaw” without the
revelation. After he introduces The Sleeping Druid, source 78:

> Oben’s spirit is trapped in the Emerald Dream. The Gnarlpine shamans have
> taken control of his sleeping body and use it to attack intruders. Bring him
> one of their charms so he can examine the enchantment.
>
> **Collect a Shaman Voodoo Charm — 0/1**
>
> Defeat Gnarlpine Shamans in the next room.
>
> Recent story

Unlock: Sleeping Druid accepted for the fixture, not proximity to Oben.
A new optional Oben article is unnecessary: his immediate story belongs here.
After collecting the charm, source 79 still sends the player to the Raven Claw
chest. Keep that action, without suggesting the enchantment has been broken.

### F. What the charm reveals

At source 80, before the exchange:

> Bring the shamans’ charm to Oben so he can examine it.
>
> **Return to Oben Rageclaw.**
>
> **Turn in “The Sleeping Druid”.**

After examination and the Druid of the Claw offer/acceptance, source 81:

> Oben sees only one way to escape the Gnarlpine’s control. He asks you to
> destroy his captive body, then use the charm upon it.
>
> **Defeat Rageclaw.**
>
> **Use the Voodoo Charm on his fallen body.**
>
> **Release Oben’s spirit — 0/1**

Keep the item action interactive using the native item path. A kill alone does
not complete the release objective. Source 82 next collects the Sapphire of Sky;
preserve that detour. Do not show Oben’s final words yet.

### G. Oben’s farewell

At source 83, before turn-in, show Return / Talk / Turn in.
Only after confirmed Druid of the Claw turn-in:

> Oben is free of the Gnarlpine’s control. His body cannot return to him, but
> his spirit can now rest peacefully in the Emerald Dream.
>
> **Return to Dolanaar.**
>
> Use your Hearthstone.
>
> Recent story

The return action corresponds to source 85, after the source 84 level check.
This mock shows the narrative alongside the next meaningful task; it does not
delete that check. If it blocks progression, retain the farewell while showing
the actual pending action. Native hearth availability remains authoritative.

The second sentence summarizes the requested destruction and his completion
dialogue; it must not become an unsupported general rule about druid death.

### H. The remaining threat

At source 86, after the relic exchange and Ursal quest introduction:

> The relics are back with Athridas, but his awakening ritual cannot succeed
> while Ursal lives. The Gnarlpine chieftain must be slain to free the sleepers.
>
> **Accept “Ursal the Mauler”.**

The route continues through other tasks. At source 140, use a concise reminder:

> Ursal’s death is the remaining condition Athridas named for the awakening.
>
> **Slay Ursal the Mauler.**

After the kill: direct the player back to Athridas when the route calls for it.
After the final turn-in, record that Athridas thanks the player. Do not invent
an awakening scene, spoken farewell, or observation of druids rising: the
reviewed completion text does not show that event.

## The optional reading window, fully populated

Entry text in A and C: **Read: Why do the druids sleep?**

Main-guide purpose, stakes, and basic definitions remain understandable without
opening it. The title is the invitation; no extra teaser paragraph is needed.
The passage is background, safe after the initial quest introduction:

> **Why do the druids sleep?**
>
> The slumber beneath Ban’ethil belongs to an ancient bargain. After the War
> of the Ancients, Ysera linked Nordrassil, the World Tree at Mount Hyjal, to
> her realm: the Emerald Dream. The night elf druids agreed to sleep for
> centuries while their spirits travelled its paths.
>
> Their hibernation was a commitment, not simply a long rest. While their
> spirits journeyed beyond the waking world, their bodies remained behind.
> Protectors such as Gaerolas kept watch over the sleepers.
>
> That is the duty behind Athridas’s concern. The missing report comes from
> someone entrusted with people who cannot simply rise to defend themselves.

Historical claims: S7 below. Gaerolas’s duty: S1. The final connection is an
editorial explanation of those facts, not additional quest dialogue.
Nordrassil is explicitly located at Hyjal to avoid confusing it with Teldrassil.
No modern Ysera events, later Dream revelations, or Oben outcomes appear here.

Proposed behavior:
- Open alongside the guide; current objectives remain visible and usable.
- Preserve selected passage and scroll position while gameplay advances.
- Close returns attention to the current task without changing progression.
- Reopening the same passage during this session restores position.
- On reload, first prototype may reopen the reader closed; history and passage
  eligibility persist. Automatic reopening and scroll persistence across reload
  are not required by this storyboard.
- No automatic reader opening and no automatic progression hold.

This is a behavior proposal to review, not proof that two windows fit the owner's
screen. Test minimum size and overlap in the native client.

## Concrete fast-progression and recovery case

Fixture scenario: player already holds the charm, meets Oben, accepts Sleeping
Druid, immediately turns it in, then accepts Druid of the Claw. The guide can
advance through E/F quickly without treating time on screen as proof of reading.

Current main guide shows F, including why the player must defeat Rageclaw.
Player selects **Recent story**; the separate reader shows eligible entries:

- The missing warden
- Gaerolas’s warning
- The relics needed for awakening
- Oben’s captive body
- What the charm revealed

Selecting “Oben’s captive body” displays E’s essential passage while the main
guide stays on the Rageclaw objective. “Oben’s farewell” is absent until its
turn-in signal; a kill or charm collection does not unlock it.

After reload: same eligible entries, once each, and current task reconstructed
from actual progress. Do not label passages Read/Unread; we do not know that.
Browsing a future guide block must not unlock its entries. For this prototype,
only explicit evidence unlocks passages: do not backfill every earlier story
because a later step was selected. Retention is limited to this walkthrough;
a campaign-wide history policy remains open.

A second quick-progress case covers Oben’s farewell: turn-in followed immediately
by the level check/hearth step. The farewell is recoverable even if its inline
appearance was brief. No mandatory acknowledgment or timed delay is added.

## Fixture contract and review ledger

New walkthrough separate from the 11 existing technical cases. Simulate quest
offers/acceptance, item collection, charm use objective credit, and turn-ins;
never change real quest or inventory state. Snapshot selection is for inspection;
transition checks must execute the events. Source step alone cannot gate story.

| Case | Required observation | State |
|---|---|---|
| Introduction + optional passage | Enough inline context; useful extra reading; basic Ysera/Dream gloss | Drafted for review |
| Delayed arrival | Entrance reminder restores purpose after unrelated tasks | Drafted for review |
| Interleaved relic/Oben work | Actual source order preserved; no premature solution | Drafted for review |
| Kill without charm use | Release remains incomplete; no farewell | Specified; unimplemented |
| Quest exchange in one source block | Correct before/after story despite same step identity | Specified; unimplemented |
| Reader open during progression | Live actions available; passage does not switch | Proposed; unimplemented |
| Fast progression + reload | Missed eligible passage recoverable once; no future entry | Proposed; unimplemented |
| Navigation and small-window layout | Useful cave legs, actionable rows visible, readable prose | Native validation pending |
| Existing technical regressions | Preserve rows, interactions, scale and refresh cases | Retain; no new tests run |

Do not implement new parser tags or classify legacy prose from this document.
Authored roles and gates above are conceptual requirements pending a format
decision. Writing/format/content budget remain with the owner. No prose length
here establishes a universal authoring limit.

## Sources and method

S1: [A Troubling Breeze, 475](https://www.wowhead.com/classic/quest=475/a-troubling-breeze);
[3.3.5a cross-check](https://wotlkdb.com/index.php?quest=475).
S2: [Gnarlpine Corruption, 476](https://wotlkdb.com/?quest=476).
S3: [The Relics of Wakening, 483](https://wotlkdb.com/?quest=483).
S4: [The Sleeping Druid, 2541](https://www.wowhead.com/classic/quest=2541/the-sleeping-druid).
S5: [Druid of the Claw, 2561](https://wotlkdb.com/?quest=2561).
S6: [Ursal the Mauler, 486](https://wotlkdb.com/?quest=486).
S7: [The World Tree and the Emerald Dream](https://warcraft.blizzplanet.com/the_world_tree_and_the_emerald_dream/),
a transcription of the existing in-game history book, published 2008.
Route: [older Alliance leveling source](../ZygorGuidesViewerRM/Guides/Leveling/ZygorGuidesAlliance.lua).

Method: read quest objectives and description/progress/completion dialogue; map
disclosure timing; check the actual route and interruptions; introduce relevant
names; draft essential text with actions; add one sourced background passage;
check each outcome against the source. Player comments were not lore evidence.
This sample demonstrates a method, not a measured campaign-wide research budget.
