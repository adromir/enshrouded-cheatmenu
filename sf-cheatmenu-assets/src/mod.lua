--[[
    SF Cheat Menu Assets & Unified Tweaks Suite for Enshrouded
    Author: Adromir (incorporating Unified Tweaks by Canarious)
    License: MIT
    Version: 0.0.2

    Pregame KFC asset patcher (capabilities: ["patch"]).
    Uses deferred OwnedStructValue dirty tracking + plain-table RecipeRegistry serialization
    for 100% compatibility with ShroudForge 1.7.5 multi-mod asset transactions.
]]

if not game or not game.assets then
    return {}
end
if type(runtime) == "table" and runtime.phase and runtime.phase ~= "pregame" then
    return {}
end

local pcall = pcall
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local tonumber = tonumber
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local m_abs = math.abs
local s_lower = string.lower
local s_find = string.find
local s_format = string.format
local t_concat = table.concat
local t_insert = table.insert
local t_remove = table.remove
local collectgarbage = collectgarbage

local NONE_GUID = "00000000-0000-0000-0000-000000000000"

-- ============================================================================
-- SETTINGS & FALLBACKS
-- ============================================================================

local _FALLBACKS = {
    -- Category Master Switches
    ["Enable_NoIntroVideo"] = false,
    ["Enable_Category_LevelsSkills"] = false,
    ["Enable_AttributeScaling"] = false,
    ["Enable_Category_BaseStats"] = false,
    ["Enable_ItemLevelMinimums"] = false,
    ["Enable_DamageTweaks"] = false,
    ["Enable_ToolTweaks"] = false,
    ["Enable_GearStatTweaks"] = false,
    ["Enable_SpellTweaks"] = false,
    ["Enable_Category_Storage"] = false,
    ["Enable_StackSizeTweaks"] = false,
    ["Enable_LootTweaks"] = false,
    ["Enable_GemTweaks"] = false,
    ["Enable_CraftingTweaks"] = false,
    ["Enable_SlotResetTool"] = false,
    ["Enable_Category_Movement"] = false,
    ["Enable_SkillTweaks_Updraft"] = false,
    ["Enable_Category_Map"] = false,
    ["Enable_Category_AltarsBase"] = false,
    ["Enable_Category_BuildingPlacement"] = false,
    ["Enable_FogTweaks"] = false,
    ["Enable_GliderTuning"] = false,
    ["Enable_Category_Terraforming"] = false,
    ["Enable_ExpandedGameSettings"] = false,

    -- Levels & Skill Tree
    ["Enable_PlayerItemLevelTweaks"] = false,
    ["Enable_ItemLevelCapSync"] = false,
    ["PlayerLevelCap"] = 60,
    ["ItemLevelCap"] = 60,
    ["SkillPointsPerLevel"] = 3,
    ["freeSkillTree"] = false,

    -- Attribute Scaling
    ["AttributeScaling_HealthPerCon"] = 100,
    ["AttributeScaling_ManaPerSpi"] = 25,
    ["AttributeScaling_StaminaPerEnd"] = 20,
    ["AttributeScaling_DamagePerAttr"] = "0.1",

    -- Player Base Stats & Comfort
    ["Enable_PlayerBaseStats"] = false,
    ["PlayerBase_Health"] = 100,
    ["PlayerBase_Mana"] = 100,
    ["PlayerBase_Stamina"] = 100,
    ["PlayerBase_Oxygen"] = 60,
    ["PlayerBase_FogResistance"] = 240,
    ["PlayerFog_PerFlameLevel"] = 90,
    ["comfortBuffMultiplier"] = 1,

    -- Item Level Minimums
    ["Enable_ItemLevelMin_Weapon"] = false,
    ["ItemLevelMin_Weapon"] = 55,
    ["Enable_ItemLevelMin_Armor"] = false,
    ["ItemLevelMin_Armor"] = 45,
    ["Enable_ItemLevelMin_Shield"] = false,
    ["ItemLevelMin_Shield"] = 45,
    ["Enable_ItemLevelMin_Gem"] = false,
    ["ItemLevelMin_Gem"] = 60,
    ["Enable_ItemLevelMin_Ring"] = false,
    ["ItemLevelMin_Ring"] = 45,
    ["Enable_ItemLevelMin_Spell"] = false,
    ["ItemLevelMin_Spell"] = 50,
    ["Enable_ItemLevelMin_Arrow"] = false,
    ["ItemLevelMin_Arrow"] = 50,
    ["Enable_ItemLevelMin_Tool"] = false,
    ["ItemLevelMin_Tool"] = 50,
    ["Enable_ItemLevelMin_Misc"] = false,
    ["ItemLevelMin_Misc"] = 50,

    -- Combat & Tools
    ["DamageMult_Melee1H"] = "2.0",
    ["DamageMult_Melee2H"] = "2.0",
    ["DamageMult_Range"] = "2.0",
    ["BowDrawSpeed_Multiplier"] = "0.5",
    ["DamageMult_Wand"] = "2.0",
    ["DamageMult_Arrow"] = "2.0",
    ["DamageMult_Spell"] = "2.0",
    ["ToolMult_Axe"] = "2.0",
    ["ToolMult_Pickaxe"] = "2.0",

    -- Gear Stats & Spells
    ["RegenMult_Health"] = "5.0",
    ["RegenMult_Mana"] = "5.0",
    ["RegenMult_Stamina"] = "5.0",
    ["GearMult_HealthBonus"] = "3.0",
    ["GearMult_StaminaBonus"] = "3.0",
    ["GearMult_ManaBonus"] = "3.0",
    ["SpellCastTime_Multiplier"] = "0.2",
    ["SpellManaCost_Multiplier"] = "0.2",

    -- Storage & Stack Sizes
    ["Enable_BackpackTweaks"] = false,
    ["Backpack_SlotMultiplier"] = 2,
    ["Enable_ChestSizeTweaks"] = false,
    ["Chest_MaxSlots"] = 96,
    ["Chest_SlotMultiplier"] = 2,
    ["Enable_MagicFurniture"] = false,
    ["Enable_MagicFactories"] = false,
    ["StackSize_MaxStack"] = 9999,

    -- Loot & Gems
    ["Loot_WorldDropMultiplier"] = "5.0",
    ["Loot_ScalableDropMultiplier"] = "5.0",
    ["Loot_EnemyDropMultiplier"] = "5.0",
    ["Loot_EquipmentDropMultiplier"] = "1.0",
    ["Loot_ConsumableDropMultiplier"] = "5.0",
    ["Loot_ExplosiveDropMultiplier"] = "5.0",
    ["Loot_ArrowDropMultiplier"] = "5.0",
    ["Loot_GemDropMultiplier"] = "5.0",
    ["Loot_BaitDropMultiplier"] = "5.0",
    ["Loot_CollectibleDropMultiplier"] = "1.0",
    ["Loot_GoldDropMultiplier"] = "5.0",
    ["GemTweaks_SalvageRate"] = "1.0",
    ["GemTweaks_Probability_Common"] = "1.0",
    ["GemTweaks_Probability_Uncommon"] = "1.0",
    ["GemTweaks_Probability_Rare"] = "1.0",
    ["GemTweaks_Probability_Epic"] = "1.0",
    ["GemTweaks_Probability_Legendary"] = "1.0",

    -- Crafting
    ["CraftingTweaks_CreativeMode"] = false,
    ["CraftingTweaks_InfinitePropPlacement"] = false,
    ["CraftingTweaks_UnlockAllRecipes"] = false,
    ["CraftingTweaks_FreeFlameAltar"] = false,
    ["CraftingTweaks_FreeFood"] = false,
    ["CraftingTweaks_FreeFactories"] = false,
    ["CraftingTweaks_OutputMultiplier"] = 1,

    -- Station Crusher
    ["Reset_Factory"] = false,
    ["Reset_Production"] = false,
    ["Reset_Farmbed"] = false,
    ["Reset_Beehive"] = false,
    ["Reset_Furniture"] = false,

    -- Movement, Jump, Slope & Updraft
    ["movementSpeedMultiplier"] = 100,
    ["jumpHeightMultiplier"] = 100,
    ["Enable_SlopeTweaks"] = false,
    ["steepFloorAngle"] = "89.0",
    ["slidingAngle"] = "89.0",
    ["fallDamageAngle"] = "89.0",
    ["Updraft_IgnoreManaCost"] = false,
    ["GroundRelative_X"] = "",
    ["GroundRelative_Y"] = "",
    ["GroundRelative_Z"] = "",
    ["PlayerRelative_X"] = "",
    ["PlayerRelative_Y"] = "",
    ["PlayerRelative_Z"] = "",
    ["Boost_Duration"] = "",
    ["Updraft_ManaCost_Value"] = "",

    -- Map & Fast Travel
    ["Enable_FastTravelTweaks"] = false,
    ["FastTravel_FlameMarkers"] = false,
    ["FastTravel_DungeonMarkers"] = false,
    ["FastTravel_LocationMarkers"] = false,
    ["FastTravel_None"] = false,
    ["Enable_FogOfWarTweaks"] = false,
    ["FogOfWar_Range"] = 600,

    -- Altars, Base Size & Building Placement
    ["Enable_FlameAltarTweaks"] = false,
    ["MaxFlameAltars_Multiplier"] = 2,
    ["unlimitedFlameAltars"] = false,
    ["Enable_BaseSizeTweaks"] = false,
    ["BaseSize_Multiplier"] = "1.5",
    ["Enable_BuildingTweaks"] = false,
    ["Enable_PlacementTweaks"] = false,
    ["PlacementTweaks_BuildInFog"] = false,
    ["PlacementTweaks_NoBuildZoneNeeded"] = false,
    ["PlacementTweaks_IgnoreEnemies"] = false,
    ["PlacementTweaks_IgnoreFreeSpace"] = false,
    ["PlacementTweaks_UnlockTiltAngles"] = false,

    -- Fog & Weather
    ["Fog_WorldHaze_Multiplier"] = "0.35",
    ["Fog_WeatherHaze_Multiplier"] = "0.1",
    ["Fog_BlueShroud_Multiplier"] = "0.6",
    ["Fog_RedShroud_Multiplier"] = "0.6",

    -- Gliders
    ["Glider_T1_accelerationForward"] = "0.85",
    ["Glider_T1_airResistanceLongitudinal"] = "0.32",
    ["Glider_T1_airResistanceLateral"] = "2.0",
    ["Glider_T1_airResistanceVertical"] = "0.85",
    ["Glider_T1_yawAngleSpeed"] = "80.0",
    ["Glider_T1_pitchAngleSpeed"] = "90.0",
    ["Glider_T1_rollAngleSpeed"] = "160.0",
    ["Glider_T2_accelerationForward"] = "0.95",
    ["Glider_T2_airResistanceLongitudinal"] = "0.24",
    ["Glider_T2_airResistanceLateral"] = "1.75",
    ["Glider_T2_airResistanceVertical"] = "1.35",
    ["Glider_T2_yawAngleSpeed"] = "70.0",
    ["Glider_T2_pitchAngleSpeed"] = "85.0",
    ["Glider_T2_rollAngleSpeed"] = "165.0",
    ["Glider_T3_accelerationForward"] = "1.0",
    ["Glider_T3_airResistanceLongitudinal"] = "0.16",
    ["Glider_T3_airResistanceLateral"] = "1.5",
    ["Glider_T3_airResistanceVertical"] = "1.85",
    ["Glider_T3_yawAngleSpeed"] = "60.0",
    ["Glider_T3_pitchAngleSpeed"] = "80.0",
    ["Glider_T3_rollAngleSpeed"] = "150.0",
    ["Glider_T4_REWARD_accelerationForward"] = "1.0",
    ["Glider_T4_REWARD_airResistanceLongitudinal"] = "0.08",
    ["Glider_T4_REWARD_airResistanceLateral"] = "1.25",
    ["Glider_T4_REWARD_airResistanceVertical"] = "2.35",
    ["Glider_T4_REWARD_yawAngleSpeed"] = "50.0",
    ["Glider_T4_REWARD_pitchAngleSpeed"] = "75.0",
    ["Glider_T4_REWARD_rollAngleSpeed"] = "145.0",

    -- Terraforming
    ["MakeUnbreakableBreakable"] = false,
    ["rakeAnywhere"] = false,
    ["Enable_TerrainDropTweaks"] = false,
    ["TerrainDrop_ExchangeRate"] = "1.0",

    -- Expanded Difficulty
    ["EGS_Standard"] = "0.10, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0",
    ["EGS_XP"] = "0.00, 0.10, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0",
    ["EGS_Time"] = "1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 20.0, 30.0, 45.0, 60.0, 120.0, 180.0, 240.0, 360.0, 480.0",

    ["Log_Level"] = 1,
}

local function S(key)
    local fallback = _FALLBACKS[key]
    if shroudforge and shroudforge.settings and type(shroudforge.settings.get) == "function" then
        local ok, val = pcall(function() return shroudforge.settings.get(key, fallback) end)
        if ok and val ~= nil then return val end
    end
    return fallback
end

local function opt_num(key)
    local v = S(key)
    if v == "" or v == nil then return nil end
    local n = tonumber(v)
    return n ~= nil and n or nil
end

local function parse_array(str, fallback)
    local out = {}
    if type(str) == "string" then
        for token in string.gmatch(str, "[^,]+") do
            local n = tonumber(token)
            if n then t_insert(out, n) end
        end
    end
    if #out == 0 then return fallback end
    return out
end

-- Logging & Category Master Toggles
local safe_LOG_LEVEL
do
    local Log_Level = tonumber(S("Log_Level")) or 1
    safe_LOG_LEVEL = (type(Log_Level) == "number" and Log_Level >= 0) and m_floor(Log_Level) or 1
end

local Enable_NoIntroVideo = S("Enable_NoIntroVideo") == true
local Enable_AttributeScaling = S("Enable_AttributeScaling") == true
local Enable_ItemLevelMinimums = S("Enable_ItemLevelMinimums") == true
local Enable_DamageTweaks = S("Enable_DamageTweaks") == true
local Enable_ToolTweaks = S("Enable_ToolTweaks") == true
local Enable_GearStatTweaks = S("Enable_GearStatTweaks") == true
local Enable_SpellTweaks = S("Enable_SpellTweaks") == true
local Enable_StackSizeTweaks = S("Enable_StackSizeTweaks") == true
local Enable_LootTweaks = S("Enable_LootTweaks") == true
local Enable_GemTweaks = S("Enable_GemTweaks") == true
local Enable_CraftingTweaks = S("Enable_CraftingTweaks") == true
local Enable_SlotResetTool = S("Enable_SlotResetTool") == true
local Enable_SkillTweaks_Updraft = S("Enable_SkillTweaks_Updraft") == true
local Enable_FogTweaks = S("Enable_FogTweaks") == true
local Enable_GliderTuning = S("Enable_GliderTuning") == true
local Enable_ExpandedGameSettings = S("Enable_ExpandedGameSettings") == true

-- Sub-Settings (Category-Gated)
local Enable_PlayerItemLevelTweaks, Enable_ItemLevelCapSync, PlayerLevelMax, PlayerLevelCap, ItemLevelCap, SkillPointsPerLevel, FreeSkillTree
local PlayerItemLevel_MaxClamp, SkillPoints_MaxClamp, ItemLevelSync_SafetySkip = 200, 15, "Material"
local AttributeScaling_HealthPerCon, AttributeScaling_ManaPerSpi, AttributeScaling_StaminaPerEnd, AttributeScaling_DamagePerAttr
local Enable_PlayerBaseStats, PlayerBase_Health, PlayerBase_Mana, PlayerBase_Stamina, PlayerBase_Oxygen, PlayerBase_FogResistance, PlayerFog_PerFlameLevel, ComfortBuffMultiplier
local DamageMult_Melee1H, DamageMult_Melee2H, DamageMult_Range, BowDrawSpeed_Multiplier, DamageMult_Wand, DamageMult_Arrow, DamageMult_Spell, ToolMult_Axe, ToolMult_Pickaxe
local Enable_BackpackTweaks, Backpack_SlotMultiplier, Enable_ChestSizeTweaks, Chest_MaxSlots, Chest_SlotMultiplier, Enable_MagicFurniture, Enable_MagicFactories, StackSize_MaxStack
local MovementSpeedPct, JumpHeightPct, Enable_SlopeTweaks, steepFloorAngle, slidingAngle, fallDamageAngle, Max_Angle
local Enable_FastTravelTweaks, FastTravel_FlameMarkers, FastTravel_DungeonMarkers, FastTravel_LocationMarkers, FastTravel_None, Enable_FogOfWarTweaks, FogOfWar_Range, FogOfWar_MaxRangeClamp
local Enable_FlameAltarTweaks, MaxFlameAltars_Multiplier, UnlimitedFlameAltars, Enable_BaseSizeTweaks, BaseSize_Multiplier, BaseSize_MaxMultiplierClamp
local Enable_BuildingTweaks, Enable_PlacementTweaks
local Enable_TerraformingTweaks, RakeAnywhere, Enable_TerrainDropTweaks, TerrainDrop_ExchangeRate, TerrainDrop_MaxExchangeRateClamp

do
    local catLevels = S("Enable_Category_LevelsSkills") == true
    local catBaseStats = S("Enable_Category_BaseStats") == true
    local catStorage = S("Enable_Category_Storage") == true
    local catMovement = S("Enable_Category_Movement") == true
    local catMap = S("Enable_Category_Map") == true
    local catAltars = S("Enable_Category_AltarsBase") == true
    local catBuild = S("Enable_Category_BuildingPlacement") == true
    local catTerra = S("Enable_Category_Terraforming") == true

    Enable_PlayerItemLevelTweaks = catLevels and (S("Enable_PlayerItemLevelTweaks") == true)
    Enable_ItemLevelCapSync = S("Enable_ItemLevelCapSync") == true
    PlayerLevelMax = 200
    PlayerLevelCap = tonumber(S("PlayerLevelCap"))
    ItemLevelCap = tonumber(S("ItemLevelCap"))
    SkillPointsPerLevel = tonumber(S("SkillPointsPerLevel"))
    FreeSkillTree = catLevels and (S("freeSkillTree") == true)

    AttributeScaling_HealthPerCon = tonumber(S("AttributeScaling_HealthPerCon"))
    AttributeScaling_ManaPerSpi = tonumber(S("AttributeScaling_ManaPerSpi"))
    AttributeScaling_StaminaPerEnd = tonumber(S("AttributeScaling_StaminaPerEnd"))
    AttributeScaling_DamagePerAttr = tonumber(S("AttributeScaling_DamagePerAttr"))

    Enable_PlayerBaseStats = catBaseStats and (S("Enable_PlayerBaseStats") == true)
    PlayerBase_Health = tonumber(S("PlayerBase_Health"))
    PlayerBase_Mana = tonumber(S("PlayerBase_Mana"))
    PlayerBase_Stamina = tonumber(S("PlayerBase_Stamina"))
    PlayerBase_Oxygen = tonumber(S("PlayerBase_Oxygen"))
    PlayerBase_FogResistance = tonumber(S("PlayerBase_FogResistance"))
    PlayerFog_PerFlameLevel = tonumber(S("PlayerFog_PerFlameLevel"))
    ComfortBuffMultiplier = catBaseStats and (tonumber(S("comfortBuffMultiplier")) or 1) or 1

    DamageMult_Melee1H = tonumber(S("DamageMult_Melee1H"))
    DamageMult_Melee2H = tonumber(S("DamageMult_Melee2H"))
    DamageMult_Range = tonumber(S("DamageMult_Range"))
    BowDrawSpeed_Multiplier = tonumber(S("BowDrawSpeed_Multiplier"))
    DamageMult_Wand = tonumber(S("DamageMult_Wand"))
    DamageMult_Arrow = tonumber(S("DamageMult_Arrow"))
    DamageMult_Spell = tonumber(S("DamageMult_Spell"))
    ToolMult_Axe = tonumber(S("ToolMult_Axe"))
    ToolMult_Pickaxe = tonumber(S("ToolMult_Pickaxe"))

    Enable_BackpackTweaks = catStorage and (S("Enable_BackpackTweaks") == true)
    Backpack_SlotMultiplier = tonumber(S("Backpack_SlotMultiplier"))
    Enable_ChestSizeTweaks = catStorage and (S("Enable_ChestSizeTweaks") == true)
    Chest_MaxSlots = tonumber(S("Chest_MaxSlots"))
    Chest_SlotMultiplier = tonumber(S("Chest_SlotMultiplier"))
    Enable_MagicFurniture = catStorage and (S("Enable_MagicFurniture") == true)
    Enable_MagicFactories = catStorage and (S("Enable_MagicFactories") == true)
    StackSize_MaxStack = tonumber(S("StackSize_MaxStack"))

    MovementSpeedPct = catMovement and (tonumber(S("movementSpeedMultiplier")) or 100) or 100
    JumpHeightPct = catMovement and (tonumber(S("jumpHeightMultiplier")) or 100) or 100
    Enable_SlopeTweaks = catMovement and (S("Enable_SlopeTweaks") == true)
    steepFloorAngle = tonumber(S("steepFloorAngle"))
    slidingAngle = tonumber(S("slidingAngle"))
    fallDamageAngle = tonumber(S("fallDamageAngle"))
    Max_Angle = 89.0

    Enable_FastTravelTweaks = catMap and (S("Enable_FastTravelTweaks") == true)
    FastTravel_FlameMarkers = S("FastTravel_FlameMarkers") == true
    FastTravel_DungeonMarkers = S("FastTravel_DungeonMarkers") == true
    FastTravel_LocationMarkers = S("FastTravel_LocationMarkers") == true
    FastTravel_None = S("FastTravel_None") == true
    Enable_FogOfWarTweaks = catMap and (S("Enable_FogOfWarTweaks") == true)
    FogOfWar_Range = tonumber(S("FogOfWar_Range"))
    FogOfWar_MaxRangeClamp = 20000

    Enable_FlameAltarTweaks = catAltars and (S("Enable_FlameAltarTweaks") == true)
    MaxFlameAltars_Multiplier = tonumber(S("MaxFlameAltars_Multiplier"))
    UnlimitedFlameAltars = catAltars and (S("unlimitedFlameAltars") == true)
    Enable_BaseSizeTweaks = catAltars and (S("Enable_BaseSizeTweaks") == true)
    BaseSize_Multiplier = tonumber(S("BaseSize_Multiplier"))
    BaseSize_MaxMultiplierClamp = 3.0

    Enable_BuildingTweaks = catBuild and (S("Enable_BuildingTweaks") == true)
    Enable_PlacementTweaks = catBuild and (S("Enable_PlacementTweaks") == true)

    Enable_TerraformingTweaks = catTerra and (S("MakeUnbreakableBreakable") == true)
    RakeAnywhere = catTerra and (S("rakeAnywhere") == true)
    Enable_TerrainDropTweaks = catTerra and (S("Enable_TerrainDropTweaks") == true)
    TerrainDrop_ExchangeRate = tonumber(S("TerrainDrop_ExchangeRate"))
    TerrainDrop_MaxExchangeRateClamp = 1.0
end

-- ============================================================================
-- RESOURCE CACHING & DEFERRED TRANSACTION COMMIT ENGINE
-- ============================================================================

local function _out(msg)
    if shroudforge and shroudforge.log and type(shroudforge.log.info) == "function" then
        shroudforge.log.info(msg)
    elseif type(print) == "function" then
        print(msg)
    end
