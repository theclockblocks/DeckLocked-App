-- DeckLocked UI: main window with two pages (Main / Materials), mirroring
-- the layout of the original Electron app.

local ADDON, DL = ...

local ui = {
  gear = {},        -- [slotId] = button
  talents = {},     -- [1..12] = button
  profs = {},       -- [profId] = button
  general = {},     -- [generalId] = button
  abilityPools = {},-- [subspec] = { button, ... }
  materials = {},   -- [materialId] = button
  dungeons = {},    -- [name] = button
  bonusBoxes = {},  -- [boxId] = button
  drawCards = {},   -- [1..3] = card button
  matCards = {},    -- ench / jc = card button
}

local GOLD = { r = 1, g = 0.82, b = 0 }
local LOCKED_BORDER = { 0.67, 0, 0 }
local UNLOCKED_BORDER = { 0, 0.67, 0 }
local NEUTRAL_BORDER = { 0.4, 0.4, 0.4 }

local PANEL_BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local BOX_BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

---------------------------------------------------------------------------
-- Widget helpers
---------------------------------------------------------------------------

local function SetBoxState(box, unlocked)
  if unlocked then
    box:SetBackdropBorderColor(unpack(UNLOCKED_BORDER))
  else
    box:SetBackdropBorderColor(unpack(LOCKED_BORDER))
  end
  if box.icon then
    box.icon:SetDesaturated(not unlocked)
    box.icon:SetAlpha(unlocked and 1 or 0.55)
  end
  if box.label then
    if unlocked then
      box.label:SetTextColor(0.3, 1, 0.3)
    else
      box.label:SetTextColor(0.8, 0.8, 0.8)
    end
  end
end

local function AttachTooltip(widget)
  widget:SetScript("OnEnter", function(self)
    if not self.tooltipText then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltipText, 1, 1, 1)
    if self.tooltipSub then
      GameTooltip:AddLine(self.tooltipSub, 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreatePanel(parent, w, h)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(w, h)
  f:SetBackdrop(PANEL_BACKDROP)
  f:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
  f:SetBackdropBorderColor(0.3, 0.3, 0.3)
  return f
end

local function CreateHeader(parent, text)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetText(text)
  fs:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
  return fs
end

local function CreateIconBox(parent, size, tooltip)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(size, size)
  b:SetBackdrop(BOX_BACKDROP)
  b:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 2, -2)
  b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  b.tooltipText = tooltip
  AttachTooltip(b)
  SetBoxState(b, false)
  return b
end

local function CreateTextBox(parent, w, h, text, tooltip)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, h)
  b:SetBackdrop(BOX_BACKDROP)
  b:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.label:SetPoint("CENTER")
  b.label:SetText(text)
  if tooltip then
    b.tooltipText = tooltip
    AttachTooltip(b)
  end
  SetBoxState(b, false)
  return b
end

local function CreateActionButton(parent, w, h, text, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, h)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  return b
end

-- A big drawn-card button: icon + name + level requirement
local function CreateDrawCard(parent, w, h)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, h)
  b:SetBackdrop(PANEL_BACKDROP)
  b:SetBackdropColor(0.12, 0.09, 0.05, 0.95)
  b:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(h * 0.32, h * 0.32)
  b.icon:SetPoint("TOP", 0, -h * 0.12)
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.name:SetPoint("TOP", b.icon, "BOTTOM", 0, -8)
  b.name:SetWidth(w - 16)

  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.sub:SetPoint("TOP", b.name, "BOTTOM", 0, -4)
  b.sub:SetTextColor(0.7, 0.7, 0.7)

  b.hint = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.hint:SetPoint("BOTTOM", 0, 10)
  b.hint:SetText("Click to choose")
  b.hint:SetTextColor(0.5, 0.9, 0.5)

  b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0, 0.67, 1) end)
  b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b) end)
  b:Hide()
  return b
end

---------------------------------------------------------------------------
-- Frame construction
---------------------------------------------------------------------------

local frame

