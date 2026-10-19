--[[
    SF Cheat Menu & Server Tweaks for Enshrouded
    Author: Adromir
    License: MIT
    Version: 0.0.1
    
    Pure in-game runtime cheat menu (capabilities: ["runtime"]).
    Operates via typed ECS attributes, GameSettings overrides, and native C++ sidecar.
    Zero restart locks, instant F9 toggling, never blocked on startup.
]]

local overrides = runtime and runtime.overrides and runtime.overrides.new()
local last_state, last_detail

--- Checks if a number is finite and positive
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

--- Safe getter for boolean settings
local function enabled(key)
    if shroudforge and shroudforge.settings and type(shroudforge.settings.get) == "function" then
        return shroudforge.settings.get(key, false) == true
    end
    return false
end

--- Safe getter for numeric settings / sliders
local function get_num(key, fallback)
    if shroudforge and shroudforge.settings and type(shroudforge.settings.get) == "function" then
        local val = shroudforge.settings.get(key, fallback)
        if type(val) == "number" and val == val then return val end
    end
    return fallback
end

--- Report runtime state to ShroudForge UI and console
local function report(state, detail)
    if not runtime or not runtime.report_effect then return end
    if last_state == state and last_detail == detail then return end
    last_state, last_detail = state, detail
    runtime.report_effect(state, detail)
end

-- Core Player Attributes (verified against original KFC attribute programs)
local attributes = {
    {setting = "infiniteStamina", root = "Stamina", field = "Stamina_Min", maximum = "Stamina_Max"},
    {setting = "infiniteMana", root = "Mana", field = "Mana_Min", maximum = "Mana_Max"},
    {setting = "infiniteOxygen", root = "Oxygen", field = "Oxygen_Min", maximum = "Oxygen_Max"},
    {setting = "noHypothermia", root = "BodyHeat", field = "BodyHeat_Min", maximum = "BodyHeat_Max"},
}

local function attribute_target(feature, snapshot, baseline)
    if feature.maximum then
        local maximum = snapshot.values[feature.maximum]
        if not finite(maximum) or maximum <= 0 then
            return nil, "A positive original maximum is required"
        end
        return maximum
    end
    return nil, "Unknown attribute feature"
end

local function check_enabled(key)
    if key == "healthRegenMultiplier" then return get_num("healthRegenMultiplier", 1) > 1 end
    if key == "staminaRegenMultiplier" then return get_num("staminaRegenMultiplier", 1) > 1 end
    if key == "manaRegenMultiplier" then return get_num("manaRegenMultiplier", 1) > 1 end
    if key == "critChance" then return get_num("critChance", 0) > 0 end
    if key == "critDamageMultiplier" then return get_num("critDamageMultiplier", 100) > 100 end
    if key == "meleeDamageMultiplier" then return get_num("meleeDamageMultiplier", 100) > 100 end
    if key == "rangedDamageMultiplier" then return get_num("rangedDamageMultiplier", 100) > 100 end
    if key == "magicDamageMultiplier" then return get_num("magicDamageMultiplier", 100) > 100 end
    if key == "itemAmountMultiplier" then return get_num("itemAmountMultiplier", 1) > 1 end
    if key == "enemyPerceptionMultiplier" then return get_num("enemyPerceptionMultiplier", 100) ~= 100 end
    if key == "productionSpeedMultiplier" then return get_num("productionSpeedMultiplier", 1) > 1 end
    if key == "plantGrowthMultiplier" then return get_num("plantGrowthMultiplier", 1) > 1 end
    if key == "jumpHeightMultiplier" then return get_num("jumpHeightMultiplier", 100) > 100 end

    -- Aliases for multi-target settings
    if key:find("^infiniteHealth") then return enabled("infiniteHealth") end
    if key:find("^infiniteStamina") then return enabled("infiniteStamina") end
    if key:find("^infiniteShroud") then return enabled("infiniteShroud") or get_num("shroudTimeMultiplier", 1) > 1 end
    if key:find("^oneHitKill") then return enabled("oneHitKill") end
    if key:find("^freeSkillTree") then return enabled("freeSkillTree") or enabled("freeCrafting") end
    if key:find("^xpMultiplier") then return get_num("xpMultiplier", 1) > 1 end
    if key:find("^dumbEnemies") then return enabled("dumbEnemies") end
    if key:find("^creativeHover") then return enabled("creativeHover") end
    return enabled(key)