end

local function _err(msg)
    if shroudforge and shroudforge.log and type(shroudforge.log.error) == "function" then
        shroudforge.log.error(msg)
    else
        _out("ERROR: " .. tostring(msg))
    end
end

local _RESOURCE_CACHE = {}
local function get_cached_resources_by_type(typeName)
    if not _RESOURCE_CACHE[typeName] then
        local ok, res = pcall(game.assets.get_resources_by_type, typeName)
        _RESOURCE_CACHE[typeName] = ok and res or {}
    end
    return _RESOURCE_CACHE[typeName]
end

local _SINGLE_RESOURCE_CACHE = {}
local function get_cached_resource(guid, typeName, instance)
    local key = tostring(guid) .. "_" .. tostring(typeName) .. "_" .. tostring(instance or 0)
    if _SINGLE_RESOURCE_CACHE[key] == nil then
        local ok, res = pcall(game.assets.get_resource, guid, typeName, instance or 0)
        _SINGLE_RESOURCE_CACHE[key] = (ok and res) or false
    end
    return _SINGLE_RESOURCE_CACHE[key] or nil
end

local function get_first_resource_by_type(typeName)
    local list = get_cached_resources_by_type(typeName)
    if list and #list > 0 then return list[1] end
    return nil
end

local _DIRTY_MAP = {}
local _DIRTY_LIST = {}

local function res_key(res, typeName)
    return tostring(res.guid) .. "/" .. tostring(res.part or 0) .. "/" .. tostring(typeName or "")
end

local function get_data(res, typeName)
    if not res then return nil end
    local k = res_key(res, typeName)
    local entry = _DIRTY_MAP[k]
    if entry then return entry.data end
    local ok, d = pcall(function() return res.data end)
    if ok then return d end
    return nil
end

