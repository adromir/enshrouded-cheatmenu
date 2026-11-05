--[[
    SF Cheat Menu & Server Tweaks for Enshrouded
    Author: Adromir
    License: MIT
    Version: 0.0.2
    
    Pure in-game runtime cheat menu (capabilities: ["runtime"]).
    Operates via typed ECS attributes, GameSettings overrides, and native C++ sidecar.
    Zero restart locks, instant F9 toggling, per-category master switches.
]]

local overrides = runtime and runtime.overrides and runtime.overrides.new()
local last_state, last_detail

local function read_cfg(key, fallback)
    if shroudforge and shroudforge.settings and type(shroudforge.settings.get) == "function" then
        local v = shroudforge.settings.get(key, nil)
        if v ~= nil then return v end
    end
    if io and io.exists and io.exists("extended.mod.json") then
        local text = io.read_to_string("extended.mod.json")
        if text then
            local pattern = '"' .. key .. '"%s*:%s*%{[^%}]-"value"%s*:%s*([%w_%-%.]+)'
            local match = text:match(pattern)
            if match then
                if match == "true" then return true end
                if match == "false" then return false end
                local num = tonumber(match)
                if num ~= nil then return num end
            end
        end
    end
    return fallback
end

--- Safe getter for boolean settings
local function enabled(key, default_val)
    if default_val == nil then default_val = false end
    return read_cfg(key, default_val) == true
end

--- Safe getter for category master toggles (defaults to true if omitted)
local function cat_enabled(key)
    return enabled(key, true)
end

--- Safe getter for numeric settings / sliders
local function get_num(key, fallback)
    local val = read_cfg(key, fallback)
    if type(val) == "number" and val == val then return val end
    return fallback
end

--- Report runtime state to ShroudForge UI and console
local function report(state, detail)
    if not runtime or not runtime.report_effect then return end
    if last_state == state and last_detail == detail then return end
    last_state, last_detail = state, detail
    runtime.report_effect(state, detail)
end

local function check_enabled(key)
    -- Category 1: Movement & Flight
    if key == "jumpHeightMultiplier" then return cat_enabled("Enable_Flight") and get_num("jumpHeightMultiplier", 100) > 100 end
    if key:find("^creativeHover") then return cat_enabled("Enable_Flight") and enabled("creativeHover") end

    -- Category 2: God Mode & Survival
    if key:find("^infiniteHealth") then return cat_enabled("Enable_GodMode") and enabled("infiniteHealth") end
    if key:find("^infiniteShroud") then return cat_enabled("Enable_GodMode") and enabled("infiniteShroud") end

    -- Category 3: Combat, Crits & Arrows
    if key:find("^oneHitKill") then return cat_enabled("Enable_Combat") and enabled("oneHitKill") end
    if key == "critChance" then return cat_enabled("Enable_Combat") and not enabled("oneHitKill") and get_num("critChance", 0) > 0 end
    if key == "critDamageMultiplier" then return cat_enabled("Enable_Combat") and not enabled("oneHitKill") and get_num("critDamageMultiplier", 100) > 100 end
    if key == "meleeDamageMultiplier" then return cat_enabled("Enable_Combat") and not enabled("oneHitKill") and get_num("meleeDamageMultiplier", 100) > 100 end
    if key == "rangedDamageMultiplier" then return cat_enabled("Enable_Combat") and not enabled("oneHitKill") and get_num("rangedDamageMultiplier", 100) > 100 end
    if key == "magicDamageMultiplier" then return cat_enabled("Enable_Combat") and not enabled("oneHitKill") and get_num("magicDamageMultiplier", 100) > 100 end

    -- Category 5: World AI, XP & Production
    if key:find("^dumbEnemies") then return cat_enabled("Enable_WorldRules") and enabled("dumbEnemies") end
    if key == "enemyPerceptionMultiplier" then return cat_enabled("Enable_WorldRules") and get_num("enemyPerceptionMultiplier", 100) ~= 100 end
    if key:find("^xpMultiplier") then return cat_enabled("Enable_WorldRules") and get_num("xpMultiplier", 1) > 1 end
    if key:find("^itemAmountMultiplier") then return cat_enabled("Enable_WorldRules") and get_num("itemAmountMultiplier", 1) > 1 end
    if key == "productionSpeedMultiplier" then return cat_enabled("Enable_WorldRules") and get_num("productionSpeedMultiplier", 1) > 1 end
    if key == "plantGrowthMultiplier" then return cat_enabled("Enable_WorldRules") and get_num("plantGrowthMultiplier", 1) > 1 end

    return enabled(key)