local function BuildToolbar()
  local bar = CreateFrame("Frame", nil, frame)
  bar:SetPoint("TOPLEFT", 10, -30)
  bar:SetPoint("TOPRIGHT", -10, -30)
  bar:SetHeight(30)

  ui.levelText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.levelText:SetPoint("LEFT", 4, 0)
  ui.levelText:SetTextColor(GOLD.r, GOLD.g, GOLD.b)

  ui.drawsText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.drawsText:SetPoint("LEFT", ui.levelText, "RIGHT", 20, 0)
  ui.drawsText:SetTextColor(1, 1, 1)

  ui.drawMinus = CreateActionButton(bar, 22, 20, "-", function() DL.AdjustCredits(-1) end)
  ui.drawMinus:SetPoint("LEFT", ui.drawsText, "RIGHT", 8, 0)
  ui.drawPlus = CreateActionButton(bar, 22, 20, "+", function() DL.AdjustCredits(1) end)
  ui.drawPlus:SetPoint("LEFT", ui.drawMinus, "RIGHT", 2, 0)

  ui.rollsText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.rollsText:SetPoint("LEFT", ui.drawPlus, "RIGHT", 20, 0)
  ui.rollsText:SetTextColor(0, 1, 0.53)

  ui.rollMinus = CreateActionButton(bar, 30, 20, "-.5", function() DL.AdjustRolls(-0.5) end)
  ui.rollMinus:SetPoint("LEFT", ui.rollsText, "RIGHT", 8, 0)
  ui.rollPlus = CreateActionButton(bar, 30, 20, "+.5", function() DL.AdjustRolls(0.5) end)
  ui.rollPlus:SetPoint("LEFT", ui.rollMinus, "RIGHT", 2, 0)

  ui.bonusText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.bonusText:SetPoint("LEFT", ui.rollPlus, "RIGHT", 20, 0)
  ui.bonusText:SetTextColor(0.4, 0.67, 1)

  local returnBtn = CreateActionButton(bar, 100, 20, "Return Draw", DL.ReturnDraw)
  returnBtn:SetPoint("RIGHT", -262, 0)

  ui.mainTab = CreateActionButton(bar, 64, 20, "Main", function() DL.ShowTab("main") end)
  ui.mainTab:SetPoint("RIGHT", -172, 0)
  ui.dungeonsTab = CreateActionButton(bar, 84, 20, "Dungeons", function() DL.ShowTab("dungeons") end)
  ui.dungeonsTab:SetPoint("RIGHT", -86, 0)
  ui.materialsTab = CreateActionButton(bar, 84, 20, "Materials", function() DL.ShowTab("materials") end)
  ui.materialsTab:SetPoint("RIGHT", -2, 0)
end

---------------------------------------------------------------------------
-- Main page
---------------------------------------------------------------------------

local function BuildGearPanel(page)
  local panel = CreatePanel(page, 232, 556)
  panel:SetPoint("TOPLEFT", 0, 0)

  local header = CreateHeader(panel, "Gear")
  header:SetPoint("TOP", 0, -10)

  local leftSlots = { "head", "neck", "shoulders", "back", "chest", "wrists", "hands" }
  local rightSlots = { "waist", "legs", "feet", "ring1", "ring2", "trinket1", "trinket2" }
  local bottomSlots = { "mainhand", "offhand", "relic" }

  local bySlot = {}
  for _, card in ipairs(DL.cards) do
    if card.type == "gear" then bySlot[card.slot] = card end
  end

  local function makeGearBox(slot, x, y)
    local card = bySlot[slot]
    local b = CreateIconBox(panel, 46, card.name)
    b.tooltipSub = "Card appears at level " .. card.minLevel .. "."
    b:SetPoint("TOPLEFT", x, y)
    b.icon:SetTexture(DL.GetCardIcon(card))
    b:SetScript("OnClick", function() DL.ToggleBox(slot) end)
    ui.gear[slot] = b
  end

  for i, slot in ipairs(leftSlots) do
    makeGearBox(slot, 36, -30 - (i - 1) * 52)
  end
  for i, slot in ipairs(rightSlots) do
    makeGearBox(slot, 150, -30 - (i - 1) * 52)
  end
  for i, slot in ipairs(bottomSlots) do
    makeGearBox(slot, 42 + (i - 1) * 52, -410)
  end
