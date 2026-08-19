-- DeckLocked data: ported from the original Electron app's cards.json /
-- enchanting.json / jewelcraft.json, extended with ability decks for all
-- nine Classic classes. The deck is assembled at login for the player's
-- class via DL.BuildDeck().
--
-- Icon conventions:
--   icon = "Interface\\Icons\\..."  -> texture path (spell/misc art)
--   item = <itemID>                 -> resolved via GetItemIcon at runtime,
--                                      falls back to a question mark on
--                                      clients that don't know the item
--                                      (e.g. TBC materials on Classic Era)
--   invSlot = "HeadSlot" etc        -> empty paperdoll slot art via
--                                      GetInventorySlotInfo

local ADDON, DL = ...

local ICON = "Interface\\Icons\\"
DL.QUESTION_MARK = ICON .. "INV_Misc_QuestionMark"

---------------------------------------------------------------------------
-- Shared cards: gear, talents, professions, general (same for every class)
---------------------------------------------------------------------------

DL.sharedCards = {
  -- Gear slots -----------------------------------------------------------
  { id = "head1",      name = "Helm Slot",       type = "gear", slot = "head",      invSlot = "HeadSlot",          minLevel = 20 },
  { id = "neck1",      name = "Neck Slot",       type = "gear", slot = "neck",      invSlot = "NeckSlot",          minLevel = 20 },
  { id = "shoulders1", name = "Shoulder Slot",   type = "gear", slot = "shoulders", invSlot = "ShoulderSlot",      minLevel = 15 },
  { id = "back1",      name = "Back Slot",       type = "gear", slot = "back",      invSlot = "BackSlot",          minLevel = 1 },
  { id = "chest1",     name = "Chest Slot",      type = "gear", slot = "chest",     invSlot = "ChestSlot",         minLevel = 1 },
  { id = "wrists1",    name = "Wrist Slot",      type = "gear", slot = "wrists",    invSlot = "WristSlot",         minLevel = 1 },
  { id = "hands1",     name = "Glove Slot",      type = "gear", slot = "hands",     invSlot = "HandsSlot",         minLevel = 1 },
  { id = "waist1",     name = "Waist Slot",      type = "gear", slot = "waist",     invSlot = "WaistSlot",         minLevel = 1 },
  { id = "legs1",      name = "Leg Slot",        type = "gear", slot = "legs",      invSlot = "LegsSlot",          minLevel = 1 },
  { id = "feet1",      name = "Feet Slot",       type = "gear", slot = "feet",      invSlot = "FeetSlot",          minLevel = 1 },
  { id = "ring1",      name = "Ring Slot 1",     type = "gear", slot = "ring1",     invSlot = "Finger0Slot",       minLevel = 15 },
  { id = "ring2",      name = "Ring Slot 2",     type = "gear", slot = "ring2",     invSlot = "Finger1Slot",       minLevel = 15 },
  { id = "trinket1",   name = "Trinket Slot 1",  type = "gear", slot = "trinket1",  invSlot = "Trinket0Slot",      minLevel = 40 },
  { id = "trinket2",   name = "Trinket Slot 2",  type = "gear", slot = "trinket2",  invSlot = "Trinket1Slot",      minLevel = 40 },
  { id = "mainhand1",  name = "Main Hand",       type = "gear", slot = "mainhand",  invSlot = "MainHandSlot",      minLevel = 1 },
  { id = "offhand1",   name = "Offhand",         type = "gear", slot = "offhand",   invSlot = "SecondaryHandSlot", minLevel = 1 },
  { id = "relic1",     name = "Ranged/Relic Slot", type = "gear", slot = "relic",   invSlot = "RangedSlot",        minLevel = 50 },

  -- Talents (+5 each) ----------------------------------------------------
  { id = "talent1",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 15 },
  { id = "talent2",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 20 },
  { id = "talent3",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 25 },
  { id = "talent4",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 30 },
  { id = "talent5",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 35 },
  { id = "talent6",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 40 },
  { id = "talent7",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 45 },
  { id = "talent8",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 50 },
  { id = "talent9",  name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 55 },
  { id = "talent10", name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 60 },
  { id = "talent11", name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 65 },
  { id = "talent12", name = "Talent +5", type = "talent", icon = ICON .. "INV_Misc_Book_09", minLevel = 70 },

  -- Professions ----------------------------------------------------------
  { id = "prof1_card",    name = "Unlock Profession",   type = "profession", profession = "prof-1",   icon = ICON .. "Trade_BlackSmithing",        minLevel = 5 },
  { id = "prof2_card",    name = "Unlock Profession 2", type = "profession", profession = "prof-2",   icon = ICON .. "Trade_Engineering",          minLevel = 5 },
  { id = "cooking_card",  name = "Unlock Cooking",      type = "profession", profession = "cooking",  icon = ICON .. "INV_Misc_Food_15",           minLevel = 5 },
  { id = "fishing_card",  name = "Learn Fishing",       type = "profession", profession = "fishing",  icon = ICON .. "Trade_Fishing",              minLevel = 5 },
  { id = "firstaid_card", name = "Learn First Aid",     type = "profession", profession = "firstaid", icon = ICON .. "Spell_Holy_SealOfSacrifice", minLevel = 5 },

  -- General --------------------------------------------------------------
  { id = "bag1_card",       name = "Unlock Bag Slot 1",        type = "general", general = "bag-1",             icon = ICON .. "INV_Misc_Bag_08",             minLevel = 1 },
  { id = "bag2_card",       name = "Unlock Bag Slot 2",        type = "general", general = "bag-2",             icon = ICON .. "INV_Misc_Bag_10",             minLevel = 5 },
  { id = "bag3_card",       name = "Unlock Bag Slot 3",        type = "general", general = "bag-3",             icon = ICON .. "INV_Misc_Bag_11",             minLevel = 10 },
  { id = "bag4_card",       name = "Unlock Bag Slot 4",        type = "general", general = "bag-4",             icon = ICON .. "INV_Misc_Bag_12",             minLevel = 15 },
  { id = "mount_card",      name = "Unlock Mount",             type = "general", general = "mount",             icon = ICON .. "Ability_Mount_RidingHorse",   minLevel = 30 },
  { id = "epicmount_card",  name = "Unlock Epic Mount",        type = "general", general = "epic-mount",        icon = ICON .. "Ability_Mount_Charger",       minLevel = 60 },
  { id = "flying_card",     name = "Unlock Flying Mount",      type = "general", general = "flying-mount",      icon = ICON .. "Ability_Mount_Gryphon_01",    minLevel = 70 },
  { id = "epicflying_card", name = "Unlock Epic Flying Mount", type = "general", general = "epic-flying-mount", icon = ICON .. "Ability_Mount_GoldenGryphon", minLevel = 70 },
}

---------------------------------------------------------------------------
-- Class spec sections (UI headers) and ability decks.
-- Ability entries: { id, name, subspec, icon, minLevel }.
-- minLevel = the level the first rank is trainable; entries above the
-- client's level cap simply never become eligible.
---------------------------------------------------------------------------

DL.specs = {
  WARRIOR = { { key = "arms", label = "Arms" }, { key = "fury", label = "Fury" }, { key = "protection", label = "Protection" } },
  PALADIN = { { key = "holy", label = "Holy" }, { key = "protection", label = "Protection" }, { key = "retribution", label = "Retribution" } },
  HUNTER  = { { key = "beastmastery", label = "Beast Mastery" }, { key = "marksmanship", label = "Marksmanship" }, { key = "survival", label = "Survival" } },
  ROGUE   = { { key = "assassination", label = "Assassination" }, { key = "combat", label = "Combat" }, { key = "subtlety", label = "Subtlety" } },
  PRIEST  = { { key = "discipline", label = "Discipline" }, { key = "holy", label = "Holy" }, { key = "shadow", label = "Shadow" } },
  SHAMAN  = { { key = "elemental", label = "Elemental" }, { key = "enhance", label = "Enhancement" }, { key = "restoration", label = "Restoration" } },
  MAGE    = { { key = "arcane", label = "Arcane" }, { key = "fire", label = "Fire" }, { key = "frost", label = "Frost" } },
  WARLOCK = { { key = "affliction", label = "Affliction" }, { key = "demonology", label = "Demonology" }, { key = "destruction", label = "Destruction" } },
  DRUID   = { { key = "balance", label = "Balance" }, { key = "feral", label = "Feral" }, { key = "restoration", label = "Restoration" } },
}

DL.abilityDecks = {}

