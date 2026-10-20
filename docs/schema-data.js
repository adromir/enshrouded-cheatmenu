// Enshrouded SF Cheat Menu - Schema & Preset Definitions
// Auto-generated schema data for sf-cheatmenu (runtime) and sf-cheatmenu-assets (patch)

window.MOD_CONFIGS = {
  "sf-cheatmenu": {
    id: "sf-cheatmenu",
    name: "SF Cheat Menu (Live Runtime Cheats)",
    badge: "Runtime (F9 Menu)",
    description: "Pure live in-game cheat menu (capabilities: [\"runtime\"]). Operates via ECS attributes, GameSettings, and C++ native sidecar. Instant F9 toggles with zero restart requirements.",
    filename: "extended.mod.json",
    base: {
  "$schema": "https://bonsaibauer.github.io/shroudforge/schemas/extended.mod.schema.json",
  "schemaVersion": 1,
  "enabled": true,
  "targets": [
    "client",
    "server"
  ],
  "links": {
    "source-github": "https://github.com/adromir/enshrouded-cheatmenu",
    "website": "https://adromir.github.io/enshrouded-cheatmenu/"
  },
  "changelog": [
    "v0.0.1: Pure live runtime cheat menu with 33 dynamic features and C++ native sidecar. Instant F9 toggling with zero restart requirements."
  ],
  "settings": {
    "unlimitedGliding": {
      "value": true,
      "label": "Infinite Gliding (Unlimited Flight)",
      "description": "Disables glider stamina drain for unlimited glider flight.",
      "control": "checkbox"
    },
    "noFallDamage": {
      "value": true,
      "label": "No Fall Damage (Personal & Native)",
      "description": "Eliminates all fall damage regardless of height.",
      "control": "checkbox"
    },
    "infiniteAirJump": {
      "value": true,
      "label": "Infinite Air-Jump / Multi-Jump (Native)",
      "description": "Bypasses double-jump limit. Allows unlimited mid-air jumps to ascend or fly.",
      "control": "checkbox"
    },
    "creativeHover": {
      "value": false,
      "label": "Creative Mode Hovering / Flight (Personal & Native)",
      "description": "Allows floating stationary in mid-air and flying vertically without falling (R to ascend, F to descend, or Ctrl+H to toggle).",
      "control": "checkbox"
    },
    "hoverSpeed": {
      "value": 100,
      "label": "Hover Speed Multiplier %",
      "description": "Vertical ascent and descent speed while creative hovering (100% = normal, up to 500%).",
      "control": "slider",
      "min": 50,
      "max": 500,
      "step": 25
    },
    "infiniteHealth": {
      "value": true,
      "label": "Infinite Health / God Mode (Personal)",
      "description": "Clamps Health_Min to Health_Max and zeroes incoming damage factors. You become immune to lethal damage.",
      "control": "checkbox"
    },
    "healthRegenMultiplier": {
      "value": 1,
      "label": "Health Regen Multiplier (Personal)",
      "description": "Multiplies natural health regeneration rate for your character (1x = standard, up to 500x).",
      "control": "slider",
      "min": 1,
      "max": 500,
      "step": 5
    },
    "infiniteStamina": {
      "value": true,
      "label": "Infinite Stamina (Personal)",
      "description": "Locks stamina at maximum. Disables stamina drain for sprinting, fighting, and climbing.",
      "control": "checkbox"
    },
    "staminaRegenMultiplier": {
      "value": 1,
      "label": "Stamina Regen Multiplier (Personal)",
      "description": "Multiplies natural stamina regeneration rate (1x = standard, up to 500x).",
      "control": "slider",
      "min": 1,
      "max": 500,
      "step": 5
    },
    "infiniteMana": {
      "value": true,
      "label": "Infinite Mana (Personal)",
      "description": "Locks mana at maximum. Spells and abilities consume zero mana.",
      "control": "checkbox"
    },
    "manaRegenMultiplier": {
      "value": 1,
      "label": "Mana Regen Multiplier (Personal)",
      "description": "Multiplies natural mana regeneration rate (1x = standard, up to 500x).",
      "control": "slider",
      "min": 1,
      "max": 500,
      "step": 5
    },
    "noHypothermia": {
      "value": true,
      "label": "No Hypothermia / Cold Immunity (Personal)",
      "description": "Maintains body heat at maximum; eliminates freezing in cold or snowy biomes.",
      "control": "checkbox"
    },
    "infiniteOxygen": {
      "value": true,
      "label": "Infinite Oxygen / Diving Breath (Personal)",
      "description": "Maintains oxygen reserve at maximum; prevents drowning while diving.",
      "control": "checkbox"
    },
    "infiniteConsumables": {
      "value": true,
      "label": "Infinite Consumables (Native)",
      "description": "Potions, food, bandages, and flasks are not consumed upon use.",
      "control": "checkbox"
    },
    "infiniteShroud": {
      "value": true,
      "label": "Freeze Shroud Timer / Shroud God Mode (Native)",
      "description": "Bypasses engine shroud fog checks. Shroud timer is locked and will never tick down or kill you in the Shroud/Miasma.",
      "control": "checkbox"
    },
    "oneHitKill": {
      "value": false,
      "label": "One-Hit Kill / Infinite Damage (Personal)",
      "description": "Deals lethal damage on any enemy or boss hit, instantly defeating them.",
      "control": "checkbox"
    },
    "critChance": {
      "value": 100,
      "label": "Critical Hit Chance % (Personal)",
      "description": "Additional critical hit chance percentage (0% to 100% max).",
      "control": "slider",
      "min": 0,
      "max": 100,
      "step": 1
    },
    "critDamageMultiplier": {
      "value": 2000,
      "label": "Critical Damage % (Personal)",
      "description": "Multiplier for critical strike damage (100% = default, up to 2000% max).",
      "control": "slider",
      "min": 100,
      "max": 2000,
      "step": 25
    },
    "meleeDamageMultiplier": {
      "value": 2000,
      "label": "Melee Damage % (Personal)",
      "description": "Multiplier for melee weapon attacks (100% = default, up to 2000% max).",
      "control": "slider",
      "min": 100,
      "max": 2000,
      "step": 25
    },
    "rangedDamageMultiplier": {
      "value": 2000,
      "label": "Ranged Damage % (Personal)",
      "description": "Multiplier for bows and thrown weapons (100% = default, up to 2000% max).",
      "control": "slider",
      "min": 100,
      "max": 2000,
      "step": 25
    },
    "magicDamageMultiplier": {
      "value": 2000,
      "label": "Magic Damage % (Personal)",
      "description": "Multiplier for staves, wands, and spells (100% = default, up to 2000% max).",
      "control": "slider",
      "min": 100,
      "max": 2000,
      "step": 25
    },
    "fastBowDrawSpeed": {
      "value": false,
      "label": "Rapid Bow Draw Speed (Fast Shooting)",
      "description": "Reduces bow draw delay in weapon item definitions, allowing rapid firing of arrows.",
      "control": "checkbox"
    },
    "infiniteArrows": {
      "value": true,
      "label": "Infinite Arrows & Quiver (Native)",
      "description": "Bypasses arrow consumption when shooting bows. Arrows in quiver never decrease.",
      "control": "checkbox"
    },
    "infiniteDurability": {
      "value": true,
      "label": "Infinite Item Durability (World & Native)",
      "description": "Disables durability loss for all weapons, tools, and armor world-wide.",
      "control": "checkbox"
    },
    "freeCrafting": {
      "value": true,
      "label": "Free Building & Crafting (Hammer & Workbenches) (Native & Server)",
      "description": "Allows placing building blocks with the construction hammer and crafting items at workbenches with zero resource costs.",
      "control": "checkbox"
    },
    "unlockAllBlueprints": {
      "value": false,
      "label": "Unlock All Blueprints & Building Blocks (Safe Asset Pass)",
      "description": "Safely unlocks all missing building blocks, furniture, and workshop blueprints without corrupting item requirements.",
      "control": "checkbox"
    },
    "freeReskill": {
      "value": true,
      "label": "Free Reskill / Skill Reset (Zero Rune Costs)",
      "description": "Allows resetting skills at the Flame Altar with zero Rune costs.",
      "control": "checkbox"
    },
    "itemAmountMultiplier": {
      "value": 1,
      "label": "Resource Drop & Yield Multiplier (World/Server)",
      "description": "Multiplies item quantities dropped from harvesting and mining (1x to 100x).",
      "control": "slider",
      "min": 1,
      "max": 100,
      "step": 1
    },
    "xpMultiplier": {
      "value": 1,
      "label": "Experience (XP) Multiplier (World/Server)",
      "description": "Multiplies XP earned from combat, exploration, quests, and mining (1x = default, up to 100x).",
      "control": "slider",
      "min": 1,
      "max": 100,
      "step": 1
    },
    "dumbEnemies": {
      "value": false,
      "label": "Pacify World Enemies (Server/Host AI)",
      "description": "Enemies will not initiate attacks and are completely pacified.",
      "control": "checkbox"
    },
    "enemyPerceptionMultiplier": {
      "value": 100,
      "label": "Enemy Perception Range % (World/Server)",
      "description": "Detection and sight range of enemies (100% = normal, 0% = completely blind).",
      "control": "slider",
      "min": 0,
      "max": 200,
      "step": 5
    },
    "productionSpeedMultiplier": {
      "value": 1,
      "label": "Production Station Speed (World/Server)",
      "description": "Speed multiplier for furnaces, kilns, drying racks, and workbenches (1x to 50x).",
      "control": "slider",
      "min": 1,
      "max": 50,
      "step": 1
    },
    "plantGrowthMultiplier": {
      "value": 1,
      "label": "Plant & Crop Growth Speed (World/Server)",
      "description": "Speed multiplier for seedlings, farm plots, and tree growth (1x to 50x).",
      "control": "slider",
      "min": 1,
      "max": 50,
      "step": 1
    }
  },
  "groups": [
    {
      "label": "Movement & Flight Cheats",
      "description": "Instant runtime flight, no fall damage, infinite air jump, and creative hover.",
      "settings": [
        "unlimitedGliding",
        "noFallDamage",
        "infiniteAirJump",
        "creativeHover",
        "hoverSpeed"
      ]
    },
    {
      "label": "Player Attributes & God Mode",
      "description": "Invulnerability, unlimited stamina, mana, oxygen, temperature, consumables, and shroud fog immunity.",
      "settings": [
        "infiniteHealth",
        "healthRegenMultiplier",
        "infiniteStamina",
        "staminaRegenMultiplier",
        "infiniteMana",
        "manaRegenMultiplier",
        "noHypothermia",
        "infiniteOxygen",
        "infiniteConsumables",
        "infiniteShroud"
      ]
    },
    {
      "label": "Combat, Damage & Arrows",
      "description": "Instant one-hit kill, critical strike multipliers, damage amplification, rapid bow draw, and infinite arrows.",
      "settings": [
        "oneHitKill",
        "critChance",
        "critDamageMultiplier",
        "meleeDamageMultiplier",
        "rangedDamageMultiplier",
        "magicDamageMultiplier",
        "fastBowDrawSpeed",
        "infiniteArrows"
      ]
    },
    {
      "label": "World Rules, Crafting & Durability",
      "description": "Unbreakable gear durability, free bench crafting, blueprint unlocking, free reskill, and item drops.",
      "settings": [
        "infiniteDurability",
        "freeCrafting",
        "unlockAllBlueprints",
        "freeReskill",
        "itemAmountMultiplier"
      ]
    },
    {
      "label": "World Difficulty, XP & Production",
      "description": "Passive enemy AI, perception range, XP multiplier, and accelerated workstation production / plant growth.",
      "settings": [
        "dumbEnemies",
        "enemyPerceptionMultiplier",
        "xpMultiplier",
        "productionSpeedMultiplier",
        "plantGrowthMultiplier"
      ]
    }
  ]
},
    presets: {
  "ultimate_godmode": {
    "name": "💥 Ultimate God Mode",
    "desc": "Invulnerability, Infinite Stamina & Mana, One-Hit Kill, Shroud Fog Immunity, Infinite Air-Jump, Infinite Consumables & Arrows.",
    "values": {
      "infiniteHealth": true,
      "infiniteStamina": true,
      "infiniteMana": true,
      "noFallDamage": true,
      "unlimitedGliding": true,
      "infiniteAirJump": true,
      "creativeHover": false,
      "noHypothermia": true,
      "infiniteOxygen": true,
      "infiniteConsumables": true,
      "infiniteShroud": true,
      "oneHitKill": true,
      "critChance": 100,
      "critDamageMultiplier": 2000,
      "meleeDamageMultiplier": 2000,
      "rangedDamageMultiplier": 2000,
      "magicDamageMultiplier": 2000,
      "fastBowDrawSpeed": true,
      "infiniteArrows": true,
      "infiniteDurability": true,
      "freeCrafting": true,
      "freeReskill": true
    }
  },
  "flight_explorer": {
    "name": "🕊️ Creative Flight & Explorer",
    "desc": "Infinite Gliding, No Fall Damage, Unlimited Air Jump, and Creative Hovering (R to ascend, F to descend, Ctrl+H to toggle).",
    "values": {
      "unlimitedGliding": true,
      "noFallDamage": true,
      "infiniteAirJump": true,
      "creativeHover": true,
      "hoverSpeed": 150,
      "infiniteStamina": true,
      "infiniteHealth": true,
      "infiniteDurability": true
    }
  },
  "combat_marksman": {
    "name": "🏹 Legendary Marksman",
    "desc": "Rapid bow draw, infinite arrows, 100% crit chance, amplified ranged damage, and enhanced mobility.",
    "values": {
      "fastBowDrawSpeed": true,
      "infiniteArrows": true,
      "critChance": 100,
      "critDamageMultiplier": 500,
      "rangedDamageMultiplier": 500,
      "infiniteStamina": true,
      "noFallDamage": true,
      "unlimitedGliding": true
    }
  },
  "peaceful_server": {
    "name": "🌿 Peaceful World & Fast Production",
    "desc": "Pacified world enemies, 10x XP multiplier, accelerated crafting production and plant growth.",
    "values": {
      "dumbEnemies": true,
      "enemyPerceptionMultiplier": 10,
      "freeCrafting": true,
      "infiniteDurability": true,
      "freeReskill": true,
      "xpMultiplier": 5,
      "itemAmountMultiplier": 2,
      "productionSpeedMultiplier": 10,
      "plantGrowthMultiplier": 10
    }
  },
  "vanilla": {
    "name": "🔄 Vanilla Defaults",
    "desc": "Resets all runtime cheats to clean game defaults.",
    "values": {}
  }
}
  },
  "sf-cheatmenu-assets": {
    id: "sf-cheatmenu-assets",
    name: "SF Cheat Menu Assets (Static World & Inventory Patches)",
    badge: "Static KFC Patch",
    description: "Static KFC pregame asset patcher (capabilities: [\"patch\"]). Patches 9,999 item stacks, 160 chest slots, altar radius, slope climbing, and template movement speed. Requires launcher preparation.",
    filename: "extended.mod.json",
    base: {
  "$schema": "https://bonsaibauer.github.io/shroudforge/schemas/extended.mod.schema.json",
  "schemaVersion": 1,
  "enabled": true,
  "targets": [
    "client",
    "server"
  ],
  "links": {
    "source-github": "https://github.com/adromir/enshrouded-cheatmenu",
    "website": "https://adromir.github.io/enshrouded-cheatmenu/"
  },
  "changelog": [
    "v0.0.1: Static KFC asset patches: 9999 Item Stacks, 160 Chest Slots, Altar Build Radius, Unlimited Altars, Steep Slope Walking, Movement Speed, Free Skills, and Comfort Multiplier."
  ],
  "settings": {
    "movementSpeedMultiplier": {
      "value": 100,
      "label": "Movement Speed % (Walking & Sprinting)",
      "description": "Patches player locomotion speed via keen::ecs::Movement template. (100% = normal, up to 500%). Requires game restart to take effect.",
      "control": "slider",
      "min": 100,
      "max": 500,
      "step": 10
    },
    "jumpHeightMultiplier": {
      "value": 100,
      "label": "Jump Height Multiplier %",
      "description": "Multiplies vertical jump launch height (100% = normal, up to 500%). Requires game restart.",
      "control": "slider",
      "min": 100,
      "max": 500,
      "step": 25
    },
    "noSlopeSlide": {
      "value": true,
      "label": "Walk on Steep Slopes (No Sliding)",
      "description": "Adjusts slope sliding threshold on player SlopeConfig to 89 degrees. Allows walking up sheer cliffs and mountain slopes without sliding.",
      "control": "checkbox"
    },
    "altarBuildRadiusMultiplier": {
      "value": 100,
      "label": "Flame Altar Build Radius Multiplier %",
      "description": "Expands protected building radius per Flame Altar level (100% = vanilla up to 1000% / 320m). Requires game restart.",
      "control": "slider",
      "min": 100,
      "max": 1000,
      "step": 50
    },
    "unlimitedFlameAltars": {
      "value": true,
      "label": "Unlimited Flame Altars",
      "description": "Sets maximum active Flame Altars per flame level to 255 and removes placement slot requirements. Place unlimited bases across the map.",
      "control": "checkbox"
    },
    "comfortBuffMultiplier": {
      "value": 1,
      "label": "Comfort Rested Buff Multiplier",
      "description": "Scales rested buff duration from shelter comfort (1x = vanilla up to 100x). Requires game restart.",
      "control": "slider",
      "min": 1,
      "max": 100,
      "step": 1
    },
    "shroudTimeMultiplier": {
      "value": 1,
      "label": "Shroud Fog Time Multiplier",
      "description": "Extends authoritative player base fog resistance duration (1x = 90s, up to 100x / ~2.5 hrs). Requires game restart.",
      "control": "slider",
      "min": 1,
      "max": 100,
      "step": 1
    },
    "extraChestSlots": {
      "value": true,
      "label": "Extra Chest Slots (160 Slots per Storage)",
      "description": "Expands storage capacity of all crafted storage chests to 160 slots (20 rows). Requires game restart.",
      "control": "checkbox"
    },
    "maxStackSize": {
      "value": 9500,
      "label": "Max Item & Ammo Stack Size",
      "description": "Sets maximum inventory stack size for all stackable items, ores, ammo, and arrows up to 9,999 (0 = default stack sizes). Requires game restart.",
      "control": "slider",
      "min": 0,
      "max": 9999,
      "step": 50
    },
    "rakeAnywhere": {
      "value": false,
      "label": "Terraform Rake Everywhere (No Base Required)",
      "description": "Clears build-zone restrictions on rakes. Allows terraforming and leveling terrain anywhere in the world.",
      "control": "checkbox"
    },
    "cheatBestBackpack": {
      "value": true,
      "label": "Unlock Best Tier 3 Backpack Recipe",
      "description": "Redirects backpack crafting recipes to create the Tier 3 +32 slot backpack for 1 simple ingredient. Requires game restart.",
      "control": "checkbox"
    },
    "fastTravelAllMarkers": {
      "value": true,
      "label": "Fast Travel to All Map Markers",
      "description": "Unlocks direct fast travel teleportation to all shrines, obelisks, dungeons, and POIs across the map. Requires game restart.",
      "control": "checkbox"
    },
    "freeSkillTree": {
      "value": true,
      "label": "Free Skill Tree Node Perks",
      "description": "Sets skill point costs of all skill tree nodes to 0 and grants bonus SP per level in BalancingTable. Requires game restart.",
      "control": "checkbox"
    }
  },
  "groups": [
    {
      "label": "Movement & Physics Patches",
      "description": "Static player template locomotion patches applied on game startup.",
      "settings": [
        "movementSpeedMultiplier",
        "jumpHeightMultiplier",
        "noSlopeSlide"
      ]
    },
    {
      "label": "Base Building & Altar Patches",
      "description": "Flame Altar radius, placement count, comfort buff, and terraforming tools.",
      "settings": [
        "altarBuildRadiusMultiplier",
        "unlimitedFlameAltars",
        "comfortBuffMultiplier",
        "rakeAnywhere"
      ]
    },
    {
      "label": "Inventory, Storage & Stacks",
      "description": "Max item stack sizes up to 9,999, 160 chest slots, and best backpack recipe.",
      "settings": [
        "maxStackSize",
        "extraChestSlots",
        "cheatBestBackpack"
      ]
    },
    {
      "label": "Progression & Travel Patches",
      "description": "Fast travel destination flags, extended base shroud timer, and free skill tree nodes.",
      "settings": [
        "fastTravelAllMarkers",
        "shroudTimeMultiplier",
        "freeSkillTree"
      ]
    }
  ]
},
    presets: {
  "max_storage_stacks": {
    "name": "🎒 9999 Stacks & 160 Chest Slots",
    "desc": "Max 9,999 item & ammo stacks, 160 chest slots per storage box, and 1-ingredient Tier 3 Backpack recipe.",
    "values": {
      "maxStackSize": 9999,
      "extraChestSlots": true,
      "cheatBestBackpack": true,
      "unlimitedFlameAltars": true,
      "altarBuildRadiusMultiplier": 200,
      "noSlopeSlide": true,
      "freeSkillTree": true
    }
  },
  "mountain_climber": {
    "name": "🏔️ Mountain Climber & World Explorer",
    "desc": "Walk up 89° cliff walls without sliding, 200% movement speed, 150% jump height, and fast travel to all POIs.",
    "values": {
      "noSlopeSlide": true,
      "movementSpeedMultiplier": 200,
      "jumpHeightMultiplier": 150,
      "fastTravelAllMarkers": true,
      "unlimitedFlameAltars": true,
      "altarBuildRadiusMultiplier": 300,
      "shroudTimeMultiplier": 10
    }
  },
  "mega_base_builder": {
    "name": "🏰 Mega Base & Unlimited Altars",
    "desc": "320m Altar Build Radius, Unlimited Altars, Rake anywhere terraforming, 160 Chest Slots, and 100x Rested Buff.",
    "values": {
      "altarBuildRadiusMultiplier": 500,
      "unlimitedFlameAltars": true,
      "rakeAnywhere": true,
      "extraChestSlots": true,
      "comfortBuffMultiplier": 50,
      "maxStackSize": 9999,
      "freeSkillTree": true
    }
  },
  "vanilla": {
    "name": "🔄 Vanilla Defaults",
    "desc": "Resets all static asset patches to game defaults.",
    "values": {}
  }
}
  }
};

// Backwards compatibility pointer
window.BASE_EXTENDED_MOD_JSON = window.MOD_CONFIGS["sf-cheatmenu"].base;
window.PRESETS = window.MOD_CONFIGS["sf-cheatmenu"].presets;