end

local function BuildAbilitiesAndDeck(page)
  local panel = CreatePanel(page, 508, 556)
  panel:SetPoint("TOPLEFT", 238, 0)

  local header = CreateHeader(panel, "Abilities")
  header:SetPoint("TOP", 0, -10)

  -- sections come from the player's class specs; count abilities per
  -- subspec so each pool is exactly big enough
  local sections = DL.specList or {}
  local counts = {}
  for _, section in ipairs(sections) do
    counts[section.key] = 0
  end
  for _, card in ipairs(DL.cards) do
    if card.type == "ability" and counts[card.subspec] then
      counts[card.subspec] = counts[card.subspec] + 1
    end
  end

  local PER_ROW = 16
  local ICON_SIZE = 26
  local y = -30
  for _, section in ipairs(sections) do
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 14, y)
    label:SetText(section.label)
    label:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    y = y - 16

    ui.abilityPools[section.key] = {}
    local rows = math.ceil(counts[section.key] / PER_ROW)
    for i = 1, counts[section.key] do
      local col = (i - 1) % PER_ROW
      local row = math.floor((i - 1) / PER_ROW)
      local b = CreateIconBox(panel, ICON_SIZE)
      b:SetPoint("TOPLEFT", 14 + col * (ICON_SIZE + 4), y - row * (ICON_SIZE + 4))
      b:EnableMouse(true)
      b:Hide()
      ui.abilityPools[section.key][i] = b
    end
    y = y - rows * (ICON_SIZE + 4) - 8
  end

  -- Deck controls
  local drawBtn = CreateActionButton(panel, 120, 26, "Draw 3 Cards", function() DL.DrawCards(false) end)
  drawBtn:SetPoint("TOPLEFT", 90, y - 6)
  local bonusBtn = CreateActionButton(panel, 120, 26, "Bonus Draw", function() DL.DrawCards(true) end)
  bonusBtn:SetPoint("LEFT", drawBtn, "RIGHT", 10, 0)

  ui.availableText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.availableText:SetPoint("LEFT", bonusBtn, "RIGHT", 14, 0)
  ui.availableText:SetTextColor(GOLD.r, GOLD.g, GOLD.b)

  -- Draw area: three cards
  local CARD_W, CARD_H = 150, 200
  for i = 1, 3 do
    local card = CreateDrawCard(panel, CARD_W, CARD_H)
    card:SetPoint("BOTTOMLEFT", 14 + (i - 1) * (CARD_W + 12), 14)
    ui.drawCards[i] = card
  end
end