-- SHAMAN -----------------------------------------------------------------
-- Complete Classic trainer/quest ability list, verified against Wowhead
-- Classic (spell = rank-1 spell ID; icons resolve from it automatically).
-- Card ids preserved from v1 so existing progress carries over.
-- tbcOnly cards are hidden on the Classic Era client.
DL.abilityDecks.SHAMAN = {
  { id = "lightning",         name = "Lightning Bolt",          subspec = "elemental",   spell = 403,   minLevel = 1 },
  { id = "rockbiter",         name = "Rockbiter Weapon",        subspec = "enhance",     spell = 8017,  minLevel = 1 },
  { id = "healingwave",       name = "Healing Wave",            subspec = "restoration", spell = 331,   minLevel = 1 },
  { id = "earthshock",        name = "Earth Shock",             subspec = "elemental",   spell = 8042,  minLevel = 4 },
  { id = "stoneskin",         name = "Stoneskin Totem",         subspec = "enhance",     spell = 8071,  minLevel = 4 },
  { id = "earthbind",         name = "Earthbind Totem",         subspec = "elemental",   spell = 2484,  minLevel = 6 },
  { id = "lightningshield",   name = "Lightning Shield",        subspec = "enhance",     spell = 324,   minLevel = 8 },
  { id = "stoneclaw",         name = "Stoneclaw Totem",         subspec = "elemental",   spell = 5730,  minLevel = 8 },
  { id = "flameshock",        name = "Flame Shock",             subspec = "elemental",   spell = 8050,  minLevel = 10 },
  { id = "flametonguewep",    name = "Flametongue Weapon",      subspec = "enhance",     spell = 8024,  minLevel = 10 },
  { id = "searingtotem",      name = "Searing Totem",           subspec = "elemental",   spell = 3599,  minLevel = 10 },
  { id = "strengthofearth",   name = "Strength of Earth Totem", subspec = "enhance",     spell = 8075,  minLevel = 10 },
  { id = "ancestralspirit",   name = "Ancestral Spirit",        subspec = "restoration", spell = 2008,  minLevel = 12 },
  { id = "firenova",          name = "Fire Nova Totem",         subspec = "elemental",   spell = 1535,  minLevel = 12 },
  { id = "purge",             name = "Purge",                   subspec = "elemental",   spell = 370,   minLevel = 12 },
  { id = "curepoison",        name = "Cure Poison",             subspec = "restoration", spell = 526,   minLevel = 16 },
  { id = "tremor",            name = "Tremor Totem",            subspec = "restoration", spell = 8143,  minLevel = 18 },
  { id = "frostshock",        name = "Frost Shock",             subspec = "elemental",   spell = 8056,  minLevel = 20 },
  { id = "frostbrandwep",     name = "Frostbrand Weapon",       subspec = "enhance",     spell = 8033,  minLevel = 20 },
  { id = "ghostwolf",         name = "Ghost Wolf",              subspec = "enhance",     spell = 2645,  minLevel = 20 },
  { id = "healingstream",     name = "Healing Stream Totem",    subspec = "restoration", spell = 5394,  minLevel = 20 },
  { id = "lesserhealingwave", name = "Lesser Healing Wave",     subspec = "restoration", spell = 8004,  minLevel = 20 },
  { id = "curedisease",       name = "Cure Disease",            subspec = "restoration", spell = 2870,  minLevel = 22 },
  { id = "poisoncleansetotem",name = "Poison Cleansing Totem",  subspec = "restoration", spell = 8166,  minLevel = 22 },
  { id = "waterbreathing",    name = "Water Breathing",         subspec = "enhance",     spell = 131,   minLevel = 22 },
  { id = "frosttotem",        name = "Frost Resistance Totem",  subspec = "enhance",     spell = 8181,  minLevel = 24 },
  { id = "farsight",          name = "Far Sight",               subspec = "enhance",     spell = 6196,  minLevel = 26 },
  { id = "magmatotem",        name = "Magma Totem",             subspec = "elemental",   spell = 8190,  minLevel = 26 },
  { id = "manaspring",        name = "Mana Spring Totem",       subspec = "restoration", spell = 5675,  minLevel = 26 },
  { id = "firetotem",         name = "Fire Resistance Totem",   subspec = "enhance",     spell = 8184,  minLevel = 28 },
  { id = "flametonguetotem",  name = "Flametongue Totem",       subspec = "enhance",     spell = 8227,  minLevel = 28 },
  { id = "waterwalking",      name = "Water Walking",           subspec = "enhance",     spell = 546,   minLevel = 28 },
  { id = "astralrecall",      name = "Astral Recall",           subspec = "enhance",     spell = 556,   minLevel = 30 },
  { id = "grounding",         name = "Grounding Totem",         subspec = "enhance",     spell = 8177,  minLevel = 30 },
  { id = "naturetotem",       name = "Nature Resistance Totem", subspec = "enhance",     spell = 10595, minLevel = 30 },
  { id = "reincarnation",     name = "Reincarnation",           subspec = "restoration", spell = 20608, minLevel = 30 },
  { id = "windfurywep",       name = "Windfury Weapon",         subspec = "enhance",     spell = 8232,  minLevel = 30 },
  { id = "chainlightning",    name = "Chain Lightning",         subspec = "elemental",   spell = 421,   minLevel = 32 },
  { id = "windfurytotem",     name = "Windfury Totem",          subspec = "enhance",     spell = 8512,  minLevel = 32 },
  { id = "sentry",            name = "Sentry Totem",            subspec = "enhance",     spell = 6495,  minLevel = 34 },
  { id = "windwall",          name = "Windwall Totem",          subspec = "enhance",     spell = 15107, minLevel = 36 },
  { id = "diseasetotem",      name = "Disease Cleansing Totem", subspec = "restoration", spell = 8170,  minLevel = 38 },
  { id = "chainheal",         name = "Chain Heal",              subspec = "restoration", spell = 1064,  minLevel = 40 },
  { id = "graceofair",        name = "Grace of Air Totem",      subspec = "enhance",     spell = 8835,  minLevel = 42 },
  { id = "tranquiltotem",     name = "Tranquil Air Totem",      subspec = "restoration", spell = 25908, minLevel = 50 },
  -- TBC-only (hidden on Classic Era, ready for TBC/retail clients)
  { id = "totemiccall",       name = "Totemic Call",            subspec = "restoration", spell = 36936, icon = ICON .. "Spell_Shaman_TotemRecall",          minLevel = 30, tbcOnly = true },
  { id = "watershield",       name = "Water Shield",            subspec = "restoration", spell = 24398, icon = ICON .. "Ability_Shaman_WaterShield",        minLevel = 62, tbcOnly = true },
  { id = "wrathtotem",        name = "Wrath of Air Totem",      subspec = "enhance",     spell = 3738,  icon = ICON .. "Spell_Nature_SlowingTotem",         minLevel = 64, tbcOnly = true },
  { id = "earthele",          name = "Earth Elemental Totem",   subspec = "enhance",     spell = 2062,  icon = ICON .. "Spell_Nature_EarthElemental_Totem", minLevel = 66, tbcOnly = true },
  { id = "fireele",           name = "Fire Elemental Totem",    subspec = "elemental",   spell = 2894,  icon = ICON .. "Spell_Fire_Elemental_Totem",        minLevel = 68, tbcOnly = true },
  { id = "bloodlust",         name = "Bloodlust",               subspec = "enhance",     spell = 2825,  icon = ICON .. "Spell_Nature_BloodLust",            minLevel = 70, tbcOnly = true },
}

-- WARRIOR ----------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
DL.abilityDecks.WARRIOR = {
  { id = "heroicstrike",     name = "Heroic Strike",       subspec = "arms",       spell = 78,    minLevel = 1 },
  { id = "battlestance",     name = "Battle Stance",       subspec = "arms",       spell = 2457,  minLevel = 1 },
  { id = "battleshout",      name = "Battle Shout",        subspec = "fury",       spell = 6673,  minLevel = 1 },
  { id = "charge",           name = "Charge",              subspec = "arms",       spell = 100,   minLevel = 4 },
  { id = "rend",             name = "Rend",                subspec = "arms",       spell = 772,   minLevel = 4 },
  { id = "thunderclap",      name = "Thunder Clap",        subspec = "arms",       spell = 6343,  minLevel = 6 },
  { id = "hamstring",        name = "Hamstring",           subspec = "arms",       spell = 1715,  minLevel = 8 },
  { id = "bloodrage",        name = "Bloodrage",           subspec = "fury",       spell = 2687,  minLevel = 10 },
  { id = "defensivestance",  name = "Defensive Stance",    subspec = "protection", spell = 71,    minLevel = 10 },
  { id = "sunderarmor",      name = "Sunder Armor",        subspec = "protection", spell = 7386,  minLevel = 10 },
  { id = "taunt",            name = "Taunt",               subspec = "protection", spell = 355,   minLevel = 10 },
  { id = "overpower",        name = "Overpower",           subspec = "arms",       spell = 7384,  minLevel = 12 },
  { id = "shieldbash",       name = "Shield Bash",         subspec = "protection", spell = 72,    minLevel = 12 },
  { id = "demoshout",        name = "Demoralizing Shout",  subspec = "fury",       spell = 1160,  minLevel = 14 },
  { id = "revenge",          name = "Revenge",             subspec = "protection", spell = 6572,  minLevel = 14 },
  { id = "mockingblow",      name = "Mocking Blow",        subspec = "arms",       spell = 694,   minLevel = 16 },
  { id = "shieldblock",      name = "Shield Block",        subspec = "protection", spell = 2565,  minLevel = 16 },
  { id = "disarm",           name = "Disarm",              subspec = "protection", spell = 676,   minLevel = 18 },
  { id = "cleave",           name = "Cleave",              subspec = "fury",       spell = 845,   minLevel = 20 },
  { id = "retaliation",      name = "Retaliation",         subspec = "arms",       spell = 20230, minLevel = 20 },
  { id = "intimidatingshout",name = "Intimidating Shout",  subspec = "fury",       spell = 5246,  minLevel = 22 },
  { id = "execute",          name = "Execute",             subspec = "fury",       spell = 5308,  minLevel = 24 },
  { id = "challengingshout", name = "Challenging Shout",   subspec = "protection", spell = 1161,  minLevel = 26 },
  { id = "shieldwall",       name = "Shield Wall",         subspec = "protection", spell = 871,   minLevel = 28 },
  { id = "berserkerstance",  name = "Berserker Stance",    subspec = "fury",       spell = 2458,  minLevel = 30 },
  { id = "intercept",        name = "Intercept",           subspec = "fury",       spell = 20252, minLevel = 30 },
  { id = "slam",             name = "Slam",                subspec = "arms",       spell = 1464,  minLevel = 30 },
  { id = "berserkerrage",    name = "Berserker Rage",      subspec = "fury",       spell = 18499, minLevel = 32 },
  { id = "whirlwind",        name = "Whirlwind",           subspec = "fury",       spell = 1680,  minLevel = 36 },
  { id = "pummel",           name = "Pummel",              subspec = "fury",       spell = 6552,  minLevel = 38 },
  { id = "recklessness",     name = "Recklessness",        subspec = "fury",       spell = 1719,  minLevel = 50 },
  -- TBC-only
  { id = "victoryrush",      name = "Victory Rush",        subspec = "fury",       spell = 34428, icon = ICON .. "Ability_Warrior_Devastate",        minLevel = 62, tbcOnly = true },
  { id = "spellreflection",  name = "Spell Reflection",    subspec = "protection", spell = 23920, icon = ICON .. "Ability_Warrior_ShieldReflection", minLevel = 64, tbcOnly = true },
  { id = "commandingshout",  name = "Commanding Shout",    subspec = "fury",       spell = 469,   icon = ICON .. "Ability_Warrior_RallyingCry",      minLevel = 68, tbcOnly = true },
}

