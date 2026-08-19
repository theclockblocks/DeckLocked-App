-- DeckLocked core: state, saved variables and all game logic.
-- UI.lua reads state through DL and calls these functions.
--
-- Level comes straight from the character (UnitLevel). Where the original
-- app made "choose a card" increment a manual level counter, the addon
-- inverts that loop: leveling up EARNS a draw credit, and choosing a card
-- from a normal draw spends one.

local ADDON, DL = ...

DL.currentDraw = nil        -- array of card tables currently on display
DL.currentDrawIsBonus = false
DL.materialDraw = { ench = nil, jc = nil }  -- currently displayed material cards

-- id -> card lookups, rebuilt after the deck is assembled
function DL.RebuildCardIndex()
  DL.cardIndex = {}
  for _, card in ipairs(DL.cards or {}) do
    DL.cardIndex[card.id] = card
  end
  DL.materialIndex = {}
  for _, card in ipairs(DL.enchantingDeck) do
    DL.materialIndex[card.materialId] = card
  end
  for _, card in ipairs(DL.jewelcraftDeck) do
    DL.materialIndex[card.materialId] = card
  end
end

---------------------------------------------------------------------------
-- Saved state
---------------------------------------------------------------------------

local defaults = {
  bonusDraws = 0,
  rolls = 0,
  enforce = true, -- gray/lock game UI for things not yet unlocked
  minimapAngle = 220, -- position of the minimap button (degrees)
  minimapHide = false,

  drawn = {},      -- [cardId] = true, main deck cards already taken
  unlocked = {},   -- [boxId] = true, visual boxes (gear slots, talents, profs, general, level/misc boxes)
  materials = {},  -- [materialId] = true, enchanting + jewelcrafting mats collected
  dungeons = {},   -- [dungeonName] = true
  -- drawCredits is initialized in SetupForPlayer (needs UnitLevel)
}

function DL.InitDB()
  DeckLockedCharDB = DeckLockedCharDB or {}
  local db = DeckLockedCharDB
  for k, v in pairs(defaults) do
    if db[k] == nil then
      db[k] = (type(v) == "table") and {} or v
    end
  end
  DL.db = db
end

