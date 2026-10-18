--[[
    SF Cheat Menu & Dedicated Server Tweaks for Enshrouded
    Author: Adromir
    License: MIT
    Version: 0.0.1
    
    Comprehensive cheat menu and server utility built on ShroudForge's typed
    runtime API, ECS attribute bindings, service overrides, and asset patching.
    Supports a clean hybrid client-server architecture:
      - Dedicated Server authoritatively manages world rules (stacks, chests, durability, free crafting, XP, world AI, altar boundaries).
      - Individual Clients toggle personal god mode, flight, gliding, super jump, speed, slope climbing, combat, vision, item spawner, and waypoints via local F9 menu.
]]

local overrides = runtime.overrides.new()
local pitch_overrides = runtime.overrides.new()
local last_state, last_detail

-- Storage for original baseline values to ensure clean restoration
local original_item_stacks = {}
local original_container_slots = {}
local original_altar_radii = {}
local last_applied_stack_val = nil
local last_applied_container_slots = nil
local last_applied_altar_mult = nil

-- Saved Waypoint coordinates (Slot 1, 2, 3)
local saved_waypoints = {}

-- Catalog for Item Spawner (mapped to internal Keen Game item templates)
local item_spawner_catalog = {
    shroud_core = "item_shroud_core",
    spark = "item_spark",
    runes = "item_runes",
    flax = "item_resource_flax",
    copper_bar = "item_bar_copper",
    iron_bar = "item_bar_iron",
    tin_bar = "item_bar_tin",
    obsidian_bar = "item_bar_obsidian",
    fossilized_bone = "item_resource_fossilized_bone",
    legendary_sword = "item_weapon_sword_nova",
    legendary_bow = "item_weapon_bow_shadowbane",
    legendary_wand = "item_weapon_wand_igniter",
    healing_potion_greater = "item_potion_heal_greater",
    elixir_of_strength = "item_potion_elixir_strength",
    rough_stone_block = "item_block_weathered_stone",
    castle_wall_block = "item_block_castle_wall"
}

--- Safe getter for boolean settings
local function enabled(key)
    return shroudforge.settings.get(key, false) == true
end

--- Safe getter for numeric settings / sliders
local function get_num(key, fallback)
    local val = shroudforge.settings.get(key, fallback)
    if type(val) ~= "number" or val ~= val then
        return fallback
    end
    return val
end

--- Safe getter for string / select settings
local function get_str(key, fallback)
    local val = shroudforge.settings.get(key, fallback)
    if type(val) ~= "string" or val == "" then
        return fallback
    end
    return val
end

--- Report runtime state to ShroudForge UI and console
local function report(state, detail)
    if last_state == state and last_detail == detail then return end
    last_state, last_detail = state, detail
    runtime.report_effect(state, detail)
end

--- Checks if a number is finite
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- =========================================================================
-- Universal Item Stack Size & Chest Storage Modifiers (World / Server)
-- =========================================================================

--- Applies or restores item stack size adjustments across all stackable items
local function update_stack_sizes()
    if not runtime.has or not runtime.has("game.assets.write") then
        return
    end
    local item_info_type = game.types and game.types.get("keen::ItemInfo")
    if not item_info_type or not game.assets or type(game.assets.get_resources_by_type) ~= "function" then
        return
    end

    local mode = get_str("stackSizeMode", "multiplier")
    local mult = math.max(1, math.min(100, get_num("stackSizeMultiplier", 1)))
    local custom_val = math.max(10, math.min(32767, math.floor(get_num("customStackSize", 1000))))

    local current_signature = mode .. ":" .. tostring(mode == "custom" and custom_val or mult)
    if current_signature == last_applied_stack_val then
        return
    end

    local ok, items = pcall(game.assets.get_resources_by_type, item_info_type)
    if not ok or not items or #items == 0 then return end

    local count = 0
    for _, res in ipairs(items) do
        local data = res.data
        if data and data.maxStackSize and data.maxStackSize > 1 then
            local guid_str = tostring(res.guid)
            if not original_item_stacks[guid_str] then
                original_item_stacks[guid_str] = data.maxStackSize
            end

            local base_stack = original_item_stacks[guid_str]
            local target_stack = base_stack

            if mode == "max" then
                target_stack = 32767
            elseif mode == "custom" then
                target_stack = custom_val
            elseif mode == "multiplier" and mult > 1 then
                target_stack = math.min(32767, math.floor(base_stack * mult))
            end

            if data.maxStackSize ~= target_stack then
                pcall(function()
                    data.maxStackSize = target_stack
                    res.data = data
                    count = count + 1
                end)
            end
        end
    end

    last_applied_stack_val = current_signature
    if count > 0 then
        shroudforge.log.info(string.format("SF Cheat Menu: Updated stack size for %d items (Mode: %s, Signature: %s)",
            count, mode, current_signature))
    end
end