-- PALADIN ----------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
DL.abilityDecks.PALADIN = {
  { id = "holylight",        name = "Holy Light",             subspec = "holy",        spell = 635,   minLevel = 1 },
  { id = "devotionaura",     name = "Devotion Aura",          subspec = "protection",  spell = 465,   minLevel = 1 },
  { id = "sealofright",      name = "Seal of Righteousness",  subspec = "retribution", spell = 20154, minLevel = 1 },
  { id = "judgement",        name = "Judgement",              subspec = "retribution", spell = 20271, minLevel = 4 },
  { id = "blessingofmight",  name = "Blessing of Might",      subspec = "retribution", spell = 19740, minLevel = 4 },
  { id = "sealofcrusader",   name = "Seal of the Crusader",   subspec = "retribution", spell = 21082, minLevel = 6 },
  { id = "divineprotection", name = "Divine Protection",      subspec = "protection",  spell = 498,   minLevel = 6 },
  { id = "purify",           name = "Purify",                 subspec = "holy",        spell = 1152,  minLevel = 8 },
  { id = "hammerofjustice",  name = "Hammer of Justice",      subspec = "protection",  spell = 853,   minLevel = 8 },
  { id = "layonhands",       name = "Lay on Hands",           subspec = "holy",        spell = 633,   minLevel = 10 },
  { id = "blessingofprot",   name = "Blessing of Protection", subspec = "protection",  spell = 1022,  minLevel = 10 },
  { id = "redemption",       name = "Redemption",             subspec = "holy",        spell = 7328,  minLevel = 12 },
  { id = "blessingofwisdom", name = "Blessing of Wisdom",     subspec = "holy",        spell = 19742, minLevel = 14 },
  { id = "righteousfury",    name = "Righteous Fury",         subspec = "protection",  spell = 25780, minLevel = 16 },
  { id = "retributionaura",  name = "Retribution Aura",       subspec = "retribution", spell = 7294,  minLevel = 16 },
  { id = "blessingoffreedom",name = "Blessing of Freedom",    subspec = "protection",  spell = 1044,  minLevel = 18 },
  { id = "flashoflight",     name = "Flash of Light",         subspec = "holy",        spell = 19750, minLevel = 20 },
  { id = "exorcism",         name = "Exorcism",               subspec = "retribution", spell = 879,   minLevel = 20 },
  { id = "senseundead",      name = "Sense Undead",           subspec = "protection",  spell = 5502,  minLevel = 20 },
  { id = "sealofjustice",    name = "Seal of Justice",        subspec = "retribution", spell = 20164, minLevel = 22 },
  { id = "concentrationaura",name = "Concentration Aura",     subspec = "holy",        spell = 19746, minLevel = 22 },
  { id = "turnundead",       name = "Turn Undead",            subspec = "holy",        spell = 2878,  minLevel = 24 },
  { id = "blessingofsalv",   name = "Blessing of Salvation",  subspec = "protection",  spell = 1038,  minLevel = 26 },
  { id = "shadowresaura",    name = "Shadow Resistance Aura", subspec = "protection",  spell = 19876, minLevel = 28 },
  { id = "divineinterv",     name = "Divine Intervention",    subspec = "holy",        spell = 19752, minLevel = 30 },
  { id = "sealoflight",      name = "Seal of Light",          subspec = "holy",        spell = 20165, minLevel = 30 },
  { id = "frostresaura",     name = "Frost Resistance Aura",  subspec = "protection",  spell = 19888, minLevel = 32 },
  { id = "divineshield",     name = "Divine Shield",          subspec = "holy",        spell = 642,   minLevel = 34 },
  { id = "fireresaura",      name = "Fire Resistance Aura",   subspec = "protection",  spell = 19891, minLevel = 36 },
  { id = "sealofwisdom",     name = "Seal of Wisdom",         subspec = "holy",        spell = 20166, minLevel = 38 },
  { id = "blessingoflight",  name = "Blessing of Light",      subspec = "holy",        spell = 19977, minLevel = 40 },
  { id = "summonwarhorse",   name = "Summon Warhorse",        subspec = "retribution", spell = 13819, minLevel = 40 },
  { id = "cleanse",          name = "Cleanse",                subspec = "holy",        spell = 4987,  minLevel = 42 },
  { id = "hammerofwrath",    name = "Hammer of Wrath",        subspec = "retribution", spell = 24275, minLevel = 44 },
  { id = "blessingofsac",    name = "Blessing of Sacrifice",  subspec = "protection",  spell = 6940,  minLevel = 46 },
  { id = "holywrath",        name = "Holy Wrath",             subspec = "holy",        spell = 2812,  minLevel = 50 },
  { id = "gblessingmight",   name = "Greater Blessing of Might",   subspec = "retribution", spell = 25782, minLevel = 52 },
  { id = "gblessingwisdom",  name = "Greater Blessing of Wisdom",  subspec = "holy",        spell = 25894, minLevel = 54 },
  { id = "gblessingkings",   name = "Greater Blessing of Kings",   subspec = "protection",  spell = 25898, minLevel = 60 },
  { id = "gblessinglight",   name = "Greater Blessing of Light",   subspec = "holy",        spell = 25890, minLevel = 60 },
  { id = "gblessingsalv",    name = "Greater Blessing of Salvation", subspec = "protection", spell = 25895, minLevel = 60 },
  { id = "gblessingsanc",    name = "Greater Blessing of Sanctuary", subspec = "protection", spell = 25899, minLevel = 60 },
  { id = "summoncharger",    name = "Summon Charger",         subspec = "retribution", spell = 23214, minLevel = 60 },
  -- TBC-only
  { id = "crusaderaura",     name = "Crusader Aura",          subspec = "retribution", spell = 32223, icon = ICON .. "Spell_Holy_CrusaderAura",  minLevel = 62, tbcOnly = true },
  { id = "sealofblood",      name = "Seal of Blood/Vengeance",subspec = "retribution", spell = 31892, icon = ICON .. "Spell_Holy_SealOfBlood",   minLevel = 64, tbcOnly = true },
  { id = "avengingwrath",    name = "Avenging Wrath",         subspec = "retribution", spell = 31884, icon = ICON .. "Spell_Holy_AvengineWrath", minLevel = 70, tbcOnly = true },
}