local function mark_dirty(res, typeName, data)
    if not res or not data then return end
    local k = res_key(res, typeName)
    local entry = _DIRTY_MAP[k]
    if entry then
        entry.data = data
    else
        local newEntry = { res = res, data = data, typeName = typeName }
        _DIRTY_MAP[k] = newEntry
        _DIRTY_LIST[#_DIRTY_LIST + 1] = newEntry
    end
end

local function commit_dirty_resources()
    local count = 0
    for _, entry in ipairs(_DIRTY_LIST) do
        local ok, err = pcall(function()
            entry.res.data = entry.data
        end)
        if ok then
            count = count + 1
        else
            _err(s_format("Commit failed for %s (%s): %s", tostring(entry.typeName), tostring(entry.res.guid), tostring(err)))
            error(err, 0)
        end
    end
    return count
end

-- Safe setters for nested inline structs on MappedStructValue resources
local function set_item_level_range(d, newMin, newMax)
    local r = d.itemLevelRange
    if not r then return false end
    local finalMin = (newMin ~= nil) and newMin or r.minLevel
    local finalMax = (newMax ~= nil) and newMax or r.maxLevel
    local ok = pcall(function()
        if newMin ~= nil then r.minLevel = finalMin end
        if newMax ~= nil then r.maxLevel = finalMax end
    end)
    if not ok then
        d.itemLevelRange = { minLevel = finalMin, maxLevel = finalMax }
    end
    return true
end

local function set_random_loot_stack_range(d, newMin, newMax)
    local r = d.randomLootStackRange
    if not r then return false end
    local ok = pcall(function()
        r.minStackSize = newMin
        r.maxStackSize = newMax
    end)
    if not ok then
        d.randomLootStackRange = { minStackSize = newMin, maxStackSize = newMax }
    end
    return true
end

local function find_component_by_type(components, typeName)
    if not components then return nil end
    for _, c in ipairs(components) do
        if c and c.type == typeName then
            return c
        end
    end
    return nil
end

local function flush_lua_refs()
    pcall(function() collectgarbage("collect") end)
end

local _feature = nil
local function _emit(lines)
    if not lines or #lines == 0 then return end
    for i = 1, #lines do
        _out("[SF-CheatAssets] " .. tostring(lines[i]))
    end
end

local function feature_begin(title, level)
    level = level or 1
    if safe_LOG_LEVEL < level then
        _feature = { muted = true, level = level }
        return
    end
    _feature = { muted = false, level = level, title = tostring(title), lines = {} }
end

local function feature_end(didWork)
    flush_lua_refs()
    local f = _feature
    _feature = nil
    if not f or f.muted then return end
    local status = didWork and "OK" or "SKIPPED"
    _emit({ "=== " .. f.title .. " [" .. status .. "] ===" })
    if f.lines and #f.lines > 0 then
        _emit(f.lines)
    end
end

local function log_line(msg, level)
    level = level or 1
    if safe_LOG_LEVEL < level then return end
    if _feature and not _feature.muted then
        t_insert(_feature.lines, tostring(msg))
        return
    end
    _emit({ tostring(msg) })
end

local function is_harvesting_axe(dbg)
    return s_find(dbg, "fellingaxe", 1, true) ~= nil
        or (s_find(dbg, "tool_", 1, true) == 1 and s_find(dbg, "axe", 1, true) ~= nil and s_find(dbg, "pickaxe", 1, true) == nil)
end

local function is_harvesting_pickaxe(dbg)
    return s_find(dbg, "pickaxe", 1, true) ~= nil
end

local function is_harvesting_tool(dbg)
    return is_harvesting_axe(dbg) or is_harvesting_pickaxe(dbg)
end

local function is_safe_stackable_item(d)
    if not d then return false end
    local cur = d.maxStackSize
    if type(cur) ~= "number" or cur <= 1 then return false end

    local dbg = s_lower(tostring(d.debugName or ""))
    local cat = s_lower(tostring(d.category or ""))
    local eq = d.equipment
    local slot = eq and s_lower(tostring(eq.slot or "")) or ""

    if s_find(dbg, "cheat", 1, true) ~= nil or
       s_find(dbg, "test_", 1, true) == 1 or
       s_find(dbg, "_test", 1, true) ~= nil or
       s_find(dbg, "debug", 1, true) ~= nil or
       s_find(dbg, "philipp_", 1, true) == 1 or
       s_find(dbg, "deprecated", 1, true) ~= nil or
       s_find(dbg, "donotplace", 1, true) ~= nil or
       s_find(dbg, "dummy_", 1, true) ~= nil or
       s_find(dbg, "base_", 1, true) == 1 or
       s_find(dbg, "icon_", 1, true) == 1 or
       s_find(dbg, "ability_", 1, true) == 1 or
       s_find(dbg, "vc_", 1, true) == 1 or
       s_find(dbg, "vanity_", 1, true) == 1 or
       s_find(dbg, "npc_", 1, true) == 1 or
       s_find(dbg, "npcsummoner_", 1, true) == 1 or
       s_find(dbg, "ammo_enemy_", 1, true) == 1 or
       s_find(dbg, "ammo_trap_", 1, true) == 1 or
       s_find(dbg, "_ammo_consumable_", 1, true) == 1 or
       s_find(dbg, "eternal", 1, true) ~= nil or
       s_find(dbg, "backpack_", 1, true) == 1 or
       s_find(dbg, "glider", 1, true) ~= nil or
       s_find(dbg, "key_", 1, true) == 1 or
       s_find(dbg, "quest_", 1, true) ~= nil or
       s_find(dbg, "_quest", 1, true) ~= nil or
       s_find(dbg, "loretext", 1, true) ~= nil or
       s_find(dbg, "lore_", 1, true) == 1 or
       s_find(dbg, "colorpalette", 1, true) ~= nil or
       s_find(dbg, "instrument_", 1, true) == 1 or
       s_find(dbg, "music_sheet", 1, true) ~= nil or
       is_harvesting_tool(dbg) then
        return false
    end

    if s_find(dbg, "flamealtar", 1, true) ~= nil or
       s_find(dbg, "craftingstation_", 1, true) == 1 or
       s_find(dbg, "_factory", 1, true) ~= nil or
       s_find(dbg, "factory_", 1, true) == 1 or
       (s_find(dbg, "prop_decoration_t", 1, true) ~= nil and s_find(dbg, "storage", 1, true) ~= nil) or
       (s_find(dbg, "animal_", 1, true) == 1 and s_find(dbg, "fur", 1, true) == nil and s_find(dbg, "meat", 1, true) == nil and s_find(dbg, "hide", 1, true) == nil and s_find(dbg, "bone", 1, true) == nil and s_find(dbg, "fat", 1, true) == nil and s_find(dbg, "claw", 1, true) == nil and s_find(dbg, "scale", 1, true) == nil and s_find(dbg, "feather", 1, true) == nil) then
        return false
    end

    if slot == "chestarmour" or slot == "helmetarmour" or slot == "pantsarmour" or slot == "bootsarmour" or slot == "glovesarmour" or slot == "shield" or slot == "ring" or slot == "glider" or slot == "backpack" then
        return false
    end

    if cat == "quest" or cat == "questitems" then
        return false
    end

    return true
end


-- ============================================================================
-- FEATURE IMPLEMENTATIONS (PART A)
-- ============================================================================

local function ApplyNoIntroVideo()
    feature_begin("No Intro Video", 1)

    if not Enable_NoIntroVideo then
        log_line("No Intro Video: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local uiRes = get_first_resource_by_type("keen::FbUiBundle")
    local ui = get_data(uiRes, "keen::FbUiBundle")
    local didWork = false

    if ui and ui.preGame and ui.preGame.startUpSequence then
        local seq = ui.preGame.startUpSequence
        local function zero_dur(parent, field)
            local ok = pcall(function() parent[field].value = 0 end)
            if not ok then pcall(function() parent[field] = { value = 0 } end) end
        end
        zero_dur(seq, "logoFadeDuration")
        zero_dur(seq, "logoIdleDuration")
        zero_dur(seq, "postLogoDelay")
        zero_dur(seq, "mainMenuFadeInDuration")
        zero_dur(ui.preGame, "startGameFadeOutDuration")
        mark_dirty(uiRes, "keen::FbUiBundle", ui)
        didWork = true
        log_line("Patched startup sequence timings (all fade/logo delays -> 0).", 1)
    else
        log_line("WARN: keen::FbUiBundle not present; skipping (normal on Dedicated Servers).", 1)
    end

    feature_end(didWork)
end

local function ApplyPlayerAttributes()
    feature_begin("Player Attributes", 1)

    if not Enable_AttributeScaling then
        log_line("Attribute Scaling: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local btRes = get_first_resource_by_type("keen::BalancingTable")
    local bt = get_data(btRes, "keen::BalancingTable")
    if not bt then
        log_line("WARN: keen::BalancingTable not found; skipping.", 1)
        feature_end(false)
        return
    end

    local changed = false
    pcall(function()
        if type(AttributeScaling_HealthPerCon) == "number" then bt.playerHealthPerAP = AttributeScaling_HealthPerCon; changed = true end
        if type(AttributeScaling_ManaPerSpi) == "number" then bt.playerManaPerAP = AttributeScaling_ManaPerSpi; changed = true end
        if type(AttributeScaling_StaminaPerEnd) == "number" then bt.playerStaminaPerAP = AttributeScaling_StaminaPerEnd; changed = true end
        if type(AttributeScaling_DamagePerAttr) == "number" then bt.damageScalePerAttributePoint = AttributeScaling_DamagePerAttr; changed = true end
    end)

    if changed then
        mark_dirty(btRes, "keen::BalancingTable", bt)
        log_line(("AttributeScaling applied: HealthPerCon=%s ManaPerSpi=%s StaminaPerEnd=%s DamagePerAttr=%s"):format(
            tostring(AttributeScaling_HealthPerCon), tostring(AttributeScaling_ManaPerSpi),
            tostring(AttributeScaling_StaminaPerEnd), tostring(AttributeScaling_DamagePerAttr)
        ), 1)
    else
        log_line("AttributeScaling: no valid numeric fields applied.", 1)
    end

    feature_end(changed)
end

local function ApplyPlayerBaseStats()
    feature_begin("Player Base Stats & Comfort", 1)

    if not Enable_PlayerBaseStats and ComfortBuffMultiplier <= 1 then
        log_line("Player Base Stats & Comfort: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local btRes = get_first_resource_by_type("keen::BalancingTable")
    local bt = get_data(btRes, "keen::BalancingTable")
    if not bt then
        log_line("WARN: keen::BalancingTable not found; skipping.", 1)
        feature_end(false)
        return
    end

    local changed = false
    if Enable_PlayerBaseStats then
        pcall(function()
            if type(PlayerBase_Health) == "number" then bt.playerBaseHealth = PlayerBase_Health; changed = true end
            if type(PlayerBase_Mana) == "number" then bt.playerBaseMana = PlayerBase_Mana; changed = true end
            if type(PlayerBase_Stamina) == "number" then bt.playerBaseStamina = PlayerBase_Stamina; changed = true end
            if type(PlayerBase_Oxygen) == "number" then bt.playerBaseOxygen = PlayerBase_Oxygen; changed = true end
            if type(PlayerBase_FogResistance) == "number" then bt.playerBaseFogResistance = PlayerBase_FogResistance; changed = true end
            if type(PlayerFog_PerFlameLevel) == "number" then bt.playerFogResistancePerFlameLevel = PlayerFog_PerFlameLevel; changed = true end
        end)
        log_line(("PlayerBaseStats applied: Health=%s Mana=%s Stamina=%s Oxygen=%s FogRes=%s FogPerFlame=%s"):format(
            tostring(PlayerBase_Health), tostring(PlayerBase_Mana), tostring(PlayerBase_Stamina),
            tostring(PlayerBase_Oxygen), tostring(PlayerBase_FogResistance), tostring(PlayerFog_PerFlameLevel)
        ), 1)
    end

    if ComfortBuffMultiplier > 1 and bt.comfortSetup then
        local cs = bt.comfortSetup
        local newBase = m_floor((cs.base or 0) * ComfortBuffMultiplier)
        local newFactor = (cs.factor or 1.0) * ComfortBuffMultiplier
        local ok = pcall(function()
            cs.base = newBase
            cs.factor = newFactor
        end)
        if not ok then
            pcall(function() bt.comfortSetup = { base = newBase, factor = newFactor } end)
        end
        changed = true
        log_line(("ComfortBuffMultiplier applied: x%s (base=%s factor=%s)"):format(
            tostring(ComfortBuffMultiplier), tostring(newBase), tostring(newFactor)
        ), 1)
    end

    if changed then
        mark_dirty(btRes, "keen::BalancingTable", bt)
    end

    feature_end(changed)
end

local function ApplyPlayerItemLevelTweaks()
    feature_begin("Player / Item Level & Skill Tree Tweaks", 1)

    if not Enable_PlayerItemLevelTweaks and not FreeSkillTree then
        log_line("Player / Item Level & Skill Tree Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local didWork = false

    if Enable_PlayerItemLevelTweaks then
        local plevelMax = type(PlayerLevelMax) == "number" and PlayerLevelMax or nil
        local plevelCap = type(PlayerLevelCap) == "number" and PlayerLevelCap or nil
        local ilevelCap = type(ItemLevelCap) == "number" and ItemLevelCap or nil
        local skillPointsPL = type(SkillPointsPerLevel) == "number" and SkillPointsPerLevel or nil

        local maxClamp = type(PlayerItemLevel_MaxClamp) == "number" and PlayerItemLevel_MaxClamp or nil
        if maxClamp and maxClamp >= 1 then
            if plevelMax and plevelMax > maxClamp then plevelMax = maxClamp end
            if plevelCap and plevelCap > maxClamp then plevelCap = maxClamp end
            if ilevelCap and ilevelCap > maxClamp then ilevelCap = maxClamp end
        end

        local skillClamp = type(SkillPoints_MaxClamp) == "number" and SkillPoints_MaxClamp or nil
        if skillClamp and skillClamp >= 1 and skillPointsPL and skillPointsPL > skillClamp then
            skillPointsPL = skillClamp
        end

        if plevelCap and plevelMax and plevelCap > plevelMax then
            plevelCap = plevelMax
        end

        local btRes = get_first_resource_by_type("keen::BalancingTable")
        local bt = get_data(btRes, "keen::BalancingTable")
        if bt then
            local patchedFields = 0
            if type(bt.playerLevelMax) == "number" and plevelMax ~= nil then
                local targetMax = m_max(bt.playerLevelMax, plevelMax)
                if plevelCap and plevelCap > targetMax then targetMax = plevelCap end
                bt.playerLevelMax = targetMax
                patchedFields = patchedFields + 1
            end
            if bt.playerLevelCap ~= nil and plevelCap ~= nil then
                bt.playerLevelCap = plevelCap
                patchedFields = patchedFields + 1
            end
            if bt.itemLevelCap ~= nil and ilevelCap ~= nil then
                bt.itemLevelCap = ilevelCap
                patchedFields = patchedFields + 1
            end
            if bt.skillPointsPerLevel ~= nil and skillPointsPL ~= nil then
                bt.skillPointsPerLevel = skillPointsPL
                patchedFields = patchedFields + 1
            end
            if patchedFields > 0 then
                mark_dirty(btRes, "keen::BalancingTable", bt)
                didWork = true
            end
            log_line(("BalancingTable patchedFields=%d playerLevelMax=%s playerLevelCap=%s itemLevelCap=%s skillPointsPerLevel=%s"):format(
                patchedFields, tostring(bt.playerLevelMax), tostring(plevelCap), tostring(ilevelCap), tostring(skillPointsPL)
            ), 1)
        end

        if Enable_ItemLevelCapSync and ilevelCap ~= nil then
            local skipNeedle = tostring(ItemLevelSync_SafetySkip or "")
            local items = get_cached_resources_by_type("keen::ItemInfo")
            local scanned, eligible, syncedItemsChanged, skipped = 0, 0, 0, 0
            if items then
                for _, it in ipairs(items) do
                    scanned = scanned + 1
                    pcall(function()
                        local d = get_data(it, "keen::ItemInfo")
                        if not d then skipped = skipped + 1; return end
                        local dbg = tostring(d.debugName or "")
                        local dbgLow = s_lower(dbg)
                        if skipNeedle ~= "" and s_find(dbg, skipNeedle, 1, true) ~= nil then skipped = skipped + 1; return end
                        if s_find(dbgLow, "vanity_", 1, true) == 1 or is_harvesting_tool(dbgLow) then skipped = skipped + 1; return end
                        local range = d.itemLevelRange
                        if not range or range.maxLevel == nil then skipped = skipped + 1; return end
                        local before = range.maxLevel
                        if type(before) ~= "number" or before <= 0 then skipped = skipped + 1; return end
                        eligible = eligible + 1
                        if before >= ilevelCap then return end
                        if set_item_level_range(d, nil, ilevelCap) then
                            mark_dirty(it, "keen::ItemInfo", d)
                            syncedItemsChanged = syncedItemsChanged + 1
                            didWork = true
                        end
                    end)
                end
            end
            log_line(("ItemLevelCapSync scanned=%d eligible=%d changed=%d skipped=%d"):format(
                scanned, eligible, syncedItemsChanged, skipped
            ), 1)
        end
    end

    if FreeSkillTree then
        local skillTrees = get_cached_resources_by_type("keen::SkillTreeResource")
        local treesPatched, nodesPatched = 0, 0
        if skillTrees then
            for _, st in ipairs(skillTrees) do
                local sdata = get_data(st, "keen::SkillTreeResource")
                if sdata and sdata.nodes then
                    local treeDirty = false
                    for _, node in ipairs(sdata.nodes) do
                        if node and type(node.costs) == "number" and node.costs > 0 then
                            node.costs = 0
                            nodesPatched = nodesPatched + 1
                            treeDirty = true
                        end
                    end
                    if treeDirty then
                        mark_dirty(st, "keen::SkillTreeResource", sdata)
                        treesPatched = treesPatched + 1
                        didWork = true
                    end
                end
            end
        end
        log_line(("FreeSkillTree patched trees=%d nodes=%d (all skill costs -> 0)"):format(treesPatched, nodesPatched), 1)
    end

    feature_end(didWork)
end

local function ApplyEquipmentMultipliers()
    feature_begin("Equipment Damage & Tools", 1)

    local bowDrawMult = (Enable_DamageTweaks and type(BowDrawSpeed_Multiplier) == "number" and BowDrawSpeed_Multiplier > 0) and BowDrawSpeed_Multiplier or 1.0
    if not Enable_DamageTweaks and not Enable_ToolTweaks and bowDrawMult == 1.0 then
        log_line("Equipment Damage, Tool Multipliers, and Bow Draw Speed are all disabled/1.0; skipping.", 1)
        feature_end(false)
        return
    end

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items then
        log_line("WARN: keen::ItemInfo not found; skipping.", 1)
        feature_end(false)
        return
    end

    local changed, axeChanged, pickaxeChanged, weapChanged, bowDrawChanged = 0, 0, 0, 0, 0

    for _, it in ipairs(items) do
        local d = get_data(it, "keen::ItemInfo")
        if d and d.equipment then
            pcall(function()
                local dbg = s_lower(tostring(d.debugName or ""))
                local slot = s_lower(tostring(d.equipment.slot or ""))
                local dist = d.damageSetup and d.damageSetup.distribution
                local applied = false

                local isAxeTool = is_harvesting_axe(dbg)
                local isPickaxeTool = is_harvesting_pickaxe(dbg)
                local isHarvTool = (isAxeTool or isPickaxeTool)

                if dist then
                    if isHarvTool then
                        if Enable_ToolTweaks then
                            if isAxeTool then
                                local toolMult = type(ToolMult_Axe) == "number" and ToolMult_Axe or 1.0
                                if toolMult ~= 1.0 and dist.woodDamage then
                                    dist.woodDamage = dist.woodDamage * toolMult
                                    axeChanged = axeChanged + 1
                                    applied = true
                                end
                            elseif isPickaxeTool then
                                local toolMult = type(ToolMult_Pickaxe) == "number" and ToolMult_Pickaxe or 1.0
                                if toolMult ~= 1.0 then
                                    local pApp = false
                                    if dist.stoneDamage then dist.stoneDamage = dist.stoneDamage * toolMult; pApp = true end
                                    if dist.terrainDamage then dist.terrainDamage = dist.terrainDamage * toolMult; pApp = true end
                                    if pApp then
                                        pickaxeChanged = pickaxeChanged + 1
                                        applied = true
                                    end
                                end
                            end
                        end
                    elseif Enable_DamageTweaks then
                        local dmgMult = 1.0
                        if slot == "arrow" then dmgMult = type(DamageMult_Arrow) == "number" and DamageMult_Arrow or 1.0
                        elseif slot == "spell" then dmgMult = type(DamageMult_Spell) == "number" and DamageMult_Spell or 1.0
                        elseif slot == "meleeweapon" then
                            if s_find(dbg, "2h", 1, true) then dmgMult = type(DamageMult_Melee2H) == "number" and DamageMult_Melee2H or 1.0
                            else dmgMult = type(DamageMult_Melee1H) == "number" and DamageMult_Melee1H or 1.0 end
                        elseif slot == "rangeweapon" then dmgMult = type(DamageMult_Range) == "number" and DamageMult_Range or 1.0
                        elseif slot == "midrangeweapon" then dmgMult = type(DamageMult_Wand) == "number" and DamageMult_Wand or 1.0
                        end

                        if dmgMult ~= 1.0 then
                            for k, v in pairs(dist) do
                                if type(v) == "number" then dist[k] = v * dmgMult end
                            end
                            weapChanged = weapChanged + 1
                            applied = true
                        end
                    end
                end

                if not isHarvTool and bowDrawMult ~= 1.0 and (slot == "rangeweapon" or s_find(dbg, "bow", 1, true)) then
                    local bApp = false
                    if d.impactValues then
                        for _, key in ipairs({"simple", "scaled"}) do
                            local ok2, arr = pcall(function() return d.impactValues[key] end)
                            if ok2 and arr then
                                local durationVals = {}
                                for i = 1, 20 do
                                    local ok3, entry = pcall(function() return arr[i] end)
                                    if not ok3 or not entry then break end
                                    local ok4, v = pcall(function() return entry.value end)
                                    if ok4 and v and v.valueFormat == "Duration" and type(v.value) == "number" and v.value > 0 then
                                        durationVals[v.value] = true
                                    end
                                end
                                for i = 1, 20 do
                                    local ok3, entry = pcall(function() return arr[i] end)
                                    if not ok3 or not entry then break end
                                    local ok4, v = pcall(function() return entry.value end)
                                    if ok4 and v and type(v.value) == "number" then
                                        if (v.valueFormat == "Duration" and v.value > 0) or (v.valueFormat == "Normal" and durationVals[v.value]) then
                                            v.value = v.value * bowDrawMult
                                            bApp = true
                                            applied = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if d.uiValues then
                        for _, uv in pairs(d.uiValues) do
                            if uv and uv.valueFormat == "Duration" and type(uv.value) == "number" and uv.value > 0 then
                                local scaledUi = uv.value * bowDrawMult
                                uv.value = (uv.value > 20) and m_floor(scaledUi + 0.5) or scaledUi
                                bApp = true
                                applied = true
                            end
                        end
                    end
                    if bApp then bowDrawChanged = bowDrawChanged + 1 end
                end

                if applied then
                    mark_dirty(it, "keen::ItemInfo", d)
                    changed = changed + 1
                end
            end)
        end
    end

    local spellUiChanged = 0
    if Enable_DamageTweaks and DamageMult_Spell and DamageMult_Spell ~= 1.0 then
        for _, it in ipairs(items) do
            local d = get_data(it, "keen::ItemInfo")
            if d and d.uiValues and s_find(tostring(d.debugName or ""), "Spell", 1, true) then
                pcall(function()
                    local sDirty = false
                    for _, uv in ipairs(d.uiValues) do
                        local loca = uv.locaId and uv.locaId.value
                        if loca == 3386387946 and uv.value then
                            uv.value = uv.value * DamageMult_Spell
                            spellUiChanged = spellUiChanged + 1
                            changed = changed + 1
                            sDirty = true
                        end
                    end
                    if sDirty then
                        mark_dirty(it, "keen::ItemInfo", d)
                    end
                end)
            end
        end
    end

    log_line(("Configs: DmgTweaks=%s (1H=%s 2H=%s Range=%s Wand=%s Arrow=%s Spell=%s) | ToolTweaks=%s (Axe=%s Pickaxe=%s) | BowDrawMult=%s"):format(
        tostring(Enable_DamageTweaks), tostring(DamageMult_Melee1H), tostring(DamageMult_Melee2H), tostring(DamageMult_Range),
        tostring(DamageMult_Wand), tostring(DamageMult_Arrow), tostring(DamageMult_Spell),
        tostring(Enable_ToolTweaks), tostring(ToolMult_Axe), tostring(ToolMult_Pickaxe), tostring(bowDrawMult)
    ), 1)
    log_line(("Patched items: total=%d | axes=%d | pickaxes=%d | weapons/ammo=%d | bowDraw=%d | spellUi=%d"):format(
        changed, axeChanged, pickaxeChanged, weapChanged, bowDrawChanged, spellUiChanged
    ), 1)

    feature_end(changed > 0)
end

local function ApplyItemLevelMinimums()
    feature_begin("Item Level Minimums", 1)

    if not Enable_ItemLevelMinimums then
        log_line("Item Level Minimums: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local Enable_ItemLevelMin_Weapon = S("Enable_ItemLevelMin_Weapon") == true
    local ItemLevelMin_Weapon = tonumber(S("ItemLevelMin_Weapon"))
    local Enable_ItemLevelMin_Armor = S("Enable_ItemLevelMin_Armor") == true
    local ItemLevelMin_Armor = tonumber(S("ItemLevelMin_Armor"))
    local Enable_ItemLevelMin_Shield = S("Enable_ItemLevelMin_Shield") == true
    local ItemLevelMin_Shield = tonumber(S("ItemLevelMin_Shield"))
    local Enable_ItemLevelMin_Gem = S("Enable_ItemLevelMin_Gem") == true
    local ItemLevelMin_Gem = tonumber(S("ItemLevelMin_Gem"))
    local Enable_ItemLevelMin_Ring = S("Enable_ItemLevelMin_Ring") == true
    local ItemLevelMin_Ring = tonumber(S("ItemLevelMin_Ring"))
    local Enable_ItemLevelMin_Spell = S("Enable_ItemLevelMin_Spell") == true
    local ItemLevelMin_Spell = tonumber(S("ItemLevelMin_Spell"))
    local Enable_ItemLevelMin_Arrow = S("Enable_ItemLevelMin_Arrow") == true
    local ItemLevelMin_Arrow = tonumber(S("ItemLevelMin_Arrow"))
    local Enable_ItemLevelMin_Tool = S("Enable_ItemLevelMin_Tool") == true
    local ItemLevelMin_Tool = tonumber(S("ItemLevelMin_Tool"))
    local Enable_ItemLevelMin_Misc = S("Enable_ItemLevelMin_Misc") == true
    local ItemLevelMin_Misc = tonumber(S("ItemLevelMin_Misc"))

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items then
        log_line("WARN: keen::ItemInfo not found; skipping.", 1)
        feature_end(false)
        return
    end

    local changed = 0
    local counts = { Weapon = 0, Armor = 0, Shield = 0, Gem = 0, Ring = 0, Spell = 0, Arrow = 0, Tool = 0, Misc = 0 }

    for _, it in ipairs(items) do
        local d = get_data(it, "keen::ItemInfo")
        if d and d.itemLevelRange then
            pcall(function()
                local curMin = d.itemLevelRange.minLevel
                local curMax = d.itemLevelRange.maxLevel
                if (type(curMin) ~= "number" or curMin <= 0) and (type(curMax) ~= "number" or curMax <= 0) then
                    return
                end

                local dbg = s_lower(tostring(d.debugName or ""))
                if s_find(dbg, "vanity_", 1, true) == 1 or s_find(dbg, "material_", 1, true) == 1 or is_harvesting_tool(dbg) then
                    return
                end

                local cat = s_lower(tostring(d.category or ""))
                local slot = d.equipment and s_lower(tostring(d.equipment.slot or "")) or ""
                local targetMin = nil
                local matchedType = nil

                local isGem = (s_find(dbg, "_gem_", 1, true) ~= nil or s_find(dbg, "gem_", 1, true) == 1 or cat == "gems") and not s_find(dbg, "food_", 1, true) and not s_find(dbg, "prop_", 1, true)

                if isGem then
                    if Enable_ItemLevelMin_Gem then targetMin = ItemLevelMin_Gem; matchedType = "Gem" end
                elseif s_find(slot, "armour", 1, true) and not s_find(slot, "ring", 1, true) then
                    if Enable_ItemLevelMin_Armor then targetMin = ItemLevelMin_Armor; matchedType = "Armor" end
                elseif s_find(slot, "shield", 1, true) or s_find(dbg, "shield_", 1, true) == 1 or s_find(dbg, "ward_", 1, true) == 1 then
                    if Enable_ItemLevelMin_Shield then targetMin = ItemLevelMin_Shield; matchedType = "Shield" end
                elseif s_find(slot, "ring", 1, true) or s_find(dbg, "ring_", 1, true) == 1 then
                    if Enable_ItemLevelMin_Ring then targetMin = ItemLevelMin_Ring; matchedType = "Ring" end
                elseif s_find(slot, "spell", 1, true) or s_find(dbg, "spell", 1, true) ~= nil then
                    if Enable_ItemLevelMin_Spell then targetMin = ItemLevelMin_Spell; matchedType = "Spell" end
                elseif s_find(slot, "arrow", 1, true) or (s_find(dbg, "ammo_", 1, true) == 1 and s_find(dbg, "arrow", 1, true) ~= nil) then
                    if Enable_ItemLevelMin_Arrow then targetMin = ItemLevelMin_Arrow; matchedType = "Arrow" end
                elseif (s_find(slot, "melee", 1, true) or s_find(slot, "range", 1, true) or s_find(slot, "midrange", 1, true)) and not s_find(slot, "tool", 1, true) then
                    if not (s_find(dbg, "consumable", 1, true) or s_find(dbg, "grenade", 1, true) or s_find(dbg, "powderball", 1, true)) then
                        if Enable_ItemLevelMin_Weapon then targetMin = ItemLevelMin_Weapon; matchedType = "Weapon" end
                    elseif Enable_ItemLevelMin_Misc then
                        targetMin = ItemLevelMin_Misc; matchedType = "Misc"
                    end
                elseif s_find(slot, "tool", 1, true) and slot ~= "buildtool" then
                    if Enable_ItemLevelMin_Tool then targetMin = ItemLevelMin_Tool; matchedType = "Tool" end
                else
                    if Enable_ItemLevelMin_Misc then targetMin = ItemLevelMin_Misc; matchedType = "Misc" end
                end

                if type(targetMin) == "number" and targetMin > 0 then
                    local newMax = (type(curMax) == "number" and curMax < targetMin) and targetMin or curMax
                    if set_item_level_range(d, targetMin, newMax) then
                        mark_dirty(it, "keen::ItemInfo", d)
                        changed = changed + 1
                        if matchedType and counts[matchedType] then
                            counts[matchedType] = counts[matchedType] + 1
                        end
                    end
                end
            end)
        end
    end

    log_line(("ItemLevelMinimums patched total=%d (Weapon=%d Armor=%d Shield=%d Gem=%d Ring=%d Spell=%d Arrow=%d Tool=%d Misc=%d)"):format(
        changed, counts.Weapon, counts.Armor, counts.Shield, counts.Gem, counts.Ring, counts.Spell, counts.Arrow, counts.Tool, counts.Misc
    ), 1)

    feature_end(changed > 0)
end

local function ApplySpellTweaks()
    feature_begin("Spell Tweaks", 1)

    if not Enable_SpellTweaks then
        log_line("Spell Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local SpellCastTime_Multiplier = tonumber(S("SpellCastTime_Multiplier"))
    local SpellManaCost_Multiplier = tonumber(S("SpellManaCost_Multiplier"))
    local SpellTweaks_MinMultiplier = 0.0

    local castMult = SpellCastTime_Multiplier
    local manaMult = SpellManaCost_Multiplier

    local validCast = (type(castMult) == "number" and castMult >= 0)
    local validMana = (type(manaMult) == "number" and manaMult >= 0)

    if not validCast and not validMana then
        log_line("WARN: Both Spell Multipliers are nil/invalid; skipping", 1)
        feature_end(false)
        return
    end

    local minMult = SpellTweaks_MinMultiplier
    if type(minMult) == "number" then
        if validCast and castMult < minMult then castMult = minMult end
        if validMana and manaMult < minMult then manaMult = minMult end
    end

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items or #items == 0 then
        log_line("WARN: No ItemInfo entries found", 1)
        feature_end(false)
        return
    end

    local scanned, matched, skipped, failed = 0, 0, 0, 0
    local impactEntriesTouched, uiEntriesTouched = 0, 0

    local function floor_nonneg(n)
        if type(n) ~= "number" then return nil end
        local f = m_floor(n)
        if f < 0 then f = 0 end
        return f
    end

    for _, it in ipairs(items) do
        scanned = scanned + 1
        local ok = pcall(function()
            local d = get_data(it, "keen::ItemInfo")
            if not d then skipped = skipped + 1; return end
            local dbg = tostring(d.debugName or "")
            if dbg == "" then skipped = skipped + 1; return end
            if not s_find(dbg, "Ammo", 1, true) and not s_find(dbg, "Spell", 1, true) then
                return
            end

            matched = matched + 1
            local itemDirty = false

            local ui = d.uiValues
            local chargeTimeVal, manaCostVal = nil, nil
            if ui then
                for _, j in pairs(ui) do
                    if j and j.value ~= nil and type(j.value) == "number" then
                        local vf = j.valueFormat
                        if chargeTimeVal == nil and vf == "Duration" and j.value > 0 then
                            chargeTimeVal = j.value
                        elseif manaCostVal == nil and vf == "Normal" and j.value > 0 then
                            manaCostVal = j.value
                        end
                    end
                end
            end

            if ui and validCast and castMult ~= 1.0 and chargeTimeVal then
                for _, j in pairs(ui) do
                    if j and j.valueFormat == "Duration" and type(j.value) == "number" and j.value == chargeTimeVal then
                        j.value = floor_nonneg(j.value * castMult)
                        uiEntriesTouched = uiEntriesTouched + 1
                        itemDirty = true
                        break
                    end
                end
            end

            if ui and validMana and manaMult ~= 1.0 and manaCostVal then
                for _, j in pairs(ui) do
                    if j and j.valueFormat == "Normal" and type(j.value) == "number" and j.value == manaCostVal then
                        j.value = floor_nonneg(j.value * manaMult)
                        uiEntriesTouched = uiEntriesTouched + 1
                        itemDirty = true
                        break
                    end
                end
            end

            local impacts = d.impactValues
            if impacts then
                for _, key in ipairs({"simple", "scaled"}) do
                    local ok2, arr = pcall(function() return impacts[key] end)
                    if ok2 and arr then
                        local scaledFirstDuration = false
                        for i = 1, 20 do
                            local ok3, entry = pcall(function() return arr[i] end)
                            if not ok3 or not entry then break end
                            local ok4, v = pcall(function() return entry.value end)
                            if ok4 and v then
                                local ok5, vf = pcall(function() return v.valueFormat end)
                                local ok6, valRaw = pcall(function() return v.value end)
                                if ok5 and ok6 and type(valRaw) == "number" and valRaw > 0 then
                                    if validCast and castMult ~= 1.0 and vf == "Duration" and not scaledFirstDuration then
                                        v.value = valRaw * castMult
                                        impactEntriesTouched = impactEntriesTouched + 1
                                        scaledFirstDuration = true
                                        itemDirty = true
                                    elseif validMana and manaMult ~= 1.0 and vf == "Normal" and manaCostVal and valRaw == manaCostVal then
                                        v.value = floor_nonneg(valRaw * manaMult)
                                        impactEntriesTouched = impactEntriesTouched + 1
                                        itemDirty = true
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if itemDirty then
                mark_dirty(it, "keen::ItemInfo", d)
            end
        end)
        if not ok then failed = failed + 1 end
    end

    log_line(("ItemInfo scanned=%d matched(Ammo+Spell)=%d skipped=%d failed=%d | impactValues=%d uiValues=%d"):format(
        scanned, matched, skipped, failed, impactEntriesTouched, uiEntriesTouched
    ), 1)

    feature_end((impactEntriesTouched + uiEntriesTouched) > 0)
end

local GEAR_LOCA = {
    [3144141133] = "HealthRegen",
    [2429421730] = "HealthRegen",
    [1748353866] = "ManaRegen",
    [3794775993] = "ManaRegen",
    [1661244498] = "StaminaRegen",
    [4245854444] = "StaminaRegen",
    [4085987468] = "HealthBonus",
    [1640932545] = "StaminaBonus",
    [3659778886] = "ManaBonus",
}

local function ApplyGearStatTweaks()
    feature_begin("Gear Stat Tweaks", 1)

    if not Enable_GearStatTweaks then
        log_line("Gear Stat Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local RegenMult_Health = tonumber(S("RegenMult_Health"))
    local RegenMult_Mana = tonumber(S("RegenMult_Mana"))
    local RegenMult_Stamina = tonumber(S("RegenMult_Stamina"))
    local GearMult_HealthBonus = tonumber(S("GearMult_HealthBonus"))
    local GearMult_StaminaBonus = tonumber(S("GearMult_StaminaBonus"))
    local GearMult_ManaBonus = tonumber(S("GearMult_ManaBonus"))

    local didApply = false
    local ok, err = pcall(function()
        local mults = {
            HealthRegen  = type(RegenMult_Health) == "number" and RegenMult_Health or 1.0,
            ManaRegen    = type(RegenMult_Mana) == "number" and RegenMult_Mana or 1.0,
            StaminaRegen = type(RegenMult_Stamina) == "number" and RegenMult_Stamina or 1.0,
            HealthBonus  = type(GearMult_HealthBonus) == "number" and GearMult_HealthBonus or 1.0,
            StaminaBonus = type(GearMult_StaminaBonus) == "number" and GearMult_StaminaBonus or 1.0,
            ManaBonus    = type(GearMult_ManaBonus) == "number" and GearMult_ManaBonus or 1.0,
        }

        local anyActive = false
        for _, m in pairs(mults) do
            if m ~= 1.0 then anyActive = true; break end
        end
        if not anyActive then
            log_line("Gear Stat Tweaks: all multipliers are 1.0; skipping.", 1)
            return
        end

        local function scale_impact_by_index(impacts, statByIndex)
            if not impacts or not statByIndex then return 0 end
            local count = 0
            for _, arrName in ipairs({"simple", "scaled"}) do
                pcall(function()
                    local arr = impacts[arrName]
                    if arr then
                        for uiIdx, stat in pairs(statByIndex) do
                            local impactIdx = uiIdx + 1
                            local entry = arr[impactIdx]
                            if entry and stat and mults[stat] and mults[stat] ~= 1.0 then
                                local vObj = entry.value
                                if vObj then
                                    pcall(function()
                                        local numVal = vObj.value
                                        if type(numVal) == "number" and numVal > 0 then
                                            vObj.value = m_floor(numVal * mults[stat] + 0.5)
                                            count = count + 1
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
            return count
        end

        local uiChanged, impactChanged = 0, 0
        local items = get_cached_resources_by_type("keen::ItemInfo")
        if items then
            for _, it in ipairs(items) do
                pcall(function()
                    local d = get_data(it, "keen::ItemInfo")
                    if not d then return end
                    local dbg = tostring(d.debugName or "")
                    local isGear = s_find(dbg, "Ring", 1, true) or s_find(dbg, "Armor", 1, true) or s_find(dbg, "Armour", 1, true)
                    if not isGear then return end

                    local statByIndex = {}
                    local itemUiChanged = 0
                    if d.uiValues then
                        pcall(function()
                            local idx = 0
                            for _, uv in pairs(d.uiValues) do
                                idx = idx + 1
                                if uv and type(uv.value) == "number" and uv.value > 0 then
                                    local loca = uv.locaId and uv.locaId.value
                                    local st = loca and GEAR_LOCA[loca]
                                    if st then
                                        statByIndex[idx] = st
                                        if mults[st] and mults[st] ~= 1.0 then
                                            uv.value = m_floor(uv.value * mults[st] + 0.5)
                                            itemUiChanged = itemUiChanged + 1
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    local itemImpChanged = scale_impact_by_index(d.impactValues, statByIndex)
                    if (itemUiChanged + itemImpChanged) > 0 then
                        uiChanged = uiChanged + itemUiChanged
                        impactChanged = impactChanged + itemImpChanged
                        mark_dirty(it, "keen::ItemInfo", d)
                    end
                end)
            end
        end

        didApply = (uiChanged + impactChanged) > 0
        log_line(s_format("Gear Stat Tweaks applied: ui=%d impacts=%d", uiChanged, impactChanged), 1)
    end)

    if not ok then
        log_line("ERROR in ApplyGearStatTweaks: " .. tostring(err), 1)
    end
    feature_end(ok and didApply)
end

local function ApplyInventoryTweaks()
    feature_begin("Inventory & Chest Sizes", 1)

    if not Enable_BackpackTweaks and not Enable_ChestSizeTweaks then
        log_line("Inventory & Chest Sizes: both Backpack and Chest toggles are disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local bpMax = 40
    local bpMult = type(Backpack_SlotMultiplier) == "number" and m_max(1, m_floor(Backpack_SlotMultiplier + 0.5)) or 1
    local chestMax = type(Chest_MaxSlots) == "number" and Chest_MaxSlots > 0 and Chest_MaxSlots or nil
    local chestMult = type(Chest_SlotMultiplier) == "number" and Chest_SlotMultiplier > 0 and Chest_SlotMultiplier or 2.0

    local validBp = Enable_BackpackTweaks and (bpMult > 1)
    local validChest = Enable_ChestSizeTweaks and (chestMax ~= nil)

    if not validBp and not validChest then
        log_line(("Notice: Backpack (enabled=%s, mult=%s) and Chest (enabled=%s, max=%s) require no changes; skipping."):format(
            tostring(Enable_BackpackTweaks), tostring(bpMult), tostring(Enable_ChestSizeTweaks), tostring(chestMax)
        ), 1)
        feature_end(false)
        return
    end

    local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")
    if not templates then
        log_line("WARN: keen::ecs::TemplateResource not found; skipping.", 1)
        feature_end(false)
        return
    end

    local bpTemplatesChanged, chestTemplatesChanged, bpUiChanged = 0, 0, 0

    for _, t in ipairs(templates) do
        pcall(function()
            local d = get_data(t, "keen::ecs::TemplateResource")
            if not d then return end
            local name = tostring(d.name or "")
            local comps = d.components or {}
            local tDirty = false

            if validBp and s_find(name, "Backpack_", 1, true) == 1 then
                local newBpSlots = nil
                for _, c in pairs(comps) do
                    if c.type == "keen::ecs::InventorySetup" then
                        local cur = type(c.value.genericSlotCount) == "number" and c.value.genericSlotCount or 8
                        local target = m_min(bpMax, m_max(8, m_floor((cur * bpMult) / 8 + 0.5) * 8))
                        log_line(("  Backpack template '%s': %d -> %d"):format(name, cur, target), 2)
                        if c.value.genericSlotCount ~= target or c.value.availableSlotCount ~= target then
                            c.value.genericSlotCount = target
                            c.value.availableSlotCount = target
                            bpTemplatesChanged = bpTemplatesChanged + 1
                            tDirty = true
                        end
                        newBpSlots = target
                    end
                end
                if newBpSlots then
                    for _, c in pairs(comps) do
                        if c.type == "keen::ecs::InventorySetupOverwrite" and c.value and type(c.value.genericSlotCount) == "number" then
                            if c.value.genericSlotCount ~= newBpSlots then
                                c.value.genericSlotCount = newBpSlots
                                tDirty = true
                            end
                        end
                    end
                end
            elseif validBp and s_find(name, "Backpack", 1, true) then
                for _, c in pairs(comps) do
                    if c.type == "keen::ecs::InventorySetup" then
                        log_line(("  Skipped non-item backpack template '%s' (slots=%s)"):format(name, tostring(c.value.genericSlotCount)), 2)
                    end
                end
            end

            if validChest and s_find(name, "Prop_Decoration_T", 1, true) and s_find(name, "Storage", 1, true) and not s_find(name, "Base", 1, true) and not s_find(name, "Dummy_", 1, true) then
                local newGenericSlots = nil
                for _, c in pairs(comps) do
                    if c.type == "keen::ecs::InventorySetup" then
                        if type(c.value.genericSlotCount) == "number" and c.value.genericSlotCount > 0 then
                            newGenericSlots = m_min(m_floor(c.value.genericSlotCount * chestMult + 0.5), chestMax)
                            if c.value.genericSlotCount ~= newGenericSlots then
                                c.value.genericSlotCount = newGenericSlots
                                tDirty = true
                            end
                        end
                        if type(c.value.availableSlotCount) == "number" and c.value.availableSlotCount > 0 then
                            local newAvail = m_min(m_floor(c.value.availableSlotCount * chestMult + 0.5), chestMax)
                            if c.value.availableSlotCount ~= newAvail then
                                c.value.availableSlotCount = newAvail
                                tDirty = true
                            end
                        end
                        if tDirty then
                            chestTemplatesChanged = chestTemplatesChanged + 1
                        end
                    end
                end
                if newGenericSlots then
                    for _, c in pairs(comps) do
                        if c.type == "keen::ecs::InventorySetupOverwrite" and c.value and type(c.value.genericSlotCount) == "number" then
                            if c.value.genericSlotCount ~= newGenericSlots then
                                c.value.genericSlotCount = newGenericSlots
                                tDirty = true
                            end
                        end
                    end
                end
            end

            if tDirty then
                mark_dirty(t, "keen::ecs::TemplateResource", d)
            end
        end)
    end

    if validBp then
        local items = get_cached_resources_by_type("keen::ItemInfo")
        if items then
            for _, it in ipairs(items) do
                pcall(function()
                    local d = get_data(it, "keen::ItemInfo")
                    if not d then return end
                    local dbg = tostring(d.debugName or "")
                    if s_find(dbg, "Backpack", 1, true) and d.uiValues then
                        for _, v in pairs(d.uiValues) do
                            if v and v.value ~= nil and v.valueFormat ~= "Duration" then
                                local cur = type(v.value) == "number" and v.value or (type(v.value) == "table" and v.value.value) or nil
                                if type(cur) == "number" and cur >= 4 and cur <= 40 then
                                    local target = m_min(bpMax, m_max(8, m_floor((cur * bpMult) / 8 + 0.5) * 8))
                                    if cur ~= target then
                                        if type(v.value) == "number" then
                                            v.value = target
                                        elseif type(v.value) == "table" and v.value.value ~= nil then
                                            v.value.value = target
                                        end
                                        mark_dirty(it, "keen::ItemInfo", d)
                                        bpUiChanged = bpUiChanged + 1
                                    end
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    log_line(("Inventory & Chest Tweaks: BackpackEnabled=%s (mult=%s, cap=%d, templatesPatched=%d, uiPatched=%d) | ChestEnabled=%s (mult=%s, maxSlots=%s, storageChestsPatched=%d)"):format(
        tostring(Enable_BackpackTweaks), tostring(bpMult), bpMax, bpTemplatesChanged, bpUiChanged,
        tostring(Enable_ChestSizeTweaks), tostring(chestMult), tostring(chestMax), chestTemplatesChanged
    ), 1)

    feature_end((bpTemplatesChanged + chestTemplatesChanged + bpUiChanged) > 0)
end

local function ApplyExtendedMagicStorage()
    feature_begin("Extended Magic Storage", 1)

    if not Enable_MagicFurniture and not Enable_MagicFactories then
        log_line("Extended Magic Storage: both MagicFurniture and MagicFactories are disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")
    if not templates or #templates == 0 then
        log_line("WARN: No TemplateResource entries found", 1)
        feature_end(false)
        return
    end

    local STOCK_TYPE = "keen::ecs::InventoryCraftingStock"
    local FACTORY_TYPE = "keen::ecs::FactoryStation"
    local SOURCE_GUID = "439225f1-191d-415c-a335-013419b202e7"

    local donorRes = get_cached_resource(SOURCE_GUID, "keen::ecs::TemplateResource", 0)
    if not donorRes then
        for _, t in ipairs(templates) do
            local td = get_data(t, "keen::ecs::TemplateResource")
            if td and td.name and s_find(td.name, "Prop_Decoration_T1_Storage_24_Magic", 1, true) then
                donorRes = t
                break
            end
        end
    end

    local magicFurnData = donorRes and donorRes.data
    local magicFactData = donorRes and donorRes.data
    local magicCompFurn = magicFurnData and find_component_by_type(magicFurnData.components, STOCK_TYPE)
    local magicCompFact = magicFactData and find_component_by_type(magicFactData.components, STOCK_TYPE)

    if not magicCompFurn or not magicCompFact then
        log_line("WARN: Could not locate keen::ecs::InventoryCraftingStock component to copy", 1)
        feature_end(false)
        return
    end

    pcall(function()
        if magicCompFact.value then
            magicCompFact.value.canReceiveAreaDeposit = false
        end
    end)

    local modifiedFactories, modifiedFurniture = 0, 0

    for _, t in ipairs(templates) do
        local td = get_data(t, "keen::ecs::TemplateResource")
        local name = td and td.name

        if name and td.components and not s_find(name, "Dummy_", 1, true) and not s_find(name, "Broken", 1, true) and not s_find(name, "broken", 1, true) then
            local hasStock, hasFactoryStation, hasInventorySetup = false, false, false
            local comps = {}

            for _, c in ipairs(td.components) do
                if c then
                    if c.type == STOCK_TYPE then hasStock = true end
                    if c.type == FACTORY_TYPE then hasFactoryStation = true end
                    if c.type == "keen::ecs::InventorySetup" then hasInventorySetup = true end
                    comps[#comps + 1] = c
                end
            end

            if not hasStock and hasInventorySetup then
                local isTargetFactory = Enable_MagicFactories and (hasFactoryStation or (s_find(name, "Factory", 1, true) ~= nil and not s_find(name, "Force_Generator", 1, true)))
                local isTargetFurniture = Enable_MagicFurniture and not isTargetFactory and s_find(name, "Furniture", 1, true) ~= nil and not s_find(name, "Loot", 1, true)

                if isTargetFactory or isTargetFurniture then
                    pcall(function()
                        local insertPos = #comps + 1
                        for idx, c in ipairs(comps) do
                            if tostring(c.type or "") > STOCK_TYPE then
                                insertPos = idx
                                break
                            end
                        end
                        t_insert(comps, insertPos, isTargetFactory and magicCompFact or magicCompFurn)
                        td.components = comps
                        mark_dirty(t, "keen::ecs::TemplateResource", td)
                        if isTargetFactory then
                            modifiedFactories = modifiedFactories + 1
                        else
                            modifiedFurniture = modifiedFurniture + 1
                        end
                    end)
                end
            end
        end
    end

    local totalModified = modifiedFactories + modifiedFurniture
    log_line(s_format("Extended Magic Storage applied: total=%d (Factories=%d [QuickStack=off], Furniture=%d)",
        totalModified, modifiedFactories, modifiedFurniture), 1)

    feature_end(totalModified > 0)
end

local function ApplyStackSizeTweaks()
    feature_begin("Stack Size Tweaks", 1)

    if not Enable_StackSizeTweaks then
        log_line("Stack Size Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local maxStack = type(StackSize_MaxStack) == "number" and StackSize_MaxStack or nil
    if maxStack and maxStack > 65535 then
        maxStack = 65535
    end

    if not maxStack or maxStack < 1 then
        log_line("Notice: StackSize_MaxStack is nil/invalid. Skipping.", 1)
        feature_end(false)
        return
    end

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items or #items == 0 then
        log_line("WARN: keen::ItemInfo not found; skipping.", 1)
        feature_end(false)
        return
    end

    local changed, skippedUnsafe = 0, 0
    for _, it in ipairs(items) do
        local d = get_data(it, "keen::ItemInfo")
        local cur = d and d.maxStackSize
        if type(cur) == "number" and cur >= 1 then
            if is_safe_stackable_item(d) then
                if maxStack > cur then
                    local ok = pcall(function() d.maxStackSize = maxStack end)
                    if ok then
                        mark_dirty(it, "keen::ItemInfo", d)
                        changed = changed + 1
                    end
                end
            else
                skippedUnsafe = skippedUnsafe + 1
            end
        end
    end

    log_line(("Stack Size Tweaks: patched=%d safe stackable items -> MaxStack=%s (skippedUnsafe=%d)"):format(
        changed, tostring(maxStack), skippedUnsafe
    ), 1)

    feature_end(changed > 0)
end

local function ApplyLootTweaks()
    feature_begin("Loot Tweaks", 1)

    if not Enable_LootTweaks then
        log_line("Loot Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local Loot_WorldDropMultiplier = tonumber(S("Loot_WorldDropMultiplier"))
    local Loot_ScalableDropMultiplier = tonumber(S("Loot_ScalableDropMultiplier"))
    local Loot_EnemyDropMultiplier = tonumber(S("Loot_EnemyDropMultiplier"))
    local Loot_EquipmentDropMultiplier = tonumber(S("Loot_EquipmentDropMultiplier"))
    local Loot_ConsumableDropMultiplier = tonumber(S("Loot_ConsumableDropMultiplier"))
    local Loot_ExplosiveDropMultiplier = tonumber(S("Loot_ExplosiveDropMultiplier"))
    local Loot_ArrowDropMultiplier = tonumber(S("Loot_ArrowDropMultiplier"))
    local Loot_GemDropMultiplier = tonumber(S("Loot_GemDropMultiplier"))
    local Loot_BaitDropMultiplier = tonumber(S("Loot_BaitDropMultiplier"))
    local Loot_CollectibleDropMultiplier = tonumber(S("Loot_CollectibleDropMultiplier"))
    local Loot_GoldDropMultiplier = tonumber(S("Loot_GoldDropMultiplier"))
    local Loot_MaxStackSize = 65535

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items or #items == 0 then
        log_line("WARN: No ItemInfo entries found; skipping", 1)
        feature_end(false)
        return
    end

    local lootRes = get_cached_resources_by_type("keen::LootableItemsResource")
    local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")

    local scalableByGame = {}
    if lootRes and #lootRes > 0 then
        for _, res in ipairs(lootRes) do
            pcall(function()
                local ld = get_data(res, "keen::LootableItemsResource")
                local entries = ld and ld.items
                if not entries then return end
                for _, entry in pairs(entries) do
                    local id = entry and entry.itemId and entry.itemId.value
                    if id and entry.stackSizeScalable == true then
                        scalableByGame[id] = true
                    end
                end
            end)
        end
    end

    local bushForageDefaultInvGuids = {}
    local worldChestDefaultInvGuids = {}
    local enemyDefaultInvGuids = {}
    local skipCheatOrStorageInvGuids = {}
    local normalTemplateInvGuids = {}

    if templates and #templates > 0 then
        for _tIdx, t in ipairs(templates) do
            if _tIdx % 2000 == 0 then flush_lua_refs() end
            pcall(function()
                local td = get_data(t, "keen::ecs::TemplateResource")
                if not td or not td.components then return end
                local tLow = s_lower(tostring(td.name or ""))
                local invGuid = nil

                local isCheatOrStorage = (
                    s_find(tLow, "cheat", 1, true) ~= nil or
                    s_find(tLow, "test_chest", 1, true) ~= nil or
                    s_find(tLow, "playerstorage", 1, true) ~= nil
                )
                local isEnemyTemplate = (
                    s_find(tLow, "enemy", 1, true) ~= nil or
                    s_find(tLow, "wildlife", 1, true) ~= nil or
                    s_find(tLow, "creature", 1, true) ~= nil or
                    s_find(tLow, "fell", 1, true) ~= nil or
                    s_find(tLow, "skeleton", 1, true) ~= nil or
                    s_find(tLow, "scavenger", 1, true) ~= nil or
                    s_find(tLow, "vukah", 1, true) ~= nil or
                    s_find(tLow, "corpse", 1, true) ~= nil or
                    s_find(tLow, "critter", 1, true) ~= nil or
                    s_find(tLow, "hound", 1, true) ~= nil or
                    s_find(tLow, "boss", 1, true) ~= nil
                ) and s_find(tLow, "prop_destructible_", 1, true) ~= 1

                for _, c in ipairs(td.components) do
                    local cType = c and c.type
                    if cType == "keen::ecs::DefaultInventory" and c.value and c.value.defaultInventory then
                        local g = tostring(c.value.defaultInventory)
                        if g ~= "" and g ~= NONE_GUID then
                            invGuid = g
                        end
                    elseif cType == "keen::ecs::RandomLoot" and c.value then
                        local rlGuid = c.value.defaultLabels and tostring(c.value.defaultLabels) or ""
                        if rlGuid ~= "" and rlGuid ~= NONE_GUID then
                            if isCheatOrStorage then
                                skipCheatOrStorageInvGuids[rlGuid] = true
                            else
                                normalTemplateInvGuids[rlGuid] = true
                                if isEnemyTemplate then
                                    enemyDefaultInvGuids[rlGuid] = true
                                else
                                    worldChestDefaultInvGuids[rlGuid] = true
                                end
                            end
                        end
                    end
                end

                if invGuid then
                    if isCheatOrStorage then
                        skipCheatOrStorageInvGuids[invGuid] = true
                    else
                        normalTemplateInvGuids[invGuid] = true
                        if s_find(tLow, "scatter_loot_", 1, true) == 1 or
                           s_find(tLow, "lootpickup_", 1, true) == 1 or
                           s_find(tLow, "plant_", 1, true) ~= nil or
                           s_find(tLow, "bush", 1, true) ~= nil or
                           s_find(tLow, "shrub", 1, true) ~= nil or
                           s_find(tLow, "herb", 1, true) ~= nil then
                            bushForageDefaultInvGuids[invGuid] = true
                        elseif isEnemyTemplate then
                            enemyDefaultInvGuids[invGuid] = true
                        else
                            worldChestDefaultInvGuids[invGuid] = true
                        end
                    end
                end
            end)
        end
    end

    local itemCategoryById = {}
    local eligibleItems = {}
    local itemMultipliers = {}
    local itemGuidToId = {}
    local itemIsStackable = {}
    local itemIsScalableLoot = {}
    local itemIsEnemyDropItem = {}
    local itemIsDedicatedCategory = {}

    local equipMulti = type(Loot_EquipmentDropMultiplier) == "number" and Loot_EquipmentDropMultiplier > 0 and Loot_EquipmentDropMultiplier or 1.0
    local consMulti = type(Loot_ConsumableDropMultiplier) == "number" and Loot_ConsumableDropMultiplier > 0 and Loot_ConsumableDropMultiplier or 1.0
    local arrowMulti = type(Loot_ArrowDropMultiplier) == "number" and Loot_ArrowDropMultiplier > 0 and Loot_ArrowDropMultiplier or 1.0
    local gemMulti = type(Loot_GemDropMultiplier) == "number" and Loot_GemDropMultiplier > 0 and Loot_GemDropMultiplier or 1.0
    local explosiveMulti = type(Loot_ExplosiveDropMultiplier) == "number" and Loot_ExplosiveDropMultiplier > 0 and Loot_ExplosiveDropMultiplier or 1.0
    local nonScalableMulti = type(Loot_WorldDropMultiplier) == "number" and Loot_WorldDropMultiplier > 0 and Loot_WorldDropMultiplier or 1.0
    local scalableMulti = type(Loot_ScalableDropMultiplier) == "number" and Loot_ScalableDropMultiplier > 0 and Loot_ScalableDropMultiplier or 1.0
    local enemyMulti = type(Loot_EnemyDropMultiplier) == "number" and Loot_EnemyDropMultiplier > 0 and Loot_EnemyDropMultiplier or 1.0
    local baitMulti = type(Loot_BaitDropMultiplier) == "number" and Loot_BaitDropMultiplier > 0 and Loot_BaitDropMultiplier or 1.0
    local collectibleMulti = type(Loot_CollectibleDropMultiplier) == "number" and Loot_CollectibleDropMultiplier > 0 and Loot_CollectibleDropMultiplier or 1.0
    local goldMulti = type(Loot_GoldDropMultiplier) == "number" and Loot_GoldDropMultiplier > 0 and Loot_GoldDropMultiplier or 1.0
    local maxStack = type(Loot_MaxStackSize) == "number" and Loot_MaxStackSize >= 1 and Loot_MaxStackSize or nil

    local function compute_scaled(before, mult)
        if type(before) ~= "number" or mult == 1.0 then return before, false end
        local after = m_floor(before * mult + 0.5)
        if before > 0 and after < 1 then after = 1 end
        if after < 0 then after = 0 end
        return after, (after ~= before)
    end

    local function scale_field(obj, field, mult)
        if not obj or type(obj[field]) ~= "number" then return false end
        local after, changed = compute_scaled(obj[field], mult)
        if changed then
            obj[field] = after
            return true
        end
        return false
    end

    local itemInfoRangeChanged = 0

    for _, it in ipairs(items) do
        local d = get_data(it, "keen::ItemInfo")
        if d then
            local id = d.itemId and d.itemId.value
            local guidStr = it.guid and tostring(it.guid) or nil
            local dbgRaw = tostring(d.debugName or "unknown")
            if type(id) == "number" then
                if guidStr and guidStr ~= "" then
                    itemGuidToId[guidStr] = id
                end
                local dbg = s_lower(dbgRaw)
                local cat = s_lower(tostring(d.category or ""))
                local slot = d.equipment and s_lower(tostring(d.equipment.slot or "")) or ""
                local maxStackVal = d.maxStackSize
                local isStackable = (type(maxStackVal) == "number" and maxStackVal > 1)
                itemIsStackable[id] = isStackable
                local isGameScalable = (scalableByGame[id] == true)
                local isTerrainMat = (s_find(dbg, "build_terrainmaterial_", 1, true) == 1)

                local isGold = not isTerrainMat and d.equipment == nil and (
                    s_find(dbg, "gold_coin", 1, true) ~= nil or
                    s_find(dbg, "goldcoin", 1, true) ~= nil or
                    s_find(dbg, "token_gold", 1, true) ~= nil or
                    s_find(dbg, "coin_", 1, true) == 1 or
                    s_find(dbg, "_coin", 1, true) ~= nil or
                    s_find(dbg, "currency", 1, true) ~= nil
                ) and not s_find(dbg, "prop_", 1, true) and not s_find(dbg, "ingot", 1, true) and not s_find(dbg, "bar", 1, true) and not s_find(dbg, "ore", 1, true)

                local isRuneOrCore = not isGold and not isTerrainMat and d.equipment == nil and (
                    s_find(dbg, "token_weaponupgrade_rune", 1, true) ~= nil or
                    s_find(dbg, "token_rune", 1, true) ~= nil or
                    s_find(dbg, "_rune", 1, true) ~= nil or
                    s_find(dbg, "rune_", 1, true) == 1 or
                    s_find(dbg, "shroud_core", 1, true) ~= nil or
                    s_find(dbg, "shroudcore", 1, true) ~= nil or
                    s_find(dbg, "token_", 1, true) == 1
                ) and not s_find(dbg, "lore", 1, true) and not s_find(dbg, "quest", 1, true)

                local isCollectible = not isGold and not isRuneOrCore and not isTerrainMat and slot ~= "buildtool" and
                    s_find(dbg, "prop_", 1, true) ~= 1 and s_find(dbg, "_prop_", 1, true) ~= 1 and s_find(dbg, "z_prop_", 1, true) ~= 1 and
                    s_find(dbg, "material_", 1, true) ~= 1 and s_find(dbg, "_material_", 1, true) ~= 1 and (
                    s_find(dbg, "fossil", 1, true) ~= nil or
                    s_find(dbg, "colorpalette", 1, true) ~= nil or
                    s_find(dbg, "dye_", 1, true) ~= nil or
                    s_find(dbg, "_dye", 1, true) ~= nil or
                    s_find(dbg, "collection_", 1, true) == 1 or
                    s_find(dbg, "collectible", 1, true) ~= nil or
                    s_find(dbg, "instrument_", 1, true) == 1 or
                    s_find(dbg, "_toy_", 1, true) ~= nil or
                    s_find(dbg, "music_sheet", 1, true) ~= nil or
                    cat == "collectibles"
                )

                local isQuest = not isGold and not isRuneOrCore and not isCollectible and slot ~= "buildtool" and (
                    s_find(dbg, "quest_", 1, true) ~= nil or
                    s_find(dbg, "_quest", 1, true) ~= nil or
                    s_find(dbg, "loretext", 1, true) ~= nil or
                    s_find(dbg, "lore_", 1, true) == 1 or
                    s_find(dbg, "key_", 1, true) == 1 or
                    cat == "quest" or
                    cat == "questitems"
                )

                local isSpecialGroup = (isGold or isRuneOrCore or isCollectible)
                local isSpell = (slot == "spell" or cat == "spells" or cat == "magic" or s_find(dbg, "spell", 1, true) ~= nil or s_find(dbg, "eternal", 1, true) ~= nil)
                local isEnemyOrTrapProj = (s_find(dbg, "ammo_enemy_", 1, true) == 1 or s_find(dbg, "ammo_trap_", 1, true) == 1 or s_find(dbg, "_ammo_consumable_", 1, true) == 1)
                local isCraftedAnimalOrSimpleBait = (
                    s_find(dbg, "_bait", 1, true) ~= nil or
                    s_find(dbg, "_feeding", 1, true) ~= nil or
                    s_find(dbg, "simple_fishingbait", 1, true) ~= nil
                )
                local isHardExcluded = isQuest or (not isSpecialGroup and (
                    isSpell or
                    isEnemyOrTrapProj or
                    isCraftedAnimalOrSimpleBait or
                    is_harvesting_tool(dbg) or
                    s_find(dbg, "lockpick_", 1, true) == 1 or
                    s_find(dbg, "surprise_", 1, true) == 1 or
                    s_find(dbg, "prop_", 1, true) == 1 or
                    s_find(dbg, "_prop_", 1, true) == 1 or
                    s_find(dbg, "z_prop_", 1, true) == 1 or
                    s_find(dbg, "block_", 1, true) == 1 or
                    s_find(dbg, "_block_", 1, true) == 1 or
                    s_find(dbg, "building_", 1, true) == 1 or
                    s_find(dbg, "blueprint_", 1, true) == 1 or
                    s_find(dbg, "_blueprint_", 1, true) == 1 or
                    s_find(dbg, "_no_blueprint_", 1, true) == 1 or
                    s_find(dbg, "buildtool_", 1, true) == 1 or
                    s_find(dbg, "flower_pot_", 1, true) == 1 or
                    s_find(dbg, "empty_flower_pot_", 1, true) == 1 or
                    s_find(dbg, "_flower_pot_", 1, true) == 1 or
                    s_find(dbg, "seedling_", 1, true) == 1 or
                    s_find(dbg, "trophy_", 1, true) ~= nil or
                    (s_find(dbg, "animal_", 1, true) == 1 and s_find(dbg, "fur", 1, true) == nil and s_find(dbg, "meat", 1, true) == nil and s_find(dbg, "hide", 1, true) == nil and s_find(dbg, "bone", 1, true) == nil and s_find(dbg, "fat", 1, true) == nil and s_find(dbg, "claw", 1, true) == nil and s_find(dbg, "scale", 1, true) == nil and s_find(dbg, "feather", 1, true) == nil) or
                    s_find(dbg, "npc_", 1, true) == 1 or
                    s_find(dbg, "npcsummoner_", 1, true) == 1 or
                    s_find(dbg, "vc_", 1, true) == 1 or
                    s_find(dbg, "vanity_", 1, true) == 1 or
                    s_find(dbg, "backpack_", 1, true) == 1 or
                    (s_find(dbg, "tool_", 1, true) == 1 and s_find(dbg, "torch", 1, true) == nil) or
                    s_find(dbg, "icon_", 1, true) == 1 or
                    s_find(dbg, "ability_", 1, true) == 1 or
                    s_find(dbg, "base_", 1, true) == 1 or
                    s_find(dbg, "philipp_", 1, true) == 1 or
                    s_find(dbg, "test", 1, true) == 1 or
                    slot == "buildtool" or
                    slot == "tool" or
                    slot == "glider" or
                    slot == "backpack"
                ))

                local isBait = not isHardExcluded and not isSpecialGroup and (
                    s_find(dbg, "firefly", 1, true) ~= nil or
                    s_find(dbg, "fire_fly", 1, true) ~= nil or
                    s_find(dbg, "fishingbait", 1, true) ~= nil
                )
                local isArrow = not isHardExcluded and not isSpecialGroup and not isBait and isStackable and (
                    slot == "arrow" or
                    s_find(dbg, "ammo_", 1, true) == 1 or
                    s_find(dbg, "_ammo_", 1, true) == 1 or
                    s_find(dbg, "arrow_", 1, true) ~= nil
                )
                local isGem = not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and (
                    s_find(dbg, "_gem_", 1, true) ~= nil or
                    s_find(dbg, "gem_", 1, true) == 1 or
                    cat == "gems"
                ) and not s_find(dbg, "food_", 1, true)
                local isExplosive = not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and (
                    s_find(dbg, "grenade", 1, true) ~= nil or
                    s_find(dbg, "powderball", 1, true) ~= nil
                )
                local isRawMeat = (
                    (s_find(dbg, "food_", 1, true) == 1 or s_find(dbg, "_food_", 1, true) == 1) and
                    (s_find(dbg, "meat", 1, true) ~= nil or s_find(dbg, "_game", 1, true) ~= nil or s_find(dbg, "_bird", 1, true) ~= nil) and
                    (s_find(dbg, "_raw", 1, true) ~= nil or s_find(dbg, "raw_", 1, true) ~= nil)
                )
                local isRawWorldFood = not isRawMeat and (
                    s_find(dbg, "_raw", 1, true) ~= nil or
                    s_find(dbg, "raw_", 1, true) ~= nil
                )
                local isCons = not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and not isExplosive and not isRawMeat and not isRawWorldFood and (
                    s_find(dbg, "consumable_", 1, true) == 1 or
                    s_find(dbg, "_consumable_", 1, true) == 1 or
                    s_find(dbg, "food_", 1, true) == 1 or
                    s_find(dbg, "_food_", 1, true) == 1 or
                    s_find(dbg, "_unused_food_", 1, true) == 1 or
                    s_find(dbg, "potion", 1, true) ~= nil or
                    s_find(dbg, "bandage", 1, true) ~= nil
                )
                local isMaterialOrTerrain = (
                    s_find(dbg, "material_", 1, true) == 1 or
                    s_find(dbg, "_material_", 1, true) == 1 or
                    isTerrainMat
                )
                local isEquip = (not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and not isExplosive and not isCons and not isRawMeat and not isRawWorldFood and not isMaterialOrTerrain and not isGameScalable and (d.equipment ~= nil or maxStackVal == 1))
                local isEnemyDropItem = not isHardExcluded and not isGold and not isCollectible and not isBait and not isArrow and not isGem and not isExplosive and not isCons and not isEquip and (
                    isRuneOrCore or
                    isRawMeat or
                    s_find(dbg, "animal_fur", 1, true) ~= nil or
                    s_find(dbg, "dried_fur", 1, true) ~= nil or
                    s_find(dbg, "torn_cloth", 1, true) ~= nil or
                    s_find(dbg, "shroudspores", 1, true) ~= nil or
                    s_find(dbg, "fog_essence", 1, true) ~= nil or
                    (s_find(dbg, "bone", 1, true) ~= nil and s_find(dbg, "fossil", 1, true) == nil)
                )
                local isNonScalableMat = (
                    not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and not isExplosive and not isCons and not isEquip and not isEnemyDropItem and
                    isStackable and not isGameScalable
                )
                local isNonScalableLoot = not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and not isExplosive and not isCons and not isEquip and not isEnemyDropItem and (
                    (isRawWorldFood and not isGameScalable) or isNonScalableMat
                )
                local isScalableLoot = not isHardExcluded and not isSpecialGroup and not isBait and not isArrow and not isGem and not isExplosive and not isCons and not isEquip and not isEnemyDropItem and isStackable and isGameScalable

                itemIsScalableLoot[id] = isScalableLoot
                itemIsEnemyDropItem[id] = isEnemyDropItem
                itemIsDedicatedCategory[id] = (isGold or isCollectible or isBait or isArrow or isGem or isExplosive or isCons or isEquip)

                local assignedMult = 1.0
                if isHardExcluded then assignedMult = 1.0; itemCategoryById[id] = "Excluded"
                elseif isGold then assignedMult = goldMulti; itemCategoryById[id] = "Gold"
                elseif isCollectible then assignedMult = collectibleMulti; itemCategoryById[id] = "Collectible"
                elseif isBait then assignedMult = baitMulti; itemCategoryById[id] = "Bait"
                elseif isArrow then assignedMult = arrowMulti; itemCategoryById[id] = "Arrow/Ammo"
                elseif isGem then assignedMult = gemMulti; itemCategoryById[id] = "Gem"
                elseif isExplosive then assignedMult = explosiveMulti; itemCategoryById[id] = "Explosive"
                elseif isCons then assignedMult = consMulti; itemCategoryById[id] = "Consumable"
                elseif isEquip then assignedMult = equipMulti; itemCategoryById[id] = "Equipment"
                elseif isEnemyDropItem then assignedMult = enemyMulti; itemCategoryById[id] = "EnemyLoot"
                elseif isNonScalableLoot then assignedMult = nonScalableMulti; itemCategoryById[id] = "NonScalableLoot"
                elseif isScalableLoot then assignedMult = scalableMulti; itemCategoryById[id] = "ScalableLoot"
                else assignedMult = 1.0; itemCategoryById[id] = "Excluded"
                end

                itemMultipliers[id] = assignedMult
                if type(maxStackVal) == "number" and maxStackVal >= 1 then
                    eligibleItems[id] = true
                end

                if not isHardExcluded and assignedMult ~= 1.0 and d.randomLootStackRange then
                    pcall(function()
                        local r = d.randomLootStackRange
                        local newMin, cMin = compute_scaled(r.minStackSize, assignedMult)
                        local newMax, cMax = compute_scaled(r.maxStackSize, assignedMult)
                        if cMin or cMax then
                            if type(newMin) == "number" and type(newMax) == "number" and newMax < newMin then
                                newMax = newMin
                            end
                            if set_random_loot_stack_range(d, newMin, newMax) then
                                mark_dirty(it, "keen::ItemInfo", d)
                                itemInfoRangeChanged = itemInfoRangeChanged + 1
                            end
                        end
                    end)
                end
            end
        end
    end

    local didWork = (itemInfoRangeChanged > 0)
    log_line(("ItemInfo randomLootStackRange changed=%d"):format(itemInfoRangeChanged), 1)

    local defaultInv = get_cached_resources_by_type("keen::ecs::DefaultInventoryResource")
    if defaultInv and #defaultInv > 0 then
        local invScanned, invChanged, invFailed = 0, 0, 0
        for _, res in ipairs(defaultInv) do
            local ok = pcall(function()
                local invData = get_data(res, "keen::ecs::DefaultInventoryResource")
                local root = invData and invData.rootGroup
                if not root then return end
                local resGuid = res.guid and tostring(res.guid) or ""
                if skipCheatOrStorageInvGuids[resGuid] and not normalTemplateInvGuids[resGuid] then return end
                local isBushForageInv = (bushForageDefaultInvGuids[resGuid] == true)
                local isEnemyInv = not isBushForageInv and ((enemyDefaultInvGuids[resGuid] == true) or not worldChestDefaultInvGuids[resGuid])
                local resDirty = false

                local function patch_stacks(stacks)
                    if not stacks then return end
                    for idx, stack in pairs(stacks) do
                        local id = stack and stack.item and stack.item.value
                        if id and eligibleItems[id] then
                            invScanned = invScanned + 1
                            local m = itemMultipliers[id] or 1.0
                            if itemIsDedicatedCategory[id] then
                                m = itemMultipliers[id]
                            elseif isBushForageInv then
                                m = nonScalableMulti
                            elseif isEnemyInv or itemIsEnemyDropItem[id] then
                                m = enemyMulti
                            end
                            local newMin, cMin = compute_scaled(stack.countMin, m)
                            local newMax, cMax = compute_scaled(stack.countMax, m)
                            if cMin or cMax then
                                if type(newMin) == "number" and type(newMax) == "number" and newMax < newMin then
                                    newMax = newMin
                                end
                                local okSet = pcall(function()
                                    stack.countMin = newMin
                                    stack.countMax = newMax
                                end)
                                if not okSet then
                                    pcall(function()
                                        stacks[idx] = {
                                            itemRef = stack.itemRef or NONE_GUID,
                                            item = { value = id },
                                            countMin = newMin,
                                            countMax = newMax,
                                            spawnProbability = stack.spawnProbability,
                                            weight = stack.weight,
                                            lootLabelsId = { value = (stack.lootLabelsId and stack.lootLabelsId.value) or 0 },
                                        }
                                    end)
                                end
                                invChanged = invChanged + 1
                                resDirty = true
                            end
                        end
                    end
                end

                local function patch_group_recursive(grp, depth)
                    if not grp or depth > 12 then return end
                    patch_stacks(grp.stacks)
                    if grp.groups then
                        for _, sub in pairs(grp.groups) do
                            patch_group_recursive(sub, depth + 1)
                        end
                    end
                    if grp.lootLabels and grp.lootLabels.childGroups then
                        for _, sub in pairs(grp.lootLabels.childGroups) do
                            patch_group_recursive(sub, depth + 1)
                        end
                    end
                end

                patch_group_recursive(root, 1)
                if resDirty then
                    mark_dirty(res, "keen::ecs::DefaultInventoryResource", invData)
                end
            end)
            if not ok then invFailed = invFailed + 1 end
        end
        log_line(("DefaultInventoryResource scanned=%d changed=%d failed=%d"):format(invScanned, invChanged, invFailed), 1)
        if invChanged > 0 then didWork = true end
    end

    if lootRes and #lootRes > 0 then
        local lootScanned, lootChanged, lootFailed = 0, 0, 0
        for _, res in ipairs(lootRes) do
            local ok = pcall(function()
                local ld = get_data(res, "keen::LootableItemsResource")
                local entries = ld and ld.items
                if not entries then return end
                local resDirty = false
                for _, entry in pairs(entries) do
                    local id = entry and entry.itemId and entry.itemId.value
                    if id and eligibleItems[id] then
                        lootScanned = lootScanned + 1
                        local m = itemMultipliers[id] or 1.0
                        local any = false
                        local scaledStack = false
                        scaledStack = scale_field(entry, "stackSizeMin", m) or scaledStack
                        scaledStack = scale_field(entry, "stackSizeMax", m) or scaledStack
                        if scaledStack then
                            if type(entry.stackSizeMin) == "number" and type(entry.stackSizeMax) == "number" and entry.stackSizeMax < entry.stackSizeMin then
                                entry.stackSizeMax = entry.stackSizeMin
                            end
                            any = true
                        end
                        if itemIsStackable[id] == true and maxStack ~= nil and entry.stackSizeMaxScaled ~= nil then
                            if entry.stackSizeMaxScaled < maxStack then
                                entry.stackSizeMaxScaled = maxStack
                                any = true
                            end
                        end
                        if any then
                            lootChanged = lootChanged + 1
                            resDirty = true
                        end
                    end
                end
                if resDirty then
                    mark_dirty(res, "keen::LootableItemsResource", ld)
                end
            end)
            if not ok then lootFailed = lootFailed + 1 end
        end
        log_line(("LootableItemsResource scanned=%d changed=%d failed=%d"):format(lootScanned, lootChanged, lootFailed), 1)
        if lootChanged > 0 then didWork = true end
    end

    if templates and #templates > 0 then
        local pickupScanned, pickupChanged, tmplInvScanned, tmplInvChanged = 0, 0, 0, 0
        for _, t in ipairs(templates) do
            pcall(function()
                local td = get_data(t, "keen::ecs::TemplateResource")
                local comps = td and td.components
                if not comps then return end
                local tLow = s_lower(tostring(td.name or ""))
                if s_find(tLow, "base_", 1, true) == 1 or
                   s_find(tLow, "dummy_", 1, true) ~= nil or
                   s_find(tLow, "broken", 1, true) ~= nil or
                   s_find(tLow, "player", 1, true) ~= nil or
                   s_find(tLow, "backpack", 1, true) ~= nil or
                   s_find(tLow, "cheat", 1, true) ~= nil or
                   s_find(tLow, "test_chest", 1, true) ~= nil then
                    return
                end

                local isDecorationStorage = (s_find(tLow, "prop_decoration_t", 1, true) ~= nil and s_find(tLow, "storage", 1, true) ~= nil)
                local isEnemyPickup = (s_find(tLow, "enemy", 1, true) ~= nil or s_find(tLow, "skeleton", 1, true) ~= nil or s_find(tLow, "wildlife", 1, true) ~= nil or s_find(tLow, "fell", 1, true) ~= nil)
                local tDirty = false

                for _, c in ipairs(comps) do
                    local cType = c and c.type
                    local cVal = c and c.value
                    if cType == "keen::ecs::PickupItem" and cVal and not isDecorationStorage then
                        pickupScanned = pickupScanned + 1
                        local itemGuid = cVal.item and tostring(cVal.item) or nil
                        local idVal = (cVal.itemId and cVal.itemId.value ~= 0 and cVal.itemId.value) or (itemGuid and itemGuidToId[itemGuid]) or nil
                        if idVal and itemIsStackable[idVal] == true and itemCategoryById[idVal] ~= "Excluded" then
                            local m = itemMultipliers[idVal] or 1.0
                            if itemIsDedicatedCategory[idVal] then
                                m = itemMultipliers[idVal]
                            elseif isEnemyPickup or itemIsEnemyDropItem[idVal] then
                                m = enemyMulti
                            elseif itemIsScalableLoot[idVal] then
                                m = nonScalableMulti
                            end
                            if scale_field(cVal, "pickupAmount", m) then
                                pickupChanged = pickupChanged + 1
                                tDirty = true
                            end
                        end
                    elseif cType == "keen::ecs::Inventory" and cVal and cVal.slots and not isDecorationStorage then
                        for sIdx = 1, #cVal.slots do
                            local sl = cVal.slots[sIdx]
                            local idVal = sl and sl.id and sl.id.value
                            if idVal and idVal ~= 0 and eligibleItems[idVal] and sl.data and type(sl.data.count) == "number" and sl.data.count > 0 then
                                tmplInvScanned = tmplInvScanned + 1
                                local m = itemMultipliers[idVal] or 1.0
                                if itemCategoryById[idVal] == "Excluded" then
                                    m = 1.0
                                elseif not itemIsDedicatedCategory[idVal] and isEnemyPickup then
                                    m = enemyMulti
                                end
                                if scale_field(sl.data, "count", m) then
                                    tmplInvChanged = tmplInvChanged + 1
                                    tDirty = true
                                end
                            end
                        end
                    end
                end

                if tDirty then
                    mark_dirty(t, "keen::ecs::TemplateResource", td)
                end
            end)
        end
        log_line(("TemplateResource WorldPickups scanned=%d changed=%d | EmbeddedTemplateSlots scanned=%d changed=%d"):format(
            pickupScanned, pickupChanged, tmplInvScanned, tmplInvChanged
        ), 1)
        if pickupChanged > 0 or tmplInvChanged > 0 then didWork = true end
    end

    feature_end(didWork)
end

local function ApplyGemTweaks()
    feature_begin("Gem Tweaks", 1)

    if not Enable_GemTweaks then
        log_line("Gem Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local GemTweaks_SalvageRate = tonumber(S("GemTweaks_SalvageRate"))
    local GemTweaks_Probability_Common = tonumber(S("GemTweaks_Probability_Common"))
    local GemTweaks_Probability_Uncommon = tonumber(S("GemTweaks_Probability_Uncommon"))
    local GemTweaks_Probability_Rare = tonumber(S("GemTweaks_Probability_Rare"))
    local GemTweaks_Probability_Epic = tonumber(S("GemTweaks_Probability_Epic"))
    local GemTweaks_Probability_Legendary = tonumber(S("GemTweaks_Probability_Legendary"))

    local function clamp_gem_rate(val)
        if type(val) ~= "number" then return nil end
        return m_max(0.0, m_min(val, 1.0))
    end

    local salvageRate = clamp_gem_rate(GemTweaks_SalvageRate)
    local commonRate = clamp_gem_rate(GemTweaks_Probability_Common)
    local uncommonRate = clamp_gem_rate(GemTweaks_Probability_Uncommon)
    local rareRate = clamp_gem_rate(GemTweaks_Probability_Rare)
    local epicRate = clamp_gem_rate(GemTweaks_Probability_Epic)
    local legendaryRate = clamp_gem_rate(GemTweaks_Probability_Legendary)

    if not salvageRate and not commonRate and not uncommonRate and not rareRate and not epicRate and not legendaryRate then
        log_line("Notice: All GemTweaks parameters are nil/invalid. Skipping.", 1)
        feature_end(false)
        return
    end

    local btRes = get_first_resource_by_type("keen::BalancingTable")
    local bt = get_data(btRes, "keen::BalancingTable")
    if not bt then
        log_line("WARN: keen::BalancingTable not found; skipping", 1)
        feature_end(false)
        return
    end

    local patchedFields = 0
    pcall(function()
        if bt.gemCrafting ~= nil and salvageRate ~= nil and bt.gemCrafting.salvageGainPercentage ~= nil then
            bt.gemCrafting.salvageGainPercentage = salvageRate
            patchedFields = patchedFields + 1
        end
        if bt.gemSlotProbability ~= nil then
            if commonRate ~= nil and bt.gemSlotProbability.common ~= nil then bt.gemSlotProbability.common = commonRate; patchedFields = patchedFields + 1 end
            if uncommonRate ~= nil and bt.gemSlotProbability.uncommon ~= nil then bt.gemSlotProbability.uncommon = uncommonRate; patchedFields = patchedFields + 1 end
            if rareRate ~= nil and bt.gemSlotProbability.rare ~= nil then bt.gemSlotProbability.rare = rareRate; patchedFields = patchedFields + 1 end
            if epicRate ~= nil and bt.gemSlotProbability.epic ~= nil then bt.gemSlotProbability.epic = epicRate; patchedFields = patchedFields + 1 end
            if legendaryRate ~= nil and bt.gemSlotProbability.legendary ~= nil then bt.gemSlotProbability.legendary = legendaryRate; patchedFields = patchedFields + 1 end
        end
    end)

    if patchedFields > 0 then
        mark_dirty(btRes, "keen::BalancingTable", bt)
    end

    log_line(("BalancingTable patchedFields=%d salvageRate=%s"):format(patchedFields, tostring(salvageRate)), 1)
    feature_end(patchedFields > 0)
end


-- ============================================================================
-- FEATURE IMPLEMENTATIONS (PART B)
-- ============================================================================

local function ApplyCraftingTweaks()
    feature_begin("Crafting Tweaks", 1)

    if not Enable_CraftingTweaks then
        log_line("Crafting Tweaks: master toggle disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local unlockRecipes = S("CraftingTweaks_UnlockAllRecipes") == true
    local creativeMode = S("CraftingTweaks_CreativeMode") == true
    local infPropPlacement = S("CraftingTweaks_InfinitePropPlacement") == true
    local CraftingTweaks_FreeFactories = S("CraftingTweaks_FreeFactories") == true
    local CraftingTweaks_FreeFlameAltar = S("CraftingTweaks_FreeFlameAltar") == true
    local CraftingTweaks_FreeFood = S("CraftingTweaks_FreeFood") == true
    local outMult = tonumber(S("CraftingTweaks_OutputMultiplier")) or 1.0

    if not unlockRecipes and not creativeMode and not infPropPlacement and not CraftingTweaks_FreeFactories and not CraftingTweaks_FreeFlameAltar and not CraftingTweaks_FreeFood and outMult == 1.0 then
        log_line("Crafting Tweaks: no sub-features enabled; skipping.", 1)
        feature_end(false)
        return
    end

    local registryList = get_cached_resources_by_type("keen::RecipeRegistryResource")
    local unlockCount, creativeCount, freeFoodCount, freeFactoryCount, freeAltarCount, npcShelterPatched, propItemsPatched = 0, 0, 0, 0, 0, 0, 0
    local didWork = false

    local FACTORY_KEYS = { "Factory", "Production" }
    local FOOD_KEYS = { "Food_", "Grill", "Fish", "Oven", "Mushroom", "Meat", "Corn", "Grain" }
    local ALTAR_UPGRADE_KEYS = { "Flame_Level_", "FlameAltar_HomeBase_Upgrade_" }

    local function matchesAny(name, keys)
        for _, k in ipairs(keys) do
            if s_find(name, k, 1, true) then return true end
        end
        return false
    end

    local function isCampfireCooking(name, r)
        local lower = s_lower(name)
        return r.isCookingRecipe and s_find(lower, "campfire", 1, true)
            and not s_find(lower, "fish", 1, true)
            and not s_find(lower, "crab", 1, true)
            and not s_find(lower, "grill", 1, true)
            and not s_find(lower, "oven", 1, true)
            and not s_find(lower, "meat", 1, true)
            and not s_find(lower, "mushroom", 1, true)
            and not s_find(lower, "corn", 1, true)
            and not s_find(lower, "grain", 1, true)
    end

    local function clone_knowledge_query(kq, overrideId, overrideVal, overrideOp, overrideType, overrideExplicit)
        local curId = (kq and kq.knowledgeOrQueryId and kq.knowledgeOrQueryId.value) or 0
        if overrideId ~= nil then
            return {
                knowledgeOrQueryId = { value = overrideId },
                compareValue = overrideVal,
                compareOperator = overrideOp,
                type = overrideType,
                isExplicitPlayerKnowledgeQuery = overrideExplicit,
            }
        end
        return {
            knowledgeOrQueryId = { value = curId },
            compareValue = (kq and kq.compareValue) or 0,
            compareOperator = (kq and kq.compareOperator) or "Equals",
            type = (kq and kq.type) or "SimpleBool",
            isExplicitPlayerKnowledgeQuery = (kq and kq.isExplicitPlayerKnowledgeQuery) == true,
        }
    end

    if registryList and #registryList > 0 and (unlockRecipes or creativeMode or CraftingTweaks_FreeFactories or CraftingTweaks_FreeFlameAltar or CraftingTweaks_FreeFood or outMult ~= 1.0) then
        for _, reg in ipairs(registryList) do
            local rdata = get_data(reg, "keen::RecipeRegistryResource")
            if rdata and rdata.recipes then
                local changedReg = false
                local recipesOut = {}

                for rIdx = 1, #rdata.recipes do
                    local recipe = rdata.recipes[rIdx]
                    local dn = tostring(recipe.debugName or "")

                    local isExcluded = isCampfireCooking(dn, recipe)
                    local isFactory = matchesAny(dn, FACTORY_KEYS)
                    local isFood = matchesAny(dn, FOOD_KEYS) and not s_find(dn, "Bait", 1, true) and not s_find(dn, "Potion", 1, true) and not s_find(dn, "Rod", 1, true)
                    local isAltarUpgrade = matchesAny(dn, ALTAR_UPGRADE_KEYS)

                    local makeFree = false
                    if isExcluded then
                        if creativeMode and infPropPlacement then
                            makeFree = true
                            creativeCount = creativeCount + 1
                        end
                    elseif CraftingTweaks_FreeFood and isFood then
                        makeFree = true
                        freeFoodCount = freeFoodCount + 1
                        creativeCount = creativeCount + 1
                    elseif CraftingTweaks_FreeFlameAltar and isAltarUpgrade then
                        makeFree = true
                        freeAltarCount = freeAltarCount + 1
                        creativeCount = creativeCount + 1
                    elseif creativeMode and not isAltarUpgrade and not isFood and (infPropPlacement or not s_find(dn, "Algae", 1, true)) and (not isFactory or s_find(dn, "EctoplasmPress", 1, true) or s_find(dn, "BeeHive", 1, true) or s_find(dn, "Smoker_for_Beehive", 1, true)) then
                        makeFree = true
                        creativeCount = creativeCount + 1
                    elseif CraftingTweaks_FreeFactories and isFactory and not isFood then
                        makeFree = true
                        freeFactoryCount = freeFactoryCount + 1
                        creativeCount = creativeCount + 1
                    end

                    -- Unlock All Recipes
                    local kqOut
                    local cqOut
                    if unlockRecipes and recipe.knowledgeRequirement then
                        local req = recipe.knowledgeRequirement
                        local kid = req.knowledgeOrQueryId and req.knowledgeOrQueryId.value
                        if kid and kid ~= 1715248921 then
                            kqOut = clone_knowledge_query(req, 1715248921, 1, "Equals", "SimpleBool", false)
                            unlockCount = unlockCount + 1
                            changedReg = true
                        else
                            kqOut = clone_knowledge_query(req)
                        end
                        local creq = recipe.completionRequirementQuery
                        local cid = creq and creq.knowledgeOrQueryId and creq.knowledgeOrQueryId.value
                        if cid and cid ~= 3584013164 then
                            cqOut = {
                                knowledgeOrQueryId = { value = 3584013164 },
                                compareValue = (creq and creq.compareValue) or 0,
                                compareOperator = (creq and creq.compareOperator) or "Equals",
                                type = (creq and creq.type) or "SimpleBool",
                                isExplicitPlayerKnowledgeQuery = (creq and creq.isExplicitPlayerKnowledgeQuery) == true,
                            }
                            changedReg = true
                        else
                            cqOut = clone_knowledge_query(creq)
                        end
                    else
                        kqOut = clone_knowledge_query(recipe.knowledgeRequirement)
                        cqOut = clone_knowledge_query(recipe.completionRequirementQuery)
                    end

                    -- Inputs
                    local inputsOut = {}
                    if recipe.input then
                        for i = 1, #recipe.input do
                            local inp = recipe.input[i]
                            local st = inp.itemStack
                            local cat = inp.inputItemCategory
                            local stCount = (st and st.count) or 0
                            local catCount = (cat and cat.count) or 0
                            if makeFree then
                                if stCount ~= 0 then stCount = 0; changedReg = true end
                                if catCount ~= 0 then catCount = 0; changedReg = true end
                            end
                            inputsOut[i] = {
                                itemStack = {
                                    itemRef = (st and st.itemRef) or NONE_GUID,
                                    item = { value = (st and st.item and st.item.value) or 0 },
                                    count = stCount,
                                },
                                inputItemCategory = {
                                    categoryRef = (cat and cat.categoryRef) or NONE_GUID,
                                    category = { value = (cat and cat.category and cat.category.value) or 0 },
                                    count = catCount,
                                },
                            }
                        end
                    end

                    -- Outputs
                    local outputsOut = {}
                    if recipe.output then
                        for i = 1, #recipe.output do
                            local out = recipe.output[i]
                            local outRef = (out and out.itemRef) or NONE_GUID
                            local outId = (out and out.item and out.item.value) or 0
                            local outCount = (out and out.count) or 0
                            if outMult ~= 1.0 and outCount > 0 and outRef ~= NONE_GUID then
                                local itemRes = get_cached_resource(outRef, "keen::ItemInfo", 0)
                                local itemData = get_data(itemRes, "keen::ItemInfo")
                                local maxStack = itemData and itemData.maxStackSize
                                if itemData and is_safe_stackable_item(itemData) and maxStack and maxStack > 1 and maxStack <= 65535 then
                                    local newCount = m_floor(outCount * outMult + 0.5)
                                    if newCount < 1 then newCount = 1 end
                                    if newCount > maxStack then newCount = maxStack end
                                    if newCount ~= outCount then
                                        outCount = newCount
                                        changedReg = true
                                    end
                                end
                            end
                            outputsOut[i] = {
                                itemRef = outRef,
                                item = { value = outId },
                                count = outCount,
                            }
                        end
                    end

                    -- Required props & unrestricted overrides
                    local propsOut = {}
                    if makeFree then
                        if recipe.requiredProps and #recipe.requiredProps > 0 then
                            changedReg = true
                        end
                    elseif recipe.requiredProps then
                        for i = 1, #recipe.requiredProps do
                            local p = recipe.requiredProps[i]
                            propsOut[i] = { value = (p and p.value) or 0 }
                        end
                    end

                    local reqPropsMask = recipe.requiredPropsMask or 0
                    local reqHappyNpc = recipe.requiredHappyNpcCount or 0
                    local reqEnergy = recipe.requiredEnergy or 0
                    local waterAmt = recipe.waterAmount or 0
                    local waterChg = recipe.waterCharges or 0
                    local reqSheltered = (recipe.requiresSheltered == true)

                    if makeFree then
                        if reqPropsMask ~= 0 then reqPropsMask = 0; changedReg = true end
                        if reqHappyNpc > 0 then reqHappyNpc = 0; changedReg = true end
                        if reqEnergy ~= 0 then reqEnergy = 0; changedReg = true end
                        if waterAmt ~= 0 then waterAmt = 0; changedReg = true end
                        if waterChg ~= 0 then waterChg = 0; changedReg = true end
                        if reqSheltered then reqSheltered = false; changedReg = true end
                    end

                    recipesOut[rIdx] = {
                        recipeGuid = recipe.recipeGuid or NONE_GUID,
                        recipeId = { value = (recipe.recipeId and recipe.recipeId.value) or 0 },
                        workshopGuid = recipe.workshopGuid or NONE_GUID,
                        workshopId = { value = (recipe.workshopId and recipe.workshopId.value) or 0 },
                        input = inputsOut,
                        output = outputsOut,
                        craftingDuration = { value = (recipe.craftingDuration and recipe.craftingDuration.value) or 0 },
                        requiredProps = propsOut,
                        requiredPropsMask = reqPropsMask,
                        knowledgeRequirement = kqOut,
                        completionRequirementQuery = cqOut,
                        recipeName = recipe.recipeName or NONE_GUID,
                        debugName = dn,
                        level = recipe.level or 0,
                        comfortLevel = recipe.comfortLevel or 0,
                        serverProgressLevel = recipe.serverProgressLevel or 0,
                        requiredHappyNpcCount = reqHappyNpc,
                        requiredEnergy = reqEnergy,
                        waterAmount = waterAmt,
                        waterCharges = waterChg,
                        levelRequirement = recipe.levelRequirement or "None",
                        comfortLevelRequirement = recipe.comfortLevelRequirement or "None",
                        serverProgressLevelRequirement = recipe.serverProgressLevelRequirement or "None",
                        isCookingRecipe = recipe.isCookingRecipe == true,
                        isUpgrade = recipe.isUpgrade == true,
                        requiresSheltered = reqSheltered,
                        showIsImportantLabel = recipe.showIsImportantLabel == true,
                    }
                end

                if changedReg then
                    local catsOut = {}
                    if rdata.inputCategories then
                        for cIdx = 1, #rdata.inputCategories do
                            local c = rdata.inputCategories[cIdx]
                            local cItems = {}
                            if c.items then
                                for mIdx = 1, #c.items do
                                    local m = c.items[mIdx]
                                    cItems[mIdx] = {
                                        itemId = { value = (m and m.itemId and m.itemId.value) or 0 },
                                        scaling = (m and m.scaling) or 1.0,
                                    }
                                end
                            end
                            catsOut[cIdx] = {
                                inputCategoryId = { value = (c and c.inputCategoryId and c.inputCategoryId.value) or 0 },
                                items = cItems,
                            }
                        end
                    end
                    mark_dirty(reg, "keen::RecipeRegistryResource", {
                        inputCategories = catsOut,
                        recipes = recipesOut,
                    })
                    didWork = true
                end
            end
        end
    end

    if creativeMode or CraftingTweaks_FreeFood then
        local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")
        if templates then
            local NPC_BOOL_FIELDS = {
                "requiresSheltered", "requiresShelter", "requiresBed", "requiresShelteredBed",
                "needsShelter", "needsBed", "checkShelter", "checkBed", "shelterRequired", "bedRequired"
            }
            for _, t in ipairs(templates) do
                pcall(function()
                    local td = get_data(t, "keen::ecs::TemplateResource")
                    if not td or not td.components then return end
                    local name = tostring(td.name or "")
                    if s_find(name, "NPC_", 1, true) ~= 1 and not s_find(name, "Survivor", 1, true) and not s_find(name, "Craftsperson", 1, true) then
                        return
                    end
                    local patchedThisNpc = false
                    for _, c in ipairs(td.components) do
                        local cv = c and c.value
                        if cv and (type(cv) == "table" or type(cv) == "userdata") then
                            for _, fName in ipairs(NPC_BOOL_FIELDS) do
                                pcall(function()
                                    if cv[fName] == true then
                                        cv[fName] = false
                                        patchedThisNpc = true
                                    end
                                end)
                            end
                        end
                    end
                    if patchedThisNpc then
                        mark_dirty(t, "keen::ecs::TemplateResource", td)
                        npcShelterPatched = npcShelterPatched + 1
                        didWork = true
                    end
                end)
            end
        end
    end

    if infPropPlacement then
        local items = get_cached_resources_by_type("keen::ItemInfo")
        if items then
            for _, it in ipairs(items) do
                pcall(function()
                    local d = get_data(it, "keen::ItemInfo")
                    if not d or not d.equipment then return end
                    local eq = d.equipment
                    local placed = tostring(eq.placedEntity or NONE_GUID)
                    local voxObj = tostring(eq.voxelObject or NONE_GUID)
                    local terVox = tostring(eq.terrainVoxelObject or NONE_GUID)
                    local hasReqIng = eq.requiredCraftingIngredients and #eq.requiredCraftingIngredients > 0
                    if placed == NONE_GUID and voxObj == NONE_GUID and terVox == NONE_GUID and not hasReqIng then
                        return
                    end
                    local iDirty = false
                    if eq.placementConsume ~= false then
                        eq.placementConsume = false
                        iDirty = true
                    end
                    if hasReqIng then
                        for i = 1, #eq.requiredCraftingIngredients do
                            local req = eq.requiredCraftingIngredients[i]
                            if req and req.count and req.count > 0 then
                                local okSet = pcall(function() req.count = 0 end)
                                if not okSet then
                                    pcall(function()
                                        eq.requiredCraftingIngredients[i] = {
                                            itemRef = req.itemRef or NONE_GUID,
                                            item = { value = (req.item and req.item.value) or 0 },
                                            count = 0,
                                        }
                                    end)
                                end
                                iDirty = true
                            end
                        end
                    end
                    if iDirty then
                        mark_dirty(it, "keen::ItemInfo", d)
                        propItemsPatched = propItemsPatched + 1
                        didWork = true
                    end
                end)
            end
        end
    end

    log_line(("Crafting Tweaks: Unlock=%d | CreativeRecipes=%d | FreeFood=%d | FreeFactories=%d | FreeAltar=%d | NPCs=%d | InfiniteProps=%d | OutMult=%s"):format(
        unlockCount, creativeCount, freeFoodCount, freeFactoryCount, freeAltarCount, npcShelterPatched, propItemsPatched, tostring(outMult)
    ), 1)

    feature_end(didWork)
end

local function ApplySlotResetTweaks()
    feature_begin("Factory & Station Crusher", 1)

    if not Enable_SlotResetTool then
        log_line("Factory & Station Crusher: master toggle disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local Reset_Factory = S("Reset_Factory") == true
    local Reset_Production = S("Reset_Production") == true
    local Reset_Farmbed = S("Reset_Farmbed") == true
    local Reset_Beehive = S("Reset_Beehive") == true
    local Reset_Furniture = S("Reset_Furniture") == true

    local anyCategoryEnabled = Reset_Factory or Reset_Production or Reset_Farmbed or Reset_Beehive or Reset_Furniture
    if not anyCategoryEnabled then
        log_line("Factory & Station Crusher: all category toggles are disabled; skipping.", 1)
        feature_end(false)
        return
    end

    local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")
    if not templates or #templates == 0 then
        log_line("WARN: No keen::ecs::TemplateResource entries found; skipping.", 1)
        feature_end(false)
        return
    end

    local donorComps = {}
    local NEEDED_DONORS = {
        ["keen::ecs::Destructible"] = true,
        ["keen::ecs::DamageSusceptibility"] = true,
        ["keen::ecs::CombatFlags"] = true,
        ["keen::ecs::Health"] = true,
        ["keen::ecs::OnDestroy"] = true,
    }

    local function is_valid_donor_comp(cType, comp)
        if not comp or not comp.value then return false end
        if cType == "keen::ecs::Health" then
            local ok, nonZero = pcall(function()
                local ds = comp.value.dataStorage
                if ds then
                    for i = 1, #ds do
                        if type(ds[i]) == "number" and ds[i] ~= 0 then return true end
                    end
                end
                return false
            end)
            return ok and nonZero == true
        end
        return true
    end

    for _, t in ipairs(templates) do
        local td = get_data(t, "keen::ecs::TemplateResource")
        local tName = td and tostring(td.name or "") or ""
        if td and td.components and (s_find(tName, "Prop_Destructible_", 1, true) == 1 or s_find(tName, "BerryBush_Seedling", 1, true) ~= nil) then
            for _, c in ipairs(td.components) do
                local cType = c and tostring(c.type or "") or ""
                if NEEDED_DONORS[cType] and not donorComps[cType] and is_valid_donor_comp(cType, c) then
                    donorComps[cType] = c
                end
            end
        end
    end

    for cType in pairs(NEEDED_DONORS) do
        if not donorComps[cType] then
            for _, t in ipairs(templates) do
                local td = get_data(t, "keen::ecs::TemplateResource")
                if td and td.components then
                    local found = find_component_by_type(td.components, cType)
                    if found and is_valid_donor_comp(cType, found) then
                        donorComps[cType] = found
                        break
                    end
                end
            end
        end
    end

    local function copy_component_value_inplace(dstComp, srcComp, cType)
        if not dstComp then return false end
        local cv = dstComp.value
        local dv = srcComp and srcComp.value or nil
        if not cv then return false end

        local copiedAny = false
        if dv then
            pcall(function() dstComp.value = dv; copiedAny = true end)
        end

        if cType == "keen::ecs::Destructible" then
            pcall(function() cv.maxHealth = 1; copiedAny = true end)
        elseif cType == "keen::ecs::Health" then
            pcall(function()
                if dv and dv.rootId ~= nil and cv.rootId ~= nil and dv.rootId.value ~= nil then cv.rootId.value = dv.rootId.value end
                if dv and dv.storageOffset ~= nil and cv.storageOffset ~= nil then cv.storageOffset = dv.storageOffset end
                if dv and dv.storageCount ~= nil and cv.storageCount ~= nil then
                    cv.storageCount = (dv.storageCount > 0) and dv.storageCount or 1
                elseif cv.storageCount ~= nil and cv.storageCount == 0 then
                    cv.storageCount = 1
                end
                if cv.dataStorage then
                    local hasNonZeroDonor = false
                    if dv and dv.dataStorage then
                        for idx = 1, #dv.dataStorage do
                            if type(dv.dataStorage[idx]) == "number" and dv.dataStorage[idx] ~= 0 then hasNonZeroDonor = true; break end
                        end
                    end
                    if hasNonZeroDonor then
                        for idx = 1, #cv.dataStorage do pcall(function() cv.dataStorage[idx] = dv.dataStorage[idx] end) end
                    else
                        for idx = 1, #cv.dataStorage do pcall(function() cv.dataStorage[idx] = (idx == 1) and 1 or 0 end) end
                    end
                end
                copiedAny = true
            end)
        elseif cType == "keen::ecs::CombatFlags" then
            pcall(function()
                cv.immune = false
                cv.handleHits = true
                cv.ignoreMelee = false
                cv.ignoreTool = false
                cv.ignoreRanged = false
                cv.ignoreMagic = false
                cv.ignoreAoE = false
                cv.ignoreSkillShot = false
                cv.ignoreOther = false
                copiedAny = true
            end)
        elseif dv then
            pcall(function()
                for k, v in pairs(dv) do
                    if type(v) == "number" or type(v) == "boolean" or type(v) == "string" then
                        pcall(function() cv[k] = v; copiedAny = true end)
                    elseif (type(v) == "table" or type(v) == "userdata") and v.value ~= nil then
                        pcall(function() cv[k].value = v.value; copiedAny = true end)
                    end
                end
            end)
        end
        return copiedAny
    end

    local function has_inventory_component(comps)
        if not comps then return false end
        for i = 1, #comps do
            local cType = comps[i] and comps[i].type
            if cType == "keen::ecs::InventorySetup" or cType == "keen::ecs::Inventory" or cType == "keen::ecs::InventorySetupOverwrite"
                or cType == "keen::ecs::InventoryCraftingStock" or cType == "keen::ecs::FactoryStation" or cType == "keen::ecs::Crafting" then
                return true
            end
        end
        return false
    end

    local function get_reset_category(name, comps)
        if not name or name == "" then return nil end
        local low = s_lower(name)
        if s_find(low, "base_", 1, true) == 1 or s_find(low, "dummy_", 1, true) ~= nil or s_find(low, "broken", 1, true) ~= nil
            or s_find(low, "force_generator", 1, true) ~= nil or s_find(low, "loot", 1, true) ~= nil or s_find(low, "scatter_", 1, true) ~= nil
            or s_find(low, "enemy_", 1, true) ~= nil or s_find(low, "npc_", 1, true) ~= nil or s_find(low, "player", 1, true) ~= nil
            or s_find(low, "backpack", 1, true) ~= nil then
            return nil
        end
        if s_find(low, "prop_decoration_t", 1, true) ~= nil and s_find(low, "storage", 1, true) ~= nil then
            return nil
        end
        local isFurnitureName = (s_find(low, "furniture", 1, true) ~= nil or s_find(low, "prop_decoration_", 1, true) ~= nil)
        if not isFurnitureName and not has_inventory_component(comps) then return nil end
        if (s_find(low, "farmbed", 1, true) ~= nil or s_find(low, "seedling", 1, true) ~= nil) and s_find(low, "factory", 1, true) ~= nil then return "Farmbed" end
        if s_find(low, "beehive", 1, true) ~= nil or s_find(low, "honey_factory", 1, true) ~= nil then return "Beehive" end
        if s_find(low, "production", 1, true) ~= nil then return "Production" end
        if s_find(low, "factory", 1, true) ~= nil or s_find(low, "craftingstation_", 1, true) ~= nil then return "Factory" end
        if isFurnitureName then return "Furniture" end
        return nil
    end

    local function is_reset_cat_enabled(cat)
        if cat == "Factory" then return Reset_Factory == true end
        if cat == "Production" then return Reset_Production == true end
        if cat == "Farmbed" then return Reset_Farmbed == true end
        if cat == "Beehive" then return Reset_Beehive == true end
        if cat == "Furniture" then return Reset_Furniture == true end
        return false
    end

    local function clear_userdata_array(parentObj, fieldName)
        pcall(function() parentObj[fieldName] = {} end)
        local arr = parentObj[fieldName]
        if arr and (type(arr) == "userdata" or type(arr) == "table") then
            pcall(function()
                for i = #arr, 1, -1 do
                    pcall(function() t_remove(arr, i) end)
                    pcall(function() arr[i] = nil end)
                end
            end)
        end
    end

    local function insert_or_mutate_sorted(compList, donorComp, cType)
        if not donorComp or not donorComp.type then return false end
        local targetType = tostring(donorComp.type)
        for i = 1, #compList do
            local existingType = tostring(compList[i] and compList[i].type or "")
            if existingType == targetType then
                copy_component_value_inplace(compList[i], donorComp, cType)
                return true
            elseif existingType > targetType then
                t_insert(compList, i, donorComp)
                copy_component_value_inplace(compList[i], donorComp, cType)
                return true
            end
        end
        compList[#compList + 1] = donorComp
        copy_component_value_inplace(compList[#compList], donorComp, cType)
        return true
    end

    local scanned, matched, patched = 0, 0, 0
    local catCounts = { Factory = 0, Production = 0, Farmbed = 0, Beehive = 0, Furniture = 0 }

    for _, t in ipairs(templates) do
        scanned = scanned + 1
        if scanned % 1500 == 0 then flush_lua_refs() end
        pcall(function()
            local td = get_data(t, "keen::ecs::TemplateResource")
            if not td or not td.components then return end
            local name = tostring(td.name or "")
            local comps = td.components
            local cat = get_reset_category(name, comps)
            if not cat or not is_reset_cat_enabled(cat) then return end

            matched = matched + 1
            local didPatchThis = false
            local keptComps = {}
            local addedBreakableCount = 0

            for i = 1, #comps do
                local c = comps[i]
                local cType = c and tostring(c.type or "") or ""
                local cv = c and c.value
                if cv then
                    if cType == "keen::ecs::CollisionFeedbackMaterialComponent" then
                        pcall(function() if cv.propDamageSusceptibility ~= nil then cv.propDamageSusceptibility = "Wood"; didPatchThis = true end end)
                    elseif cType == "keen::ecs::InventorySetup" then
                        pcall(function() clear_userdata_array(cv, "inventoryFlags"); didPatchThis = true end)
                    elseif cType == "keen::ecs::DismantleOverride" then
                        pcall(function() if cv.preventDismantlingWithFilledInventory ~= nil then cv.preventDismantlingWithFilledInventory = false end; didPatchThis = true end)
                    elseif NEEDED_DONORS[cType] then
                        if copy_component_value_inplace(c, donorComps[cType], cType) then didPatchThis = true end
                    end
                end
                keptComps[#keptComps + 1] = c
            end

            for _, dType in ipairs({ "keen::ecs::CombatFlags", "keen::ecs::DamageSusceptibility", "keen::ecs::Destructible", "keen::ecs::OnDestroy" }) do
                if donorComps[dType] and insert_or_mutate_sorted(keptComps, donorComps[dType], dType) then
                    addedBreakableCount = addedBreakableCount + 1
                    didPatchThis = true
                end
            end

            if addedBreakableCount > 0 then
                pcall(function() td.components = keptComps end)
            end

            if didPatchThis then
                mark_dirty(t, "keen::ecs::TemplateResource", td)
                patched = patched + 1
                if catCounts[cat] ~= nil then catCounts[cat] = catCounts[cat] + 1 end
            end
        end)
    end

    log_line(s_format("Summary: Scanned=%d | Matched=%d | Patched=%d (Factory=%d, Production=%d, Farmbed=%d, Beehive=%d, Furniture=%d)",
        scanned, matched, patched, catCounts.Factory, catCounts.Production, catCounts.Farmbed, catCounts.Beehive, catCounts.Furniture), 1)

    feature_end(patched > 0)
end

local function ApplyMovementAndSlopeTweaks()
    feature_begin("Movement, Jump & Slope Tweaks", 1)

    local moveMult = MovementSpeedPct / 100.0
    local jumpMult = JumpHeightPct / 100.0

    if not Enable_SlopeTweaks and moveMult <= 1.0 and jumpMult <= 1.0 then
        log_line("Movement, Jump & Slope Tweaks: disabled/default in config; skipping.", 1)
        feature_end(false)
        return
    end

    local playerRes = get_cached_resource("c3db66d6-89a5-4a6c-a8e3-d9a1f6009812", "keen::ecs::TemplateResource", 0)
    local player = get_data(playerRes, "keen::ecs::TemplateResource")
    if not player or not player.components then
        log_line("ERROR: player TemplateResource not found", 1)
        feature_end(false)
        return
    end

    local patched = 0
    local maxAng = type(Max_Angle) == "number" and Max_Angle or 89.0
    local st = type(steepFloorAngle) == "number" and steepFloorAngle or nil
    local sl = type(slidingAngle) == "number" and slidingAngle or nil
    local fd = type(fallDamageAngle) == "number" and fallDamageAngle or nil

    for _, component in ipairs(player.components) do
        if component.type == "keen::ecs::Movement" and moveMult > 1.0 then
            local mv = component.value
            if mv and mv.dataStorage then
                local baseRun = (mv.dataStorage[5] and mv.dataStorage[5] > 0) and mv.dataStorage[5] or 5.0
                local baseSprint = (mv.dataStorage[6] and mv.dataStorage[6] > 0) and mv.dataStorage[6] or 8.0
                mv.dataStorage[5] = m_min(baseRun * moveMult, 100.0)
                mv.dataStorage[6] = m_min(baseSprint * moveMult, 160.0)
                patched = patched + 1
                log_line(s_format("  Movement speed x%.2f: run=%.1f sprint=%.1f", moveMult, mv.dataStorage[5], mv.dataStorage[6]), 1)
            end
        elseif component.type == "keen::ecs::JumpParameters" and jumpMult > 1.0 then
            local jp = component.value
            if jp then
                local baseH = (jp.jumpHeight and jp.jumpHeight > 0) and jp.jumpHeight or 4.0
                jp.jumpHeight = m_min(baseH * jumpMult, 40.0)
                patched = patched + 1
                log_line(s_format("  Jump height x%.2f: %.1f", jumpMult, jp.jumpHeight), 1)
            end
        elseif component.type == "keen::ecs::SlopeConfig" and Enable_SlopeTweaks and (st or sl or fd) then
            local sc = component.value
            local sd = sc and sc.slopeDefinition
            if sd then
                local finalSteep = st and m_min(st, maxAng) or sd.steepFloorAngle
                local finalSlide = sl and m_min(sl, maxAng) or sd.slidingAngle
                local finalFall = fd and m_min(fd, maxAng) or sd.fallDamageAngle
                local finalMatMin = sd.slidingMaterialMinAngle or 45.0
                local ok = pcall(function()
                    if st then sd.steepFloorAngle = finalSteep end
                    if sl then sd.slidingAngle = finalSlide end
                    if fd then sd.fallDamageAngle = finalFall end
                end)
                if not ok then
                    pcall(function()
                        sc.slopeDefinition = {
                            steepFloorAngle = finalSteep,
                            slidingAngle = finalSlide,
                            fallDamageAngle = finalFall,
                            slidingMaterialMinAngle = finalMatMin,
                        }
                    end)
                end
                patched = patched + 1
                log_line(s_format("  SlopeConfig: steepFloor=%.1f | sliding=%.1f | fallDamage=%.1f", finalSteep, finalSlide, finalFall), 1)
            end
        end
    end

    if patched > 0 then
        mark_dirty(playerRes, "keen::ecs::TemplateResource", player)
    end

    feature_end(patched > 0)
end

local UPDRAFT_GUID = "56f35356-aa4b-4cc1-b5c6-088ecce9aa45"
local UPDRAFT_TARGET_TYPE = "keen::actor::ActorSequenceResource"

local function ApplyUpdraftTweaks()
    feature_begin("Updraft Tweaks", 1)

    if not Enable_SkillTweaks_Updraft then
        log_line("Updraft Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local Updraft_IgnoreManaCost = S("Updraft_IgnoreManaCost") == true
    local GroundRelative_X = opt_num("GroundRelative_X")
    local GroundRelative_Y = opt_num("GroundRelative_Y")
    local GroundRelative_Z = opt_num("GroundRelative_Z")
    local PlayerRelative_X = opt_num("PlayerRelative_X")
    local PlayerRelative_Y = opt_num("PlayerRelative_Y")
    local PlayerRelative_Z = opt_num("PlayerRelative_Z")
    local Boost_Duration = opt_num("Boost_Duration")
    local Updraft_ManaCost_Value = opt_num("Updraft_ManaCost_Value")

    local function normalize_duration_ns(v)
        if type(v) ~= "number" then return nil end
        if v < 1000 then return m_floor(v * 1000000000 + 0.5) end
        return m_floor(v + 0.5)
    end

    local function patch_scalar_if(obj, field, new_val)
        if new_val == nil or not obj then return false end
        if obj[field] ~= new_val then
            obj[field] = new_val
            return true
        end
        return false
    end

    local function safe_get(obj, field)
        local ok, val = pcall(function() return obj[field] end)
        if ok then return val end
        return nil
    end

    local function safe_set(obj, field, value)
        local ok, err = pcall(function() obj[field] = value end)
        if ok then return true end
        return false, err
    end

    local function apply_ignore_mana_cost(val)
        if not val then return false end
        local mask = safe_get(val, "ignoreCostMask")
        local target = "Mana"
        if mask == nil then
            return safe_set(val, "ignoreCostMask", { target })
        end
        local found = false
        local idx = 1
        pcall(function()
            for _, v in ipairs(mask) do
                idx = idx + 1
                if tostring(v) == target then found = true end
            end
        end)
        if found then return false end
        if safe_set(mask, idx, target) then return true end
        return safe_set(val, "ignoreCostMask", { target })
    end

    local function apply_mana_cost_override(val, new_value)
        if not val or type(new_value) ~= "number" then return false end
        local impacts = safe_get(val, "impactValues")
        if not impacts then return false end
        local changed = false
        pcall(function()
            for _, entry in ipairs(impacts) do
                local entry_val = safe_get(entry, "value") or safe_get(entry, "$value")
                if entry_val then
                    local old = safe_get(entry_val, "value")
                    if type(old) == "number" and old ~= new_value then
                        if safe_set(entry_val, "value", new_value) then changed = true end
                    end
                end
            end
        end)
        return changed
    end

    local list = get_cached_resources_by_type(UPDRAFT_TARGET_TYPE)
    if not list or #list == 0 then
        log_line("WARN: No resources found for type: " .. UPDRAFT_TARGET_TYPE, 1)
        feature_end(false)
        return
    end

    for _, res in ipairs(list) do
        if tostring(res.guid) == UPDRAFT_GUID then
            local data = get_data(res, UPDRAFT_TARGET_TYPE)
            if not data or not data.subSequences then
                feature_end(false)
                return
            end

            local changed = 0
            for _, seq in ipairs(data.subSequences) do
                for _, event in ipairs(seq.events or {}) do
                    local val = event.value
                    if val then
                        if event.type == "keen::actor::ImpulseEvent" then
                            if val.uprightImpulse then
                                if type(GroundRelative_X) == "number" and patch_scalar_if(val.uprightImpulse, "x", GroundRelative_X) then changed = changed + 1 end
                                if type(GroundRelative_Y) == "number" and patch_scalar_if(val.uprightImpulse, "y", GroundRelative_Y) then changed = changed + 1 end
                                if type(GroundRelative_Z) == "number" and patch_scalar_if(val.uprightImpulse, "z", GroundRelative_Z) then changed = changed + 1 end
                            end
                            if val.orientedImpulse then
                                if type(PlayerRelative_X) == "number" and patch_scalar_if(val.orientedImpulse, "x", PlayerRelative_X) then changed = changed + 1 end
                                if type(PlayerRelative_Y) == "number" and patch_scalar_if(val.orientedImpulse, "y", PlayerRelative_Y) then changed = changed + 1 end
                                if type(PlayerRelative_Z) == "number" and patch_scalar_if(val.orientedImpulse, "z", PlayerRelative_Z) then changed = changed + 1 end
                            end
                            if val.duration and type(Boost_Duration) == "number" then
                                if patch_scalar_if(val.duration, "value", normalize_duration_ns(Boost_Duration)) then changed = changed + 1 end
                            end
                        elseif event.type == "keen::actor::PayUsageCost" then
                            if Updraft_IgnoreManaCost and apply_ignore_mana_cost(val) then changed = changed + 1 end
                            if type(Updraft_ManaCost_Value) == "number" and apply_mana_cost_override(val, Updraft_ManaCost_Value) then changed = changed + 1 end
                        end
                    end
                end
            end

            if changed > 0 then
                mark_dirty(res, UPDRAFT_TARGET_TYPE, data)
            end
            log_line("Updraft changes applied: " .. tostring(changed), 1)
            feature_end(changed > 0)
            return
        end
    end

    feature_end(false)
end

local function ApplyFastTravelTweaks()
    feature_begin("Map & Fog of War Tweaks", 1)

    local didWork = false

    if Enable_FastTravelTweaks then
        local toggles = {
            None = FastTravel_None,
            FlameRelated = FastTravel_FlameMarkers,
            Dungeons = FastTravel_DungeonMarkers,
            Locations = FastTravel_LocationMarkers,
        }
        local registry_res = get_first_resource_by_type("keen::MapMarkerRegistryResource")
        local registry = get_data(registry_res, "keen::MapMarkerRegistryResource")
        local markerList = registry and registry.mapMarkers and registry.mapMarkers.values
        if markerList then
            local changed, matched = 0, 0
            local ok = pcall(function()
                for _, marker in ipairs(markerList) do
                    local cat = marker.sortingCategory
                    local enabled = toggles[cat]
                    if enabled ~= nil then
                        matched = matched + 1
                        if enabled == true and marker.isFastTravelDestination ~= true then
                            marker.isFastTravelDestination = true
                            changed = changed + 1
                        end
                    end
                end
            end)
            if ok and changed > 0 then
                mark_dirty(registry_res, "keen::MapMarkerRegistryResource", registry)
                didWork = true
            end
            log_line(("Fast Travel markers matched=%d changed=%d"):format(matched, changed), 1)
        end
    end

    if Enable_FogOfWarTweaks then
        local range = FogOfWar_Range
        if type(range) == "number" and range > 0 then
            if type(FogOfWar_MaxRangeClamp) == "number" and range > FogOfWar_MaxRangeClamp then
                range = FogOfWar_MaxRangeClamp
            end
            local templates = get_cached_resources_by_type("keen::ecs::TemplateResource")
            local matched, changed = 0, 0
            if templates then
                pcall(function()
                    for _, res in ipairs(templates) do
                        local td = get_data(res, "keen::ecs::TemplateResource")
                        local comps = td and td.components
                        if comps then
                            local tDirty = false
                            for _, comp in ipairs(comps) do
                                if comp and comp.type == "keen::ecs::FogOfWarDiscovery" then
                                    matched = matched + 1
                                    local v = comp.value
                                    if v and v.discoveryRange ~= range then
                                        v.discoveryRange = range
                                        changed = changed + 1
                                        tDirty = true
                                    end
                                end
                            end
                            if tDirty then
                                mark_dirty(res, "keen::ecs::TemplateResource", td)
                            end
                        end
                    end
                end)
            end
            if changed > 0 then didWork = true end
            log_line(("Fog of War discoveryRange matched=%d changed=%d range=%s"):format(matched, changed, tostring(range)), 1)
        end
    end

    feature_end(didWork)
end

local function ApplyFlameAltarTweaks()
    feature_begin("Flame Altar Tweaks", 1)

    if not Enable_FlameAltarTweaks and not UnlimitedFlameAltars then
        log_line("Flame Altar Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local didWork = false
    local btRes = get_first_resource_by_type("keen::BalancingTable")
    local bt = get_data(btRes, "keen::BalancingTable")

    if UnlimitedFlameAltars then
        if bt and bt.altarsPerFlameLevel then
            for i = 1, #bt.altarsPerFlameLevel do
                bt.altarsPerFlameLevel[i] = 255
            end
            mark_dirty(btRes, "keen::BalancingTable", bt)
            didWork = true
        end
        local items = get_cached_resources_by_type("keen::ItemInfo")
        local itemPatched = 0
        if items then
            for _, it in ipairs(items) do
                local d = get_data(it, "keen::ItemInfo")
                if d and d.equipment then
                    local guidStr = tostring(it.guid or "")
                    local placed = tostring(d.equipment.placedEntity or "")
                    if guidStr == "85ad0843-7f32-4026-95d2-96c8e54e2899" or placed == "5bcf6d3e-6067-4e25-a0f9-dab49aed4ae3" then
                        if d.equipment.requiresAltarSlot ~= false then
                            d.equipment.requiresAltarSlot = false
                            mark_dirty(it, "keen::ItemInfo", d)
                            itemPatched = itemPatched + 1
                            didWork = true
                        end
                    end
                end
            end
        end
        log_line(("UnlimitedFlameAltars applied: altarsPerFlameLevel=255, altarItemsPatched=%d"):format(itemPatched), 1)
        feature_end(didWork)
        return
    end

    local mult = type(MaxFlameAltars_Multiplier) == "number" and MaxFlameAltars_Multiplier > 0 and m_floor(MaxFlameAltars_Multiplier + 0.5) or 1
    local cap = 16
    if mult <= 1 or not bt or not bt.altarsPerFlameLevel then
        feature_end(false)
        return
    end

    local changed = 0
    for i, oldCount in ipairs(bt.altarsPerFlameLevel) do
        pcall(function()
            if type(oldCount) == "number" then
                local newCount = m_min(cap, m_floor(oldCount * mult + 0.5))
                if newCount > oldCount then
                    bt.altarsPerFlameLevel[i] = newCount
                    changed = changed + 1
                end
            end
        end)
    end

    if changed > 0 then
        mark_dirty(btRes, "keen::BalancingTable", bt)
    end
    log_line(("altarsPerFlameLevel changed=%d multiplier=%s cap=%s"):format(changed, tostring(mult), tostring(cap)), 1)
    feature_end(changed > 0)
end

local function ApplyBaseSizeTweaks()
    feature_begin("Base Size Multipliers", 1)

    if not Enable_BaseSizeTweaks then
        log_line("Base Size Multipliers: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local mult = BaseSize_Multiplier
    if type(mult) ~= "number" or mult <= 0 then
        feature_end(false)
        return
    end

    if type(BaseSize_MaxMultiplierClamp) == "number" and BaseSize_MaxMultiplierClamp > 0 and mult > BaseSize_MaxMultiplierClamp then
        mult = BaseSize_MaxMultiplierClamp
    end

    local btRes = get_first_resource_by_type("keen::BalancingTable")
    local bt = get_data(btRes, "keen::BalancingTable")
    local sizes = bt and bt.buildzoneSizesPerAltarLevel
    if not sizes then
        feature_end(false)
        return
    end

    local function snap_chunk_20(n)
        return m_max(20, m_floor((n / 20) + 0.5) * 20)
    end

    local changed = 0
    for idx, v in ipairs(sizes) do
        pcall(function()
            local x, y, z = v.x, v.y, v.z
            if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or x <= 0 then return end
            local newX = snap_chunk_20(x * mult)
            local newY = snap_chunk_20(y * mult)
            local newZ = snap_chunk_20(z * mult)
            if m_abs(newX - x) > 0.01 or m_abs(newY - y) > 0.01 or m_abs(newZ - z) > 0.01 then
                local ok = pcall(function()
                    v.x = newX
                    v.y = newY
                    v.z = newZ
                end)
                if not ok then
                    pcall(function() sizes[idx] = { x = newX, y = newY, z = newZ } end)
                end
                changed = changed + 1
            end
        end)
    end

    if changed > 0 then
        mark_dirty(btRes, "keen::BalancingTable", bt)
    end
    log_line(("buildzoneSizesPerAltarLevel changed=%d multiplier=%s (snapped to 20m voxel chunks)"):format(changed, tostring(mult)), 1)
    feature_end(changed > 0)
end

local function BuildingTweaks()
    feature_begin("Building & Placement Tweaks", 1)

    local didWork = false

    if Enable_BuildingTweaks then
        local scenes = get_cached_resources_by_type("keen::SceneResource")
        if scenes and #scenes > 0 then
            local TARGET_IBL = "9743d1a0-007d-4a8a-9088-82d34ce7a697"
            local sceneChanged = 0
            for _, s in ipairs(scenes) do
                local d = get_data(s, "keen::SceneResource")
                if d and tostring(d.ibl) == TARGET_IBL and d.noBuildZones ~= nil then
                    d.noBuildZones = {}
                    mark_dirty(s, "keen::SceneResource", d)
                    sceneChanged = sceneChanged + 1
                end
            end
            log_line("SceneResource noBuildZones cleared: " .. tostring(sceneChanged), 1)
            if sceneChanged > 0 then didWork = true end
        end
    end

    if Enable_PlacementTweaks then
        local buildInFog      = (S("PlacementTweaks_BuildInFog") == true)
        local noZoneNeed      = (S("PlacementTweaks_NoBuildZoneNeeded") == true)
        local ignoreEnemies   = (S("PlacementTweaks_IgnoreEnemies") == true)
        local ignoreFreeSpace = (S("PlacementTweaks_IgnoreFreeSpace") == true)
        local unlockTilt      = ignoreFreeSpace and (S("PlacementTweaks_UnlockTiltAngles") == true)
        local PlacementTweaks_SafetySkip = "Material"

        if buildInFog or noZoneNeed or ignoreEnemies or ignoreFreeSpace then
            local items = get_cached_resources_by_type("keen::ItemInfo")
            if items and #items > 0 then
                local skipNeedle = tostring(PlacementTweaks_SafetySkip or "")
                local changedAllowBelowFog, changedInhibitBuild, changedBuildZoneReq, changedPermissions = 0, 0, 0, 0
                local changedIgnoreEnemies, changedFreeSpace, changedTiltAngles = 0, 0, 0

                local function clear_ud_array(parentObj, fieldName)
                    if not parentObj then return end
                    pcall(function() parentObj[fieldName] = {} end)
                    local arr = parentObj[fieldName]
                    if arr and (type(arr) == "userdata" or type(arr) == "table") then
                        pcall(function()
                            for i = #arr, 1, -1 do
                                pcall(function() t_remove(arr, i) end)
                                pcall(function() arr[i] = nil end)
                            end
                        end)
                    end
                end

                local function zero_vec3(parentObj, fieldName)
                    local vec = parentObj and parentObj[fieldName]
                    if not vec then return false end
                    if (type(vec.x) == "number" and vec.x ~= 0) or (type(vec.y) == "number" and vec.y ~= 0) or (type(vec.z) == "number" and vec.z ~= 0) then
                        local ok = pcall(function() vec.x = 0; vec.y = 0; vec.z = 0 end)
                        if not ok then pcall(function() parentObj[fieldName] = { x = 0, y = 0, z = 0 } end) end
                        return true
                    end
                    return false
                end

                for idx, it in ipairs(items) do
                    if idx % 1500 == 0 then flush_lua_refs() end
                    pcall(function()
                        local d = get_data(it, "keen::ItemInfo")
                        if not d then return end
                        local dbg = tostring(d.debugName or "")
                        if skipNeedle ~= "" and s_find(dbg, skipNeedle, 1, true) ~= nil then return end
                        local eq = d.equipment
                        if not eq then return end

                        local changedAny = false
                        local cc = eq.cursorConfig

                        if buildInFog then
                            if eq.allowPlacementBelowFog ~= true then
                                eq.allowPlacementBelowFog = true
                                changedAllowBelowFog = changedAllowBelowFog + 1
                                changedAny = true
                            end
                            local current = tostring(eq.checkInhibitBuild)
                            if current == "Strict" or current == "Lenient" then
                                eq.checkInhibitBuild = "None"
                                changedInhibitBuild = changedInhibitBuild + 1
                                changedAny = true
                            end
                        end

                        if noZoneNeed then
                            if eq.buildZoneRequired ~= false then
                                eq.buildZoneRequired = false
                                changedBuildZoneReq = changedBuildZoneReq + 1
                                changedAny = true
                            end
                            if d.permissionSetup and d.permissionSetup.isSet ~= false then
                                local okP = pcall(function() d.permissionSetup.isSet = false end)
                                if not okP then pcall(function() d.permissionSetup = { isSet = false } end) end
                                changedPermissions = changedPermissions + 1
                                changedAny = true
                            end
                        end

                        if ignoreEnemies and cc then
                            pcall(function()
                                if cc.checkBuildZoneEnemies == true then
                                    cc.checkBuildZoneEnemies = false
                                    changedIgnoreEnemies = changedIgnoreEnemies + 1
                                    changedAny = true
                                end
                            end)
                        end

                        if ignoreFreeSpace then
                            local spaceTouched = false
                            local currentInhibit = tostring(eq.checkInhibitBuild)
                            if currentInhibit == "Strict" or currentInhibit == "Lenient" then
                                eq.checkInhibitBuild = "None"
                                spaceTouched = true
                            end
                            if zero_vec3(eq, "placementAABBmin") then spaceTouched = true end
                            if zero_vec3(eq, "placementAABBmax") then spaceTouched = true end
                            if eq.placementNoBuildZones and eq.placementNoBuildZones.shapes then
                                clear_ud_array(eq.placementNoBuildZones, "shapes")
                                spaceTouched = true
                            end
                            if eq.placementColliders then
                                clear_ud_array(eq, "placementColliders")
                                spaceTouched = true
                            end
                            if tostring(eq.placementWaterEntityType) == "BlockWater" then
                                pcall(function() eq.placementWaterEntityType = "None" end)
                                spaceTouched = true
                            end
                            if eq.waterUsability then
                                pcall(function()
                                    if eq.waterUsability.outsideBuildzone then
                                        eq.waterUsability.outsideBuildzone.allowOutsideWater = true
                                        eq.waterUsability.outsideBuildzone.allowInsideWater = true
                                    end
                                    if eq.waterUsability.insideBuildzone then
                                        eq.waterUsability.insideBuildzone.allowOutsideWater = true
                                        eq.waterUsability.insideBuildzone.allowInsideWater = true
                                    end
                                end)
                                spaceTouched = true
                            end
                            if cc then
                                pcall(function()
                                    if cc.checkSurfaceTopology == true then cc.checkSurfaceTopology = false; spaceTouched = true end
                                    if cc.allowWaterPlacement == false then cc.allowWaterPlacement = true; spaceTouched = true end
                                    if cc.collisionCheckFlags then clear_ud_array(cc, "collisionCheckFlags") end
                                end)
                            end
                            if spaceTouched then
                                changedFreeSpace = changedFreeSpace + 1
                                changedAny = true
                            end

                            if unlockTilt then
                                local tiltTouched = false
                                if eq.maxTiltAngle and type(eq.maxTiltAngle) == "number" and eq.maxTiltAngle < 180.0 then
                                    eq.maxTiltAngle = 180.0
                                    tiltTouched = true
                                end
                                if cc then
                                    pcall(function()
                                        if cc.attachAngleConfig then
                                            if cc.attachAngleConfig.forceUprightNormal == true then
                                                cc.attachAngleConfig.forceUprightNormal = false
                                                tiltTouched = true
                                            end
                                            pcall(function() cc.attachAngleConfig.floorAngle = "Wide"; tiltTouched = true end)
                                            pcall(function() cc.attachAngleConfig.wallAngle = "Wide"; tiltTouched = true end)
                                            pcall(function() cc.attachAngleConfig.ceilingAngle = "Wide"; tiltTouched = true end)
                                        end
                                        for _, axisKey in ipairs({"axisRotationX", "axisRotationY", "axisRotationZ"}) do
                                            local ax = cc[axisKey]
                                            if ax then
                                                pcall(function()
                                                    if tostring(ax.automatic) == "Disabled" or tostring(ax.automatic) == "WorldGrid" then ax.automatic = "Free"; tiltTouched = true end
                                                    if tostring(ax.manual) == "Disabled" or tostring(ax.manual) == "WorldGrid" then ax.manual = "Free"; tiltTouched = true end
                                                end)
                                            end
                                        end
                                    end)
                                end
                                if tiltTouched then
                                    changedTiltAngles = changedTiltAngles + 1
                                    changedAny = true
                                end
                            end
                        end

                        if changedAny then
                            mark_dirty(it, "keen::ItemInfo", d)
                            didWork = true
                        end
                    end)
                end

                log_line(("Placement Patches: Fog=%d | Inhibit=%d | NoZone=%d | Perms=%d | IgnoreEnemies=%d | IgnoreFreeSpace=%d | UnlockTilt=%d"):format(
                    changedAllowBelowFog, changedInhibitBuild, changedBuildZoneReq, changedPermissions, changedIgnoreEnemies, changedFreeSpace, changedTiltAngles
                ), 1)
            end
        end
    end

    feature_end(didWork)
end

local function ApplyFogTweaks()
    feature_begin("Fog & Weather Tweaks", 1)

    if not Enable_FogTweaks then
        log_line("Fog & Weather Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local Fog_WorldHaze_Multiplier = tonumber(S("Fog_WorldHaze_Multiplier"))
    local Fog_WeatherHaze_Multiplier = tonumber(S("Fog_WeatherHaze_Multiplier"))
    local Fog_BlueShroud_Multiplier = tonumber(S("Fog_BlueShroud_Multiplier"))
    local Fog_RedShroud_Multiplier = tonumber(S("Fog_RedShroud_Multiplier"))
    local Fog_Density_MaxClamp = 100.0
    local Fog_Opacity_MaxClamp = 100.0
    local Fog_Emissive_MaxClamp = 100.0

    local res = get_first_resource_by_type("keen::VolumetricFog3Resource")
    local data = get_data(res, "keen::VolumetricFog3Resource")
    local mats = data and data.materials
    if not mats then
        feature_end(false)
        return
    end

    local function clamp_num(val, lo, hi, defaultVal)
        if type(val) ~= "number" then return defaultVal end
        if val < lo then return lo end
        if val > hi then return hi end
        return val
    end

    local worldMult      = clamp_num(Fog_WorldHaze_Multiplier, 0.0, 10.0, 1.0)
    local weatherMult    = clamp_num(Fog_WeatherHaze_Multiplier, 0.0, 10.0, 1.0)
    local blueShroudMult = clamp_num(Fog_BlueShroud_Multiplier, 0.0, 10.0, 1.0)
    local redShroudMult  = clamp_num(Fog_RedShroud_Multiplier, 0.0, 10.0, 1.0)

    local changed_count = 0
    local function scale_prop(target_tbl, field_name, mult, maxCap)
        if not target_tbl or mult == 1.0 then return end
        local before = target_tbl[field_name]
        if type(before) ~= "number" then return end
        local after = before * mult
        if maxCap and after > maxCap then after = m_max(maxCap, before) end
        if after < 0 then after = 0 end
        if m_abs(after - before) > 1e-6 then
            target_tbl[field_name] = after
            changed_count = changed_count + 1
        end
    end

    pcall(function()
        if mats[1] then
            scale_prop(mats[1], "densityScale", worldMult, Fog_Density_MaxClamp)
            scale_prop(mats[1], "extinction",   worldMult, Fog_Opacity_MaxClamp)
        end
        if data.heightFogMaterial then
            scale_prop(data.heightFogMaterial, "densityScale", worldMult, Fog_Density_MaxClamp)
            scale_prop(data.heightFogMaterial, "extinction",   worldMult, Fog_Opacity_MaxClamp)
        end
        scale_prop(data, "rainExtinction",     weatherMult, Fog_Opacity_MaxClamp)
        scale_prop(data, "snowExtinction",     weatherMult, Fog_Opacity_MaxClamp)
        scale_prop(data, "blizzardExtinction", weatherMult, Fog_Opacity_MaxClamp)

        if mats[2] then
            scale_prop(mats[2], "densityScale", blueShroudMult, Fog_Density_MaxClamp)
            scale_prop(mats[2], "extinction",   blueShroudMult, 1.0)
        end
        if data.dangerousBarrierFogMaterial then
            scale_prop(data.dangerousBarrierFogMaterial, "emissiveExposuredIntensity", blueShroudMult, Fog_Emissive_MaxClamp)
            scale_prop(data.dangerousBarrierFogMaterial, "emissiveIntensity",          blueShroudMult, Fog_Emissive_MaxClamp)
            scale_prop(data.dangerousBarrierFogMaterial, "extinction",                 blueShroudMult, Fog_Opacity_MaxClamp)
        end

        if mats[3] then
            scale_prop(mats[3], "densityScale", redShroudMult, Fog_Density_MaxClamp)
            scale_prop(mats[3], "extinction",   redShroudMult, 1.0)
        end
        if data.deadlyBarrierFogMaterial then
            scale_prop(data.deadlyBarrierFogMaterial, "emissiveExposuredIntensity", redShroudMult, Fog_Emissive_MaxClamp)
            scale_prop(data.deadlyBarrierFogMaterial, "emissiveIntensity",          redShroudMult, Fog_Emissive_MaxClamp)
            scale_prop(data.deadlyBarrierFogMaterial, "extinction",                 redShroudMult, Fog_Opacity_MaxClamp)
        end

        local barrierMult = (blueShroudMult ~= 1.0) and blueShroudMult or redShroudMult
        scale_prop(data, "barrierFogThickness", barrierMult, Fog_Density_MaxClamp)
    end)

    if changed_count > 0 then
        mark_dirty(res, "keen::VolumetricFog3Resource", data)
    end

    log_line(s_format("Fog Tweaks: changed %d fields.", changed_count), 1)
    feature_end(changed_count > 0)
end

local function ApplyGliderTuning()
    feature_begin("Glider Stats", 1)

    if not Enable_GliderTuning then
        log_line("Glider Tuning: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local function G(tier, prop)
        return tonumber(S("Glider_" .. tier .. "_" .. prop))
    end
    local GliderConfig = {}
    for _, tName in ipairs({"T1", "T2", "T3", "T4_REWARD"}) do
        GliderConfig[tName] = {
            accelerationForward = G(tName, "accelerationForward"),
            airResistanceLongitudinal = G(tName, "airResistanceLongitudinal"),
            airResistanceLateral = G(tName, "airResistanceLateral"),
            airResistanceVertical = G(tName, "airResistanceVertical"),
            yawAngleSpeed = G(tName, "yawAngleSpeed"),
            pitchAngleSpeed = G(tName, "pitchAngleSpeed"),
            rollAngleSpeed = G(tName, "rollAngleSpeed"),
        }
    end

    local GLIDER_GUIDS = {
        ["33834394-99c5-47b2-93b2-36aa6a2eaa73"] = "T1",
        ["1da8d177-3a28-43b1-b430-44b38022d925"] = "T2",
        ["f5520401-f5aa-41cd-99e1-609b884cc492"] = "T3",
        ["80c9eaeb-7fa0-480d-a55f-91c2c51b383e"] = "T4_REWARD",
    }
    local GLIDER_NAMES = {
        ["Tool_Glider_T1"]        = "T1",
        ["Tool_Glider_T2"]        = "T2",
        ["Tool_Glider_T3"]        = "T3",
        ["Tool_Glider_T4_REWARD"] = "T4_REWARD",
    }
    local GLIDER_FIELDS = {
        "accelerationForward", "airResistanceLongitudinal", "airResistanceLateral",
        "airResistanceVertical", "yawAngleSpeed", "pitchAngleSpeed", "rollAngleSpeed",
    }

    local items = get_cached_resources_by_type("keen::ItemInfo")
    if not items then
        feature_end(false)
        return
    end

    local glidersModified = 0
    for _, res in ipairs(items) do
        pcall(function()
            local d = get_data(res, "keen::ItemInfo")
            local eq = d and d.equipment
            if not eq or tostring(eq.slot) ~= "Glider" then return end

            local guid = tostring(res.guid or "unknown")
            local debugName = tostring(d.debugName or "unknown")
            local tier = GLIDER_GUIDS[guid] or GLIDER_NAMES[debugName]
            local tierConfig = tier and GliderConfig[tier]
            local gc = eq.gliderConfig
            if not tierConfig or not gc then return end

            local changedAny = false
            for _, field in ipairs(GLIDER_FIELDS) do
                local override = tierConfig[field]
                if override ~= nil and gc[field] ~= override then
                    gc[field] = override
                    changedAny = true
                end
            end
            if changedAny then
                mark_dirty(res, "keen::ItemInfo", d)
                glidersModified = glidersModified + 1
            end
        end)
    end

    log_line("Gliders modified=" .. tostring(glidersModified), 1)
    feature_end(glidersModified > 0)
end

local function ApplyTerraformingTweaks()
    feature_begin("Terraforming & Rake Tweaks", 1)

    if not Enable_TerraformingTweaks and not RakeAnywhere then
        log_line("Terraforming & Rake Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local didWork = false

    if Enable_TerraformingTweaks then
        local reg = get_first_resource_by_type("keen::TerraformingEfficiencyRegistryResource")
        local data = get_data(reg, "keen::TerraformingEfficiencyRegistryResource")
        local cfgs = data and data.terrainConfigs
        if cfgs then
            local changed = 0
            for _, c in ipairs(cfgs) do
                if c.hardness == "Unbreakable" then
                    c.hardness = "Hard"
                    changed = changed + 1
                end
            end
            if changed > 0 then
                mark_dirty(reg, "keen::TerraformingEfficiencyRegistryResource", data)
                didWork = true
            end
            log_line("Unbreakable->Hard=" .. tostring(changed), 1)
        end
    end

    if RakeAnywhere then
        local items = get_cached_resources_by_type("keen::ItemInfo")
        local rakePatched = 0
        if items then
            for _, it in ipairs(items) do
                local d = get_data(it, "keen::ItemInfo")
                if d and d.category == "BuildTools" and s_find(tostring(d.debugName or ""), "Rake", 1, true) and d.equipment then
                    d.equipment.buildZoneRequired = false
                    d.equipment.allowPlacementBelowFog = true
                    d.equipment.checkInhibitBuild = "None"
                    mark_dirty(it, "keen::ItemInfo", d)
                    rakePatched = rakePatched + 1
                    didWork = true
                end
            end
        end
        log_line("RakeAnywhere patched=" .. tostring(rakePatched), 1)
    end

    feature_end(didWork)
end

local function ApplyTerrainDropTweaks()
    feature_begin("Terrain Loot Tweaks", 1)

    if not Enable_TerrainDropTweaks then
        log_line("Terrain Loot Tweaks: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local reg = get_first_resource_by_type("keen::TerraformingEfficiencyRegistryResource")
    local data = get_data(reg, "keen::TerraformingEfficiencyRegistryResource")
    if not data then
        feature_end(false)
        return
    end

    local rate = TerrainDrop_ExchangeRate
    if type(rate) ~= "number" or rate < 0 then
        feature_end(false)
        return
    end
    local maxRateClamp = type(TerrainDrop_MaxExchangeRateClamp) == "number" and TerrainDrop_MaxExchangeRateClamp or 1.0
    if rate > maxRateClamp then rate = maxRateClamp end

    local changedRate = 0
    pcall(function()
        for _, v in pairs(data) do
            if type(v) == "table" or type(v) == "userdata" then
                for _, e in pairs(v) do
                    if type(e) == "table" or type(e) == "userdata" then
                        if e.terrainPerLootItemExchangeRate ~= nil and e.terrainPerLootItemExchangeRate ~= rate then
                            e.terrainPerLootItemExchangeRate = rate
                            changedRate = changedRate + 1
                        end
                    end
                end
            end
        end
    end)

    if changedRate > 0 then
        mark_dirty(reg, "keen::TerraformingEfficiencyRegistryResource", data)
    end
    log_line(("Patched terrainPerLootItemExchangeRate on %d entries (rate=%s)"):format(changedRate, tostring(rate)), 1)
    feature_end(changedRate > 0)
end

local function ApplyExpandedGameSettings()
    feature_begin("Expanded Game Settings", 1)

    if not Enable_ExpandedGameSettings then
        log_line("Expanded Game Settings: disabled in config; skipping.", 1)
        feature_end(false)
        return
    end

    local egsStd = parse_array(S("EGS_Standard"), {1.0})
    local egsXp = parse_array(S("EGS_XP"), {1.0})
    local egsTime = parse_array(S("EGS_Time"), {10.0})
    local ExpandedGameSettings_Config = {
        { Name = "playerHealth", Values = egsStd, Enabled = true },
        { Name = "playerMana", Values = egsStd, Enabled = true },
        { Name = "playerStamina", Values = egsStd, Enabled = true },
        { Name = "bodyHeat", Values = egsStd, Enabled = true },
        { Name = "foodDuration", Values = egsStd, Enabled = true },
        { Name = "starvingTime", Values = egsTime, Enabled = true },
        { Name = "playerDivingTime", Values = egsStd, Enabled = true },
        { Name = "shroudTime", Values = egsStd, Enabled = true },
        { Name = "miningDamage", Values = egsStd, Enabled = true },
        { Name = "plantGrowTime", Values = egsStd, Enabled = true },
        { Name = "dropAmount", Values = egsStd, Enabled = true },
        { Name = "productionTime", Values = egsStd, Enabled = true },
        { Name = "weaponUpgradeCost", Values = egsStd, Enabled = true },
        { Name = "durability", Values = egsStd, Enabled = true },
        { Name = "enemyDamage", Values = egsStd, Enabled = true },
        { Name = "enemyHealth", Values = egsStd, Enabled = true },
        { Name = "enemyStamina", Values = egsStd, Enabled = true },
        { Name = "enemyPerceptionRange", Values = egsStd, Enabled = true },
        { Name = "enemyAttackFrequency", Values = egsStd, Enabled = true },
        { Name = "bossDamage", Values = egsStd, Enabled = true },
        { Name = "bossHealth", Values = egsStd, Enabled = true },
        { Name = "dayTime", Values = egsTime, Enabled = true },
        { Name = "nightTime", Values = egsTime, Enabled = true },
        { Name = "combatXp", Values = egsXp, Enabled = true },
        { Name = "miningXp", Values = egsXp, Enabled = true },
        { Name = "questXp", Values = egsXp, Enabled = true },
        { Name = "perkUpgradeRecyclingFactor", Values = egsStd, Enabled = true },
    }

    local presets_res = get_first_resource_by_type("keen::GameSettingsPresetsResource")
    local ui_res = get_first_resource_by_type("keen::FbUiBundle")
    local presets = get_data(presets_res, "keen::GameSettingsPresetsResource")
    local ui = get_data(ui_res, "keen::FbUiBundle")

    if not presets then
        feature_end(false)
        return
    end

    local VALID_GAME_SETTINGS = {
        playerHealthFactor = true, playerManaFactor = true, playerStaminaFactor = true,
        playerBodyHeatFactor = true, playerDivingTimeFactor = true, foodBuffDurationFactor = true,
        fromHungerToStarving = true, shroudTimeFactor = true,
        miningDamageFactor = true, plantGrowthSpeedFactor = true,
        resourceDropStackAmountFactor = true, factoryProductionSpeedFactor = true,
        perkUpgradeRecyclingFactor = true, perkCostFactor = true, experienceCombatFactor = true,
        experienceMiningFactor = true, experienceExplorationQuestsFactor = true,
        enemyDamageFactor = true, enemyHealthFactor = true, enemyStaminaFactor = true,
        enemyPerceptionRangeFactor = true,
        bossDamageFactor = true, bossHealthFactor = true, threatBonus = true,
        tamingStartleRepercussion = true, dayTimeDuration = true, nightTimeDuration = true,
    }

    local ConfigToPresetMap = {
        ["bodyHeat"] = "playerBodyHeatFactor",
        ["foodDuration"] = "foodBuffDurationFactor", ["starvingTime"] = "fromHungerToStarving",
        ["playerDivingTime"] = "playerDivingTimeFactor", ["shroudTime"] = "shroudTimeFactor",
        ["miningDamage"] = "miningDamageFactor", ["plantGrowTime"] = "plantGrowthSpeedFactor",
        ["dropAmount"] = "resourceDropStackAmountFactor", ["productionTime"] = "factoryProductionSpeedFactor",
        ["weaponUpgradeCost"] = "perkCostFactor", ["perkUpgradeRecyclingFactor"] = "perkUpgradeRecyclingFactor",
        ["combatXp"] = "experienceCombatFactor", ["miningXp"] = "experienceMiningFactor",
        ["questXp"] = "experienceExplorationQuestsFactor", ["enemyDamage"] = "enemyDamageFactor",
        ["enemyHealth"] = "enemyHealthFactor", ["enemyStamina"] = "enemyStaminaFactor",
        ["enemyPerceptionRange"] = "enemyPerceptionRangeFactor",
        ["bossDamage"] = "bossDamageFactor", ["bossHealth"] = "bossHealthFactor",
        ["dayTime"] = "dayTimeDuration", ["nightTime"] = "nightTimeDuration",
    }

    local UI_ONLY_SETTINGS = {
        ["durability"] = true,
        ["enemyAttackFrequency"] = true,
    }

    local function SafeSetPreset(key, minVal, maxVal)
        if not VALID_GAME_SETTINGS[key] then return false end
        local ok = pcall(function()
            if presets.minValues and presets.minValues[key] ~= nil then
                local field = presets.minValues[key]
                if type(field) == "userdata" or type(field) == "table" then
                    local okW = pcall(function() field.value = minVal end)
                    if not okW then presets.minValues[key] = { value = minVal } end
                else
                    presets.minValues[key] = minVal
                end
            end
            if presets.maxValues and presets.maxValues[key] ~= nil then
                local fieldMax = presets.maxValues[key]
                if type(fieldMax) == "userdata" or type(fieldMax) == "table" then
                    local okW = pcall(function() fieldMax.value = maxVal end)
                    if not okW then presets.maxValues[key] = { value = maxVal } end
                else
                    presets.maxValues[key] = maxVal
                end
            end
        end)
        return ok
    end

    local uiUpdatedCount, backendUpdatedCount = 0, 0

    local function SetCustomRange(settingName, values)
        if not values or #values == 0 then return end
        if ui and ui.difficultySettings and ui.difficultySettings.settingValues and ui.difficultySettings.settingValues[settingName] then
            ui.difficultySettings.settingValues[settingName].steps = values
            uiUpdatedCount = uiUpdatedCount + 1
        end
        if UI_ONLY_SETTINGS[settingName] then return end

        local minVal, maxVal = values[1], values[1]
        for _, v in ipairs(values) do
            if v < minVal then minVal = v end
            if v > maxVal then maxVal = v end
        end

        local backendMin, backendMax = minVal, maxVal
        if settingName == "dayTime" or settingName == "nightTime" or settingName == "starvingTime" then
            local SEC = 1e9
            backendMin = backendMin * 60 * SEC
            backendMax = backendMax * 60 * SEC
        end

        local backendKeys = {}
        if ConfigToPresetMap[settingName] then t_insert(backendKeys, ConfigToPresetMap[settingName]) end
        t_insert(backendKeys, settingName .. "Factor")
        t_insert(backendKeys, settingName)

        for _, key in ipairs(backendKeys) do
            if SafeSetPreset(key, backendMin, backendMax) then
                backendUpdatedCount = backendUpdatedCount + 1
                break
            end
        end
    end

    local ok = pcall(function()
        for _, cfg in ipairs(ExpandedGameSettings_Config) do
            if cfg.Enabled ~= false and type(cfg.Values) == "table" then
                SetCustomRange(cfg.Name, cfg.Values)
            end
        end
    end)

    if ok then
        if backendUpdatedCount > 0 then mark_dirty(presets_res, "keen::GameSettingsPresetsResource", presets) end
        if uiUpdatedCount > 0 and ui_res then mark_dirty(ui_res, "keen::FbUiBundle", ui) end
    end

    log_line(s_format("Expanded Game Settings applied: uiSliders=%d backendPresets=%d", uiUpdatedCount, backendUpdatedCount), 1)
    feature_end(ok and (uiUpdatedCount + backendUpdatedCount) > 0)
end

-- ============================================================================
-- EXECUTION & COMMIT
-- ============================================================================

local function ExecuteAllTweaks()
    _out("[SF-CheatAssets] Initializing SF Cheat Menu Assets & Unified Tweaks Suite...")

    ApplyNoIntroVideo()
    ApplyPlayerAttributes()
    ApplyPlayerBaseStats()
    ApplyPlayerItemLevelTweaks()
    ApplyEquipmentMultipliers()
    ApplyItemLevelMinimums()
    ApplySpellTweaks()
    ApplyGearStatTweaks()
    ApplyInventoryTweaks()
    ApplyStackSizeTweaks()
    ApplyExtendedMagicStorage()
    ApplyLootTweaks()
    ApplyGemTweaks()
    ApplyCraftingTweaks()
    ApplySlotResetTweaks()
    ApplyGliderTuning()
    ApplyMovementAndSlopeTweaks()
    ApplyFastTravelTweaks()
    ApplyFogTweaks()
    ApplyUpdraftTweaks()
    ApplyFlameAltarTweaks()
    ApplyBaseSizeTweaks()
    BuildingTweaks()
    ApplyTerraformingTweaks()
    ApplyTerrainDropTweaks()
    ApplyExpandedGameSettings()

    local committed = commit_dirty_resources()
    _RESOURCE_CACHE = {}
    _SINGLE_RESOURCE_CACHE = {}
    _DIRTY_MAP = {}
    _DIRTY_LIST = {}
    flush_lua_refs()

    _out(s_format("[SF-CheatAssets] Asset preparation complete: committed %d modified resources.", committed))
end

local ok_exec, err_exec = pcall(ExecuteAllTweaks)
if not ok_exec then
    _err("[SF-CheatAssets] Pregame asset pass failed: " .. tostring(err_exec))
    error(err_exec, 0)
end

return {}