--- Applies or restores chest / container size templates (storage slots only)
local function update_container_sizes()
    if not runtime.has or not runtime.has("game.assets.write") then
        return
    end
    local template_info_type = game.types and game.types.get("keen::TemplateInfo")
    if not template_info_type or not game.assets or type(game.assets.get_resources_by_type) ~= "function" then
        return
    end

    local is_custom_enabled = enabled("enableCustomContainer")
    local desired_slots = math.max(16, math.min(96, math.floor(get_num("customContainerSlots", 64))))
    local target_signature = is_custom_enabled and desired_slots or 0

    if target_signature == last_applied_container_slots then
        return
    end

    local ok, templates = pcall(game.assets.get_resources_by_type, template_info_type)
    if not ok or not templates or #templates == 0 then return end

    local count = 0
    for _, res in ipairs(templates) do
        local data = res.data
        if data and data.isContainer then
            local guid_str = tostring(res.guid)
            if not original_container_slots[guid_str] then
                original_container_slots[guid_str] = data.containerSlotCount or 24
            end

            local base_slots = original_container_slots[guid_str]
            local target_slots = is_custom_enabled and desired_slots or base_slots

            if data.containerSlotCount ~= target_slots then
                pcall(function()
                    data.containerSlotCount = target_slots
                    res.data = data
                    count = count + 1
                end)
            end
        end
    end

    last_applied_container_slots = target_signature
    if count > 0 then
        shroudforge.log.info(string.format("SF Cheat Menu: Updated container capacity for %d chest templates (Slots: %d)",
            count, is_custom_enabled and desired_slots or 0))
    end
end

--- Applies Flame Altar boundary radius multiplier
local function update_altar_radius()
    if not runtime.has or not runtime.has("game.assets.write") then
        return
    end
    local altar_type = game.types and game.types.get("keen::FlameAltarTemplate")
    if not altar_type or not game.assets or type(game.assets.get_resources_by_type) ~= "function" then
        return
    end

    local mult = math.max(1, math.min(10, math.floor(get_num("altarRadiusMultiplier", 1))))
    if mult == last_applied_altar_mult then return end

    local ok, altars = pcall(game.assets.get_resources_by_type, altar_type)
    if not ok or not altars or #altars == 0 then return end

    for _, res in ipairs(altars) do
        local data = res.data
        if data and data.buildRadius then
            local guid_str = tostring(res.guid)
            if not original_altar_radii[guid_str] then
                original_altar_radii[guid_str] = data.buildRadius
            end
            local base_r = original_altar_radii[guid_str]
            pcall(function()
                data.buildRadius = math.min(500.0, base_r * mult)
                res.data = data
            end)
        end
    end
    last_applied_altar_mult = mult
end

-- =========================================================================
-- Main Runtime Update Tick
-- =========================================================================

local function any_feature_active()
    return enabled("infiniteHealth")
        or get_num("healthRegenMultiplier", 1) > 1
        or enabled("infiniteStamina")
        or get_num("staminaRegenMultiplier", 1) > 1
        or enabled("infiniteMana")
        or get_num("manaRegenMultiplier", 1) > 1
        or enabled("freezeShroudTimer")
        or get_num("shroudTimeMultiplier", 1) > 1
        or enabled("redShroudImmunity")
        or enabled("maxComfort")
        or get_num("customComfortLevel", 0) > 0
        or enabled("noHypothermia")
        or enabled("infiniteOxygen")
        or enabled("infiniteFocus")
        or get_num("critChance", 0) > 0
        or get_num("critDamageMultiplier", 100) > 100
        or get_num("meleeDamageMultiplier", 100) > 100
        or get_num("rangedDamageMultiplier", 100) > 100
        or get_num("magicDamageMultiplier", 100) > 100
        or enabled("oneHitKill")
        or enabled("personalZeroThreat")
        or enabled("infiniteArrows")
        or enabled("instantBowDraw")
        or enabled("rapidWandCadence")
        or enabled("buildFlyMode")
        or enabled("unlimitedGliding")
        or get_num("jumpHeightMultiplier", 100) > 100
        or get_num("movementSpeedMultiplier", 100) > 100
        or enabled("slopeWalking")
        or enabled("unlimitedGrapplingHook")
        or enabled("teleportMapMarker")
        or enabled("saveWaypointSlot1")
        or enabled("teleportWaypointSlot1")
        or get_num("altarRadiusMultiplier", 1) > 1
        or enabled("unlimitedFlameAltars")
        or enabled("freeBuildingBlocks")
        or enabled("ignoreStructuralStability")
        or enabled("freeFlameUpgrades")
        or enabled("infiniteDurability")
        or enabled("freeCrafting")
        or enabled("unlockAllRecipes")
        or get_num("itemAmountMultiplier", 1) > 1
        or enabled("editItemQuantity")
        or enabled("enableCustomInventory")
        or enabled("enableCustomContainer")
        or enabled("freeWeaponUpgrades")
        or enabled("maxWeaponPerks")
        or enabled("triggerItemSpawn")
        or get_num("xpMultiplier", 1) > 1
        or enabled("infiniteSkillPoints")
        or enabled("freeRespecAnywhere")
        or enabled("dumbEnemies")
        or get_num("enemyPerceptionMultiplier", 100) < 100
        or get_num("enemyDamageMultiplier", 100) ~= 100
        or enabled("freezeTimeOfDay")
        or get_num("gameSpeed", 100) ~= 100
        or get_num("productionSpeedMultiplier", 1) > 1
        or get_num("plantGrowthMultiplier", 1) > 1
        or enabled("clearShroudVision")
        or enabled("revealAllMapIcons")
        or get_num("fogOfWarDiscoveryRange", 1) > 1
        or enabled("hudMinimapRadar")
end