end

local function any_feature_active()
    local flight_on = cat_enabled("Enable_Flight") and (
        enabled("creativeHover")
        or get_num("jumpHeightMultiplier", 100) > 100
    )
    local god_on = cat_enabled("Enable_GodMode") and (
        enabled("infiniteHealth")
        or enabled("infiniteConsumables")
        or enabled("infiniteShroud")
    )
    local combat_on = cat_enabled("Enable_Combat") and (
        enabled("oneHitKill")
        or get_num("critChance", 0) > 0
        or get_num("critDamageMultiplier", 100) > 100
        or get_num("meleeDamageMultiplier", 100) > 100
        or get_num("rangedDamageMultiplier", 100) > 100
        or get_num("magicDamageMultiplier", 100) > 100
        or enabled("infiniteArrows")
    )
    local craft_on = cat_enabled("Enable_CraftingRules") and (
        enabled("freeCrafting")
        or enabled("freeReskill")
    )
    local world_on = cat_enabled("Enable_WorldRules") and (
        enabled("dumbEnemies")
        or get_num("enemyPerceptionMultiplier", 100) ~= 100
        or get_num("xpMultiplier", 1) > 1
        or get_num("itemAmountMultiplier", 1) > 1
        or get_num("productionSpeedMultiplier", 1) > 1
        or get_num("plantGrowthMultiplier", 1) > 1
    )
    return flight_on or god_on or combat_on or craft_on or world_on
end