end

local function any_feature_active()
    return enabled("infiniteHealth")
        or get_num("healthRegenMultiplier", 1) > 1
        or enabled("infiniteStamina")
        or get_num("staminaRegenMultiplier", 1) > 1
        or get_num("jumpHeightMultiplier", 100) > 100
        or enabled("infiniteMana")
        or get_num("manaRegenMultiplier", 1) > 1
        or enabled("noFallDamage")
        or enabled("creativeHover")
        or enabled("unlimitedGliding")
        or enabled("noHypothermia")
        or enabled("infiniteOxygen")
        or enabled("oneHitKill")
        or get_num("critChance", 0) > 0
        or get_num("critDamageMultiplier", 100) > 100
        or get_num("meleeDamageMultiplier", 100) > 100
        or get_num("rangedDamageMultiplier", 100) > 100
        or get_num("magicDamageMultiplier", 100) > 100
        or enabled("infiniteDurability")
        or enabled("freeCrafting")
        or enabled("freeSkillTree")
        or enabled("freeReskill")
        or enabled("infiniteArrows")
        or enabled("infiniteAirJump")
        or enabled("infiniteShroud")
        or enabled("infiniteConsumables")
        or get_num("itemAmountMultiplier", 1) > 1
        or get_num("xpMultiplier", 1) > 1
        or enabled("dumbEnemies")
        or get_num("enemyPerceptionMultiplier", 100) ~= 100
        or get_num("productionSpeedMultiplier", 1) > 1
        or get_num("plantGrowthMultiplier", 1) > 1
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

    -- =========================================================================
    -- Authoritative World / Server Rules (ecs::GameSettings)
    -- =========================================================================
    local game_settings = runtime.services and runtime.services.get("ecs::GameSettings")
    if game_settings then
        -- 1. Infinite Item Durability (World)
        if enabled("infiniteDurability") then
            local target, failure = runtime.overrides.service(game_settings, "enableDurability")
            if target then
                overrides:apply(target.key, "infiniteDurability", target, function() return false end)
            else
                overrides:waiting("Infinite Durability: " .. tostring(failure))
            end
        end

        -- 2. God Mode / Incoming Damage Factors (World/Server)
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

        -- 3. Infinite Stamina (World/Server Multiplier)
        if enabled("infiniteStamina") then
            local t_stam = runtime.overrides.service(game_settings, "playerStaminaFactor")
            if t_stam then
                overrides:apply(t_stam.key, "infiniteStamina_factor", t_stam, function() return 100.0 end)
            end
        end

        -- 4. Freeze Shroud Timer (World/Server Shroud Time Multiplier)
        if enabled("infiniteShroud") or get_num("shroudTimeMultiplier", 1) > 1 then
            local t_shroud = runtime.overrides.service(game_settings, "shroudTimeFactor")
            if t_shroud then
                overrides:apply(t_shroud.key, "infiniteShroud_factor", t_shroud, function() return 10000.0 end)
            end
        end

        -- 5. Free Skill Perks / Zero Cost Factor
        if enabled("freeSkillTree") or enabled("freeCrafting") then
            local t_perk = runtime.overrides.service(game_settings, "perkCostFactor")
            if t_perk then
                overrides:apply(t_perk.key, "freeSkillTree_perkCost", t_perk, function() return 0.0 end)
            end
        end

        -- 4. Resource Drop & Harvesting Yield Multiplier
        local drop_mult = get_num("itemAmountMultiplier", 1)
        if drop_mult > 1 then
            local t_drop = runtime.overrides.service(game_settings, "resourceDropStackAmountFactor")
            if t_drop then
                overrides:apply(t_drop.key, "itemAmountMultiplier", t_drop, function(_, base)
                    return (base or 1.0) * drop_mult
                end)
            end
        end

        -- 5. XP Multiplier (Combat, Mining, Exploration/Quests)
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

        -- 6. Pacify World Enemies
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

        -- 7. Enemy Perception Range Multiplier
        local percept_mult = get_num("enemyPerceptionMultiplier", 100)
        if percept_mult ~= 100 then
            local t_percept = runtime.overrides.service(game_settings, "enemyPerceptionRangeFactor")
            if t_percept then
                overrides:apply(t_percept.key, "enemyPerceptionMultiplier", t_percept, function()
                    return percept_mult / 100.0
                end)
            end
        end

        -- 8. Production Station Speed Multiplier
        local prod_mult = get_num("productionSpeedMultiplier", 1)
        if prod_mult > 1 then
            local t_prod = runtime.overrides.service(game_settings, "factoryProductionSpeedFactor")
            if t_prod then
                overrides:apply(t_prod.key, "productionSpeedMultiplier", t_prod, function(_, base)
                    return (base or 1.0) * prod_mult
                end)
            end
        end

        -- 9. Plant & Crop Growth Multiplier
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

    -- =========================================================================
    -- Personal Player Attributes, Defense & Mobility (Local Client)
    -- =========================================================================
    local players, p_why = runtime.ecs.query("keen::ecs::PlayerInput")
    if players and #players > 0 then
        for _, player_entity in ipairs(players) do
            -- 1. Bound Attributes (Mana, Stamina, Oxygen, BodyHeat)
            for _, feature in ipairs(attributes) do
                if enabled(feature.setting) then
                    local target, failure = runtime.overrides.attribute(player_entity, feature.field)
                    if target then
                        overrides:apply(target.key, feature.setting, target, function(snapshot, baseline)
                            return attribute_target(feature, snapshot, baseline)
                        end)
                    else
                        overrides:waiting(feature.setting .. ": " .. tostring(failure))
                    end
                end
            end

            -- 2. Fast Health Regen / God Mode Regeneration
            local hp_regen_mult = get_num("healthRegenMultiplier", 1)
            if enabled("infiniteHealth") or hp_regen_mult > 1 then
                local setting_key = enabled("infiniteHealth") and "infiniteHealth_recharge" or "healthRegenMultiplier"
                local mult = enabled("infiniteHealth") and 100 or hp_regen_mult
                local target, failure = runtime.overrides.attribute(player_entity, "Health_Recharge")
                if target then
                    overrides:apply(target.key, setting_key, target, function(_, baseline)
                        if baseline <= 0 then
                            return enabled("infiniteHealth") and 1000 or nil, "No natural health regen active"
                        end
                        return math.min(baseline * mult, 65536)
                    end)
                end
            end

            -- 3. Fast Stamina Regen & Infinite Stamina boost
            local stam_regen_mult = get_num("staminaRegenMultiplier", 1)
            if enabled("infiniteStamina") or stam_regen_mult > 1 then
                local setting_key = enabled("infiniteStamina") and "infiniteStamina_recharge" or "staminaRegenMultiplier"
                local mult = enabled("infiniteStamina") and 500 or stam_regen_mult
                local target = runtime.overrides.attribute(player_entity, "Stamina_Recharge")
                if target then
                    overrides:apply(target.key, setting_key, target, function(_, baseline)
                        if baseline <= 0 then
                            return enabled("infiniteStamina") and 1000 or nil, "No natural stamina regen active"
                        end
                        return math.min(baseline * mult, 65536)
                    end)
                end
            end

            -- 4. Fast Mana Regen
            local mana_regen_mult = get_num("manaRegenMultiplier", 1)
            if mana_regen_mult > 1 then
                local target = runtime.overrides.attribute(player_entity, "Mana_Recharge")
                if target then
                    overrides:apply(target.key, "manaRegenMultiplier", target, function(_, baseline)
                        if baseline <= 0 then return nil, "No natural mana regen active" end
                        return math.min(baseline * mana_regen_mult, 65536)
                    end)
                end
            end

            -- 5. Jump Height Multiplier (Runtime Template Override)
            local jump_val = get_num("jumpHeightMultiplier", 100)
            if jump_val > 100 then
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

            -- 6. Combat Damage Multipliers & One-Hit Kill
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
