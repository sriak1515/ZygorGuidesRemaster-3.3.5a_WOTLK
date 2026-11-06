# Repeatable parchment client tests — fixture v1

The agreed vertical parchment brief remains the design specification. These fixtures provide stable content for implementing and checking it. They are synthetic UI test material, not campaign writing or a proposed campaign structure.

The guide is loaded under **Ares' Guide Authoring > UI Tests > Parchment Fixtures v1**. It is never selected automatically and has no default race, class, quest or continuation route. Open it explicitly with `/zgfixture` or choose it through Guides.

## Baseline and controls

- `/zgfixture baseline`: explicitly sets the viewer to 380 x 520 logical units, a 55% action split, Tools closed, Context expanded and untagged-text reading off; opens F01 and clears the simulated token. It preserves viewer position, lock, addon scale, client UI scale and other addons. These layout preferences persist through the normal addon settings; this is an explicit test preset, not an automatic layout reset.
- `/zgfixture 1` through `/zgfixture 11`: jump directly to a case, keeping layout preferences. Native step selection resets the content scroll positions and transient manual completion.
- `/zgfixture reset`: clear the simulated token and return to F01, keeping layout preferences.
- Return to the campaign through **Guides > Recent**, or select it normally. No fixture command alters campaign text, quest completion records, inventory or other UI placement. The optional real item must be activated explicitly.

The core cases use `|context`, fixed `|condition false, true` / `true, true` states, and explicit Continue goals for reading-only cases. They do not need a particular character, quest log, server NPC data, location or bag contents. The fixed `(2/8)` label is a wrapping sample, not a claim about live quest progress. The optional item case is deliberately separate.

Keep the client resolution/UI scale and addon scale the same between screenshots and note them when comparing different setups. The preset preserves these values rather than changing the rest of the game UI.

## Cases

| Command | Case | Main check |
| --- | --- | --- |
| `/zgfixture 1` | F01 Short mixed | Two actions, attached directions and one context paragraph; normally no action scrolling. |
| `/zgfixture 2` | F02 Long mixed | Four actions and seven context paragraphs. Scroll Context to its final sentence without moving Actions. |
| `/zgfixture 3` | F03 Action only | Four actions/directions; no empty context allocation. Visit from a collapsed mixed case and back to check preference retention. |
| `/zgfixture 4` | F04 Story only | Two paragraphs, fixed title and native Continue control. No invented action list. |
| `/zgfixture 5` | F05 Completion | Two completed and two pending rows. Checks remain visible; right-click completion preserves rows and scroll. |
| `/zgfixture 6` | F06 Long names | Long synthetic NPC, quest and item labels plus a long direction tip. Check every final wrapped line. |
| `/zgfixture 7` | F07 Action overflow | 32 pending objectives exceed the old 20-row display limit. Objective 32 remains reachable; Context keeps its own minimum. |
| `/zgfixture 8` | F08 Long story | 13 reading paragraphs, final-line marker and fixed Continue. |
| `/zgfixture 9` | F09 Legacy text | An empty `info` row, an ambiguous untagged note, an actionable direction and explicit context. The empty spacer is omitted; compare the reading preference without guessing from prose. |
| `/zgfixture 10` | F10 Harmless inline action | Click the token icon: only a volatile fixture flag changes, and its row becomes complete. The second action holds the step open. Test secure overlay clipping and combat hide/restore here. |
| `/zgfixture 11` | F11 Optional real item | Native Refreshing Spring Water item row. Its actual usable icon depends on carrying item 159 and enabling inline controls. Clicking consumes/uses the real item. Record interaction as not tested when unavailable. |

F10 uses the normal secure **script** action path and a fixed icon; it does not simulate or establish real item cooldown behavior. F11 exercises the real item path separately. No fake player inventory or quest completion is injected into the runtime.

## Space and settings

Actions and Context are the persistent content. Tools expands to **one row**. The optional plain-text placement preference is a checkbox under **Tools > Settings > Read untagged text in Context**, rather than a permanent row of its own. The Context disclosure shares a thin draggable rule; expanded Context retains at least 144 units including its heading, and Actions retains 160 including its heading. Plain reading rows use the text area without an unused icon gutter. Empty `info` spacers are omitted only when they have no prose, tooltip, icon or interaction payload; an empty spacer cannot create an empty reading region. Context collapse remains explicit and persistent.

For the first comparison, capture F01, F02 and F04 with the baseline preset and normal client/addon scale. Then test F07 at minimum size, divider extremes with Tools open, collapse/restore, and `/reload` persistence. No additional visual workshop or alternate layout is needed before assessing these against the existing brief.

## WIP campaign reference

`DruidCalling.lua` v0.6 was supplied and inspected read-only. Its 15 parsed steps contain seven reading-only states and eight mixed/travel states under the explicit untagged-text reading preference. Parsed authored text totals 3,808 bytes, with a maximum of 460 per step, excluding generated objective labels, localized names and NPC tooltips. Several `info` rows are empty spacers. These are observations of this WIP, not future campaign authoring constraints.

The uploaded campaign source is not copied into the public branch and has not been rewritten. It mixes lore and practical directions in generic note rows, so the viewer must keep its conservative fallback and preserve unknown rows. Fixtures support adapting the addon to real content without making the WIP campaign serve as a test harness.

## Automation and client limits

The real parser, goal statuses and step completion model verify case partitions, fixed completion, manual completion, reset/selection commands, stable core content across player states, the token callback and the separate real item path. The existing stateful frame harness also renders the actual fixture file, checks all rows/final lines remain reachable, exercises real Settings menu callbacks, and retains scrolling across repeated refreshes. Its frames intentionally lack `SetShown`.

Mock wrapping is approximate. Pixel rendering, input clipping, real secure execution, inventory use, combat behavior and live reload persistence still require the client. The user's successful startup report confirms the preceding compatibility fix, not completion of these new client checks.