local function update(delta_seconds)
    if not runtime or not overrides then return end

    local session = runtime.world.session_id()
    if session == 0 then
        report("waiting", "Waiting for an authoritative world session")
        return
    end

    overrides:begin_update()
    overrides:restore_disabled(check_enabled)

    if not any_feature_active() then
        report(overrides:has_ownership() and "waiting" or "no-change",
            overrides:summary("All SF Cheat Menu options are idle / default"))
        return
    end

    if not runtime.has("runtime.ecs.read") or not runtime.has("runtime.ecs.write") then
        report("waiting", "Waiting for typed ECS access and authoritative write scope")
        return
    end

    local flight_cat = cat_enabled("Enable_Flight")
    local god_cat = cat_enabled("Enable_GodMode")
    local combat_cat = cat_enabled("Enable_Combat")
    local craft_cat = cat_enabled("Enable_CraftingRules")
    local world_cat = cat_enabled("Enable_WorldRules")

    -- =========================================================================
    -- Authoritative World / Server Rules (ecs::GameSettings)
    -- =========================================================================
    local game_settings = runtime.services and runtime.services.get("ecs::GameSettings")
    if game_settings then
        -- God Mode & Survival
        if god_cat then
            if enabled("infiniteHealth") then
                local t_enemy = runtime.overrides.service(game_settings, "enemyDamageFactor")
                if t_enemy then
                    overrides:apply(t_enemy.key, "infiniteHealth_enemyDmg", t_enemy, function() return 0.0 end)
                end
                local t_boss = runtime.overrides.service(game_settings, "bossDamageFactor")
                if t_boss then
                    overrides:apply(t_boss.key, "infiniteHealth_bossDmg", t_boss, function() return 0.0 end)
                end
                local t_hp = runtime.overrides.service(game_settings, "playerHealthFactor")
                if t_hp then
                    overrides:apply(t_hp.key, "infiniteHealth_playerHp", t_hp, function() return 10.0 end)
                end
            end

            if enabled("infiniteShroud") then
                local t_shroud = runtime.overrides.service(game_settings, "shroudTimeFactor")
                if t_shroud then
                    overrides:apply(t_shroud.key, "infiniteShroud_factor", t_shroud, function() return 10000.0 end)
                end
            end
        end

        -- Note: Do NOT set GameSettings.perkCostFactor = 0.0 here!
        -- In Enshrouded's engine (0x140e817a0 -> 0x140d302a0), perkCostFactor multiplies
        -- the salvage Rune yield of magic weapons, shields, and rings; setting it to 0.0
        -- reduces salvage Rune output to 0 and hides the "Salvage" UI option (leaving only "Delete").
        -- Free building, perk upgrades, and skill resets are handled natively by sf-native.dll.

        -- World AI, XP & Production
        if world_cat then
            local drop_mult = get_num("itemAmountMultiplier", 1)
            if drop_mult > 1 then
                local t_drop = runtime.overrides.service(game_settings, "resourceDropStackAmountFactor")
                if t_drop then
                    overrides:apply(t_drop.key, "itemAmountMultiplier_drop", t_drop, function(_, base)
                        return (base or 1.0) * drop_mult
                    end)
                end
                local t_mining = runtime.overrides.service(game_settings, "miningDamageFactor")
                if t_mining then
                    overrides:apply(t_mining.key, "itemAmountMultiplier_mining", t_mining, function(_, base)
                        return (base or 1.0) * drop_mult
                    end)
                end
                local t_plant = runtime.overrides.service(game_settings, "plantGrowthSpeedFactor")
                if t_plant then
                    overrides:apply(t_plant.key, "itemAmountMultiplier_plant", t_plant, function(_, base)
                        return (base or 1.0) * drop_mult
                    end)
                end
                local t_factory = runtime.overrides.service(game_settings, "factoryProductionSpeedFactor")
                if t_factory then
                    overrides:apply(t_factory.key, "itemAmountMultiplier_factory", t_factory, function(_, base)
                        return (base or 1.0) * drop_mult
                    end)
                end
            end

            local xp_mult = get_num("xpMultiplier", 1)
            if xp_mult > 1 then
                local t_combat = runtime.overrides.service(game_settings, "experienceCombatFactor")
                if t_combat then
                    overrides:apply(t_combat.key, "xpMultiplier_combat", t_combat, function(_, base)
                        return (base or 1.0) * xp_mult
                    end)
                end
                local t_mine = runtime.overrides.service(game_settings, "experienceMiningFactor")
                if t_mine then
                    overrides:apply(t_mine.key, "xpMultiplier_mine", t_mine, function(_, base)
                        return (base or 1.0) * xp_mult
                    end)
                end
                local t_quest = runtime.overrides.service(game_settings, "experienceExplorationQuestsFactor")
                if t_quest then
                    overrides:apply(t_quest.key, "xpMultiplier_quest", t_quest, function(_, base)
                        return (base or 1.0) * xp_mult
                    end)
                end
            end

            if enabled("dumbEnemies") then
                local t_pacify = runtime.overrides.service(game_settings, "pacifyAllEnemies")
                if t_pacify then
                    overrides:apply(t_pacify.key, "dumbEnemies_pacify", t_pacify, function() return true end)
                end
                local t_threat = runtime.overrides.service(game_settings, "threatBonus")
                if t_threat then
                    overrides:apply(t_threat.key, "dumbEnemies_threat", t_threat, function() return -9999.0 end)
                end
            end

            local percept_mult = get_num("enemyPerceptionMultiplier", 100)
            if percept_mult ~= 100 then
                local t_percept = runtime.overrides.service(game_settings, "enemyPerceptionRangeFactor")
                if t_percept then
                    overrides:apply(t_percept.key, "enemyPerceptionMultiplier", t_percept, function()
                        return percept_mult / 100.0
                    end)
                end
            end

            local prod_mult = get_num("productionSpeedMultiplier", 1)
            if prod_mult > 1 then
                local t_prod = runtime.overrides.service(game_settings, "factoryProductionSpeedFactor")
                if t_prod then
                    overrides:apply(t_prod.key, "productionSpeedMultiplier", t_prod, function(_, base)
                        return (base or 1.0) * prod_mult
                    end)
                end
            end

            local plant_mult = get_num("plantGrowthMultiplier", 1)
            if plant_mult > 1 then
                local t_plant = runtime.overrides.service(game_settings, "plantGrowthSpeedFactor")
                if t_plant then
                    overrides:apply(t_plant.key, "plantGrowthMultiplier", t_plant, function(_, base)
                        return (base or 1.0) * plant_mult
                    end)
                end
            end
        end
    end

    -- =========================================================================
    -- Personal Player Attributes, Defense & Mobility (Local Client)
    -- =========================================================================
    local players, p_why = runtime.ecs.query("keen::ecs::PlayerInput")
    if players and #players > 0 then
        for _, player_entity in ipairs(players) do
            -- God Mode Health Regeneration
            if god_cat and enabled("infiniteHealth") then
                local target = runtime.overrides.attribute(player_entity, "Health_Recharge")
                if target then
                    overrides:apply(target.key, "infiniteHealth_recharge", target, function()
                        return 65536
                    end)
                end
            end

            -- Jump Height Multiplier (Runtime Template Override)
            local jump_val = get_num("jumpHeightMultiplier", 100)
            if flight_cat and jump_val > 100 then
                local j_view = runtime.ecs.get_template_component(player_entity, "keen::ecs::JumpParameters")
                if j_view then
                    local j_target = runtime.overrides.template(j_view, "jumpHeight")
                    if j_target then
                        overrides:apply(j_target.key, "jumpHeightMultiplier", j_target, function(_, base)
                            return (base or 4.0) * (jump_val / 100.0)
                        end)
                    end
                end
            end

            -- Combat Damage Multipliers & One-Hit Kill
            if combat_cat then
                if enabled("oneHitKill") then
                    local melee_t = runtime.overrides.attribute(player_entity, "MeleeDamageMod")
                    if melee_t then overrides:apply(melee_t.key, "oneHitKill_melee", melee_t, function() return 1000.0 end) end
                    local ranged_t = runtime.overrides.attribute(player_entity, "RangedDamageMod")
                    if ranged_t then overrides:apply(ranged_t.key, "oneHitKill_ranged", ranged_t, function() return 1000.0 end) end
                    local magic_t = runtime.overrides.attribute(player_entity, "MagicDamageMod")
                    if magic_t then overrides:apply(magic_t.key, "oneHitKill_magic", magic_t, function() return 1000.0 end) end
                    local crit_t = runtime.overrides.attribute(player_entity, "CritDamageMod")
                    if crit_t then overrides:apply(crit_t.key, "oneHitKill_crit", crit_t, function() return 1000.0 end) end
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
            end
        end
    else
        overrides:waiting("PlayerInput query: " .. tostring(p_why or "No players"))
    end

    local state = overrides.fault and "write-failed" or
        (overrides.waiting_count > 0 and "waiting" or
        (overrides.writes > 0 and "write-confirmed" or "no-change"))
    report(state, overrides:summary("SF Cheat Menu active"))
end

return {
    update_interval_ms = 100,
    on_load = function()
        if shroudforge and shroudforge.log then
            shroudforge.log.info("SF Cheat Menu & Server Tweaks loaded. Initializing...")
        end
        report("waiting", "SF Cheat Menu initialized. Waiting for authoritative world access.")
    end,
    on_update = update,
    on_unload = function()
        if shroudforge and shroudforge.log then
            shroudforge.log.info("SF Cheat Menu unloading. Restoring original attributes and settings...")
        end
        if overrides then
            overrides:begin_update()
            overrides:restore_all()
        end
    end,
}