local function update(delta_seconds)
    local session = runtime.world.session_id()
    if session == 0 then
        report("waiting", "Waiting for an authoritative world session")
        return
    end

    -- Process asset-based world modifiers if asset write capability is active
    if runtime.has and runtime.has("game.assets.write") then
        pcall(update_stack_sizes)
        pcall(update_container_sizes)
        pcall(update_altar_radius)
    end


    overrides:begin_update()
    pitch_overrides:begin_update()

    local check_enabled = function(key)
        if key == "healthRegenMultiplier" then return get_num("healthRegenMultiplier", 1) > 1 end
        if key == "staminaRegenMultiplier" then return get_num("staminaRegenMultiplier", 1) > 1 end
        if key == "manaRegenMultiplier" then return get_num("manaRegenMultiplier", 1) > 1 end
        if key == "shroudTimeMultiplier" then return get_num("shroudTimeMultiplier", 1) > 1 end
        if key == "customComfortLevel" then return get_num("customComfortLevel", 0) > 0 end
        if key == "critChance" then return get_num("critChance", 0) > 0 end
        if key == "critDamageMultiplier" then return get_num("critDamageMultiplier", 100) > 100 end
        if key == "meleeDamageMultiplier" then return get_num("meleeDamageMultiplier", 100) > 100 end
        if key == "rangedDamageMultiplier" then return get_num("rangedDamageMultiplier", 100) > 100 end
        if key == "magicDamageMultiplier" then return get_num("magicDamageMultiplier", 100) > 100 end
        if key == "jumpHeightMultiplier" then return get_num("jumpHeightMultiplier", 100) > 100 end
        if key == "movementSpeedMultiplier" or key == "movementSpeedMultiplier_run" or key == "movementSpeedMultiplier_sprint" then
            return get_num("movementSpeedMultiplier", 100) > 100
        end
        if key == "altarRadiusMultiplier" then return get_num("altarRadiusMultiplier", 1) > 1 end
        if key == "xpMultiplier" then return get_num("xpMultiplier", 1) > 1 end
        if key == "itemAmountMultiplier" then return get_num("itemAmountMultiplier", 1) > 1 or enabled("freeCrafting") end
        if key == "enemyPerceptionMultiplier" then return get_num("enemyPerceptionMultiplier", 100) < 100 end
        if key == "enemyDamageMultiplier" then return get_num("enemyDamageMultiplier", 100) ~= 100 end
        if key == "productionSpeedMultiplier" then return get_num("productionSpeedMultiplier", 1) > 1 end
        if key == "plantGrowthMultiplier" then return get_num("plantGrowthMultiplier", 1) > 1 end
        if key == "fogOfWarDiscoveryRange" then return get_num("fogOfWarDiscoveryRange", 1) > 1 end

        -- Aliases for multi-target settings
        if key == "infiniteHealth_godmode_dmg" or key == "infiniteHealth_godmode_boss" then return enabled("infiniteHealth") end
        if key == "infiniteStamina_world" or key == "infiniteStamina_glider" then return enabled("infiniteStamina") end
        if key == "infiniteMana_world" then return enabled("infiniteMana") end
        if key == "enableCustomInventory_generic" then return enabled("enableCustomInventory") end
        return enabled(key)
    end

    overrides:restore_disabled(check_enabled)
    pitch_overrides:restore_disabled(check_enabled)

    if overrides.fault or pitch_overrides.fault then
        report("write-failed", overrides.fault or pitch_overrides.fault)
        return
    end

    if not any_feature_active() then
        report(overrides:has_ownership() and "waiting" or "no-change",
            overrides:summary("All SF Cheat Menu options are idle / default"))
        return
    end

    if not runtime.has("runtime.ecs.read") or not runtime.has("runtime.ecs.write") then
        report("waiting", "Waiting for typed ECS access and authoritative write scope")
        return
    end

    -- ---------------------------------------------------------------------
    -- Authoritative World / Server Rules (ecs::GameSettings & World Services)
    -- ---------------------------------------------------------------------
    local game_settings, gs_why = runtime.services.get("ecs::GameSettings")
    if game_settings then
        -- Durability
        if enabled("infiniteDurability") or enabled("infiniteHealth") then
            local target = runtime.overrides.service(game_settings, "enableDurability")
            if target then
                overrides:apply(target.key, "infiniteDurability", target, function() return false end)
            end
        end

        -- God Mode / Enemy & Boss Damage Scaling (World / Host)
        if enabled("infiniteHealth") then
            local dmg_target = runtime.overrides.service(game_settings, "enemyDamageFactor")
            if dmg_target then
                overrides:apply(dmg_target.key, "infiniteHealth_godmode_dmg", dmg_target, function() return 0.0 end)
            end
            local boss_target = runtime.overrides.service(game_settings, "bossDamageFactor")
            if boss_target then
                overrides:apply(boss_target.key, "infiniteHealth_godmode_boss", boss_target, function() return 0.0 end)
            end
        end

        -- Player Stamina Factor (World / Host)
        if enabled("infiniteStamina") then
            local target = runtime.overrides.service(game_settings, "playerStaminaFactor")
            if target then
                overrides:apply(target.key, "infiniteStamina_world", target, function() return 0.0 end)
            end
        end

        -- Player Mana Factor (World / Host)
        if enabled("infiniteMana") then
            local target = runtime.overrides.service(game_settings, "playerManaFactor")
            if target then
                overrides:apply(target.key, "infiniteMana_world", target, function() return 0.0 end)
            end
        end

        -- Free Crafting & 0 Perk Cost Factor
        if enabled("freeCrafting") or enabled("infiniteSkillPoints") then
            local target = runtime.overrides.service(game_settings, "perkCostFactor")
            if target then
                overrides:apply(target.key, "freeCrafting", target, function() return 0.0 end)
            end
        end

        -- Unlock All Recipes
        if enabled("unlockAllRecipes") then
            local target = runtime.overrides.service(game_settings, "unlockAllRecipes")
            if target then
                overrides:apply(target.key, "unlockAllRecipes", target, function() return true end)
            end
        end

        -- Free Skill Respec Anywhere (0 Runes)
        if enabled("freeRespecAnywhere") then
            local target = runtime.overrides.service(game_settings, "respecCostFactor")
            if target then
                overrides:apply(target.key, "freeRespecAnywhere", target, function() return 0.0 end)
            end
        end

        -- Unlimited Flame Altars
        if enabled("unlimitedFlameAltars") then
            local target = runtime.overrides.service(game_settings, "maxFlameAltars")
            if target then
                overrides:apply(target.key, "unlimitedFlameAltars", target, function() return 9999 end)
            end
        end

        -- Free Building Blocks (Hammer consumes 0 materials)
        if enabled("freeBuildingBlocks") then
            local target = runtime.overrides.service(game_settings, "buildingBlockCostFactor")
            if target then
                overrides:apply(target.key, "freeBuildingBlocks", target, function() return 0.0 end)
            end
        end

        -- Ignore Structural Stability
        if enabled("ignoreStructuralStability") then
            local target = runtime.overrides.service(game_settings, "enableStructuralStability")
            if target then
                overrides:apply(target.key, "ignoreStructuralStability", target, function() return false end)
            end
        end

        -- Free Flame Altar Upgrades
        if enabled("freeFlameUpgrades") then
            local target = runtime.overrides.service(game_settings, "flameUpgradeCostFactor")
            if target then
                overrides:apply(target.key, "freeFlameUpgrades", target, function() return 0.0 end)
            end
        end

        -- Free Weapon Upgrades at Blacksmith
        if enabled("freeWeaponUpgrades") then
            local target = runtime.overrides.service(game_settings, "weaponUpgradeRuneCostFactor")
            if target then
                overrides:apply(target.key, "freeWeaponUpgrades", target, function() return 0.0 end)
            end
        end

        -- Shroud Survival Timer (Server/World multiplier)
        if enabled("freezeShroudTimer") then
            local target = runtime.overrides.service(game_settings, "shroudTimeFactor")
            if target then
                overrides:apply(target.key, "freezeShroudTimer", target, function() return 9999.0 end)
            end
        else
            local shroud_mult = get_num("shroudTimeMultiplier", 1)
            if shroud_mult > 1 then
                local target = runtime.overrides.service(game_settings, "shroudTimeFactor")
                if target then
                    overrides:apply(target.key, "shroudTimeMultiplier", target, function(_, base)
                        return (base or 1.0) * shroud_mult
                    end)
                end
            end
        end

        -- Global Pacification (Server/Host)
        if enabled("dumbEnemies") then
            local p_target = runtime.overrides.service(game_settings, "pacifyAllEnemies")
            if p_target then
                overrides:apply(p_target.key, "dumbEnemies", p_target, function() return true end)
            end
            local r_target = runtime.overrides.service(game_settings, "enemyPerceptionRangeFactor")
            if r_target then
                overrides:apply(r_target.key, "dumbEnemies", r_target, function() return 0.0 end)
            end
            local t_target = runtime.overrides.service(game_settings, "threatBonus")
            if t_target then
                overrides:apply(t_target.key, "dumbEnemies", t_target, function() return -9999.0 end)
            end
        else
            -- Configurable Global Enemy Perception
            local perception_pct = get_num("enemyPerceptionMultiplier", 100)
            if perception_pct < 100 then
                local target = runtime.overrides.service(game_settings, "enemyPerceptionRangeFactor")
                if target then
                    overrides:apply(target.key, "enemyPerceptionMultiplier", target, function(_, base)
                        return (base or 1.0) * (perception_pct / 100.0)
                    end)
                end
            end
        end

        -- Global Enemy Damage Scaling
        local enemy_dmg_pct = get_num("enemyDamageMultiplier", 100)
        if enemy_dmg_pct ~= 100 then
            local target = runtime.overrides.service(game_settings, "enemyDamageFactor")
            if target then
                overrides:apply(target.key, "enemyDamageMultiplier", target, function(_, base)
                    return (base or 1.0) * (enemy_dmg_pct / 100.0)
                end)
            end
        end

        -- XP Multipliers (Combat, Quests, Mining)
        local xp_mult = get_num("xpMultiplier", 1)
        if xp_mult > 1 then
            local c_target = runtime.overrides.service(game_settings, "experienceCombatFactor")
            if c_target then
                overrides:apply(c_target.key, "xpMultiplier", c_target, function(_, base) return (base or 1.0) * xp_mult end)
            end
            local q_target = runtime.overrides.service(game_settings, "experienceExplorationQuestsFactor")
            if q_target then
                overrides:apply(q_target.key, "xpMultiplier", q_target, function(_, base) return (base or 1.0) * xp_mult end)
            end
            local m_target = runtime.overrides.service(game_settings, "experienceMiningFactor")
            if m_target then
                overrides:apply(m_target.key, "xpMultiplier", m_target, function(_, base) return (base or 1.0) * xp_mult end)
            end
        end

        -- Resource & Drop Yield Multiplier
        local drop_mult = get_num("itemAmountMultiplier", 1)
        if drop_mult > 1 then
            local target = runtime.overrides.service(game_settings, "resourceDropStackAmountFactor")
            if target then
                overrides:apply(target.key, "itemAmountMultiplier", target, function(_, base) return (base or 1.0) * drop_mult end)
            end
        end

        -- Workshop Production Speed Multiplier
        local prod_mult = get_num("productionSpeedMultiplier", 1)
        if prod_mult > 1 then
            local target = runtime.overrides.service(game_settings, "factoryProductionSpeedFactor")
            if target then
                overrides:apply(target.key, "productionSpeedMultiplier", target, function(_, base) return (base or 1.0) * prod_mult end)
            end
        end

        -- Plant Growth Multiplier
        local plant_mult = get_num("plantGrowthMultiplier", 1)
        if plant_mult > 1 then
            local target = runtime.overrides.service(game_settings, "plantGrowthSpeedFactor")
            if target then
                overrides:apply(target.key, "plantGrowthMultiplier", target, function(_, base) return (base or 1.0) * plant_mult end)
            end
        end
    else
        overrides:waiting("ecs::GameSettings: " .. tostring(gs_why))
    end

    -- ---------------------------------------------------------------------
    -- Personal Player Attributes, Combat & Mobility (Local Client)
    -- ---------------------------------------------------------------------
    local players, p_why = runtime.ecs.query("keen::ecs::PlayerInput")
    if players and #players > 0 then
        for _, player_entity in ipairs(players) do
            -- 1. Health & Regeneration
            if enabled("infiniteHealth") then
                local target = runtime.overrides.attribute(player_entity, "Health_Min")
                if target then
                    overrides:apply(target.key, "infiniteHealth", target, function(snapshot)
                        local max = snapshot.values["Health_Max"]
                        if finite(max) and max > 0 then return max end
                        return 99999.0
                    end)
                else
                    local h_target = runtime.overrides.attribute(player_entity, "Health")
                    if h_target then
                        overrides:apply(h_target.key, "infiniteHealth", h_target, function() return 99999.0 end)
                    end
                end
            end

            local hp_regen_mult = get_num("healthRegenMultiplier", 1)
            if hp_regen_mult > 1 then
                local target = runtime.overrides.attribute(player_entity, "Health_Recharge")
                if target then
                    overrides:apply(target.key, "healthRegenMultiplier", target, function(_, base)
                        if base <= 0 then return nil, "No natural health regen active" end
                        return math.min(base * hp_regen_mult, 65536)
                    end)
                end
            end

            -- 2. Stamina
            if enabled("infiniteStamina") then
                local target = runtime.overrides.attribute(player_entity, "Stamina_Min")
                if target then
                    overrides:apply(target.key, "infiniteStamina", target, function(snapshot)
                        local max = snapshot.values["Stamina_Max"]
                        if finite(max) and max > 0 then return max end
                        return 9999.0
                    end)
                end
                local g_target = runtime.overrides.attribute(player_entity, "StaminaDepletionMod_Glider")
                if g_target then
                    overrides:apply(g_target.key, "infiniteStamina_glider", g_target, function() return 0 end)
                end
            end

            local stam_regen_mult = get_num("staminaRegenMultiplier", 1)
            if stam_regen_mult > 1 then
                local target = runtime.overrides.attribute(player_entity, "Stamina_Recharge")
                if target then
                    overrides:apply(target.key, "staminaRegenMultiplier", target, function(_, base)
                        if base <= 0 then return nil, "No natural stamina regen active" end
                        return math.min(base * stam_regen_mult, 65536)
                    end)
                end
            end

            -- 3. Mana
            if enabled("infiniteMana") then
                local target = runtime.overrides.attribute(player_entity, "Mana_Min")
                if target then
                    overrides:apply(target.key, "infiniteMana", target, function(snapshot)
                        local max = snapshot.values["Mana_Max"]
                        if finite(max) and max > 0 then return max end
                        return 9999.0
                    end)
                end
            end

            local mana_regen_mult = get_num("manaRegenMultiplier", 1)
            if mana_regen_mult > 1 then
                local target = runtime.overrides.attribute(player_entity, "Mana_Recharge")
                if target then
                    overrides:apply(target.key, "manaRegenMultiplier", target, function(_, base)
                        if base <= 0 then return nil, "No natural mana regen active" end
                        return math.min(base * mana_regen_mult, 65536)
                    end)
                end
            end

            -- 4. Red Shroud Immunity & Cold / Oxygen
            if enabled("redShroudImmunity") then
                local red_target = runtime.overrides.attribute(player_entity, "DeadlyShroudExposure")
                if red_target then
                    overrides:apply(red_target.key, "redShroudImmunity", red_target, function() return 0.0 end)
                end
                local prot_target = runtime.overrides.attribute(player_entity, "FlameProtectionLevel")
                if prot_target then
                    overrides:apply(prot_target.key, "redShroudImmunity", prot_target, function() return 99 end)
                end
            end

            if enabled("noHypothermia") then
                local target = runtime.overrides.attribute(player_entity, "BodyHeat_Min")
                if target then
                    overrides:apply(target.key, "noHypothermia", target, function(snapshot)
                        local max = snapshot.values["BodyHeat_Max"]
                        if finite(max) and max > 0 then return max end
                        return nil, "Invalid BodyHeat_Max"
                    end)
                end
            end

            if enabled("infiniteOxygen") then
                local target = runtime.overrides.attribute(player_entity, "Oxygen_Min")
                if target then
                    overrides:apply(target.key, "infiniteOxygen", target, function(snapshot)
                        local max = snapshot.values["Oxygen_Max"]
                        if finite(max) and max > 0 then return max end
                        return nil, "Invalid Oxygen_Max"
                    end)
                end
            end

            if enabled("infiniteFocus") then
                local target = runtime.overrides.attribute(player_entity, "Focus_Min")
                if target then
                    overrides:apply(target.key, "infiniteFocus", target, function(snapshot)
                        local max = snapshot.values["Focus_Max"]
                        if finite(max) and max > 0 then return max end
                        return nil, "Invalid Focus_Max"
                    end)
                end
            end

            -- 5. Comfort Level
            if enabled("maxComfort") then
                local target = runtime.overrides.attribute(player_entity, "Comfort")
                    or runtime.overrides.attribute(player_entity, "SufficientComfortLevel")
                if target then
                    overrides:apply(target.key, "maxComfort", target, function() return 100 end)
                end
            else
                local custom_comfort = get_num("customComfortLevel", 0)
                if custom_comfort > 0 then
                    local target = runtime.overrides.attribute(player_entity, "Comfort")
                        or runtime.overrides.attribute(player_entity, "SufficientComfortLevel")
                    if target then
                        overrides:apply(target.key, "customComfortLevel", target, function() return custom_comfort end)
                    end
                end
            end

            -- 6. Critical Chance, Damage Multipliers & One-Hit Kill
            if enabled("oneHitKill") then
                local melee_t = runtime.overrides.attribute(player_entity, "MeleeDamageMod")
                if melee_t then overrides:apply(melee_t.key, "oneHitKill", melee_t, function() return 99999.0 end) end
                local ranged_t = runtime.overrides.attribute(player_entity, "RangedDamageMod")
                if ranged_t then overrides:apply(ranged_t.key, "oneHitKill", ranged_t, function() return 99999.0 end) end
                local magic_t = runtime.overrides.attribute(player_entity, "MagicDamageMod")
                if magic_t then overrides:apply(magic_t.key, "oneHitKill", magic_t, function() return 99999.0 end) end
                local crit_t = runtime.overrides.attribute(player_entity, "CritDamageMod")
                if crit_t then overrides:apply(crit_t.key, "oneHitKill", crit_t, function() return 99999.0 end) end
            else
                local crit_val = get_num("critChance", 0)
                if crit_val > 0 then
                    local crit_target = runtime.overrides.attribute(player_entity, "CritChance")
                    if crit_target then
                        overrides:apply(crit_target.key, "critChance", crit_target, function(_, baseline)
                            return math.min(1.0, (baseline or 0) + (crit_val / 100.0))
                        end)
                    end
                end

                local crit_dmg = get_num("critDamageMultiplier", 100)
                if crit_dmg > 100 then
                    local target = runtime.overrides.attribute(player_entity, "CritDamageMod")
                    if target then
                        overrides:apply(target.key, "critDamageMultiplier", target, function(_, base)
                            return (base or 1.0) * (crit_dmg / 100.0)
                        end)
                    end
                end

                local melee_dmg = get_num("meleeDamageMultiplier", 100)
                if melee_dmg > 100 then
                    local target = runtime.overrides.attribute(player_entity, "MeleeDamageMod")
                    if target then
                        overrides:apply(target.key, "meleeDamageMultiplier", target, function(_, base)
                            return (base or 1.0) * (melee_dmg / 100.0)
                        end)
                    end
                end

                local ranged_dmg = get_num("rangedDamageMultiplier", 100)
                if ranged_dmg > 100 then
                    local target = runtime.overrides.attribute(player_entity, "RangedDamageMod")
                    if target then
                        overrides:apply(target.key, "rangedDamageMultiplier", target, function(_, base)
                            return (base or 1.0) * (ranged_dmg / 100.0)
                        end)
                    end
                end

                local magic_dmg = get_num("magicDamageMultiplier", 100)
                if magic_dmg > 100 then
                    local target = runtime.overrides.attribute(player_entity, "MagicDamageMod")
                    if target then
                        overrides:apply(target.key, "magicDamageMultiplier", target, function(_, base)
                            return (base or 1.0) * (magic_dmg / 100.0)
                        end)
                    end
                end
            end

            -- 7. Personal Stealth: Enemies Ignore Me (Zero Threat)
            if enabled("personalZeroThreat") then
                local t_target = runtime.overrides.attribute(player_entity, "Threat")
                if t_target then
                    overrides:apply(t_target.key, "personalZeroThreat", t_target, function() return 0 end)
                end
                local tb_target = runtime.overrides.attribute(player_entity, "ThreatBonus")
                if tb_target then
                    overrides:apply(tb_target.key, "personalZeroThreat", tb_target, function() return -9999 end)
                end
                local a_target = runtime.overrides.attribute(player_entity, "AllyAggroMultiplier")
                if a_target then
                    overrides:apply(a_target.key, "personalZeroThreat", a_target, function() return 0 end)
                end
            end

            -- 8. Combat Mechanics: Ammo, Rapid Archery & Machine-Gun Wands
            if enabled("infiniteArrows") then
                local ammo_target = runtime.overrides.component(player_entity, "keen::ecs::RangedWeaponSetup", "consumeAmmo")
                if ammo_target then
                    overrides:apply(ammo_target.key, "infiniteArrows", ammo_target, function() return false end)
                end
            end

            if enabled("instantBowDraw") then
                local draw_target = runtime.overrides.component(player_entity, "keen::ecs::BowChargeParameters", "chargeTime")
                if draw_target then
                    overrides:apply(draw_target.key, "instantBowDraw", draw_target, function() return 0.0 end)
                end
                local delay_target = runtime.overrides.component(player_entity, "keen::ecs::BowChargeParameters", "drawDelay")
                if delay_target then
                    overrides:apply(delay_target.key, "instantBowDraw", delay_target, function() return 0.0 end)
                end
            end

            if enabled("rapidWandCadence") then
                local wand_target = runtime.overrides.component(player_entity, "keen::ecs::WandCastCooldown", "cooldown")
                if wand_target then
                    overrides:apply(wand_target.key, "rapidWandCadence", wand_target, function() return 0.0 end)
                end
                local rec_target = runtime.overrides.component(player_entity, "keen::ecs::WeaponAttackParameters", "recoveryTime")
                if rec_target then
                    overrides:apply(rec_target.key, "rapidWandCadence", rec_target, function() return 0.0 end)
                end
            end

            -- 9. Unlimited Grappling Hook Range & Zero Stamina
            if enabled("unlimitedGrapplingHook") then
                local hook_range = runtime.overrides.component(player_entity, "keen::ecs::GrapplingHookParameters", "maxRange")
                if hook_range then
                    overrides:apply(hook_range.key, "unlimitedGrapplingHook", hook_range, function() return 9999.0 end)
                end
                local hook_stam = runtime.overrides.component(player_entity, "keen::ecs::GrapplingHookParameters", "staminaCost")
                if hook_stam then
                    overrides:apply(hook_stam.key, "unlimitedGrapplingHook", hook_stam, function() return 0.0 end)
                end
            end

            -- 10. Building Fly Mode (Zero Gravity & Hovering)
            if enabled("buildFlyMode") then
                local grav_target = runtime.overrides.component(player_entity, "keen::ecs::Gravity", "isActive")
                if grav_target then
                    overrides:apply(grav_target.key, "buildFlyMode", grav_target, function() return false end)
                end
                local grav_val_target = runtime.overrides.component(player_entity, "keen::ecs::Gravity", "value")
                if grav_val_target then
                    overrides:apply(grav_val_target.key, "buildFlyMode", grav_val_target, function() return 0.0 end)
                end
            end

            -- 11. Infinite Gliding (Zero Glider Stamina & High Lift Drag)
            if enabled("unlimitedGliding") then
                local g_target = runtime.overrides.attribute(player_entity, "StaminaDepletionMod_Glider")
                if g_target then
                    overrides:apply(g_target.key, "unlimitedGliding", g_target, function() return 0 end)
                end
            end

            -- 12. Adjustable Jump Height
            local jump_mult = get_num("jumpHeightMultiplier", 100)
            if jump_mult > 100 then
                local j_height_target = runtime.overrides.component(player_entity, "keen::ecs::JumpParameters", "jumpHeight")
                if j_height_target then
                    overrides:apply(j_height_target.key, "jumpHeightMultiplier", j_height_target, function(_, base)
                        return (base or 2.0) * (jump_mult / 100.0)
                    end)
                end
                local j_dist_target = runtime.overrides.component(player_entity, "keen::ecs::JumpParameters", "jumpDistance")
                if j_dist_target then
                    overrides:apply(j_dist_target.key, "jumpHeightMultiplier", j_dist_target, function(_, base)
                        return (base or 3.0) * math.sqrt(jump_mult / 100.0)
                    end)
                end
            end

            -- 13. Adjustable Walking / Movement Speed
            local move_mult = get_num("movementSpeedMultiplier", 100)
            if move_mult > 100 then
                local factor = move_mult / 100.0
                local move_target = runtime.overrides.attribute(player_entity, "Movement")
                    or runtime.overrides.attribute(player_entity, "MovementSpeed")
                if move_target then
                    overrides:apply(move_target.key, "movementSpeedMultiplier", move_target, function(_, base)
                        return (base or 1.0) * factor
                    end)
                end
                local run_target = runtime.overrides.component(player_entity, "keen::ecs::ClientLocomotion", "runSpeed")
                    or runtime.overrides.component(player_entity, "keen::ecs::ClientLocomotion", "baseMovementSpeed")
                if run_target then
                    overrides:apply(run_target.key, "movementSpeedMultiplier_run", run_target, function(_, base)
                        return (base or 5.0) * factor
                    end)
                end
                local sprint_target = runtime.overrides.component(player_entity, "keen::ecs::ClientLocomotion", "sprintSpeed")
                    or runtime.overrides.component(player_entity, "keen::ecs::ClientLocomotion", "sprintMovementSpeed")
                if sprint_target then
                    overrides:apply(sprint_target.key, "movementSpeedMultiplier_sprint", sprint_target, function(_, base)
                        return (base or 8.0) * factor
                    end)
                end
            end

            -- 14. Slope Walking (Walk up 89-degree mountains without sliding)
            if enabled("slopeWalking") then
                local slope_steep = runtime.overrides.component(player_entity, "keen::ecs::SlopeConfig", "slopeDefinition.steepFloorAngle")
                if slope_steep then
                    overrides:apply(slope_steep.key, "slopeWalking", slope_steep, function() return 89.9 end)
                end
                local slope_slide = runtime.overrides.component(player_entity, "keen::ecs::SlopeConfig", "slopeDefinition.slidingAngle")
                if slope_slide then
                    overrides:apply(slope_slide.key, "slopeWalking", slope_slide, function() return 89.9 end)
                end
                local slope_mat = runtime.overrides.component(player_entity, "keen::ecs::SlopeConfig", "slopeDefinition.slidingMaterialMinAngle")
                if slope_mat then
                    overrides:apply(slope_mat.key, "slopeWalking", slope_mat, function() return 89.9 end)
                end
            end

            -- 15. Map Teleportation & Saved Waypoints
            pcall(function()
                if enabled("saveWaypointSlot1") then
                    local fields = runtime.ecs.read_fields(player_entity, "keen::ecs::Transform", {"position.x", "position.y", "position.z"})
                    if fields and fields["position.x"] then
                        saved_waypoints[1] = {
                            x = fields["position.x"],
                            y = fields["position.y"],
                            z = fields["position.z"]
                        }
                        shroudforge.settings.set("saveWaypointSlot1", false)
                        shroudforge.log.info(string.format("SF Cheat Menu: Saved Waypoint Slot 1 at (%.1f, %.1f, %.1f)",
                            saved_waypoints[1].x, saved_waypoints[1].y, saved_waypoints[1].z))
                    end
                end

                if enabled("teleportWaypointSlot1") and saved_waypoints[1] then
                    runtime.ecs.write_fields(player_entity, "keen::ecs::Transform", {
                        ["position.x"] = saved_waypoints[1].x,
                        ["position.y"] = saved_waypoints[1].y,
                        ["position.z"] = saved_waypoints[1].z
                    })
                    shroudforge.settings.set("teleportWaypointSlot1", false)
                    shroudforge.log.info("SF Cheat Menu: Teleported to Saved Waypoint Slot 1")
                end

                if enabled("teleportMapMarker") then
                    local map_service = runtime.services and runtime.services.get("keen::ecs::MapService")
                    if map_service and map_service.activePinPosition then
                        runtime.ecs.write_fields(player_entity, "keen::ecs::Transform", {
                            ["position.x"] = map_service.activePinPosition.x,
                            ["position.y"] = map_service.activePinPosition.y + 1.0,
                            ["position.z"] = map_service.activePinPosition.z
                        })
                        shroudforge.log.info("SF Cheat Menu: Teleported to active map marker pin")
                    end
                    shroudforge.settings.set("teleportMapMarker", false)
                end
            end)

            -- 16. Map / Minimap Fog of War Reveal Multiplier
            local fow_mult = get_num("fogOfWarDiscoveryRange", 1)
            if fow_mult > 1 then
                local fow_target = runtime.overrides.component(player_entity, "keen::ecs::FogOfWarDiscovery", "discoveryRange")
                if fow_target then
                    overrides:apply(fow_target.key, "fogOfWarDiscoveryRange", fow_target, function(_, base)
                        return (base or 100.0) * fow_mult
                    end)
                end
            end

            -- 17. Clear Shroud Blinding Fog Vision
            if enabled("clearShroudVision") then
                local fog_target = runtime.overrides.component(player_entity, "keen::ecs::ShroudPostProcess", "fogDensity")
                if fog_target then
                    overrides:apply(fog_target.key, "clearShroudVision", fog_target, function() return 0.0 end)
                end
                local vig_target = runtime.overrides.component(player_entity, "keen::ecs::ShroudPostProcess", "vignetteStrength")
                if vig_target then
                    overrides:apply(vig_target.key, "clearShroudVision", vig_target, function() return 0.0 end)
                end
            end

            -- 18. Reveal All Map Icons
            if enabled("revealAllMapIcons") then
                pcall(function()
                    local poi_query = runtime.ecs.query("keen::ecs::MapPOI")
                    if poi_query and #poi_query > 0 then
                        for _, poi in ipairs(poi_query) do
                            runtime.ecs.write_fields(poi, "keen::ecs::MapPOI", {["isDiscovered"] = true})
                        end
                    end
                end)
            end

            -- 19. Configurable Backpack Inventory Storage Slots (16 to 96)
            if enabled("enableCustomInventory") then
                local desired_inv_slots = math.max(16, math.min(96, math.floor(get_num("customInventorySlots", 64))))
                local target = runtime.overrides.component(player_entity, "keen::ecs::InventorySetup", "availableSlotCount")
                    or runtime.overrides.component(player_entity, "keen::ecs::InventorySetup", "genericSlots")
                if target then
                    overrides:apply(target.key, "enableCustomInventory", target, function() return desired_inv_slots end)
                end
                local g_target = runtime.overrides.component(player_entity, "keen::ecs::InventorySetup", "genericSlotCount")
                if g_target then
                    overrides:apply(g_target.key, "enableCustomInventory_generic", g_target, function() return desired_inv_slots end)
                end
            end

            -- 20. Interactive Item Spawner
            if enabled("triggerItemSpawn") then
                pcall(function()
                    local chosen_key = get_str("itemSpawnerItem", "shroud_core")
                    local template_id = item_spawner_catalog[chosen_key] or chosen_key
                    local spawn_count = math.max(1, math.min(32767, math.floor(get_num("itemSpawnerAmount", 100))))

                    if game.inventory and type(game.inventory.spawn_item) == "function" then
                        game.inventory.spawn_item(player_entity, template_id, spawn_count)
                        shroudforge.log.info(string.format("SF Cheat Menu: Spawned %d of %s into backpack", spawn_count, template_id))
                    end
                end)
                shroudforge.settings.set("triggerItemSpawn", false)
            end

            -- 21. Max Weapon Enhancement Perks
            if enabled("maxWeaponPerks") then
                pcall(function()
                    local eq_view = runtime.ecs.get_template_component and runtime.ecs.get_template_component(player_entity, "keen::ecs::EquipmentComponent")
                end)
            end
        end
    else
        overrides:waiting("PlayerInput query: " .. tostring(p_why or "No players"))
    end

    pitch_overrides:restore_unused()

    local state = (overrides.fault or pitch_overrides.fault) and "write-failed" or
        (overrides.waiting_count + pitch_overrides.waiting_count > 0 and "waiting" or
        (overrides.writes + pitch_overrides.writes > 0 and "write-confirmed" or "no-change"))
    report(state, overrides:summary("SF Cheat Menu v0.0.1 active"))
end

return {
    update_interval_ms = 100,
    on_load = function()
        shroudforge.log.info("SF Cheat Menu & Server Tweaks v0.0.1 loaded. Initializing...")
        report("waiting", "SF Cheat Menu initialized. Waiting for authoritative world access.")
    end,
    on_update = update,
    on_unload = function()
        shroudforge.log.info("SF Cheat Menu unloading. Restoring original attributes and settings...")
        overrides:begin_update()
        overrides:restore_all()
        pitch_overrides:begin_update()
        pitch_overrides:restore_all()
    end,
}
