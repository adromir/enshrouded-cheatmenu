--[[
    SF Cheat Menu - Static World & Inventory Patches for Enshrouded
    Author: Adromir
    License: MIT
    Version: 0.0.1
    
    Pure pregame KFC asset pass mod (capabilities: ["patch"]).
    Applies static binary alterations during the startup preparation pass
    for stack sizes, chest slots, altar radius, slope walking, and recipes.
]]

if not loader or not loader.features or not loader.features.patch then
    return
end

local ok_patch, err_patch = pcall(function()
    if not game or not game.assets then return end

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

    -- 1. Movement Speed, Jump Height & Steep Slope Walking
    local move_mult = (read_cfg("movementSpeedMultiplier", 100) or 100) / 100.0
    local jump_mult = (read_cfg("jumpHeightMultiplier", 100) or 100) / 100.0
    local no_slope = read_cfg("noSlopeSlide", false) == true

    if move_mult > 1.0 or jump_mult > 1.0 or no_slope then
        local ok_res, player_res = pcall(game.assets.get_resource, "c3db66d6-89a5-4a6c-a8e3-d9a1f6009812", "keen::ecs::TemplateResource", 0)
        if ok_res and player_res and player_res.data and player_res.data.components then
            for _, comp in ipairs(player_res.data.components) do
                if comp.type == "keen::ecs::Movement" and move_mult > 1.0 then
                    local movement = comp.value
                    if movement and movement.dataStorage then
                        local base_run = (movement.dataStorage[5] and movement.dataStorage[5] > 0) and movement.dataStorage[5] or 5.0
                        local base_sprint = (movement.dataStorage[6] and movement.dataStorage[6] > 0) and movement.dataStorage[6] or 8.0
                        movement.dataStorage[5] = math.min(base_run * move_mult, 100.0)
                        movement.dataStorage[6] = math.min(base_sprint * move_mult, 160.0)
                    end
                elseif comp.type == "keen::ecs::JumpParameters" and jump_mult > 1.0 then
                    local jp = comp.value
                    if jp then
                        local base_h = (jp.jumpHeight and jp.jumpHeight > 0) and jp.jumpHeight or 4.0
                        jp.jumpHeight = math.min(base_h * jump_mult, 40.0)
                    end
                elseif comp.type == "keen::ecs::SlopeConfig" and no_slope then
                    local slope = comp.value
                    if slope and slope.slopeDefinition then
                        slope.slopeDefinition.steepFloorAngle = 89.0
                        slope.slopeDefinition.slidingAngle = 89.0
                        slope.slopeDefinition.fallDamageAngle = 89.0
                    end
                end
            end
            player_res.data = player_res.data
        end
    end

    -- 2. Balancing Table: Buildzone, Altars, Comfort, Shroud, Skill Points
    local altar_mult = (read_cfg("altarBuildRadiusMultiplier", 100) or 100) / 100.0
    local unlimited_altars = read_cfg("unlimitedFlameAltars", false) == true
    local comfort_mult = read_cfg("comfortBuffMultiplier", 1) or 1
    local shroud_mult = read_cfg("shroudTimeMultiplier", 1) or 1
    local free_skills = read_cfg("freeSkillTree", false) == true

    local balancing_tables = game.assets.get_resources_by_type("keen::BalancingTable")
    if balancing_tables then
        for _, bres in ipairs(balancing_tables) do
            local bdata = bres.data
            if bdata then
                local changed = false
                if altar_mult > 1.0 and bdata.buildzoneSizesPerAltarLevel then
                    for _, size in ipairs(bdata.buildzoneSizesPerAltarLevel) do
                        local max_safe = 320.0
                        size.x = math.min(size.x * altar_mult, max_safe)
                        size.z = math.min(size.z * altar_mult, max_safe)
                        size.y = math.min(size.y * altar_mult, max_safe)
                    end
                    changed = true
                end
                if unlimited_altars and bdata.altarsPerFlameLevel then
                    for i = 1, #bdata.altarsPerFlameLevel do
                        bdata.altarsPerFlameLevel[i] = 255
                    end
                    changed = true
                end
                if comfort_mult > 1 and bdata.comfortSetup then
                    bdata.comfortSetup.base = math.floor(bdata.comfortSetup.base * comfort_mult)
                    bdata.comfortSetup.factor = bdata.comfortSetup.factor * comfort_mult
                    changed = true
                end
                if shroud_mult > 1 then
                    if bdata.playerBaseFogResistance then
                        bdata.playerBaseFogResistance = math.min(math.floor(bdata.playerBaseFogResistance * shroud_mult), 86400)
                        changed = true
                    end
                    if bdata.playerFogResistancePerFlameLevel then
                        bdata.playerFogResistancePerFlameLevel = math.min(math.floor(bdata.playerFogResistancePerFlameLevel * shroud_mult), 86400)
                        changed = true
                    end
                end
                if free_skills and bdata.skillPointsPerLevel then
                    bdata.skillPointsPerLevel = math.max(bdata.skillPointsPerLevel, 10)
                    changed = true
                end
                if changed then
                    bres.data = bdata
                end
            end
        end
    end

    -- 3. Map Markers: Fast travel to all markers
    local ft_markers = read_cfg("fastTravelAllMarkers", false) == true
    if ft_markers then
        local map_registries = game.assets.get_resources_by_type("keen::MapMarkerRegistryResource")
        if map_registries and #map_registries > 0 and map_registries[1].data then
            local reg = map_registries[1].data
            if reg.mapMarkers and reg.mapMarkers.values then
                for _, marker in ipairs(reg.mapMarkers.values) do
                    local cat = marker.sortingCategory
                    if cat == "FlameRelated" or cat == "Dungeons" or cat == "Locations" or cat == "CustomMarker" then
                        marker.isFastTravelDestination = true
                    end
                end
                map_registries[1].data = reg
            end
        end
    end

    -- 4. Extra Chest Slots (Expand Storage to 160 Slots)
    local extra_chests = read_cfg("extraChestSlots", false) == true
    if extra_chests then
        local templates = game.assets.get_resources_by_type("keen::ecs::TemplateResource")
        if templates then
            for _, t in ipairs(templates) do
                local td = t and t.data
                local name = td and td.name
                if name and string.find(name, "Storage_", 1, true) and not string.find(name, "Loot", 1, true) and not string.find(name, "Player", 1, true) then
                    if td.components then
                        local changed = false
                        for _, comp in ipairs(td.components) do
                            if comp.type == "keen::ecs::InventorySetup" and comp.value then
                                local g = comp.value.genericSlotCount
                                if g and g >= 16 and (g % 8) == 0 then
                                    local rows = g // 8
                                    local new_slots = math.min(g + (rows - 1) * 8, 160)
                                    new_slots = new_slots - (new_slots % 8)
                                    comp.value.genericSlotCount = new_slots
                                    comp.value.availableSlotCount = new_slots
                                    changed = true
                                end
                            end
                        end
                        if changed then
                            t.data = td
                        end
                    end
                end
            end
        end
    end

    -- 5. Max Stack Size & Item Tweaks (Flame Altar Item, Rake)
    local stack_size = read_cfg("maxStackSize", 0) or 0
    local rake_anywhere = read_cfg("rakeAnywhere", false) == true

    local items = game.assets.get_resources_by_type("keen::ItemInfo")
    if items then
        for _, item_res in ipairs(items) do
            local item = item_res.data
            if item then
                local changed = false
                if stack_size > 1 and item.maxStackSize and item.maxStackSize > 1 and item.maxStackSize < stack_size then
                    item.maxStackSize = stack_size
                    changed = true
                end
                if unlimited_altars and item.equipment then
                    local guid_str = tostring(item_res.guid or "")
                    local placed = tostring(item.equipment.placedEntity or "")
                    if guid_str == "85ad0843-7f32-4026-95d2-96c8e54e2899" or placed == "5bcf6d3e-6067-4e25-a0f9-dab49aed4ae3" then
                        item.equipment.requiresAltarSlot = false
                        changed = true
                    end
                end
                if rake_anywhere and item.category == "BuildTools" and string.find(item.debugName or "", "Rake") then
                    if item.equipment then
                        item.equipment.buildZoneRequired = false
                        item.equipment.allowPlacementBelowFog = true
                        item.equipment.checkInhibitBuild = "None"
                        changed = true
                    end
                end
                if changed then
                    item_res.data = item
                end
            end
        end
    end

    -- 6. Recipes: Best Tier 3 Backpack
    local best_bp = read_cfg("cheatBestBackpack", false) == true
    local recipe_registries = game.assets.get_resources_by_type("keen::RecipeRegistryResource")
    if recipe_registries then
        local bp_guid = "e43e65ad-24d6-4f1e-8c76-0270ef5ab0c6"
        local bp_id = nil
        if best_bp and items then
            for _, it in ipairs(items) do
                if tostring(it.guid or "") == bp_guid and it.data and it.data.itemId then
                    bp_id = it.data.itemId.value
                    break
                end
            end
        end

        for _, reg_res in ipairs(recipe_registries) do
            local rdata = reg_res.data
            if rdata and rdata.recipes then
                local changed_reg = false
                for _, recipe in ipairs(rdata.recipes) do
                    local rname = tostring(recipe.debugName or "")
                    if best_bp and bp_id and string.find(rname, "^Special_Backpack_") then
                        if recipe.output then
                            for _, out in ipairs(recipe.output) do
                                out.itemRef = bp_guid
                                out.item = { value = bp_id }
                                out.count = 1
                            end
                        end
                        if recipe.input then
                            for _, inp in ipairs(recipe.input) do
                                if inp.itemStack and (inp.itemStack.count or 0) > 1 then
                                    inp.itemStack.count = 1
                                end
                            end
                        end
                        changed_reg = true
                    end
                end

                if changed_reg then
                    reg_res.data = rdata
                end
            end
        end
    end

    -- 7. Free Skill Perks: Skill tree node costs = 0
    if free_skills then
        local skill_trees = game.assets.get_resources_by_type("keen::SkillTreeResource")
        if skill_trees then
            for _, st in ipairs(skill_trees) do
                if st.data and st.data.nodes then
                    for _, node in ipairs(st.data.nodes) do
                        node.costs = 0
                    end
                    st.data = st.data
                end
            end
        end
    end

    print("[SF Cheat Menu Assets] Pregame asset pass complete: all selected assets patched.")
end)

if not ok_patch and err_patch then
    print("[SF Cheat Menu Assets] Pregame asset pass error: " .. tostring(err_patch))
end