-- HUNTER -----------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
-- Pet-training spells (Growl, Great Stamina, resistances) are excluded:
-- those are taught to the pet, not the hunter.
DL.abilityDecks.HUNTER = {
  { id = "raptorstrike",    name = "Raptor Strike",         subspec = "survival",     spell = 2973,  minLevel = 1 },
  { id = "trackbeasts",     name = "Track Beasts",          subspec = "survival",     spell = 1494,  minLevel = 1 },
  { id = "aspectmonkey",    name = "Aspect of the Monkey",  subspec = "survival",     spell = 13163, minLevel = 4 },
  { id = "serpentsting",    name = "Serpent Sting",         subspec = "marksmanship", spell = 1978,  minLevel = 4 },
  { id = "arcaneshot",      name = "Arcane Shot",           subspec = "marksmanship", spell = 3044,  minLevel = 6 },
  { id = "huntersmark",     name = "Hunter's Mark",         subspec = "marksmanship", spell = 1130,  minLevel = 6 },
  { id = "concussiveshot",  name = "Concussive Shot",       subspec = "marksmanship", spell = 5116,  minLevel = 8 },
  { id = "tamebeast",       name = "Tame Beast",            subspec = "beastmastery", spell = 1515,  minLevel = 10 },
  { id = "callpet",         name = "Call Pet",              subspec = "beastmastery", spell = 883,   minLevel = 10 },
  { id = "dismisspet",      name = "Dismiss Pet",           subspec = "beastmastery", spell = 2641,  minLevel = 10 },
  { id = "feedpet",         name = "Feed Pet",              subspec = "beastmastery", spell = 6991,  minLevel = 10 },
  { id = "revivepet",       name = "Revive Pet",            subspec = "beastmastery", spell = 982,   minLevel = 10 },
  { id = "aspecthawk",      name = "Aspect of the Hawk",    subspec = "marksmanship", spell = 13165, minLevel = 10 },
  { id = "trackhumanoids",  name = "Track Humanoids",       subspec = "survival",     spell = 19883, minLevel = 10 },
  { id = "distractingshot", name = "Distracting Shot",      subspec = "marksmanship", spell = 20736, minLevel = 12 },
  { id = "mendpet",         name = "Mend Pet",              subspec = "beastmastery", spell = 136,   minLevel = 12 },
  { id = "wingclip",        name = "Wing Clip",             subspec = "survival",     spell = 2974,  minLevel = 12 },
  { id = "eagleeye",        name = "Eagle Eye",             subspec = "marksmanship", spell = 6197,  minLevel = 14 },
  { id = "eyesofbeast",     name = "Eyes of the Beast",     subspec = "beastmastery", spell = 1002,  minLevel = 14 },
  { id = "scarebeast",      name = "Scare Beast",           subspec = "beastmastery", spell = 1513,  minLevel = 14 },
  { id = "immolationtrap",  name = "Immolation Trap",       subspec = "survival",     spell = 13795, minLevel = 16 },
  { id = "mongoosebite",    name = "Mongoose Bite",         subspec = "survival",     spell = 1495,  minLevel = 16 },
  { id = "multishot",       name = "Multi-Shot",            subspec = "marksmanship", spell = 2643,  minLevel = 18 },
  { id = "trackundead",     name = "Track Undead",          subspec = "survival",     spell = 19884, minLevel = 18 },
  { id = "aspectcheetah",   name = "Aspect of the Cheetah", subspec = "survival",     spell = 5118,  minLevel = 20 },
  { id = "disengage",       name = "Disengage",             subspec = "survival",     spell = 781,   minLevel = 20 },
  { id = "freezingtrap",    name = "Freezing Trap",         subspec = "survival",     spell = 1499,  minLevel = 20 },
  { id = "scorpidsting",    name = "Scorpid Sting",         subspec = "marksmanship", spell = 3043,  minLevel = 22 },
  { id = "beastlore",       name = "Beast Lore",            subspec = "beastmastery", spell = 1462,  minLevel = 24 },
  { id = "trackhidden",     name = "Track Hidden",          subspec = "survival",     spell = 19885, minLevel = 24 },
  { id = "rapidfire",       name = "Rapid Fire",            subspec = "marksmanship", spell = 3045,  minLevel = 26 },
  { id = "trackelementals", name = "Track Elementals",      subspec = "survival",     spell = 19880, minLevel = 26 },
  { id = "frosttrap",       name = "Frost Trap",            subspec = "survival",     spell = 13809, minLevel = 28 },
  { id = "aspectbeast",     name = "Aspect of the Beast",   subspec = "beastmastery", spell = 13161, minLevel = 30 },
  { id = "feigndeath",      name = "Feign Death",           subspec = "survival",     spell = 5384,  minLevel = 30 },
  { id = "flare",           name = "Flare",                 subspec = "survival",     spell = 1543,  minLevel = 32 },
  { id = "trackdemons",     name = "Track Demons",          subspec = "survival",     spell = 19878, minLevel = 32 },
  { id = "explosivetrap",   name = "Explosive Trap",        subspec = "survival",     spell = 13813, minLevel = 34 },
  { id = "vipersting",      name = "Viper Sting",           subspec = "marksmanship", spell = 3034,  minLevel = 36 },
  { id = "aspectpack",      name = "Aspect of the Pack",    subspec = "beastmastery", spell = 13159, minLevel = 40 },
  { id = "trackgiants",     name = "Track Giants",          subspec = "survival",     spell = 19882, minLevel = 40 },
  { id = "volley",          name = "Volley",                subspec = "marksmanship", spell = 1510,  minLevel = 40 },
  { id = "aspectwild",      name = "Aspect of the Wild",    subspec = "beastmastery", spell = 20043, minLevel = 46 },
  { id = "trackdragonkin",  name = "Track Dragonkin",       subspec = "survival",     spell = 19879, minLevel = 50 },
  { id = "tranqshot",       name = "Tranquilizing Shot",    subspec = "marksmanship", spell = 19801, minLevel = 60 },
  -- TBC-only
  { id = "steadyshot",      name = "Steady Shot",           subspec = "marksmanship", spell = 34120, icon = ICON .. "Ability_Hunter_SteadyShot",   minLevel = 62, tbcOnly = true },
  { id = "killcommand",     name = "Kill Command",          subspec = "beastmastery", spell = 34026, icon = ICON .. "Ability_Hunter_KillCommand",  minLevel = 66, tbcOnly = true },
  { id = "misdirection",    name = "Misdirection",          subspec = "marksmanship", spell = 34477, icon = ICON .. "Ability_Hunter_Misdirection", minLevel = 70, tbcOnly = true },
}

-- ROGUE ------------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
-- Poison ranks (Instant Poison II etc.) collapse into one card per poison.
DL.abilityDecks.ROGUE = {
  { id = "sinisterstrike", name = "Sinister Strike",    subspec = "combat",        spell = 1752,  minLevel = 1 },
  { id = "eviscerate",     name = "Eviscerate",         subspec = "assassination", spell = 2098,  minLevel = 1 },
  { id = "stealth",        name = "Stealth",            subspec = "subtlety",      spell = 1784,  minLevel = 1 },
  { id = "backstab",       name = "Backstab",           subspec = "assassination", spell = 53,    minLevel = 4 },
  { id = "pickpocket",     name = "Pick Pocket",        subspec = "subtlety",      spell = 921,   minLevel = 4 },
  { id = "gouge",          name = "Gouge",              subspec = "combat",        spell = 1776,  minLevel = 6 },
  { id = "evasion",        name = "Evasion",            subspec = "combat",        spell = 5277,  minLevel = 8 },
  { id = "sap",            name = "Sap",                subspec = "subtlety",      spell = 6770,  minLevel = 10 },
  { id = "sprint",         name = "Sprint",             subspec = "combat",        spell = 2983,  minLevel = 10 },
  { id = "sliceanddice",   name = "Slice and Dice",     subspec = "assassination", spell = 5171,  minLevel = 10 },
  { id = "kick",           name = "Kick",               subspec = "combat",        spell = 1766,  minLevel = 12 },
  { id = "garrote",        name = "Garrote",            subspec = "assassination", spell = 703,   minLevel = 14 },
  { id = "exposearmor",    name = "Expose Armor",       subspec = "assassination", spell = 8647,  minLevel = 14 },
  { id = "feint",          name = "Feint",              subspec = "subtlety",      spell = 1966,  minLevel = 16 },
  -- Pick Lock's spell data says level 1, but trainers gate it at 16
  { id = "picklock",       name = "Pick Lock",          subspec = "subtlety",      spell = 1804,  minLevel = 16 },
  { id = "ambush",         name = "Ambush",             subspec = "subtlety",      spell = 8676,  minLevel = 18 },
  { id = "poisons",        name = "Poisons",            subspec = "assassination", spell = 2842,  minLevel = 20 },
  { id = "cripplingpoison",name = "Crippling Poison",   subspec = "assassination", spell = 3420,  minLevel = 20 },
  { id = "instantpoison",  name = "Instant Poison",     subspec = "assassination", spell = 8681,  minLevel = 20 },
  { id = "rupture",        name = "Rupture",            subspec = "assassination", spell = 1943,  minLevel = 20 },
  { id = "distract",       name = "Distract",           subspec = "subtlety",      spell = 1725,  minLevel = 22 },
  { id = "vanish",         name = "Vanish",             subspec = "subtlety",      spell = 1856,  minLevel = 22 },
  { id = "detecttraps",    name = "Detect Traps",       subspec = "subtlety",      spell = 2836,  minLevel = 24 },
  { id = "mindnumbing",    name = "Mind-numbing Poison",subspec = "assassination", spell = 5763,  minLevel = 24 },
  { id = "cheapshot",      name = "Cheap Shot",         subspec = "subtlety",      spell = 1833,  minLevel = 26 },
  { id = "deadlypoison",   name = "Deadly Poison",      subspec = "assassination", spell = 2835,  minLevel = 30 },
  { id = "disarmtrap",     name = "Disarm Trap",        subspec = "subtlety",      spell = 1842,  minLevel = 30 },
  { id = "kidneyshot",     name = "Kidney Shot",        subspec = "assassination", spell = 408,   minLevel = 30 },
  { id = "woundpoison",    name = "Wound Poison",       subspec = "assassination", spell = 13220, minLevel = 32 },
  { id = "blind",          name = "Blind",              subspec = "subtlety",      spell = 2094,  minLevel = 34 },
  { id = "safefall",       name = "Safe Fall",          subspec = "subtlety",      spell = 1860,  minLevel = 40 },
  -- TBC-only
  { id = "deadlythrow",    name = "Deadly Throw",       subspec = "combat",        spell = 26679, icon = ICON .. "INV_ThrowingKnife_06",     minLevel = 64, tbcOnly = true },
  { id = "cloakofshadows", name = "Cloak of Shadows",   subspec = "subtlety",      spell = 31224, icon = ICON .. "Spell_Shadow_NetherCloak", minLevel = 66, tbcOnly = true },
  { id = "shiv",           name = "Shiv",               subspec = "combat",        spell = 5938,  icon = ICON .. "INV_ThrowingKnife_04",     minLevel = 70, tbcOnly = true },
}

