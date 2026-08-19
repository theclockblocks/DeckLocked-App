# DeckLocked

**A deck-of-cards unlock challenge for WoW Classic Era and TBC Anniversary — as a real in-game addon.**

DeckLocked started life as a desktop companion app by [IronPad](https://github.com/IronPadYT/DeckLocked-App), built for his TBC Anniversary *Decklocked* YouTube series. This fork rewrites it from scratch as a native WoW addon: same challenge, same cards, but it now lives inside the game — it knows your class and level, watches your dungeon kills, and physically locks the pieces of the game you haven't earned yet.

## The challenge

Your character starts with almost nothing: no gear slots, no abilities, no talents, no bags, no professions. Every time you level up you earn a **draw** — three cards appear and you keep exactly one:

- **Gear slot** — unlock a piece of your paperdoll (chest, weapon, rings…)
- **Ability** — unlock one of your class's spells (all ranks of it)
- **Talent +5 / +1** — permission to spend talent points (51 unlockable at level 60, 61 at 70)
- **Profession** — unlock a profession, cooking, fishing or first aid
- **General** — bag slots and mounts

Dungeons feed a second economy: killing a dungeon's final boss earns a **material roll**, which reveals enchanting and jewelcrafting material cards — the only mats you're allowed to use. Profession milestones and misc goals (Kara, 1k HKs, exploration…) bank **bonus draws**.

Everything else stays locked. That's the run.

## Features

- **Class-aware**: ability decks for all nine classes, grouped by talent tree, verified against the Classic and TBC databases (levels, spell IDs, icons) — including the complete TBC level 61–70 trainer spells.
- **Level-aware**: the addon reads your real level; dinging grants a draw. A character adopting the addon mid-journey starts with one draw per level already earned.
- **Dungeon auto-detection**: final-boss kills are detected from the combat log and complete the dungeon automatically — all 26 Classic dungeons/wings plus all 15 TBC dungeons. Bonus boxes (SM / Classic / TBC) are derived from full clears.
- **Group sync**: boss kills are shared with party/raid members running DeckLocked, so being dead or out of range never costs credit.
- **Full enforcement mode** (on by default):
  - Locked gear slots are shaded on the character sheet and **anything equipped in one is automatically removed** (queued politely until combat ends).
  - Locked spells are grayed and un-clickable in the spellbook, red-tinted on action bars, and casting one triggers a raid-warning callout.
  - Locked bag slots and the talent frame are gated the same way.
  - The tracker itself is cheat-proofed: no manual toggles, no free rerolls, no clamp exploits, undo restores the *same* three cards, and pending draws survive relogging.
- **Minimap button**: left-click opens the tracker, right-click toggles enforcement, drag to reposition.
- **Per-character saves**: every character is its own profile, automatically.

## Installation

1. Download this repository (Code → Download ZIP, or a release if available).
2. Copy the `DeckLocked` folder into your AddOns directory — the same folder works on both clients:
   ```
   World of Warcraft\_classic_era_\Interface\AddOns\DeckLocked    (Classic Era)
   World of Warcraft\_anniversary_\Interface\AddOns\DeckLocked    (TBC Anniversary)
   ```
   The folder must be named exactly `DeckLocked` and contain the `.toc` files.
3. Restart the game or `/reload`. You'll see the DeckLocked minimap button.

## Commands

| Command | Effect |
|---|---|
| `/dl` or `/decklocked` | Open/close the tracker |
| `/dl enforce` | Toggle enforcement (also `on` / `off`) |
| `/dl minimap` | Hide/show the minimap button |
| `/dl reset` | Wipe this character's progress (asks first) |

## Playing it

**Main page** — your character. Draw with the *Draw 3 Cards* button when you have draws banked (the toolbar shows how many), click a card to claim it. *Bonus Draw* spends a bonus draw instead. *Return Draw* is a single-step undo: it reverts the unlock, refunds the draw, and brings back the same three cards.

**Dungeons page** — every Classic dungeon/wing and the TBC list. They complete themselves when the final boss dies (shared with your group); each completion banks a material roll.

**Materials page** — professions and goals. *Roll Materials* (1 roll minimum) reveals one enchanting and one jewelcrafting card; claiming one costs 0.5 rolls (1.0 once the enchanting deck is complete). Check off profession levels and misc goals as you hit them for bonus draws.

**Enforcement** is the honor system made mechanical. Turn it off (`/dl enforce off`) and the addon becomes a permissive tracker: everything is click-to-toggle and the manual +/- adjusters return — useful for house rules, fixing mistakes, or crediting runs done before you installed. Turning it back on re-locks everything and re-sweeps your gear.

### What enforcement can't do

WoW's secure-code sandbox means no addon can hard-block a protected action: if a locked spell is on your action bar, the key still casts it. DeckLocked makes violations *loud* (raid warning + sound + chat) rather than impossible. Everything else — gear, UI clicks, tracker integrity — is genuinely enforced.

## Customizing

All content lives in [`Data.lua`](DeckLocked/Data.lua) as plain tables — ability decks per class, gear/talent/general cards, material decks, dungeon lists and their final-boss NPC IDs, misc goals. Each card is one line; abilities carry their rank-1 spell ID (`spell = 403`), which is also where their icon comes from. `expansion = 1` hides a card on the Classic Era client while keeping it live on TBC. Edit, `/reload`, done.

## Project layout

```
DeckLocked/
├── DeckLocked.toc          -- fallback manifest (all supported versions)
├── DeckLocked_Vanilla.toc  -- Classic Era manifest
├── DeckLocked_TBC.toc      -- TBC Anniversary manifest
├── Data.lua                -- every card, deck, dungeon and boss ID
├── Core.lua                -- game logic, saved variables, draw economy, group sync
├── UI.lua                  -- the tracker window + minimap button
└── Enforce.lua             -- game-UI locking, auto-unequip, violation detection
```

No libraries, no dependencies — one addon, plain Lua, running on Classic Era (Interface 11505–11509) and TBC Anniversary (Interface 20505). The client picks its own `.toc`; everything else is shared, with TBC-only content expansion-gated in `Data.lua`.

## Roadmap

- Retail client support (the data model is already expansion-gated; mostly an API-shim exercise)
- Auto-detection for more goals (profession skill levels, exploration, HKs)
- Optional import/export strings for sharing runs

## Credits

- **[IronPad](https://github.com/IronPadYT)** — the DeckLocked challenge, the original app, and the invitation to rebuild it properly. Watch the original *Decklocked* series on his YouTube channel.
- Addon rewrite by theclockblocks.

## License

[GPL-3.0](LICENSE), same as the original project.