local function BuildRightPanel(page)
  local panel = CreatePanel(page, 272, 556)
  panel:SetPoint("TOPLEFT", 752, 0)

  -- Talents
  local header = CreateHeader(panel, "Talents")
  header:SetPoint("TOP", 0, -10)

  for i = 1, 12 do
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    local b = CreateIconBox(panel, 44, "Talent +5")
    b:SetPoint("TOPLEFT", 62 + col * 50, -28 - row * 50)
    b.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local index = i
    b:SetScript("OnClick", function() DL.ToggleBox("talent-" .. index) end)

    local tp = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tp:SetPoint("BOTTOM", 0, 2)
    tp:SetText("+5")
    ui.talents[i] = b
  end

  ui.talentPoints = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.talentPoints:SetPoint("TOP", 0, -232)
  ui.talentPoints:SetTextColor(0.3, 1, 0.3)

  -- Professions
  local profHeader = CreateHeader(panel, "Professions")
  profHeader:SetPoint("TOP", 0, -256)

  local profs = {
    { id = "prof-1",   name = "Profession 1", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { id = "prof-2",   name = "Profession 2", icon = "Interface\\Icons\\Trade_Engineering" },
    { id = "cooking",  name = "Cooking",      icon = "Interface\\Icons\\INV_Misc_Food_15" },
    { id = "fishing",  name = "Fishing",      icon = "Interface\\Icons\\Trade_Fishing" },
    { id = "firstaid", name = "First Aid",    icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
  }
  for i, prof in ipairs(profs) do
    local b = CreateIconBox(panel, 42, prof.name)
    b:SetPoint("TOPLEFT", 18 + (i - 1) * 48, -274)
    b.icon:SetTexture(prof.icon)
    b:SetScript("OnClick", function() DL.ToggleBox(prof.id) end)
    ui.profs[prof.id] = b
  end

  -- General
  local genHeader = CreateHeader(panel, "General")
  genHeader:SetPoint("TOP", 0, -334)

  local generalRows = {
    {
      { id = "bag-1", name = "Bag Slot 1", icon = "Interface\\Icons\\INV_Misc_Bag_08" },
      { id = "bag-2", name = "Bag Slot 2", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
      { id = "bag-3", name = "Bag Slot 3", icon = "Interface\\Icons\\INV_Misc_Bag_11" },
      { id = "bag-4", name = "Bag Slot 4", icon = "Interface\\Icons\\INV_Misc_Bag_12" },
    },
    {
      { id = "mount",             name = "Mount",             icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
      { id = "epic-mount",        name = "Epic Mount",        icon = "Interface\\Icons\\Ability_Mount_Charger" },
      { id = "flying-mount",      name = "Flying Mount",      icon = "Interface\\Icons\\Ability_Mount_Gryphon_01" },
      { id = "epic-flying-mount", name = "Epic Flying Mount", icon = "Interface\\Icons\\Ability_Mount_GoldenGryphon" },
    },
  }
  for r, rowItems in ipairs(generalRows) do
    for i, item in ipairs(rowItems) do
      local b = CreateIconBox(panel, 42, item.name)
      b:SetPoint("TOPLEFT", 42 + (i - 1) * 48, -352 - (r - 1) * 48)
      b.icon:SetTexture(item.icon)
      b:SetScript("OnClick", function() DL.ToggleBox(item.id) end)
      ui.general[item.id] = b
    end
  end
end

---------------------------------------------------------------------------
-- Materials page
---------------------------------------------------------------------------

local function BuildMaterialGrid(panel, deck, from, to, xStart, yStart, perRow, size)
  for i = from, to do
    local card = deck[i]
    local idx = i - from
    local col = idx % perRow
    local row = math.floor(idx / perRow)
    local b = CreateIconBox(panel, size, card.name)
    b.tooltipSub = "Available at level " .. card.minLevel .. "."
    b:SetPoint("TOPLEFT", xStart + col * (size + 4), yStart - row * (size + 4))
    b.icon:SetTexture(DL.GetCardIcon(card))
    local materialId = card.materialId
    b:SetScript("OnClick", function() DL.ToggleMaterial(materialId) end)
    ui.materials[materialId] = b
  end
  return yStart - math.ceil((to - from + 1) / perRow) * (size + 4)
end

local function BuildBonusBoxRow(panel, boxes, xStart, yStart, w, h, perRow)
  for i, box in ipairs(boxes) do
    local col = (i - 1) % perRow
    local row = math.floor((i - 1) / perRow)
    local b = CreateTextBox(panel, w, h, box.label, "Grants 1 bonus draw when checked")
    b:SetPoint("TOPLEFT", xStart + col * (w + 4), yStart - row * (h + 4))
    local id = box.id
    b:SetScript("OnClick", function() DL.ToggleBonusBox(id) end)
    ui.bonusBoxes[id] = b
  end
  return yStart - math.ceil(#boxes / perRow) * (h + 4)
end

local function BuildEnchantingPanel(page)
  local panel = CreatePanel(page, 300, 556)
  panel:SetPoint("TOPLEFT", 0, 0)

  local h1 = CreateHeader(panel, "Classic Enchanting")
  h1:SetPoint("TOP", 0, -8)
  local y = BuildMaterialGrid(panel, DL.enchantingDeck, 1, DL.ENCH_CLASSIC_COUNT, 14, -26, 9, 26)

  local h2 = CreateHeader(panel, "TBC Enchanting")
  h2:SetPoint("TOP", 0, y - 6)
  y = BuildMaterialGrid(panel, DL.enchantingDeck, DL.ENCH_CLASSIC_COUNT + 1, #DL.enchantingDeck, 14, y - 24, 9, 26)

  local h3 = CreateHeader(panel, "Enchanting Level")
  h3:SetPoint("TOP", 0, y - 8)
  BuildBonusBoxRow(panel, DL.enchantLevelBoxes, 14, y - 26, 50, 20, 5)
end

-- Materials page center: misc goals + the roll/claim area
local function BuildMaterialsCenter(page)
  local panel = CreatePanel(page, 416, 556)
  panel:SetPoint("TOPLEFT", 306, 0)

  local h1 = CreateHeader(panel, "Misc Goals")
  h1:SetPoint("TOP", 0, -8)
  local y = BuildBonusBoxRow(panel, DL.miscBoxes, 24, -26, 120, 20, 3)

  local rollBtn = CreateActionButton(panel, 130, 26, "Roll Materials", DL.RollMaterials)
  rollBtn:SetPoint("TOP", 0, y - 16)

  -- Two claimable material cards (enchanting + jewelcrafting)
  local CARD_W, CARD_H = 130, 170
  local ench = CreateDrawCard(panel, CARD_W, CARD_H)
  ench:SetPoint("BOTTOMLEFT", 68, 20)
  ench.hint:SetText("Click to claim")
  ench:SetScript("OnClick", function() DL.ClaimMaterial("ench") end)
  ui.matCards.ench = ench

  local jc = CreateDrawCard(panel, CARD_W, CARD_H)
  jc:SetPoint("BOTTOMLEFT", 68 + CARD_W + 20, 20)
  jc.hint:SetText("Click to claim")
  jc:SetScript("OnClick", function() DL.ClaimMaterial("jc") end)
  ui.matCards.jc = jc
end

-- Dungeons page: classic on the left, TBC on the right
local function BuildDungeonsPage(page)
  local function makeDungeonBoxes(panel, names, yStart)
    local perRow = 4
    for i, name in ipairs(names) do
      local col = (i - 1) % perRow
      local row = math.floor((i - 1) / perRow)
      local b = CreateTextBox(panel, 114, 22, name, name)
      b.tooltipSub = "Auto-completes when the final boss dies (+1 material roll)."
      b:SetPoint("TOPLEFT", 16 + col * 120, yStart - row * 26)
      local dungeonName = name
      b:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          DL.UncompleteDungeon(dungeonName)
        else
          DL.CompleteDungeon(dungeonName)
        end
      end)
      ui.dungeons[dungeonName] = b
    end
    return yStart - math.ceil(#names / perRow) * 26
  end

  local classicPanel = CreatePanel(page, 508, 556)
  classicPanel:SetPoint("TOPLEFT", 0, 0)
  local h1 = CreateHeader(classicPanel, "Classic Dungeons")
  h1:SetPoint("TOP", 0, -10)
  makeDungeonBoxes(classicPanel, DL.classicDungeons, -32)

  local tbcPanel = CreatePanel(page, 508, 556)
  tbcPanel:SetPoint("TOPLEFT", 516, 0)
  local h2 = CreateHeader(tbcPanel, "TBC Dungeons")
  h2:SetPoint("TOP", 0, -10)
  makeDungeonBoxes(tbcPanel, DL.tbcDungeons, -32)

  local note = tbcPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("BOTTOM", 0, 16)
  note:SetWidth(440)
  note:SetTextColor(0.6, 0.6, 0.6)
  note:SetText("Dungeons complete automatically when their final boss dies. Kills are shared with party members running DeckLocked. Bonus boxes are earned by clearing every dungeon in their group.")
end

local function BuildJewelcraftPanel(page)
  local panel = CreatePanel(page, 296, 556)
  panel:SetPoint("TOPLEFT", 728, 0)

  local h1 = CreateHeader(panel, "Classic Jewelcrafting")
  h1:SetPoint("TOP", 0, -8)
  local y = BuildMaterialGrid(panel, DL.jewelcraftDeck, 1, DL.JC_CLASSIC_COUNT, 14, -26, 9, 26)

  local h2 = CreateHeader(panel, "TBC Jewelcrafting")
  h2:SetPoint("TOP", 0, y - 6)
  y = BuildMaterialGrid(panel, DL.jewelcraftDeck, DL.JC_CLASSIC_COUNT + 1, #DL.jewelcraftDeck, 14, y - 24, 9, 26)

  local h3 = CreateHeader(panel, "Jewelcrafting Level")
  h3:SetPoint("TOP", 0, y - 8)
  BuildBonusBoxRow(panel, DL.jcLevelBoxes, 14, y - 26, 50, 20, 5)
end

---------------------------------------------------------------------------
-- Page switching + refresh
---------------------------------------------------------------------------

function DL.ShowTab(which)
  ui.mainPage:SetShown(which == "main")
  ui.dungeonsPage:SetShown(which == "dungeons")
  ui.materialsPage:SetShown(which == "materials")
  ui.mainTab:SetEnabled(which ~= "main")
  ui.dungeonsTab:SetEnabled(which ~= "dungeons")
  ui.materialsTab:SetEnabled(which ~= "materials")
end

function DL.ToggleFrame()
  if not frame then return end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
    DL.Refresh()
  end
end

local function RefreshDrawCards()
  for i = 1, 3 do
    local button = ui.drawCards[i]
    local card = DL.currentDraw and DL.currentDraw[i]
    if card then
      button.card = card
      button.icon:SetTexture(DL.GetCardIcon(card))
      button.name:SetText(card.name)
      button.sub:SetText("Level " .. card.minLevel .. "+  |  " .. card.type)
      button:SetScript("OnClick", function() DL.ChooseCard(card) end)
      button:Show()
    else
      button:Hide()
    end
  end
end

local function RefreshAbilities()
  for subspec, pool in pairs(ui.abilityPools) do
    local shown = 0
    for _, card in ipairs(DL.cards) do
      if card.type == "ability" and card.subspec == subspec and DL.db.drawn[card.id] then
        shown = shown + 1
        local b = pool[shown]
        if b then
          b.icon:SetTexture(DL.GetCardIcon(card))
          b.tooltipText = card.name
          SetBoxState(b, true)
          b:Show()
        end
      end
    end
    for i = shown + 1, #pool do
      pool[i]:Hide()
    end
  end
end

local function RefreshMaterialCards()
  for which, button in pairs(ui.matCards) do
    local card = DL.materialDraw[which]
    if card then
      button.icon:SetTexture(DL.GetCardIcon(card))
      button.name:SetText(card.name)
      button.sub:SetText(which == "ench" and "Enchanting" or "Jewelcrafting")
      button:Show()
    else
      button:Hide()
    end
  end
end

function DL.UI_Refresh()
  if not frame or not frame:IsShown() then return end
  local db = DL.db

  ui.levelText:SetText("LEVEL " .. DL.PlayerLevel())
  ui.drawsText:SetText("Draws: " .. (db.drawCredits or 0))
  ui.rollsText:SetText("Rolls: " .. DL.FormatNumber(db.rolls))

  -- manual adjusters are a cheat vector: hidden while enforcement is on
  local manual = not db.enforce
  ui.drawMinus:SetShown(manual)
  ui.drawPlus:SetShown(manual)
  ui.rollMinus:SetShown(manual)
  ui.rollPlus:SetShown(manual)
  ui.bonusText:SetText("Bonus Draws: " .. db.bonusDraws)
  ui.availableText:SetText("Cards left: " .. DL.AvailableCount())

  for slot, b in pairs(ui.gear) do SetBoxState(b, db.unlocked[slot]) end
  for i, b in ipairs(ui.talents) do SetBoxState(b, db.unlocked["talent-" .. i]) end
  ui.talentPoints:SetText(DL.TalentPoints() .. " / 60")
  for id, b in pairs(ui.profs) do SetBoxState(b, db.unlocked[id]) end
  for id, b in pairs(ui.general) do SetBoxState(b, db.unlocked[id]) end
  for id, b in pairs(ui.materials) do SetBoxState(b, db.materials[id]) end
  for id, b in pairs(ui.bonusBoxes) do SetBoxState(b, db.unlocked[id]) end
  for name, b in pairs(ui.dungeons) do SetBoxState(b, db.dungeons[name]) end

  RefreshDrawCards()
  RefreshAbilities()
  RefreshMaterialCards()
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------

local minimapButton

local function UpdateMinimapButtonPosition()
  local angle = math.rad(DL.db.minimapAngle or 220)
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER",
    math.cos(angle) * 80, math.sin(angle) * 80)
end

function DL.UpdateMinimapButton()
  if not minimapButton then return end
  minimapButton:SetShown(not DL.db.minimapHide)
  UpdateMinimapButtonPosition()
end

local function CreateMinimapButton()
  minimapButton = CreateFrame("Button", "DeckLockedMinimapButton", Minimap)
  minimapButton:SetSize(32, 32)
  minimapButton:SetFrameStrata("MEDIUM")
  minimapButton:SetFrameLevel(8)
  minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  minimapButton:RegisterForDrag("LeftButton")
  minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 7, -5)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Note_05")
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  local border = minimapButton:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  minimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      DL.SetEnforce(not DL.db.enforce)
    else
      DL.ToggleFrame()
    end
  end)

  minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      DL.db.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
      UpdateMinimapButtonPosition()
    end)
  end)
  minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("DeckLocked", 1, 0.82, 0)
    GameTooltip:AddLine("Left-click: open the tracker", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: toggle enforcement", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move this button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

  DL.UpdateMinimapButton()
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function DL.UI_Init()
  frame = CreateFrame("Frame", "DeckLockedFrame", UIParent, "BackdropTemplate")
  frame:SetSize(1040, 660)
  frame:SetPoint("CENTER")
  frame:SetBackdrop(PANEL_BACKDROP)
  frame:SetBackdropColor(0.03, 0.03, 0.05, 0.95)
  frame:SetBackdropBorderColor(0.5, 0.42, 0.2)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:Hide()
  frame:SetScript("OnShow", function() DL.Refresh() end)
  tinsert(UISpecialFrames, "DeckLockedFrame")

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -10)
  title:SetTextColor(GOLD.r, GOLD.g, GOLD.b)

  local className, classToken = UnitClass("player")
  local color = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]
  if color and color.colorStr then
    title:SetText("DeckLocked  -  |c" .. color.colorStr .. className .. "|r")
  else
    title:SetText("DeckLocked  -  " .. (className or ""))
  end

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  BuildToolbar()

  ui.mainPage = CreateFrame("Frame", nil, frame)
  ui.mainPage:SetPoint("TOPLEFT", 8, -66)
  ui.mainPage:SetPoint("BOTTOMRIGHT", -8, 8)

  ui.dungeonsPage = CreateFrame("Frame", nil, frame)
  ui.dungeonsPage:SetPoint("TOPLEFT", 8, -66)
  ui.dungeonsPage:SetPoint("BOTTOMRIGHT", -8, 8)
  ui.dungeonsPage:Hide()

  ui.materialsPage = CreateFrame("Frame", nil, frame)
  ui.materialsPage:SetPoint("TOPLEFT", 8, -66)
  ui.materialsPage:SetPoint("BOTTOMRIGHT", -8, 8)
  ui.materialsPage:Hide()

  BuildGearPanel(ui.mainPage)
  BuildAbilitiesAndDeck(ui.mainPage)
  BuildRightPanel(ui.mainPage)

  BuildDungeonsPage(ui.dungeonsPage)

  BuildEnchantingPanel(ui.materialsPage)
  BuildMaterialsCenter(ui.materialsPage)
  BuildJewelcraftPanel(ui.materialsPage)

  DL.ShowTab("main")
  CreateMinimapButton()
  DL.Msg("Loaded. Click the minimap button or type /dl to open.")
end