-- PRIEST -----------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
-- Race-specific priest spells (Fear Ward, Starshards, etc.) are excluded.
DL.abilityDecks.PRIEST = {
  { id = "smite",           name = "Smite",                subspec = "holy",       spell = 585,   minLevel = 1 },
  { id = "lesserheal",      name = "Lesser Heal",          subspec = "holy",       spell = 2050,  minLevel = 1 },
  { id = "pwfortitude",     name = "Power Word: Fortitude",        subspec = "discipline", spell = 1243,  minLevel = 1 },
  { id = "swpain",          name = "Shadow Word: Pain",             subspec = "shadow",     spell = 589,   minLevel = 4 },
  { id = "pwshield",        name = "Power Word: Shield",           subspec = "discipline", spell = 17,    minLevel = 6 },
  { id = "renew",           name = "Renew",                subspec = "holy",       spell = 139,   minLevel = 8 },
  { id = "fade",            name = "Fade",                 subspec = "shadow",     spell = 586,   minLevel = 8 },
  { id = "mindblast",       name = "Mind Blast",           subspec = "shadow",     spell = 8092,  minLevel = 10 },
  { id = "resurrection",    name = "Resurrection",         subspec = "holy",       spell = 2006,  minLevel = 10 },
  { id = "innerfire",       name = "Inner Fire",           subspec = "discipline", spell = 588,   minLevel = 12 },
  { id = "psychicscream",   name = "Psychic Scream",       subspec = "shadow",     spell = 8122,  minLevel = 14 },
  { id = "curedisease",     name = "Cure Disease",         subspec = "holy",       spell = 528,   minLevel = 14 },
  { id = "heal",            name = "Heal",                 subspec = "holy",       spell = 2054,  minLevel = 16 },
  { id = "dispelmagic",     name = "Dispel Magic",         subspec = "discipline", spell = 527,   minLevel = 18 },
  { id = "flashheal",       name = "Flash Heal",           subspec = "holy",       spell = 2061,  minLevel = 20 },
  { id = "holyfire",        name = "Holy Fire",            subspec = "holy",       spell = 14914, minLevel = 20 },
  { id = "mindsoothe",      name = "Mind Soothe",          subspec = "shadow",     spell = 453,   minLevel = 20 },
  { id = "shackleundead",   name = "Shackle Undead",       subspec = "discipline", spell = 9484,  minLevel = 20 },
  { id = "mindvision",      name = "Mind Vision",          subspec = "shadow",     spell = 2096,  minLevel = 22 },
  { id = "manaburn",        name = "Mana Burn",            subspec = "discipline", spell = 8129,  minLevel = 24 },
  { id = "prayerofhealing", name = "Prayer of Healing",    subspec = "holy",       spell = 596,   minLevel = 30 },
  { id = "mindcontrol",     name = "Mind Control",         subspec = "shadow",     spell = 605,   minLevel = 30 },
  { id = "shadowprotection",name = "Shadow Protection",    subspec = "discipline", spell = 976,   minLevel = 30 },
  { id = "abolishdisease",  name = "Abolish Disease",      subspec = "holy",       spell = 552,   minLevel = 32 },
  { id = "levitate",        name = "Levitate",             subspec = "discipline", spell = 1706,  minLevel = 34 },
  { id = "greaterheal",     name = "Greater Heal",         subspec = "holy",       spell = 2060,  minLevel = 40 },
  { id = "prayerfortitude", name = "Prayer of Fortitude",  subspec = "discipline", spell = 21562, minLevel = 48 },
  { id = "prayershadowprot",name = "Prayer of Shadow Protection",subspec = "discipline", spell = 27683, minLevel = 56 },
  { id = "prayerspirit",    name = "Prayer of Spirit",     subspec = "discipline", spell = 27681, minLevel = 60 },
  -- TBC-only
  { id = "swdeath",         name = "Shadow Word: Death",            subspec = "shadow",     spell = 32379, icon = ICON .. "Spell_Shadow_DemonicFortitude", minLevel = 62, tbcOnly = true },
  { id = "bindingheal",     name = "Binding Heal",         subspec = "holy",       spell = 32546, icon = ICON .. "Spell_Holy_BlindingHeal",       minLevel = 64, tbcOnly = true },
  { id = "prayerofmending", name = "Prayer of Mending",    subspec = "holy",       spell = 33076, icon = ICON .. "Spell_Holy_PrayerOfMendingtga", minLevel = 68, tbcOnly = true },
  { id = "massdispel",      name = "Mass Dispel",          subspec = "discipline", spell = 32375, icon = ICON .. "Spell_Arcane_MassDispel",       minLevel = 70, tbcOnly = true },
}

-- MAGE -------------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
-- Teleports and portals stay collapsed into one generic card each.
DL.abilityDecks.MAGE = {
  { id = "fireball",        name = "Fireball",             subspec = "fire",   spell = 133,   minLevel = 1 },
  { id = "arcaneintellect", name = "Arcane Intellect",     subspec = "arcane", spell = 1459,  minLevel = 1 },
  { id = "frostarmor",      name = "Frost Armor",          subspec = "frost",  spell = 168,   minLevel = 1 },
  { id = "frostbolt",       name = "Frostbolt",            subspec = "frost",  spell = 116,   minLevel = 4 },
  { id = "conjurewater",    name = "Conjure Water",        subspec = "arcane", spell = 5504,  minLevel = 4 },
  { id = "fireblast",       name = "Fire Blast",           subspec = "fire",   spell = 2136,  minLevel = 6 },
  { id = "conjurefood",     name = "Conjure Food",         subspec = "arcane", spell = 587,   minLevel = 6 },
  { id = "arcanemissiles",  name = "Arcane Missiles",      subspec = "arcane", spell = 5143,  minLevel = 8 },
  { id = "polymorph",       name = "Polymorph",            subspec = "arcane", spell = 118,   minLevel = 8 },
  { id = "frostnova",       name = "Frost Nova",           subspec = "frost",  spell = 122,   minLevel = 10 },
  { id = "dampenmagic",     name = "Dampen Magic",         subspec = "arcane", spell = 604,   minLevel = 12 },
  { id = "slowfall",        name = "Slow Fall",            subspec = "arcane", spell = 130,   minLevel = 12 },
  { id = "arcaneexplosion", name = "Arcane Explosion",     subspec = "arcane", spell = 1449,  minLevel = 14 },
  { id = "detectmagic",     name = "Detect Magic",         subspec = "arcane", spell = 2855,  minLevel = 16 },
  { id = "flamestrike",     name = "Flamestrike",          subspec = "fire",   spell = 2120,  minLevel = 16 },
  { id = "amplifymagic",    name = "Amplify Magic",        subspec = "arcane", spell = 1008,  minLevel = 18 },
  { id = "removecurse",     name = "Remove Lesser Curse",  subspec = "arcane", spell = 475,   minLevel = 18 },
  { id = "blink",           name = "Blink",                subspec = "arcane", spell = 1953,  minLevel = 20 },
  { id = "blizzard",        name = "Blizzard",             subspec = "frost",  spell = 10,    minLevel = 20 },
  { id = "manashield",      name = "Mana Shield",          subspec = "arcane", spell = 1463,  minLevel = 20 },
  { id = "teleport",        name = "Teleport",             subspec = "arcane", spell = 3561,  minLevel = 20 },
  { id = "evocation",       name = "Evocation",            subspec = "arcane", spell = 12051, minLevel = 20 },
  { id = "fireward",        name = "Fire Ward",            subspec = "fire",   spell = 543,   minLevel = 20 },
  { id = "scorch",          name = "Scorch",               subspec = "fire",   spell = 2948,  minLevel = 22 },
  { id = "frostward",       name = "Frost Ward",           subspec = "frost",  spell = 6143,  minLevel = 22 },
  { id = "counterspell",    name = "Counterspell",         subspec = "arcane", spell = 2139,  minLevel = 24 },
  { id = "coneofcold",      name = "Cone of Cold",         subspec = "frost",  spell = 120,   minLevel = 26 },
  { id = "conjuremanaagate",name = "Conjure Mana Agate",   subspec = "arcane", spell = 759,   minLevel = 28 },
  { id = "icearmor",        name = "Ice Armor",            subspec = "frost",  spell = 7302,  minLevel = 30 },
  { id = "magearmor",       name = "Mage Armor",           subspec = "arcane", spell = 6117,  minLevel = 34 },
  { id = "conjuremanajade", name = "Conjure Mana Jade",    subspec = "arcane", spell = 3552,  minLevel = 38 },
  { id = "portal",          name = "Portal",               subspec = "arcane", spell = 10059, minLevel = 40 },
  { id = "conjuremanacitrine", name = "Conjure Mana Citrine", subspec = "arcane", spell = 10053, minLevel = 48 },
  { id = "arcanebrilliance",name = "Arcane Brilliance",    subspec = "arcane", spell = 23028, minLevel = 56 },
  { id = "conjuremanaruby", name = "Conjure Mana Ruby",    subspec = "arcane", spell = 10054, minLevel = 58 },
  { id = "polycow",         name = "Polymorph: Cow",       subspec = "arcane", spell = 28270, minLevel = 60 },
  -- TBC-only
  { id = "moltenarmor",     name = "Molten Armor",         subspec = "fire",   spell = 30482, icon = ICON .. "Ability_Mage_MoltenArmor",  minLevel = 62, tbcOnly = true },
  { id = "icelance",        name = "Ice Lance",            subspec = "frost",  spell = 30455, icon = ICON .. "Spell_Frost_FrostBlast",    minLevel = 66, tbcOnly = true },
  { id = "invisibility",    name = "Invisibility",         subspec = "arcane", spell = 66,    icon = ICON .. "Ability_Mage_Invisibility", minLevel = 68, tbcOnly = true },
  { id = "spellsteal",      name = "Spellsteal",           subspec = "arcane", spell = 30449, icon = ICON .. "Spell_Arcane_Arcane02",     minLevel = 70, tbcOnly = true },
}

