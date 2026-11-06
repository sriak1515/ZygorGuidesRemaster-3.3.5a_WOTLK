# WoW Solo Adventure — product brief and session handoff

Updated 6 November 2026. This is the current product reference. It supersedes older assumptions about where narrative belongs; those older documents remain implementation history. This update changes documentation, not the addon.

## Product intent supplied by the owner

### Our goal

Experience World of Warcraft as a coherent, enjoyable adventure, with enough guidance to understand the story and navigate confidently without reading every quest dialogue.

### Lore and storytelling

- **Purpose before action:** Explain who needs help, what is happening and why our actions matter.
- **Quest-grounded writing:** Use original quest dialogue as the primary narrative foundation, complemented by verified Warcraft lore and established campaign context.
- **Correct timing:** Introduce relevant information before the task, and reveal consequences only after they occur.
- **Spoiler-conscious:** Respect the player's actual progress and preserve discoveries.
- **Natural, engaging prose:** Clear causal connections, character and occasional atmosphere, without artificial drama or invented explanations.
- **Selective depth:** Important events deserve meaningful context; routine activities shouldn't require paragraphs.
- **Narrative continuity:** Relate new tasks to what has happened earlier, without assuming the player remembers every detail.

### In-game guidance

- **Waypoint-first navigation:** Every meaningful travel instruction should normally have a useful waypoint. Missing waypoints require a reason.
- **Multi-leg travel:** Use intermediate destinations for portals, boats, flights, cave entrances and complicated routes. Avoid misleading distant arrows.
- **Unambiguous instructions:** Name the correct interaction, destination, NPC or landmark. Never assume the player already knows the geography.
- **Actions and context together:** Show the purpose of a new objective or significant transition at the moment it becomes actionable, not only afterward.
- **Scannable objectives:** Navigation, quest actions and progression must be immediately recognizable.
- **Readable narrative:** Story text should be visually distinct, comfortable to read and allowed enough space when the information is worthwhile.
- **Minimal friction:** Automatic progression wherever possible, no intrusive popups, no mandatory reading screens and no routine technical troubleshooting.
- **No player-facing technical clutter:** Hide quest IDs, debugging information, companion maintenance and unnecessary recovery branches.

### Complementary experiences

**Zygor** handles immediate gameplay, navigation and contextual storytelling.

**Azeroth Library** is an optional, occasional companion for deeper storytelling, especially at major narrative transitions. All essential context must remain understandable through Zygor alone.

**Guiding principle:** Always know where to go, understand why we're going there, and gradually discover what it means.

## Scope and ownership

The owner/team controls guide writing, format, adherence and content budgets. The implementation agent builds a platform that supports those choices; it must not rewrite campaign prose, invent lore, impose a new writing style or silently infer narrative roles/timing from untagged text. Existing content and interactions must remain accessible.

DragonUI is the owner's reference for Warcraft character with improved UX. It is not an assumed dependency or permission to copy all its assets. The owner also has a website project for general lore; no website, reader or library source has been inspected in this repository session.

## Clarifications from the latest client review

| Topic | Current direction | Status |
|---|---|---|
| Essential story | Who, why, current situation and relevant aftermath accompany the current task in the normal guide flow. Never require opening optional lore to understand the adventure. | Governing requirement |
| Objectives/directions | Compact and immediately scannable; attached directions stay with their action and waypoint. | Governing requirement |
| Optional depth | Background beyond essential understanding can be behind an explicit, discoverable reader action. | Governing requirement |
| Reader placement | Owner now prefers a separate optional window, potentially replacing the split Context pane. It should leave current actions visible. | Preferred direction; exact ownership/integration unresolved |
| Current split pane | An experiment, not the definition of all contextual storytelling. Collapsing it must not hide required understanding. | Reassess against the new requirements |
| Typography | The compact pass is much better. Owner wants normal Zygor settings to drive experimentation, with more usable size choices. | Integrate existing controls in a later code pass |
| Frame/page | Small paper changes are barely visible; metal still reads as a frame. | Open visual issue, lower priority than experience |
| Fixtures | Existing cases prove technical resilience but do not adequately demonstrate the intended adventure. | Revise alongside the next behavior pass |

The earlier popout discussion did not settle a separate reader: the prototype deliberately tried full-panel Read first. Do not describe the current implementation as the agreed final reader architecture. The latest request is a change/clarification of direction, not a missing hidden setting.