-- Runs at PLAYER_LOGIN, when class and level are reliably available.
function DL.SetupForPlayer()
  local _, classToken = UnitClass("player")
  DL.BuildDeck(classToken)

  local db = DL.db
  if db.drawCredits == nil then
    -- Fresh character: one draw per level you already have (the app drew
    -- once per level starting at 1). Migration from the old manual-level
    -- version: levels it already counted are draws already spent.
    local level = UnitLevel("player") or 1
    local used = (db.level and db.level > 1) and (db.level - 1) or 0
    db.drawCredits = math.max(0, level - used)
    db.level = nil -- old manual counter, no longer used
  end

  DL.RebuildCardIndex()

  -- Restore an in-progress draw and unclaimed material cards across
  -- sessions, so relogging can't be used to reroll.
  if db.pendingDrawIds then
    local cards = {}
    for _, id in ipairs(db.pendingDrawIds) do
      local card = DL.cardIndex[id]
      if card then cards[#cards + 1] = card end
    end
    DL.currentDraw = (#cards > 0) and cards or nil
    DL.currentDrawIsBonus = db.pendingDrawBonus or false
  end
  if db.materialDrawIds then
    DL.materialDraw.ench = db.materialDrawIds.ench and DL.materialIndex[db.materialDrawIds.ench] or nil
    DL.materialDraw.jc = db.materialDrawIds.jc and DL.materialIndex[db.materialDrawIds.jc] or nil
  end
end

function DL.PlayerLevel()
  return UnitLevel("player") or 1
end

function DL.ResetAll()
  wipe(DeckLockedCharDB)
  DL.InitDB()
  DL.SetupForPlayer()
  DL.currentDraw = nil
  DL.currentDrawIsBonus = false
  DL.materialDraw = { ench = nil, jc = nil }
  DL.Refresh()
  DL.Msg("Progress reset.")
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

function DL.Msg(text)
  print("|cff00ff88DeckLocked:|r " .. text)
end

function DL.Warn(text)
  if UIErrorsFrame then
    UIErrorsFrame:AddMessage(text, 1, 0.3, 0.3)
  end
  DL.Msg(text)
end

local function playDrawSound()
  if PlaySound and SOUNDKIT then
    PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
  end
end

local function playClickSound()
  if PlaySound and SOUNDKIT then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

function DL.FormatNumber(n)
  -- shows 3 as "3" and 2.5 as "2.5"
  return string.format("%g", n)
end

---------------------------------------------------------------------------
-- Main deck
---------------------------------------------------------------------------

function DL.EligibleCards()
  local out = {}
  local level = DL.PlayerLevel()
  for _, card in ipairs(DL.cards) do
    if not DL.db.drawn[card.id] and card.minLevel <= level and not DL.IsCardGated(card) then
      out[#out + 1] = card
    end
  end
  return out
end

function DL.AvailableCount()
  return #DL.EligibleCards()
end

function DL.DrawCards(isBonus)
  -- no free rerolls under enforcement: resolve the shown draw first
  if DL.db.enforce and DL.currentDraw then
    DL.Warn("Finish your current draw first - choose a card!")
    return
  end

  if isBonus then
    if DL.db.bonusDraws <= 0 then
      DL.Warn("No bonus draws available!")
      return
    end
  else
    if (DL.db.drawCredits or 0) < 1 then
      DL.Warn("No draws available - level up to earn more!")
      return
    end
  end

  local eligible = DL.EligibleCards()
  if #eligible == 0 then
    DL.Warn("No cards available to draw!")
    return
  end

  -- Fisher-Yates, then take up to 3
  for i = #eligible, 2, -1 do
    local j = math.random(i)
    eligible[i], eligible[j] = eligible[j], eligible[i]
  end

  local selected = {}
  for i = 1, math.min(3, #eligible) do
    selected[i] = eligible[i]
  end

  DL.currentDraw = selected
  DL.currentDrawIsBonus = isBonus and true or false
  DL.db.pendingDrawIds = {}
  for i, card in ipairs(selected) do
    DL.db.pendingDrawIds[i] = card.id
  end
  DL.db.pendingDrawBonus = DL.currentDrawIsBonus
  DL.db.lastUndo = nil
  playDrawSound()
  DL.Refresh()
end

function DL.ChooseCard(card)
  DL.db.drawn[card.id] = true
  -- single-level undo context: which card, what it cost, and the exact
  -- three cards shown (so undo can restore them - no reroll advantage)
  DL.db.lastUndo = {
    cardId = card.id,
    bonus = DL.currentDrawIsBonus and true or false,
    drawIds = DL.db.pendingDrawIds,
  }
  DL.db.pendingDrawIds = nil
  DL.db.pendingDrawBonus = nil

  if card.type == "gear" then
    DL.db.unlocked[card.slot] = true
  elseif card.type == "talent" then
    -- unlock the first locked talent box
    for i = 1, 12 do
      if not DL.db.unlocked["talent-" .. i] then
        DL.db.unlocked["talent-" .. i] = true
        break
      end
    end
  elseif card.type == "profession" then
    DL.db.unlocked[card.profession] = true
  elseif card.type == "general" then
    DL.db.unlocked[card.general] = true
  end
  -- abilities need no box: the ability lists render straight from drawn state

  if DL.currentDrawIsBonus then
    DL.db.bonusDraws = math.max(0, DL.db.bonusDraws - 1)
  else
    DL.db.drawCredits = math.max(0, (DL.db.drawCredits or 0) - 1)
  end

  DL.currentDraw = nil
  DL.currentDrawIsBonus = false
  playClickSound()
  DL.Refresh()
end

-- With cards on display: puts them back (blocked under enforcement - you
-- must choose). After a choice: full single-step undo - reverts the
-- unlock, refunds what was spent, and restores the SAME three cards.
function DL.ReturnDraw()
  if DL.currentDraw then
    if DL.db.enforce then
      DL.Warn("Enforcement is on - you must choose one of the drawn cards.")
      return
    end
    DL.currentDraw = nil
    DL.currentDrawIsBonus = false
    DL.db.pendingDrawIds = nil
    DL.db.pendingDrawBonus = nil
    DL.Refresh()
    return
  end

  local undo = DL.db.lastUndo
  if not undo then
    DL.Warn("No cards to return.")
    return
  end

  local card = DL.cardIndex and DL.cardIndex[undo.cardId]
  if card then
    DL.db.drawn[card.id] = nil

    -- revert whatever the card unlocked
    if card.type == "gear" then
      DL.db.unlocked[card.slot] = nil
    elseif card.type == "profession" then
      DL.db.unlocked[card.profession] = nil
    elseif card.type == "general" then
      DL.db.unlocked[card.general] = nil
    elseif card.type == "talent" then
      for i = 12, 1, -1 do
        if DL.db.unlocked["talent-" .. i] then
          DL.db.unlocked["talent-" .. i] = nil
          break
        end
      end
    end

    -- refund what the choice spent
    if undo.bonus then
      DL.db.bonusDraws = DL.db.bonusDraws + 1
    else
      DL.db.drawCredits = (DL.db.drawCredits or 0) + 1
    end

    -- put the same three cards back on display
    if undo.drawIds then
      local cards = {}
      for _, id in ipairs(undo.drawIds) do
        local c = DL.cardIndex[id]
        if c then cards[#cards + 1] = c end
      end
      DL.currentDraw = (#cards > 0) and cards or nil
      DL.currentDrawIsBonus = undo.bonus
      DL.db.pendingDrawIds = undo.drawIds
      DL.db.pendingDrawBonus = undo.bonus
    end

    DL.Msg("Returned '" .. card.name .. "' - unlock reverted, draw restored.")
  end

  DL.db.lastUndo = nil
  DL.Refresh()
end

---------------------------------------------------------------------------
-- Manual toggles
---------------------------------------------------------------------------

function DL.ToggleBox(id)
  if DL.db.enforce then
    DL.Warn("Enforcement is on - unlocks come from card draws. (/dl enforce off to edit manually)")
    return
  end
  DL.db.unlocked[id] = not DL.db.unlocked[id] or nil
  playClickSound()
  DL.Refresh()
end

-- Level/misc boxes grant a bonus draw when checked (and take it back).
-- Under enforcement you can't uncheck a box whose draw was already spent
-- (the old clamp made check/spend/uncheck/recheck print bonus draws).
function DL.ToggleBonusBox(id)
  if DL.db.unlocked[id] then
    if DL.db.enforce and DL.db.bonusDraws < 1 then
      DL.Warn("That bonus draw was already spent - can't uncheck this goal.")
      return
    end
    DL.db.unlocked[id] = nil
    DL.db.bonusDraws = math.max(0, DL.db.bonusDraws - 1)
  else
    DL.db.unlocked[id] = true
    DL.db.bonusDraws = DL.db.bonusDraws + 1
  end
  playClickSound()
  DL.Refresh()
end

function DL.ToggleMaterial(materialId)
  if DL.db.enforce then
    DL.Warn("Enforcement is on - materials come from dungeon rolls. (/dl enforce off to edit manually)")
    return
  end
  DL.db.materials[materialId] = not DL.db.materials[materialId] or nil
  playClickSound()
  DL.Refresh()
end

function DL.TalentPoints()
  local points = 0
  for i = 1, 12 do
    if DL.db.unlocked["talent-" .. i] then
      points = points + 5
    end
  end
  return points
end

---------------------------------------------------------------------------
-- Credits / rolls adjustments
---------------------------------------------------------------------------

function DL.AdjustCredits(delta)
  if DL.db.enforce then
    DL.Warn("Enforcement is on - draws come from leveling up.")
    return
  end
  DL.db.drawCredits = math.max(0, (DL.db.drawCredits or 0) + delta)
  DL.Refresh()
end

function DL.AdjustRolls(delta)
  if DL.db.enforce then
    DL.Warn("Enforcement is on - rolls come from completing dungeons.")
    return
  end
  DL.db.rolls = math.max(0, DL.db.rolls + delta)
  DL.Refresh()
end

---------------------------------------------------------------------------
-- Dungeons
---------------------------------------------------------------------------

-- Bonus boxes are derived: SM Bonus = all four SM wings, Classic/TBC
-- Bonus = every other dungeon in that list.
local function allComplete(names, skip)
  for _, name in ipairs(names) do
    if name ~= skip and not DL.db.dungeons[name] then
      return false
    end
  end
  return true
end

function DL.CheckBonusDungeons()
  if not DL.db.dungeons["SM Bonus"]
      and DL.db.dungeons["SM GY"] and DL.db.dungeons["SM Lib"]
      and DL.db.dungeons["SM Arms"] and DL.db.dungeons["SM Cath"] then
    DL.CompleteDungeon("SM Bonus", true)
  end
  if not DL.db.dungeons["Classic Bonus"] and allComplete(DL.classicDungeons, "Classic Bonus") then
    DL.CompleteDungeon("Classic Bonus", true)
  end
  if not DL.db.dungeons["TBC Bonus"] and allComplete(DL.tbcDungeons, "TBC Bonus") then
    DL.CompleteDungeon("TBC Bonus", true)
  end
end

-- auto = triggered by a detected boss kill (or a derived bonus), which is
-- the only path allowed while enforcement is on
function DL.CompleteDungeon(name, auto)
  if DL.db.enforce and not auto then
    DL.Warn("Enforcement is on - dungeons complete automatically when the final boss dies.")
    return
  end
  if not DL.db.dungeons[name] then
    DL.db.dungeons[name] = true
    DL.db.rolls = DL.db.rolls + 1
    playClickSound()
    DL.Msg(name .. " complete! You earned 1 material roll.")
    DL.CheckBonusDungeons()
    DL.Refresh()
  end
end

-- Shift-click un-complete (manual-mode QoL only)
function DL.UncompleteDungeon(name)
  if DL.db.enforce then
    DL.Warn("Enforcement is on - dungeon completion can't be undone.")
    return
  end
  if DL.db.dungeons[name] then
    DL.db.dungeons[name] = nil
    DL.db.rolls = math.max(0, DL.db.rolls - 1)
    playClickSound()
    DL.Refresh()
  end
end

---------------------------------------------------------------------------
-- Boss-kill detection + group sync
---------------------------------------------------------------------------

DL.MSG_PREFIX = "DeckLocked"

-- Share a detected kill with the group, so members who were dead, released
-- or out of combat-log range still get credit (addon messages reach the
-- whole group regardless of distance).
function DL.BroadcastBossKill(npcId)
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
  local channel
  if IsInRaid() then
    channel = "RAID"
  elseif IsInGroup() then
    channel = "PARTY"
  end
  if channel then
    C_ChatInfo.SendAddonMessage(DL.MSG_PREFIX, "KILL:" .. npcId, channel)
  end
end

-- Boss-kill detection: any UNIT_DIED in the combat log whose npc id maps
-- to a dungeon's final boss completes that dungeon.
function DL.OnCombatLogEvent()
  local _, subevent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
  if subevent ~= "UNIT_DIED" or not destGUID then return end
  local npcId = tonumber((select(6, strsplit("-", destGUID))))
  local dungeon = npcId and DL.bossToDungeon[npcId]
  if dungeon then
    -- broadcast even if we already have it: others may not
    DL.BroadcastBossKill(npcId)
    if not DL.db.dungeons[dungeon] then
      DL.CompleteDungeon(dungeon, true)
    end
  end
end

-- A group member's DeckLocked reported a kill. Only group channels are
-- trusted - whispers and other channels are ignored.
function DL.OnAddonMessage(prefix, msg, channel, sender)
  if prefix ~= DL.MSG_PREFIX then return end
  if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" then return end

  local shortSender = Ambiguate and Ambiguate(sender, "short") or sender
  if shortSender == UnitName("player") then return end

  local npcId = msg:match("^KILL:(%d+)$")
  local dungeon = npcId and DL.bossToDungeon[tonumber(npcId)]
  if dungeon and not DL.db.dungeons[dungeon] then
    DL.Msg("Boss kill shared by " .. shortSender .. ".")
    DL.CompleteDungeon(dungeon, true)
  end
end

---------------------------------------------------------------------------
-- Material rolls
---------------------------------------------------------------------------

local function eligibleMaterials(deck)
  local out = {}
  local level = DL.PlayerLevel()
  for _, card in ipairs(deck) do
    if not DL.db.materials[card.materialId] and card.minLevel <= level and not DL.IsCardGated(card) then
      out[#out + 1] = card
    end
  end
  return out
end

function DL.IsEnchantingComplete()
  for _, card in ipairs(DL.enchantingDeck) do
    if not DL.IsCardGated(card) and not DL.db.materials[card.materialId] then
      return false
    end
  end
  return true
end

-- Cost per claimed material card: 0.5 normally, 1 once enchanting is done
-- (same rule as the app's getJewelcraftCost)
function DL.MaterialCost()
  return DL.IsEnchantingComplete() and 1 or 0.5
end

function DL.RollMaterials()
  -- no rerolling past cards you don't like
  if DL.db.enforce and (DL.materialDraw.ench or DL.materialDraw.jc) then
    DL.Warn("Claim your current material cards first!")
    return
  end

  if DL.db.rolls < 1 then
    DL.Warn("No material rolls available!")
    return
  end

  local ench = eligibleMaterials(DL.enchantingDeck)
  local jc = eligibleMaterials(DL.jewelcraftDeck)

  DL.materialDraw.ench = (#ench > 0) and ench[math.random(#ench)] or nil
  DL.materialDraw.jc = (#jc > 0) and jc[math.random(#jc)] or nil

  if not DL.materialDraw.ench and not DL.materialDraw.jc then
    DL.Warn("No materials left to roll!")
    return
  end

  DL.db.materialDrawIds = {
    ench = DL.materialDraw.ench and DL.materialDraw.ench.materialId or nil,
    jc = DL.materialDraw.jc and DL.materialDraw.jc.materialId or nil,
  }

  playDrawSound()
  DL.Refresh()
end

function DL.ClaimMaterial(which)
  local card = DL.materialDraw[which]
  if not card then return end

  local cost = DL.MaterialCost()
  if DL.db.enforce and DL.db.rolls < cost then
    DL.Warn("Not enough rolls to claim that (" .. DL.FormatNumber(cost) .. " needed).")
    return
  end

  DL.db.materials[card.materialId] = true
  DL.db.rolls = math.max(0, DL.db.rolls - cost)
  DL.materialDraw[which] = nil
  if DL.db.materialDrawIds then
    DL.db.materialDrawIds[which] = nil
  end
  playClickSound()
  DL.Refresh()
end

---------------------------------------------------------------------------
-- Refresh dispatch (UI.lua replaces this once the frame exists)
---------------------------------------------------------------------------

function DL.Refresh()
  if DL.UI_Refresh then
    DL.UI_Refresh()
  end
  if DL.Enforce_Update then
    DL.Enforce_Update()
  end
end

---------------------------------------------------------------------------
-- Events + slash command
---------------------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_LEVEL_UP")
loader:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
loader:RegisterEvent("CHAT_MSG_ADDON")
loader:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    if DL.db then
      DL.OnCombatLogEvent()
    end
  elseif event == "CHAT_MSG_ADDON" then
    if DL.db then
      DL.OnAddonMessage(arg1, arg2, arg3, arg4)
    end
  elseif event == "ADDON_LOADED" and arg1 == ADDON then
    DL.InitDB()
    self:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    if not DL.db then DL.InitDB() end
    DL.SetupForPlayer()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(DL.MSG_PREFIX)
    end
    if DL.UI_Init then
      DL.UI_Init()
    end
  elseif event == "PLAYER_LEVEL_UP" then
    if DL.db then
      DL.db.drawCredits = (DL.db.drawCredits or 0) + 1
      DL.Msg("Ding! +1 card draw (" .. DL.db.drawCredits .. " banked). Type /dl to spend it.")
      DL.Refresh()
    end
  end
end)

SLASH_DECKLOCKED1 = "/decklocked"
SLASH_DECKLOCKED2 = "/dl"
SlashCmdList.DECKLOCKED = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "reset" then
    StaticPopup_Show("DECKLOCKED_RESET")
  elseif msg == "enforce" then
    DL.SetEnforce(not DL.db.enforce)
  elseif msg == "enforce on" then
    DL.SetEnforce(true)
  elseif msg == "enforce off" then
    DL.SetEnforce(false)
  elseif msg == "minimap" then
    DL.db.minimapHide = not DL.db.minimapHide
    if DL.UpdateMinimapButton then DL.UpdateMinimapButton() end
    DL.Msg("Minimap button " .. (DL.db.minimapHide and "hidden" or "shown") .. ".")
  else
    DL.ToggleFrame()
  end
end

StaticPopupDialogs.DECKLOCKED_RESET = {
  text = "Reset ALL DeckLocked progress for this character?",
  button1 = YES,
  button2 = NO,
  OnAccept = function() DL.ResetAll() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