-- WARLOCK ----------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
-- Stone-creation tiers (Minor/Lesser/etc.) collapse into one card each;
-- Detect Invisibility tiers collapse into one card at 26.
DL.abilityDecks.WARLOCK = {
  { id = "demonskin",       name = "Demon Skin",           subspec = "demonology",  spell = 687,   minLevel = 1 },
  { id = "shadowbolt",      name = "Shadow Bolt",          subspec = "destruction", spell = 686,   minLevel = 1 },
  { id = "summonimp",       name = "Summon Imp",           subspec = "demonology",  spell = 688,   minLevel = 1 },
  { id = "immolate",        name = "Immolate",             subspec = "destruction", spell = 348,   minLevel = 1 },
  { id = "corruption",      name = "Corruption",           subspec = "affliction",  spell = 172,   minLevel = 4 },
  { id = "curseofweakness", name = "Curse of Weakness",    subspec = "affliction",  spell = 702,   minLevel = 4 },
  { id = "lifetap",         name = "Life Tap",             subspec = "affliction",  spell = 1454,  minLevel = 6 },
  { id = "curseofagony",    name = "Curse of Agony",       subspec = "affliction",  spell = 980,   minLevel = 8 },
  { id = "fear",            name = "Fear",                 subspec = "affliction",  spell = 5782,  minLevel = 8 },
  { id = "createhealthstone",name = "Create Healthstone",  subspec = "demonology",  spell = 6201,  minLevel = 10 },
  { id = "drainsoul",       name = "Drain Soul",           subspec = "affliction",  spell = 1120,  minLevel = 10 },
  { id = "summonvoidwalker",name = "Summon Voidwalker",    subspec = "demonology",  spell = 697,   minLevel = 10 },
  { id = "healthfunnel",    name = "Health Funnel",        subspec = "demonology",  spell = 755,   minLevel = 12 },
  { id = "curseofreck",     name = "Curse of Recklessness",subspec = "affliction",  spell = 704,   minLevel = 14 },
  { id = "drainlife",       name = "Drain Life",           subspec = "affliction",  spell = 689,   minLevel = 14 },
  { id = "unendingbreath",  name = "Unending Breath",      subspec = "demonology",  spell = 5697,  minLevel = 16 },
  { id = "createsoulstone", name = "Create Soulstone",     subspec = "demonology",  spell = 693,   minLevel = 18 },
  { id = "searingpain",     name = "Searing Pain",         subspec = "destruction", spell = 5676,  minLevel = 18 },
  { id = "demonarmor",      name = "Demon Armor",          subspec = "demonology",  spell = 706,   minLevel = 20 },
  { id = "rainoffire",      name = "Rain of Fire",         subspec = "destruction", spell = 5740,  minLevel = 20 },
  { id = "ritualofsummon",  name = "Ritual of Summoning",  subspec = "demonology",  spell = 698,   minLevel = 20 },
  { id = "summonsuccubus",  name = "Summon Succubus",      subspec = "demonology",  spell = 712,   minLevel = 20 },
  { id = "eyeofkilrogg",    name = "Eye of Kilrogg",       subspec = "demonology",  spell = 126,   minLevel = 22 },
  { id = "drainmana",       name = "Drain Mana",           subspec = "affliction",  spell = 5138,  minLevel = 24 },
  { id = "sensedemons",     name = "Sense Demons",         subspec = "demonology",  spell = 5500,  minLevel = 24 },
  { id = "curseoftongues",  name = "Curse of Tongues",     subspec = "affliction",  spell = 1714,  minLevel = 26 },
  { id = "detectinvis",     name = "Detect Invisibility",  subspec = "demonology",  spell = 132,   minLevel = 26 },
  { id = "banish",          name = "Banish",               subspec = "demonology",  spell = 710,   minLevel = 28 },
  { id = "createfirestone", name = "Create Firestone",     subspec = "demonology",  spell = 6366,  minLevel = 28 },
  { id = "hellfire",        name = "Hellfire",             subspec = "destruction", spell = 1949,  minLevel = 30 },
  { id = "subjugatedemon",  name = "Subjugate Demon",      subspec = "demonology",  spell = 1098,  minLevel = 30 },
  { id = "summonfelhunter", name = "Summon Felhunter",     subspec = "demonology",  spell = 691,   minLevel = 30 },
  { id = "curseofelements", name = "Curse of the Elements",subspec = "affliction",  spell = 1490,  minLevel = 32 },
  { id = "shadowward",      name = "Shadow Ward",          subspec = "destruction", spell = 6229,  minLevel = 32 },
  { id = "createspellstone",name = "Create Spellstone",    subspec = "demonology",  spell = 2362,  minLevel = 36 },
  { id = "howlofterror",    name = "Howl of Terror",       subspec = "affliction",  spell = 5484,  minLevel = 40 },
  { id = "summonfelsteed",  name = "Summon Felsteed",      subspec = "demonology",  spell = 5784,  minLevel = 40 },
  { id = "deathcoil",       name = "Death Coil",           subspec = "affliction",  spell = 6789,  minLevel = 42 },
  { id = "curseofshadow",   name = "Curse of Shadow",      subspec = "affliction",  spell = 17862, minLevel = 44 },
  { id = "soulfire",        name = "Soul Fire",            subspec = "destruction", spell = 6353,  minLevel = 48 },
  { id = "inferno",         name = "Inferno",              subspec = "destruction", spell = 1122,  minLevel = 50 },
  { id = "curseofdoom",     name = "Curse of Doom",        subspec = "affliction",  spell = 603,   minLevel = 60 },
  { id = "ritualofdoom",    name = "Ritual of Doom",       subspec = "demonology",  spell = 18540, minLevel = 60 },
  { id = "summondreadsteed",name = "Summon Dreadsteed",    subspec = "demonology",  spell = 23161, minLevel = 60 },
  -- TBC-only
  { id = "incinerate",      name = "Incinerate",           subspec = "destruction", spell = 29722, icon = ICON .. "Spell_Fire_Burnout",             minLevel = 64, tbcOnly = true },
  { id = "soulshatter",     name = "Soulshatter",          subspec = "demonology",  spell = 29858, icon = ICON .. "Spell_Arcane_Arcane01",          minLevel = 66, tbcOnly = true },
  { id = "seedofcorruption",name = "Seed of Corruption",   subspec = "affliction",  spell = 27243, icon = ICON .. "Spell_Shadow_SeedOfDestruction", minLevel = 70, tbcOnly = true },
}

-- DRUID ------------------------------------------------------------------
-- Verified against Wowhead Classic (spell = rank-1 ID, icons auto-resolve)
DL.abilityDecks.DRUID = {
  { id = "wrath",           name = "Wrath",               subspec = "balance",     spell = 5176,  minLevel = 1 },
  { id = "healingtouch",    name = "Healing Touch",       subspec = "restoration", spell = 5185,  minLevel = 1 },
  { id = "markofthewild",   name = "Mark of the Wild",    subspec = "restoration", spell = 1126,  minLevel = 1 },
  { id = "moonfire",        name = "Moonfire",            subspec = "balance",     spell = 8921,  minLevel = 4 },
  { id = "rejuvenation",    name = "Rejuvenation",        subspec = "restoration", spell = 774,   minLevel = 4 },
  { id = "thorns",          name = "Thorns",              subspec = "balance",     spell = 467,   minLevel = 6 },
  { id = "entanglingroots", name = "Entangling Roots",    subspec = "balance",     spell = 339,   minLevel = 8 },
  { id = "bearform",        name = "Bear Form",           subspec = "feral",       spell = 5487,  minLevel = 10 },
  { id = "maul",            name = "Maul",                subspec = "feral",       spell = 6807,  minLevel = 10 },
  { id = "demoroar",        name = "Demoralizing Roar",   subspec = "feral",       spell = 99,    minLevel = 10 },
  { id = "growl",           name = "Growl",               subspec = "feral",       spell = 6795,  minLevel = 10 },
  { id = "teleportmoonglade",name = "Teleport: Moonglade",subspec = "balance",     spell = 18960, minLevel = 10 },
  { id = "enrage",          name = "Enrage",              subspec = "feral",       spell = 5229,  minLevel = 12 },
  { id = "regrowth",        name = "Regrowth",            subspec = "restoration", spell = 8936,  minLevel = 12 },
  { id = "bash",            name = "Bash",                subspec = "feral",       spell = 5211,  minLevel = 14 },
  { id = "curepoison",      name = "Cure Poison",         subspec = "restoration", spell = 8946,  minLevel = 14 },
  { id = "aquaticform",     name = "Aquatic Form",        subspec = "feral",       spell = 1066,  minLevel = 16 },
  { id = "swipe",           name = "Swipe",               subspec = "feral",       spell = 779,   minLevel = 16 },
  { id = "faeriefire",      name = "Faerie Fire",         subspec = "balance",     spell = 770,   minLevel = 18 },
  { id = "hibernate",       name = "Hibernate",           subspec = "balance",     spell = 2637,  minLevel = 18 },
  { id = "catform",         name = "Cat Form",            subspec = "feral",       spell = 768,   minLevel = 20 },
  { id = "claw",            name = "Claw",                subspec = "feral",       spell = 1082,  minLevel = 20 },
  { id = "prowl",           name = "Prowl",               subspec = "feral",       spell = 5215,  minLevel = 20 },
  { id = "rip",             name = "Rip",                 subspec = "feral",       spell = 1079,  minLevel = 20 },
  { id = "rebirth",         name = "Rebirth",             subspec = "restoration", spell = 20484, minLevel = 20 },
  { id = "starfire",        name = "Starfire",            subspec = "balance",     spell = 2912,  minLevel = 20 },
  { id = "shred",           name = "Shred",               subspec = "feral",       spell = 5221,  minLevel = 22 },
  { id = "sootheanimal",    name = "Soothe Animal",       subspec = "balance",     spell = 2908,  minLevel = 22 },
  { id = "rake",            name = "Rake",                subspec = "feral",       spell = 1822,  minLevel = 24 },
  { id = "removecurse",     name = "Remove Curse",        subspec = "restoration", spell = 2782,  minLevel = 24 },
  { id = "tigersfury",      name = "Tiger's Fury",        subspec = "feral",       spell = 5217,  minLevel = 24 },
  { id = "abolishpoison",   name = "Abolish Poison",      subspec = "restoration", spell = 2893,  minLevel = 26 },
  { id = "dash",            name = "Dash",                subspec = "feral",       spell = 1850,  minLevel = 26 },
  { id = "challengingroar", name = "Challenging Roar",    subspec = "feral",       spell = 5209,  minLevel = 28 },
  { id = "cower",           name = "Cower",               subspec = "feral",       spell = 8998,  minLevel = 28 },
  { id = "tranquility",     name = "Tranquility",         subspec = "restoration", spell = 740,   minLevel = 30 },
  { id = "travelform",      name = "Travel Form",         subspec = "feral",       spell = 783,   minLevel = 30 },
  { id = "ferociousbite",   name = "Ferocious Bite",      subspec = "feral",       spell = 22568, minLevel = 32 },
  { id = "ravage",          name = "Ravage",              subspec = "feral",       spell = 6785,  minLevel = 32 },
  { id = "trackhumanoids",  name = "Track Humanoids",     subspec = "feral",       spell = 5225,  minLevel = 32 },
  { id = "frenziedregen",   name = "Frenzied Regeneration", subspec = "feral",     spell = 22842, minLevel = 36 },
  { id = "pounce",          name = "Pounce",              subspec = "feral",       spell = 9005,  minLevel = 36 },
  { id = "direbearform",    name = "Dire Bear Form",      subspec = "feral",       spell = 9634,  minLevel = 40 },
  { id = "felinegrace",     name = "Feline Grace",        subspec = "feral",       spell = 20719, minLevel = 40 },
  { id = "hurricane",       name = "Hurricane",           subspec = "balance",     spell = 16914, minLevel = 40 },
  { id = "innervate",       name = "Innervate",           subspec = "restoration", spell = 29166, minLevel = 40 },
  { id = "barkskin",        name = "Barkskin",            subspec = "balance",     spell = 22812, minLevel = 44 },
  { id = "giftofthewild",   name = "Gift of the Wild",    subspec = "restoration", spell = 21849, minLevel = 50 },
  -- TBC-only
  { id = "cyclone",         name = "Cyclone",             subspec = "balance",     spell = 33786, icon = ICON .. "Spell_Nature_EarthBind",   minLevel = 20, tbcOnly = true },
  { id = "maim",            name = "Maim",                subspec = "feral",       spell = 22570, icon = ICON .. "Ability_Druid_Mangle2",    minLevel = 62, tbcOnly = true },
  { id = "lifebloom",       name = "Lifebloom",           subspec = "restoration", spell = 33763, icon = ICON .. "INV_Misc_Herb_Felblossom", minLevel = 64, tbcOnly = true },
  { id = "lacerate",        name = "Lacerate",            subspec = "feral",       spell = 33745, icon = ICON .. "Ability_Druid_Lacerate",   minLevel = 66, tbcOnly = true },
}