## Platform roles, independent of a future guide syntax

| Role | Required presentation | Availability |
|---|---|---|
| Objective | Interactive, compact, completion-aware | Native guide/quest progression |
| Route/instruction hint | Adjacent to its relevant action; useful waypoint when applicable | Alongside that action |
| Essential introduction/bridge | Visible in the normal authored flow, before the relevant action | When that action/transition becomes relevant |
| Consequence/aftermath | Visible in the normal flow after the event, without advance spoilers | Explicit authored progress signal |
| Optional background/reference | Discoverable reader entry; current actions stay available | Explicit association and spoiler-safe progress eligibility |

These are product requirements for rendering and availability, not instructions to invent parser tags now. The existing `|tip`, plain rows, step ordering and optional `|context` metadata provide only part of this contract. Untagged introductions and background are not reliably distinguishable. Keep unknown rows in order. Do not turn every plain paragraph into optional lore.

## Current review reference: Ban’ethil storyboard

See [Ban’ethil adventure storyboard](BANETHIL_STORYBOARD.md) for the current
route-grounded review draft. The owner found the initial researched Ban’ethil
content useful, with narrative tone still open to refinement, and requested this
storyboard before further UI implementation.

The earlier [synthetic adventure proposal](ADVENTURE_FLOW_AND_FIXTURES.md) was
labelled agreed too early. It remains design history. The separate Zygor-managed
reader and Recent story behavior are proposals to assess with the concrete
Ban’ethil scenes, not settled architecture or implemented features.

The storyboard follows the older Alliance route’s actual interleaving of relic
collection and Oben’s story, includes one complete optional background passage,
and specifies fast-progression/reload cases. It does not change campaign guides,
parser syntax, UI code, or the playable build. Navigation and native layout remain
unverified. Library integration and shared source ownership remain deferred.

## Product questions to assess with the storyboard

1. **Continuity during automatic progression:** How does important recently shown story remain recoverable if an objective completes quickly? A small recent-story/recap history is a candidate, not an implemented feature. Avoid solving this by forcing a confirmation on every step. The platform must not guess whether the player has read a passage.
2. **Optional reader ownership:** A second window managed by Zygor, an Azeroth Library addon, or a shared content source? The website can complement this, but essential in-game context must work without it. Do not assume the old client can display arbitrary live web pages. Inspect the actual library/content project before committing to integration.

Do not ask the owner to resolve a long implementation questionnaire. Demonstrate these choices with one small real guide sequence and a few explicit states.

## Font integration: source inspection, not a technical blocker

`Options.lua` already has primary `profile.fontsize` sliders (7–16, step 1) and secondary `profile.fontsecsize` sliders (5–14, step 1), in both relevant settings presentations. Their setters call AlignFrame/UpdateFrame. The prototype instead reads its own `profile.parchment.objectivesize` and `contextsize`, so the normal font sliders currently do not control these text roles.

Recommended next implementation direction: use the existing primary/secondary controls as the authoritative objective/direction settings, place a dedicated reading-size control in that same settings UI, and avoid competing quick-menu/profile values. Reconcile saved prototype preferences without silently overwriting unrelated existing settings. Exact migration and reading range should be established during that pass. Do not claim this wiring is already implemented.

## Fixture review proposal

Keep the 32-row, long-name, item, scale, split and refresh cases as technical regressions. Add/rework a short product walkthrough separately:

1. Arrival: visible who/why introduction with a destination and a scannable action.
2. Active task: compact objectives, attached directions, progress/completion styling and essential story still understandable.
3. Aftermath: consequence becomes available only after the fixture's explicit completion event.
4. Optional depth: a clearly discoverable reader entry, with essential understanding already present in the main guide. Test reader opening/closing without losing the current task.
5. Fast progression/reload: test the chosen continuity behavior once that product decision is settled.

Use synthetic or owner-authorized material and clearly label fixtures. Do not rewrite the WIP campaign to make testing convenient. The owner should review one focused flow per build with a stated question and an updated result ledger, not rediscover the whole test plan every time.

## Existing code and evidence

