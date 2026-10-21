--[[
    SF Cheat Menu - Static World & Inventory Patches for Enshrouded
    Author: Adromir
    License: MIT
    Version: 0.0.1
    
    Pure pregame KFC asset pass mod (capabilities: ["patch"]).
    Applies static binary alterations during the startup preparation pass
    for stack sizes, chest slots, altar radius, slope walking, and recipes.
]]

if not game or not game.assets then
    return
end

local ok_patch, err_patch = pcall(function()

    local function read_cfg(key, fallback)
        if shroudforge and shroudforge.settings and type(shroudforge.settings.get) == "function" then
            local v = shroudforge.settings.get(key, nil)
            if v ~= nil then return v end
        end
        local files = { "extended.mod.json", "../sf-cheatmenu/extended.mod.json", "mods/sf-cheatmenu/extended.mod.json" }
        for _, f in ipairs(files) do
            if io and io.exists and io.exists(f) then
                local text = io.read_to_string(f)
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
        end
        return fallback
    end

    -- 1. Movement Speed, Jump Height & Steep Slope Walking
    local move_mult = (read_cfg("movementSpeedMultiplier", 100) or 100) / 100.0
    local jump_mult = (read_cfg("jumpHeightMultiplier", 100) or 100) / 100.0
    local no_slope = read_cfg("noSlopeSlide", false) == true

    if no_slope then
        local slope_defs = game.assets.get_resources_by_type("keen::SlopeDefinition")
        if slope_defs then
            for _, sd_res in ipairs(slope_defs) do
                local sd = sd_res.data
                if sd then
                    sd.steepFloorAngle = 89.0
                    sd.slidingAngle = 89.0
                    sd.fallDamageAngle = 89.0
                    sd.slidingMaterialMinAngle = 89.0
                    sd_res.data = sd
                end
            end
        end
    end

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
                elseif comp.type == "keen::ecs::Locomotion" and no_slope then
                    local loc = comp.value
                    if loc and loc.slideConfig then
                        loc.slideConfig.downhillAccelerationFactor = 0.0
                        loc.slideConfig.downhillAcceleration = 0.0
                        loc.slideConfig.lateralAcceleration = 0.0
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

    -- 4. Extra Chest Slots (Integrated from ChestSlots mod by Johnson1893)
    local extra_chests = read_cfg("extraChestSlots", true) == true
    if extra_chests then
        local COLS = 8
        local MAX_SLOTS = 200

        local function find_component_by_type(components, typeName)
            if not components then return nil end
            for _, c in ipairs(components) do
                if c and c.type == typeName then
                    return c
                end
            end
            return nil
        end

        local function is_storage_template_name(name)
            if not name then return false end
            if string.find(name, "Loot", 1, true) then return false end
            if string.find(name, "Player", 1, true) then return false end
            return string.find(name, "Storage_", 1, true) ~= nil
        end

        local function compute_new_slots(slots)
            if not slots or slots < 2 * COLS or (slots % COLS) ~= 0 then return slots end
            local rows = slots // COLS
            local deltaRows = rows - 1
            if deltaRows <= 0 then return slots end
            local newSlots = slots + deltaRows * COLS
            if newSlots > MAX_SLOTS then newSlots = MAX_SLOTS end
            return newSlots - (newSlots % COLS)
        end

        local templates = game.assets.get_resources_by_type("keen::ecs::TemplateResource")
        if templates and #templates > 0 then
            local modified = 0
            for _, t in ipairs(templates) do
                local td = t and t.data
                local name = td and td.name

                if is_storage_template_name(name) then
                    local invSetup = find_component_by_type(td.components, "keen::ecs::InventorySetup")
                    if invSetup and invSetup.value then
                        local g = invSetup.value.genericSlotCount
                        local newSlots = compute_new_slots(g)
                        if newSlots ~= g then
                            invSetup.value.genericSlotCount = newSlots
                            invSetup.value.availableSlotCount = newSlots
                            t.data = td
                            modified = modified + 1
                            print(string.format("[ChestSlots] Modified slots for %s (%d >> %d)", tostring(name), g, newSlots))
                        end
                    end
                end
            end
        end
    end

    -- 5. Max Stack Size & Item Tweaks (Flame Altar Item, Rake, Free Building & Unlimited Placement)
    local stack_size = read_cfg("maxStackSize", 0) or 0
    local rake_anywhere = read_cfg("rakeAnywhere", false) == true
    local free_building = read_cfg("freeBuilding", true) == true
    local free_crafting = read_cfg("freeRecipeCrafting", true) == true or read_cfg("freeCrafting", false) == true or free_building

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
                if (free_building or free_crafting) and item.equipment then
                    if item.equipment.placementConsume ~= false then
                        item.equipment.placementConsume = false
                        changed = true
                    end
                    if item.equipment.requiredCraftingIngredients then
                        for _, req in ipairs(item.equipment.requiredCraftingIngredients) do
                            if req.count and req.count > 0 then
                                req.count = 0
                                changed = true
                            end
                        end
                    end
                end
                if changed then
                    item_res.data = item
                end
            end
        end
    end

    -- 6. Recipes: Best Tier 3 Backpack, Free Flame & Altar Upgrades, and Free Crafting
    local best_bp = read_cfg("cheatBestBackpack", false) == true
    local free_flame = read_cfg("freeFlameUpgrades", true) == true
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

                    -- Free Strengthen the Flame & Flame Altar Upgrades (Zero Sparks & Shroud Cores)
                    if free_flame and (recipe.isUpgrade == true or string.find(rname, "^Flame_Level_") or string.find(rname, "^FlameAltar_HomeBase_Upgrade_") or rname == "Prop_Building_FlameAltar_Small_Build_Base_PK") then
                        if recipe.input then
                            for _, inp in ipairs(recipe.input) do
                                if inp.itemStack and inp.itemStack.count and inp.itemStack.count > 0 then
                                    inp.itemStack.count = 0
                                    changed_reg = true
                                end
                                if inp.inputItemCategory and inp.inputItemCategory.count and inp.inputItemCategory.count > 0 then
                                    inp.inputItemCategory.count = 0
                                    changed_reg = true
                                end
                            end
                        end
                    end

                    -- Free Building Materials & Station Recipes (Zero Ingredient Costs)
                    if (free_building or free_crafting) and recipe.input then
                        for _, inp in ipairs(recipe.input) do
                            if inp.itemStack and inp.itemStack.count and inp.itemStack.count > 0 then
                                inp.itemStack.count = 0
                                changed_reg = true
                            end
                            if inp.inputItemCategory and inp.inputItemCategory.count and inp.inputItemCategory.count > 0 then
                                inp.inputItemCategory.count = 0
                                changed_reg = true
                            end
                        end
                        if free_building and recipe.output then
                            for _, out in ipairs(recipe.output) do
                                if out.count and out.count > 1 and out.count < 500 then
                                    if string.find(rname, "Block") or string.find(rname, "Building") then
                                        out.count = 500
                                        changed_reg = true
                                    end
                                end
                            end
                        end
                    end
                end

                if changed_reg then
                    reg_res.data = rdata
                end
            end
        end
    end

    -- 7. Free Skill Perks: Skill tree node costs = 0
    local free_skills = read_cfg("freeSkillTree", true) == true
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

    -- 8. Resource Drop & Harvesting Yield Multiplier
    local drop_mult = read_cfg("itemAmountMultiplier", 1) or 1
    if drop_mult > 1 then
        -- A. Chests, enemies, world containers (LootableItemsResource)
        local loot_res = game.assets.get_resources_by_type("keen::LootableItemsResource")
        if loot_res then
            for _, res in ipairs(loot_res) do
                local d = res.data
                if d and d.items then
                    local changed = false
                    for _, entry in pairs(d.items) do
                        if entry.stackSizeMin and entry.stackSizeMin > 0 then
                            entry.stackSizeMin = math.min(math.floor(entry.stackSizeMin * drop_mult), 9999)
                            changed = true
                        end
                        if entry.stackSizeMax and entry.stackSizeMax > 0 then
                            entry.stackSizeMax = math.min(math.floor(entry.stackSizeMax * drop_mult), 9999)
                            changed = true
                        end
                        if entry.stackSizeScalable ~= false then
                            entry.stackSizeScalable = false
                            changed = true
                        end
                    end
                    if changed then res.data = d end
                end
            end
        end

        -- B. ItemInfo random world loot stack range
        if items then
            for _, it in ipairs(items) do
                local d = it.data
                if d and d.randomLootStackRange then
                    local r = d.randomLootStackRange
                    local changed = false
                    if r.minStackSize and r.minStackSize > 0 then
                        r.minStackSize = math.min(math.floor(r.minStackSize * drop_mult), 9999)
                        changed = true
                    end
                    if r.maxStackSize and r.maxStackSize > 0 then
                        r.maxStackSize = math.min(math.floor(r.maxStackSize * drop_mult), 9999)
                        changed = true
                    end
                    if changed then it.data = d end
                end
            end
        end

        -- C. Templates: ResourceNodePickupDrops & MiningNode (bushes, plants, trees, rocks, ore deposits)
        local templates = game.assets.get_resources_by_type("keen::ecs::TemplateResource")
        if templates then
            for _, t in ipairs(templates) do
                local td = t.data
                if td and td.components then
                    local changed = false
                    for _, comp in ipairs(td.components) do
                        if comp.type == "keen::ecs::ResourceNodePickupDrops" and comp.value then
                            local val = comp.value
                            if val.numberOfDrops and val.numberOfDrops > 0 then
                                val.numberOfDrops = math.min(math.floor(val.numberOfDrops * drop_mult), 1000)
                                changed = true
                            end
                        elseif comp.type == "keen::ecs::MiningNode" and comp.value then
                            local val = comp.value
                            if val.numberOfDrops and val.numberOfDrops > 0 then
                                val.numberOfDrops = math.min(math.floor(val.numberOfDrops * drop_mult), 1000)
                                changed = true
                            end
                            if val.aliveDropCount and val.aliveDropCount > 0 then
                                val.aliveDropCount = math.min(math.floor(val.aliveDropCount * drop_mult), 1000)
                                changed = true
                            end
                        end
                    end
                    if changed then t.data = td end
                end
            end
        end

        -- D. DefaultInventoryResource (starter & world pickup inventory stacks)
        local default_inv = game.assets.get_resources_by_type("keen::ecs::DefaultInventoryResource")
        if default_inv then
            local function patch_stacks(stacks)
                if not stacks then return false end
                local changed = false
                for _, stack in pairs(stacks) do
                    if stack.countMin and stack.countMin > 0 then
                        stack.countMin = math.min(math.floor(stack.countMin * drop_mult), 9999)
                        changed = true
                    end
                    if stack.countMax and stack.countMax > 0 then
                        stack.countMax = math.min(math.floor(stack.countMax * drop_mult), 9999)
                        changed = true
                    end
                end
                return changed
            end
            for _, res in ipairs(default_inv) do
                local d = res.data
                if d and d.rootGroup then
                    local changed = patch_stacks(d.rootGroup.stacks)
                    for _, grp in pairs(d.rootGroup.groups or {}) do
                        if patch_stacks(grp and grp.stacks) then changed = true end
                    end
                    if changed then res.data = d end
                end
            end
        end
    end

    print("[SF Cheat Menu Assets] Pregame asset pass complete: all selected assets patched.")
end)

if not ok_patch and err_patch then
    print("[SF Cheat Menu Assets] Pregame asset pass error: " .. tostring(err_patch))
end