---------------------------------------------------------------------------
-- Deck assembly: shared cards + the player's class abilities
---------------------------------------------------------------------------

local GENERIC_SPECS = {
  { key = "spec1", label = "Abilities" },
  { key = "spec2", label = "" },
  { key = "spec3", label = "" },
}

function DL.BuildDeck(classToken)
  DL.playerClass = classToken
  DL.specList = DL.specs[classToken] or GENERIC_SPECS

  DL.cards = {}
  for _, card in ipairs(DL.sharedCards) do
    DL.cards[#DL.cards + 1] = card
  end

  local abilities = DL.abilityDecks[classToken]
  if abilities then
    for _, card in ipairs(abilities) do
      card.type = "ability"
      DL.cards[#DL.cards + 1] = card
    end
  end
end

---------------------------------------------------------------------------
-- Enchanting materials deck (enchanting.json)
-- First 24 = Classic, last 6 = TBC (same split the app used).
---------------------------------------------------------------------------

DL.enchantingDeck = {
  { materialId = "ench-1",  name = "Strange Dust",       item = 10940, minLevel = 5 },
  { materialId = "ench-2",  name = "L.Magic Essence",    item = 10938, minLevel = 5 },
  { materialId = "ench-3",  name = "G.Magic Essence",    item = 10939, minLevel = 5 },
  { materialId = "ench-4",  name = "S.Glimmering Shard", item = 10978, minLevel = 5 },
  { materialId = "ench-5",  name = "L.Glimmering Shard", item = 11084, minLevel = 5 },
  { materialId = "ench-6",  name = "Soul Dust",          item = 11083, minLevel = 15 },
  { materialId = "ench-7",  name = "L.Astral Essence",   item = 10998, minLevel = 15 },
  { materialId = "ench-8",  name = "G.Astral Essence",   item = 11082, minLevel = 15 },
  { materialId = "ench-9",  name = "Vision Dust",        item = 11137, minLevel = 20 },
  { materialId = "ench-10", name = "L.Mystic Essence",   item = 11134, minLevel = 20 },
  { materialId = "ench-11", name = "G.Mystic Essence",   item = 11135, minLevel = 20 },
  { materialId = "ench-12", name = "S.Glowing Shard",    item = 11138, minLevel = 20 },
  { materialId = "ench-13", name = "L.Glowing Shard",    item = 11139, minLevel = 20 },
  { materialId = "ench-14", name = "Dream Dust",         item = 11176, minLevel = 35 },
  { materialId = "ench-15", name = "L.Nether Essence",   item = 11174, minLevel = 35 },
  { materialId = "ench-16", name = "G.Nether Essence",   item = 11175, minLevel = 35 },
  { materialId = "ench-17", name = "S.Radiant Shard",    item = 11177, minLevel = 35 },
  { materialId = "ench-18", name = "L.Radiant Shard",    item = 11178, minLevel = 35 },
  { materialId = "ench-19", name = "Illusion Dust",      item = 16204, minLevel = 50 },
  { materialId = "ench-20", name = "L.Eternal Essence",  item = 16202, minLevel = 50 },
  { materialId = "ench-21", name = "G.Eternal Essence",  item = 16203, minLevel = 50 },
  { materialId = "ench-22", name = "S.Brilliant Shard",  item = 14343, minLevel = 50 },
  { materialId = "ench-23", name = "L.Brilliant Shard",  item = 14344, minLevel = 50 },
  { materialId = "ench-24", name = "Nexus Crystal",      item = 20725, minLevel = 50 },
  -- TBC
  { materialId = "ench-25", name = "Arcane Dust",        item = 22445, minLevel = 60 },
  { materialId = "ench-26", name = "L.Planar Essence",   item = 22447, minLevel = 60 },
  { materialId = "ench-27", name = "G.Planar Essence",   item = 22446, minLevel = 60 },
  { materialId = "ench-28", name = "S.Prismatic Shard",  item = 22448, minLevel = 60 },
  { materialId = "ench-29", name = "L.Prismatic Shard",  item = 22449, minLevel = 60 },
  { materialId = "ench-30", name = "Void Crystal",       item = 22450, minLevel = 60 },
}
DL.ENCH_CLASSIC_COUNT = 24

---------------------------------------------------------------------------
-- Jewelcrafting materials deck (jewelcraft.json)
-- First 27 = Classic, last 16 = TBC (same split the app used).
---------------------------------------------------------------------------

DL.jewelcraftDeck = {
  { materialId = "jc-1",  name = "Copper Ore",         item = 2770,  minLevel = 5 },
  { materialId = "jc-2",  name = "Rough Stone",        item = 2835,  minLevel = 5 },
  { materialId = "jc-3",  name = "Shadowgem",          item = 1210,  minLevel = 5 },
  { materialId = "jc-4",  name = "Tigerseye",          item = 818,   minLevel = 5 },
  { materialId = "jc-5",  name = "Malachite",          item = 774,   minLevel = 5 },
  { materialId = "jc-6",  name = "Tin Ore",            item = 2771,  minLevel = 10 },
  { materialId = "jc-7",  name = "Coarse Stone",       item = 2836,  minLevel = 10 },
  { materialId = "jc-8",  name = "Moss Agate",         item = 1206,  minLevel = 10 },
  { materialId = "jc-9",  name = "Lesser Moonstone",   item = 1705,  minLevel = 10 },
  { materialId = "jc-10", name = "Jade",               item = 1529,  minLevel = 10 },
  { materialId = "jc-11", name = "Iron Ore",           item = 2772,  minLevel = 20 },
  { materialId = "jc-12", name = "Heavy Stone",        item = 2838,  minLevel = 20 },
  { materialId = "jc-13", name = "Citrine",            item = 3864,  minLevel = 20 },
  { materialId = "jc-14", name = "Aquamarine",         item = 7909,  minLevel = 20 },
  { materialId = "jc-15", name = "Silver Ore",         item = 2775,  minLevel = 15 },
  { materialId = "jc-16", name = "Gold Ore",           item = 2776,  minLevel = 30 },
  { materialId = "jc-17", name = "Truesilver Ore",     item = 7911,  minLevel = 50 },
  { materialId = "jc-18", name = "Mithril Ore",        item = 3858,  minLevel = 30 },
  { materialId = "jc-19", name = "Solid Stone",        item = 7912,  minLevel = 30 },
  { materialId = "jc-20", name = "Star Ruby",          item = 7910,  minLevel = 30 },
  { materialId = "jc-21", name = "Thorium Ore",        item = 10620, minLevel = 40 },
  { materialId = "jc-22", name = "Dense Stone",        item = 12365, minLevel = 40 },
  { materialId = "jc-23", name = "Azerothian Diamond", item = 12800, minLevel = 40 },
  { materialId = "jc-24", name = "Huge Emerald",       item = 12364, minLevel = 40 },
  { materialId = "jc-25", name = "Blue Sapphire",      item = 12361, minLevel = 40 },
  { materialId = "jc-26", name = "Large Opal",         item = 12799, minLevel = 40 },
  { materialId = "jc-27", name = "Arcane Crystal",     item = 12363, minLevel = 40 },
  -- TBC
  { materialId = "jc-28", name = "Fel Iron Ore",       item = 23424, minLevel = 60 },
  { materialId = "jc-29", name = "Adamantite Ore",     item = 23425, minLevel = 60 },
  { materialId = "jc-30", name = "Khorium Ore",        item = 23426, minLevel = 60 },
  { materialId = "jc-31", name = "Eternium Ore",       item = 23427, minLevel = 60 },
  { materialId = "jc-32", name = "Golden Draenite",    item = 23112, minLevel = 60 },
  { materialId = "jc-33", name = "Blood Garnet",       item = 23077, minLevel = 60 },
  { materialId = "jc-34", name = "Deep Peridot",       item = 23079, minLevel = 60 },
  { materialId = "jc-35", name = "Flame Spessarite",   item = 21929, minLevel = 60 },
  { materialId = "jc-36", name = "Shadow Draenite",    item = 23107, minLevel = 60 },
  { materialId = "jc-37", name = "Azure Moonstone",    item = 23108, minLevel = 60 },
  { materialId = "jc-38", name = "Dawnstone",          item = 23440, minLevel = 65 },
  { materialId = "jc-39", name = "Nightseye",          item = 23441, minLevel = 65 },
  { materialId = "jc-40", name = "Living Ruby",        item = 23436, minLevel = 65 },
  { materialId = "jc-41", name = "Noble Topaz",        item = 23439, minLevel = 65 },
  { materialId = "jc-42", name = "Talasite",           item = 23437, minLevel = 65 },
  { materialId = "jc-43", name = "Star of Elune",      item = 23438, minLevel = 65 },
}
DL.JC_CLASSIC_COUNT = 27

---------------------------------------------------------------------------
-- Dungeons (completing one grants a material roll)
---------------------------------------------------------------------------

DL.classicDungeons = {
  "RFC", "WC", "DM", "SFK", "BFD", "Stocks", "Gnomer", "RFK",
  "SM GY", "SM Lib", "SM Arms", "SM Cath", "SM Bonus", "RFD",
  "Ulda", "ZF", "Mara", "ST", "BRD", "LBRS", "UBRS",
  "DME", "DMW", "DMN", "Strat", "Scholo", "Classic Bonus",
}

DL.tbcDungeons = {
  "Ramps", "BF", "SP", "UB", "MT", "AC",
  "Old Hillsbrad", "Sethekk Halls", "SV", "Shadow Lab", "SHalls",
  "BM", "Bot", "Mech", "Arca", "TBC Bonus",
}

-- Final-boss NPC ids per dungeon: killing any listed npc auto-completes
-- the dungeon. The "Bonus" boxes are derived (all wings / all dungeons)
-- and have no bosses of their own.
DL.dungeonBosses = {
  ["RFC"]    = { 11518, 11519, 11520 },     -- Jergosh, Bazzalan, Taragaman
  ["WC"]     = { 3654 },                    -- Mutanus the Devourer
  ["DM"]     = { 639 },                     -- Edwin VanCleef
  ["SFK"]    = { 4275 },                    -- Archmage Arugal
  ["BFD"]    = { 4829 },                    -- Aku'mai
  ["Stocks"] = { 1716 },                    -- Bazil Thredd
  ["Gnomer"] = { 7800 },                    -- Mekgineer Thermaplugg
  ["RFK"]    = { 4421 },                    -- Charlga Razorflank
  ["SM GY"]  = { 4543 },                    -- Bloodmage Thalnos
  ["SM Lib"] = { 6487 },                    -- Arcanist Doan
  ["SM Arms"]= { 3975 },                    -- Herod
  ["SM Cath"]= { 3977, 3976 },              -- Whitemane, Mograine
  ["RFD"]    = { 7358 },                    -- Amnennar the Coldbringer
  ["Ulda"]   = { 2748 },                    -- Archaedas
  ["ZF"]     = { 7267 },                    -- Chief Ukorz Sandscalp
  ["Mara"]   = { 12201 },                   -- Princess Theradras
  ["ST"]     = { 5709 },                    -- Shade of Eranikus
  ["BRD"]    = { 9019 },                    -- Emperor Dagran Thaurissan
  ["LBRS"]   = { 9568 },                    -- Overlord Wyrmthalak
  ["UBRS"]   = { 10363 },                   -- General Drakkisath
  ["DME"]    = { 11492 },                   -- Alzzin the Wildshaper
  ["DMW"]    = { 11486 },                   -- Prince Tortheldrin
  ["DMN"]    = { 11501 },                   -- King Gordok
  ["Strat"]  = { 10440, 10813 },            -- Baron Rivendare, Balnazzar
  ["Scholo"] = { 1853 },                    -- Darkmaster Gandling
  -- TBC (inert on Classic Era; ready for TBC clients)
  ["Ramps"]  = { 17536, 17537 },            -- Nazan, Vazruden
  ["BF"]     = { 17377 },                   -- Keli'dan the Breaker
  ["SP"]     = { 17942 },                   -- Quagmirran
  ["UB"]     = { 17882 },                   -- The Black Stalker
  ["MT"]     = { 18344 },                   -- Nexus-Prince Shaffar
  ["AC"]     = { 18373 },                   -- Exarch Maladaar
  ["Old Hillsbrad"] = { 18096 },            -- Epoch Hunter
  ["Sethekk Halls"] = { 18473 },            -- Talon King Ikiss
  ["SV"]     = { 17798 },                   -- Warlord Kalithresh
  ["Shadow Lab"] = { 18708 },               -- Murmur
  ["SHalls"] = { 16808 },                   -- Warchief Kargath Bladefist
  ["BM"]     = { 17881 },                   -- Aeonus
  ["Bot"]    = { 17977 },                   -- Warp Splinter
  ["Mech"]   = { 19220 },                   -- Pathaleon the Calculator
  ["Arca"]   = { 20912 },                   -- Harbinger Skyriss
}

-- reverse lookup: npcId -> dungeon name
DL.bossToDungeon = {}
for dungeon, ids in pairs(DL.dungeonBosses) do
  for _, id in ipairs(ids) do
    DL.bossToDungeon[id] = dungeon
  end
end

---------------------------------------------------------------------------
-- Bonus-draw checkboxes (profession levels + misc goals)
---------------------------------------------------------------------------

DL.enchantLevelBoxes = {
  { id = "enchant-75",  label = "75" },
  { id = "enchant-150", label = "150" },
  { id = "enchant-225", label = "225" },
  { id = "enchant-300", label = "300" },
  { id = "enchant-375", label = "375" },
}

DL.jcLevelBoxes = {
  { id = "jc-75",  label = "75" },
  { id = "jc-150", label = "150" },
  { id = "jc-225", label = "225" },
  { id = "jc-300", label = "300" },
  { id = "jc-375", label = "375" },
}

DL.miscBoxes = {
  { id = "misc-jc-mats",       label = "JC Mats" },
  { id = "misc-ench-mats",     label = "Ench Mats" },
  { id = "misc-exalted-rep",   label = "Exalted Rep" },
  { id = "misc-1k-hk",         label = "1k HK" },
  { id = "misc-mongoose",      label = "Big Game Hunter" },
  { id = "misc-dire-mauls",    label = "Kill Illidan" },
  { id = "misc-classic-dungs", label = "Epic Weapons" },
  { id = "misc-tbc-dungs",     label = "Explore Outlands" },
  { id = "misc-kara",          label = "Kara" },
  { id = "misc-pet",           label = "Pet" },
  { id = "misc-epic-flier",    label = "Epic Flier" },
  { id = "misc-world-boss",    label = "World Boss" },
  { id = "misc-tbc-heroics",   label = "TBC Heroics" },
}

---------------------------------------------------------------------------
-- Icon resolution helper
---------------------------------------------------------------------------

local GetItemIconCompat = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
local GetSpellTextureCompat = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture

function DL.GetCardIcon(card)
  if card.spell then
    local tex = GetSpellTextureCompat and GetSpellTextureCompat(card.spell)
    if tex then return tex end
  end
  if card.item then
    local tex = GetItemIconCompat and GetItemIconCompat(card.item)
    if tex then return tex end
  end
  if card.invSlot then
    local _, tex = GetInventorySlotInfo(card.invSlot)
    if tex then return tex end
  end
  return card.icon or DL.QUESTION_MARK
end

---------------------------------------------------------------------------
-- Expansion gating: TBC-only content is hidden on the Classic Era client
---------------------------------------------------------------------------

for i = DL.ENCH_CLASSIC_COUNT + 1, #DL.enchantingDeck do
  DL.enchantingDeck[i].tbcOnly = true
end
for i = DL.JC_CLASSIC_COUNT + 1, #DL.jewelcraftDeck do
  DL.jewelcraftDeck[i].tbcOnly = true
end

DL.IS_CLASSIC_ERA = (WOW_PROJECT_ID ~= nil and WOW_PROJECT_CLASSIC ~= nil
  and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

-- true if this card should be excluded on the current client
function DL.IsCardGated(card)
  return card.tbcOnly and DL.IS_CLASSIC_ERA or false
end