- Repository: `sriak1515/ZygorGuidesRemaster-3.3.5a_WOTLK`.
- Branch: `prototype/vertical-parchment`.
- Current playable code: **`03e01be359b362aabb46d7a08617a7e3fc34a97c`**. Previous playable build: `4486dce`.
- Base addon: 3.0.255 / revision 255, `d2aae8d0f1f3782d964e4179907b215aab484787`; client 3.3.5a/build 12340.
- No AGENTS.md found in the workspace during implementation. Recheck on a new checkout.
- Primary implementation: `ZygorGuidesViewerRM/Parchment.lua`; parser metadata in `Parser.lua`; native hooks/settings in `ZygorGuidesViewer.lua`, `Options.lua`, and viewer frame Lua/XML.
- Current window starts at 340x400 logical units, minimum 320x380, retained position/size/lock/scale. Split minima 160/144 remain implemented under the older design; revisiting/removing the split is now a product decision.
- Current code has independent scroll regions, optional in-panel full-body Read, fixed reader controls, temporary automatic-progression hold during explicit Read, native item/click interactions and completed text/check styling. Full-body Read restores the saved split/collapse and exits on a new step. It is not a second reader window.
- `plaincontext=false` preserves untagged inline order. `|context` moves only compatible passive rows; unknown/interactive rows remain actionable. The broad placement toggle is not a semantic classifier.
- Current default objectives 13, derived directions 11, reading 14; existing saved reading sizes survive. `/zgfixture baseline` explicitly applies the normalized 13/14 preset while preserving position and scale.
- Lua5.1 test-only runtime via Lupa: `PYTHONPATH=work/python python tools/ui/run_checks.py` in this workspace, or install Lupa normally. All 25 regression scripts passed on the current code. GitHub workflow builds a verified complete addon ZIP plus patch/docs/checksums.
- Public real rendering sample: Alliance Howling Fjord (69–71), step 178, source near line 1560: talk to Silvermoon Harry, turn in Scoodles, accept four quests. Fits at compact baseline in the frame model.
- Private uploaded `DruidCalling.lua` v0.6: 15 steps; step 3 has introduction, talk and accept. It was read and tested locally using `ZYGOR_CAMPAIGN_SAMPLE`; source was never copied into the public repository/package. Its actual source remains necessary for future content-specific work.
- Static corpus: 16,012 parsed leveling steps; roughly 98% have at most three completion-capable parsed rows before runtime filtering. Raw maxima include route waypoints and racial alternatives. These are not future campaign authoring limits.
- Client screenshots support successful startup, practical text-size improvement, preference for Druid Calling's inline introduction, dissatisfaction with long split reading and weak page identity. They do not establish all interaction/reload/scale cases.
- No in-game validation by the implementation agent. Do not equate mock metrics or Lua checks with native rendering/secure input validation.
- Delivery: GitHub Actions artifacts, because in-chat ZIP downloads failed. Latest playable run `42284964292`, artifact `13537366058`; artifact retention is 14 days. Rebuild if expired. No need for the owner to install a docs-only update.
- Rollback: `/zgparchment off` restores native viewer on reload; preserve prior folder/SavedVariables for full rollback. Earlier commits remain available. No default-branch merge or release publication requested.

## Next work and review ledger

| Item | State | Next evidence |
|---|---|---|
| Requirements reset | Recorded here | Use as current product reference |
| Compact typography | Implemented; owner says much better | Integrate normal font controls |
| Essential story in normal flow | Supported for untagged inline rows; experience not fully specified | Review the Ban’ethil storyboard before implementation |
| Optional separate reader | Not implemented | Choose its behavior/ownership using that same walkthrough |
| Story timing/continuity | Not solved by the placement toggle | Explicit progress states plus fast-progression case |
| Book/page identity | Owner still sees a frame | Refine after behavior is settled; no larger footprint assumed |
| Website/library sharing | Not inspected or implemented | Inspect actual projects when scope is chosen |

Recommended sequence: first make the small behavior walkthrough/fixture plan concrete; then implement that agreed behavior and settings integration; then run one focused client checkpoint. Keep this ledger current. Further skin rounds should not substitute for settling the experience.

## Starting a fresh session

Read this file first, then inspect the current branch and actual code. Preserve completed work. Treat the owner's requirements above as the product goal, distinguish implemented behavior from proposals, and retain the boundary that guide writing/format belongs to the owner. The current task is to review docs/BANETHIL_STORYBOARD.md as the concrete introduction → action → consequence + optional-depth example before changing UI or parser behavior. Keep its proposed behaviors distinct from the governing requirements. Ask at most the focused question needed by the walkthrough. Do not claim a new reader, font integration or timing model already exists.
