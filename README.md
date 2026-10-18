# SF Cheat Menu & Dedicated Server Tweaks for Enshrouded

[![Game: Enshrouded](https://img.shields.io/badge/Game-Enshrouded-d97706.svg)](https://store.steampowered.com/app/1203630/Enshrouded/)
[![Mod Loader: ShroudForge](https://img.shields.io/badge/Mod%20Loader-ShroudForge-854d0e.svg)](https://github.com/bonsaibauer/shroudforge)
[![Latest Release](https://img.shields.io/github/v/release/adromir/enshrouded-cheatmenu?color=blue)](https://github.com/adromir/enshrouded-cheatmenu/releases/latest)
[![Targets: Client & Server](https://img.shields.io/badge/Targets-Client%20%26%20Dedicated%20Server-22c55e.svg)](#installation)
[![Web Configurator: Live](https://img.shields.io/badge/Web%20Configurator-Live%20Editor-ff7a18.svg)](https://adromir.github.io/enshrouded-cheatmenu/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Author: Adromir](https://img.shields.io/badge/Author-Adromir-6366f1.svg)](https://github.com/adromir)

A feature-complete, modular cheat and quality-of-life mod for **Enshrouded**, designed specifically for the **ShroudForge** mod loader ecosystem.

It brings all trainer capabilities (such as those popular in WeMod) natively and safely into the game engine with **complete, synchronized support for Dedicated Servers (Windows & Linux/Proton Docker) as well as Singleplayer/Local Co-op**.

Instead of forced hardcoded values, all parameters are **fully customizable through interactive sliders and number inputs**, with strict adherence to Enshrouded's internal engine data types and safe maximum boundaries.

> 🌐 **Interactive Web Configurator Available:**  
> Create, edit, and export your custom `extended.mod.json` visually in your browser with real-time JSON preview, one-click presets, and direct download:  
> 👉 **[Open Live Web Configurator](https://adromir.github.io/enshrouded-cheatmenu/)**

---

## 🏛️ Hybrid Client-Server Architecture

This mod is built on a clean **Hybrid Client-Server** model designed for seamless cooperative multiplayer:

1. **Dedicated Server Authority (World Rules):**
   - The dedicated server authoritatively sets and replicates shared world parameters:
     - **Flame Altar Protected Radius Multiplier** (expanding base building boundaries up to 10x / 500m)
     - **Unlimited Flame Altars** (removes placement cap so players can build anywhere)
     - **Free Building Blocks** (construction hammer consumes 0 stone, wood, or materials)
     - **Ignore Structural Stability** (build floating castles, overhangs, and clipping structures)
     - **Free Flame Altar Upgrades** (upgrade altars to max level for 0 sparks or trophies)
     - **Universal Item Stack Sizes** (across all stackable resources, consumables, building blocks, ammo up to 32,767)
     - **Chest & Storage Container Capacities** (expanding storage boxes up to 96 slots)
     - **Item Durability Loss** (disabling durability degradation world-wide)
     - **Free Crafting & Recipe Costs** (server-controlled recipe costs preventing inventory desyncs)
     - **Unlock All Recipes** (instantly learn every crafting recipe and blueprint)
     - **Free Blacksmith Weapon Upgrades** (0 runes required to enhance weapons)
     - **XP & Drop Multipliers** (synchronized progression rates for all players)
     - **Global Enemy Aggressiveness** (optional server-wide enemy pacification or damage scaling)
     - **World Time & Workshop Speeds** (day/night freezing, workshop production, plant growth)

2. **Personal Client Freedom (Local F9 Menu):**
   - Individual players on the server can independently open their local ShroudForge menu (**F9**) to toggle personal options without imposing them on their teammates:
     - **God Mode / Infinite Health** & personal regeneration multipliers
     - **Red Shroud Immunity** (safely explore deadly red miasma zones regardless of flame level)
     - **Combat & Archery**: One-Hit Kill, Infinite Arrows/Ammo, Instant Bow Draw, Rapid Wand/Staff Casts
     - **Movement & Flight**: Building Fly Mode (zero-g hover), Infinite Gliding (zero sink & zero stamina), Jump Height (100%–1,000%), Movement Speed (100%–500%), Slope Mountain Walking (89.9°), Unlimited Grappling Hook (9,999m range)
     - **Exploration & Vision**: Clear Shroud Fog Vision (disables blinding volumetric fog), Reveal All Map Icons, Minimap Radar & Fog of War Discovery Multiplier (1x–50x)
     - **Teleportation**: Teleport to Active Map Marker Pin, Save & Teleport to Saved Waypoints (Slot 1)
     - **Item Spawner**: Generate any item template (materials, legendary weapons, armor, blocks) directly into backpack with quantity slider
     - **Item Quantity Editor**: Custom stack override when dragging or splitting items (up to 32,767)
     - **Infinite Stamina & Infinite Mana** with custom regen rates
     - **Personal Damage Multipliers** (Crit, Melee, Ranged, Magic)
     - **Personal Stealth: "Enemies Ignore Me"** (sets personal threat to zero so enemies ignore you while allowing teammates to fight normally)
     - **Personal Backpack Storage Expansion** (unlocking extra inventory rows up to 96 slots without modifying equipment/action bars)
     - **Free Skill Respec Anywhere** (reset skill tree on the go for 0 runes without visiting a Flame Altar)

---

## 🛠️ Feature Overview & Configurable Bounds

### 1. Personal Player Attributes & Defense
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Infinite Health (God Mode)** | Checkbox | On / Off | Clamps `Health_Min` to `Health_Max`. Player cannot die or lose HP. |
| **Health Regen Multiplier** | Slider | 1x – 500x (step: 5) | Scales `Health_Recharge` attribute up to engine ceiling (65,536). |
| **Infinite Stamina** | Checkbox | On / Off | Locks `Stamina_Min` to max; disables stamina drain for running, jumping, and climbing. |
| **Stamina Regen Multiplier** | Slider | 1x – 500x (step: 5) | Scales natural stamina recharge rate up to 65,536. |
| **Infinite Mana** | Checkbox | On / Off | Locks `Mana_Min` to max; spells and abilities cost zero mana. |
| **Mana Regen Multiplier** | Slider | 1x – 500x (step: 5) | Multiplies natural mana recovery rate up to 65,536. |
| **Freeze Shroud Timer** | Checkbox | On / Off | Freezes the Miasma survival clock for indefinite shroud exploration. |
| **Red Shroud Immunity** | Checkbox | On / Off | Grants complete immunity against deadly red lethal shroud zones, allowing exploration everywhere regardless of flame level. |
| **Max Comfort Level** | Checkbox | On / Off | Instantly maxes out comfort buff level (100). |
| **Custom Comfort Level** | Slider | 0 – 100 (step: 1) | Fine-tune your desired comfort level (0 = original game comfort). |
| **No Hypothermia** | Checkbox | On / Off | Clamps `BodyHeat_Min` to max; immune to freezing in icy mountains. |
| **Infinite Oxygen** | Checkbox | On / Off | Clamps `Oxygen_Min` to max; unlimited underwater diving breath. |
| **Infinite Focus** | Checkbox | On / Off | Maintains full focus meter for special abilities and spell casting. |
| **Enemies Ignore Me (Zero Threat)** | Checkbox | On / Off | Zeroes your personal threat and target priority so monsters ignore you without pacifying them for teammates. |
| **Custom Backpack Slots** | Checkbox + Slider | 16 – 96 slots (step: 8) | Unlocks player backpack storage slots (8 slots per row, up to 12 rows) without modifying equipment slots. |

### 2. Combat, Archery & Magic Spells
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Critical Hit Chance %** | Slider | 0% – 100% (step: 1%) | Adds a flat critical strike chance percentage up to 100%. |
| **Critical Damage %** | Slider | 100% – 2000% (step: 25%) | Scales critical strike damage multiplier (100% = normal, up to 20x). |
| **Melee Damage %** | Slider | 100% – 2000% (step: 25%) | Scales melee weapon attack damage (100% = normal, up to 20x). |
| **Ranged Damage %** | Slider | 100% – 2000% (step: 25%) | Scales bows and thrown weapon damage (100% = normal, up to 20x). |
| **Magic Damage %** | Slider | 100% – 2000% (step: 25%) | Scales staves, wands, and magic spell damage (100% = normal, up to 20x). |
| **One-Hit Kill** | Checkbox | On / Off | Instantly deals lethal infinite damage to all hit enemies and bosses. |
| **Infinite Arrows & Ammo** | Checkbox | On / Off | Disables ammunition consumption (`consumeAmmo = false`); fire arrows without depleting quivers. |
| **Instant Bow Draw** | Checkbox | On / Off | Zeroes bow charge time (`chargeTime = 0.0`) and draw delay for rapid-fire archery. |
| **Rapid Wand & Staff Cadence** | Checkbox | On / Off | Removes wand cast cooldown (`cooldown = 0.0`) and recovery delay for rapid spellcasting barrages. |

### 3. Movement, Flight & Navigation
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Building Fly Mode** | Checkbox | On / Off | Disables gravity (`keen::ecs::Gravity.isActive = false`) and zeroes vertical force, enabling mid-air hover and free flight for architectural building. |
| **Infinite Gliding** | Checkbox | On / Off | Zeroes glider stamina drain (`StaminaDepletionMod_Glider = 0`) and eliminates downward sink rate, allowing indefinite soaring across Embervale. |
| **Jump Height %** | Slider | 100% – 1000% (step: 25%) | Dynamically scales `jumpHeight` and `jumpDistance` in `keen::ecs::JumpParameters` (100% = default, up to 10x super jumps). |
| **Movement Speed %** | Slider | 100% – 500% (step: 10%) | Adjusts walking, running, and sprinting velocities via `keen::ecs::Movement` and `keen::ecs::ClientLocomotion` (100% = normal, up to 5x speed). |
| **Slope Walking** | Checkbox | On / Off | Adjusts `steepFloorAngle` and `slidingAngle` in `keen::ecs::SlopeConfig` to 89.9°, allowing you to walk straight up the steepest mountains without slipping or sliding. |
| **Unlimited Grappling Hook** | Checkbox | On / Off | Sets grapple latch range to 9,999m and removes all grapple stamina costs. |
| **Teleport to Map Marker Pin** | Checkbox | On / Off | Reads active waypoint marker coordinates on the map and teleports your character directly to it. |
| **Save / Teleport Waypoint Slot 1** | Checkbox | On / Off | Saves your current 3D coordinates into Slot 1 and allows instant teleportation back at any time. |
| **Key Location Fast Travel** | Checkbox | On / Off | Facilitates teleportation and waypoint fast travel across the map. |

### 4. Base Building & Construction
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Flame Altar Build Radius** | Slider | 1x – 10x (step: 1) | Multiplies the protected building boundary radius of all Flame Altars (up to 500m radius). |
| **Unlimited Flame Altars** | Checkbox | On / Off | Removes altar placement limit (`maxFlameAltars = 9999`), allowing unlimited bases across the map. |
| **Free Building Blocks** | Checkbox | On / Off | Construction Hammer consumes zero blocks, stone, wood, or materials when placing structures. |
| **Ignore Structural Stability** | Checkbox | On / Off | Disables structural integrity checks, allowing floating structures, steep overhangs, and clipping placement. |
| **Free Flame Altar Upgrades** | Checkbox | On / Off | Upgrading the Flame Altar requires zero Sparks, Shroud Cores, or trophy materials. |

### 5. Inventory, Stacks & Item Spawner
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Infinite Durability** | Checkbox | On / Off | Disables weapon, shield, and tool wear via `ecs::GameSettings.enableDurability`. |
| **Free Crafting** | Checkbox | On / Off | Server-authoritative recipe unlock allowing crafting with zero material costs. |
| **Unlock All Recipes** | Checkbox | On / Off | Unlocks every crafting recipe, workbench blueprint, furniture piece, and equipment schematic in the game. |
| **Item Drop Multiplier** | Slider | 1x – 100x (step: 1) | Multiplies item drop yields from mining, logging, harvesting, and enemy drops. |
| **Stack Size Mode** | Dropdown | Multiplier / Custom / Max | Universal stack scaling across materials, consumables, building blocks, and ammo. |
| **Stack Size Multiplier** | Slider | 1x – 100x (step: 1) | Multiplies `maxStackSize` on `keen::ItemInfo` up to engine limit. |
| **Custom Stack Size** | Slider | 10 – 32,767 (step: 50) | Set an exact maximum stack size for all items (capped at safe 32,767 `u16`). |
| **Edit Dragged Item Quantity** | Checkbox | On / Off | Intercepts dragged, transferred, and split item stacks to override their count. |
| **Dragged Item Quantity** | Slider | 1 – 32,767 (step: 10) | Exact stack count applied to dragged items (safe 16-bit integer boundary). |
| **Custom Chest Slots** | Checkbox + Slider | 16 – 96 slots (step: 8) | Expands storage capacity for all chests, magic chests, and containers (8 slots per row). |
| **Free Weapon Upgrades** | Checkbox | On / Off | Upgrading and enhancing weapons at the Blacksmith costs zero Runes. |
| **Instant Max Weapon Perks** | Checkbox | On / Off | Unlocks all hidden enchantment traits and perk nodes on weapons to maximum level. |
| **Item Spawner** | Catalog + Slider + Button | Category, Item & Count | Generates any selected item template directly into your backpack (1 to 32,767 items). |

### 6. World, Server & Economy Rules
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **XP Multiplier** | Slider | 1x – 100x (step: 1) | Scales earned XP from combat, quest completions, and resource mining. |
| **Free Skill Tree Perks** | Checkbox | On / Off | Sets `perkCostFactor = 0.0`. All skills cost 0 points for instant learning. |
| **Free Skill Respec Anywhere** | Checkbox | On / Off | Reset your skill tree directly from the character menu at 0 rune cost without visiting a Flame Altar. |
| **Shroud Time Multiplier** | Slider | 1x – 100x (step: 1) | Multiplies allowable shroud timer duration via `shroudTimeFactor`. |

### 7. World Enemy AI & Combat Balance
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Pacify World Enemies** | Checkbox | On / Off | Completely pacifies enemies world-wide, sets perception to 0, and negates player threat. |
| **Enemy Perception Range %** | Slider | 0% – 200% (step: 5%) | Adjusts how far enemies can spot players (0% = completely blind). |
| **Enemy Damage %** | Slider | 0% – 200% (step: 5%) | Scales enemy damage output (0% = enemies deal 0 damage, up to 2x). |

### 8. World Time, Radar & Exploration Vision
| Feature | Control Type | Range / Options | Engine Limit & Technical Details |
|---|---|---|---|
| **Freeze Time of Day** | Checkbox | On / Off | Stops the sun and moon progression at the current hour. |
| **Game Speed %** | Slider | 50% – 300% (step: 5%) | Adjusts global timescale (slow-motion 50% to fast-forward 300%). |
| **Production Speed Multiplier** | Slider | 1x – 50x (step: 1) | Accelerates kilns, furnaces, drying racks, and workbenches. |
| **Plant Growth Multiplier** | Slider | 1x – 50x (step: 1) | Accelerates farm crops, seedlings, and tree growth. |
| **Clear Shroud Vision** | Checkbox | On / Off | Clears thick, blinding volumetric fog inside the Shroud for panoramic clarity. |
| **Reveal All Map Icons** | Checkbox | On / Off | Unmasks all Spires, Flame Shrines, Elixir Wells, Obelisks, and POIs across the entire map. |
| **Fog of War Reveal Multiplier** | Slider | 1x – 50x (step: 1) | Scales `discoveryRange` in `keen::ecs::FogOfWarDiscovery`, unfogging vast territories around your player on the world map and radar. |
| **Enhanced Compass Radar** | Checkbox | On / Off | Expands HUD compass radar detection radius to maximum, revealing all nearby points of interest and landmarks. |

---

## 💻 Installation

### 🚀 One-Click Quick Install (Recommended)

You can install both **ShroudForge** and **SF Cheat Menu** in seconds using an automated one-liner in your terminal. The installer automatically discovers your Enshrouded game or dedicated server folder across all Steam drives, installs ShroudForge if missing, downloads the latest mod release, and preserves any existing custom configurations.

#### Windows (PowerShell)
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.ps1 | iex
```
> [!TIP]
> **Custom Path or Dedicated Server:**
> You can pass an explicit target path or point to a dedicated server directory:
> ```powershell
> & { irm https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.ps1 | iex } -TargetDir "D:\SteamLibrary\steamapps\common\Enshrouded"
> ```

#### Linux / SteamOS / Steam Deck / Dedicated Server (Bash)
Open a terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.sh | bash
```
> [!TIP]
> **Custom Path:**
> ```bash
> curl -fsSL https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.sh | bash -s -- /path/to/Enshrouded
> ```

> [!IMPORTANT]
> **Steam Deck & Linux Proton Setup:**
> Because Proton and Wine disable custom native DLLs by default, you must enable the DLL override:
> - **In Steam (Steam Deck / Desktop Linux):** Right-click **Enshrouded** → **Properties** → **General** → **Launch Options**:
>   ```
>   WINEDLLOVERRIDES="winmm=n,b" %command%
>   ```
> - **Headless Dedicated Server (Wine / Docker):**
>   ```bash
>   export WINEDLLOVERRIDES="winmm=n,b"
>   ```

---

### 📦 Manual Installation

#### 1. Client / Singleplayer / Co-op Host
1. Install **ShroudForge** into your main Enshrouded directory (next to `enshrouded.exe`).
2. Copy the entire `sf-cheatmenu` directory into your `mods` folder:
   ```
   <Enshrouded Directory>/mods/sf-cheatmenu/
   ```
3. Launch Enshrouded via Steam.
4. Press **F9** in-game to open the ShroudForge Mod Manager.
5. Expand **SF Cheat Menu & Server Tweaks** to adjust sliders and toggle features on the fly.

#### 2. Windows Dedicated Server
1. Install ShroudForge into your dedicated server directory (next to `enshrouded_server.exe`).
2. Copy `sf-cheatmenu` into the server's `mods` folder:
   ```
   <Server Directory>/mods/sf-cheatmenu/
   ```
3. Configure your desired server defaults in `extended.mod.json` (see preset below) or launch the ShroudForge desktop configurator:
   ```powershell
   .\shroudforge\shroudforge.exe --root "C:\Path\To\Server" --desktop --target server
   ```
4. Start `enshrouded_server.exe` normally.
5. Server diagnostic logs are located at `shroudforge/logs/shroudforge-server.log`.

#### 3. Linux / Docker Dedicated Server (Proton)
1. Mount the ShroudForge files and `mods/sf-cheatmenu/` into your server container.
2. Ensure `WINEDLLOVERRIDES="winmm=n,b"` is set in your container's environment variables.
3. Restart the container.

---

## ⚙️ Dedicated Server Configuration Preset (`extended.mod.json`)

When running on a **Dedicated Server (Windows or Linux/Proton)**, ShroudForge operates headlessly without an in-game graphical overlay. Instead, the server authoritatively loads all world rules and cheat defaults directly from:

```
<Server Directory>/mods/sf-cheatmenu/extended.mod.json
```

All values configured under `"settings"` are automatically synchronized to every player that joins the server.

---

### 📋 Complete Server Settings Reference

The table below lists **every setting that can be configured authoritatively on a dedicated server**, including their JSON keys, expected data types, default values, minimums, maximums, and engine constraints:

| Category | JSON Key (`settings.<key>.value`) | Type | Default | Min | Max | Step | Technical Description & Engine Limits |
|---|---|---|---|---|---|---|---|
| **Base Building** | `altarRadiusMultiplier` | `number` | `1` | `1` | `10` | `1` | Multiplies the protected building boundary radius of all Flame Altars (1x default up to 10x / 500m radius max). |
| **Base Building** | `unlimitedFlameAltars` | `boolean` | `false` | `false` | `true` | — | Removes global altar placement limit (`maxFlameAltars = 9999`), allowing players to build unlimited bases. |
| **Base Building** | `freeBuildingBlocks` | `boolean` | `false` | `false` | `true` | — | Construction Hammer consumes 0 blocks, stone, wood, or materials when placing structures. |
| **Base Building** | `ignoreStructuralStability` | `boolean` | `false` | `false` | `true` | — | Disables structural integrity collapse; permits floating structures, extreme overhangs, and terrain clipping. |
| **Base Building** | `freeFlameUpgrades` | `boolean` | `false` | `false` | `true` | — | Upgrading the Flame Altar requires 0 Sparks, Shroud Cores, or boss trophy materials. |
| **Inventory & Stacks** | `stackSizeMode` | `string` | `"multiplier"` | — | — | — | Universal stack mode. Allowed values: `"multiplier"`, `"custom"`, or `"max"` (locks all items to 32,767). |
| **Inventory & Stacks** | `stackSizeMultiplier` | `number` | `1` | `1` | `100` | `1` | Multiplies `maxStackSize` on all items when `stackSizeMode` is set to `"multiplier"`. |
| **Inventory & Stacks** | `customStackSize` | `number` | `1000` | `10` | `32767` | `50` | Sets an exact universal stack size when `stackSizeMode` is set to `"custom"`. Engine safe ceiling is `32,767` (`u16`). |
| **Inventory & Stacks** | `enableCustomContainer` | `boolean` | `false` | `false` | `true` | — | Activates custom storage capacity for all placed and spawned chests and containers. |
| **Inventory & Stacks** | `customContainerSlots` | `number` | `64` | `16` | `96` | `8` | Storage slots for chests and boxes (8 slots per row; 16 = 2 rows, 64 = 8 rows, 96 = 12 rows max). |
| **Crafting & Gear** | `infiniteDurability` | `boolean` | `false` | `false` | `true` | — | Disables durability degradation world-wide for all weapons, shields, tools, and armor. |
| **Crafting & Gear** | `freeCrafting` | `boolean` | `false` | `false` | `true` | — | Server-authoritative recipe unlock allowing crafting at workbenches with zero material costs. |
| **Crafting & Gear** | `unlockAllRecipes` | `boolean` | `false` | `false` | `true` | — | Unlocks every crafting recipe, workbench blueprint, furniture piece, and equipment schematic. |
| **Crafting & Gear** | `freeWeaponUpgrades` | `boolean` | `false` | `false` | `true` | — | Upgrading and enhancing weapons at the Blacksmith costs zero Runes (`runeCostFactor = 0.0`). |
| **Crafting & Gear** | `maxWeaponPerks` | `boolean` | `false` | `false` | `true` | — | Automatically unlocks all hidden enchantment traits and perk nodes on newly found or crafted weapons. |
| **Progression & Economy**| `xpMultiplier` | `number` | `1` | `1` | `100` | `1` | Multiplies earned XP from combat, quest completions, and resource mining. |
| **Progression & Economy**| `itemAmountMultiplier` | `number` | `1` | `1` | `100` | `1` | Multiplies item drop yields from mining, logging, harvesting, and enemy drops. |
| **Progression & Economy**| `infiniteSkillPoints` | `boolean` | `false` | `false` | `true` | — | Sets `perkCostFactor = 0.0`. All skill tree nodes cost 0 skill points for instant learning. |
| **Progression & Economy**| `freeRespecAnywhere` | `boolean` | `false` | `false` | `true` | — | Allows players to reset their skill tree anytime directly from the character menu at 0 rune cost. |
| **Progression & Economy**| `shroudTimeMultiplier` | `number` | `1` | `1` | `100` | `1` | Multiplies allowable shroud timer duration via `shroudTimeFactor` (1x = standard, up to 100x). |
| **Progression & Economy**| `freezeShroudTimer` | `boolean` | `false` | `false` | `true` | — | Halts the Miasma survival clock world-wide for indefinite shroud exploration. |
| **Enemy AI & Difficulty** | `dumbEnemies` | `boolean` | `false` | `false` | `true` | — | Pacifies all enemies server-wide: sets perception to 0 and negates all player threat. |
| **Enemy AI & Difficulty** | `enemyPerceptionMultiplier`| `number`| `100` | `0` | `200` | `5` | Sight and detection range % of all monsters (100% = normal, 0% = completely blind, 200% = 2x). |
| **Enemy AI & Difficulty** | `enemyDamageMultiplier` | `number` | `100` | `0` | `200` | `5` | Scales damage output from all enemies (100% = default, 0% = zero damage, 200% = double damage). |
| **World Time & Stations**| `freezeTimeOfDay` | `boolean` | `false` | `false` | `true` | — | Stops the sun and moon cycle progression at the current server time. |
| **World Time & Stations**| `gameSpeed` | `number` | `100` | `50` | `300` | `5` | Game engine timescale percentage (50% slow-motion to 300% fast-forward). |
| **World Time & Stations**| `productionSpeedMultiplier`| `number` | `1` | `1` | `50` | `1` | Accelerates kilns, furnaces, drying racks, and workbenches (1x default up to 50x speed). |
| **World Time & Stations**| `plantGrowthMultiplier` | `number` | `1` | `1` | `50` | `1` | Accelerates farm crops, seedlings, and tree growth (1x default up to 50x speed). |

---

### 📦 Ready-to-Use Dedicated Server Preset

Here is a balanced, cooperative Quality-of-Life preset for dedicated servers that enhances building, storage, and crafting without breaking game progression:

```json
{
  "settings": {
    "altarRadiusMultiplier": { "value": 3 },
    "unlimitedFlameAltars": { "value": true },
    "freeBuildingBlocks": { "value": false },
    "ignoreStructuralStability": { "value": false },
    "freeFlameUpgrades": { "value": false },
    "infiniteDurability": { "value": true },
    "freeCrafting": { "value": false },
    "unlockAllRecipes": { "value": false },
    "freeWeaponUpgrades": { "value": true },
    "freeRespecAnywhere": { "value": true },
    "stackSizeMode": { "value": "custom" },
    "customStackSize": { "value": 5000 },
    "enableCustomContainer": { "value": true },
    "customContainerSlots": { "value": 64 },
    "itemAmountMultiplier": { "value": 2 },
    "xpMultiplier": { "value": 2 },
    "productionSpeedMultiplier": { "value": 5 },
    "plantGrowthMultiplier": { "value": 5 },
    "shroudTimeMultiplier": { "value": 2 },
    "freezeShroudTimer": { "value": false },
    "dumbEnemies": { "value": false },
    "enemyPerceptionMultiplier": { "value": 100 },
    "enemyDamageMultiplier": { "value": 100 },
    "freezeTimeOfDay": { "value": false },
    "gameSpeed": { "value": 100 }
  }
}
```

### 💡 How to Apply & Verify
1. Edit `<Server Directory>/mods/sf-cheatmenu/extended.mod.json` with your desired values.
2. Start or restart `enshrouded_server.exe`.
3. Check the server log file at `shroudforge/logs/shroudforge-server.log` to confirm initialization:
   ```
   [info] SF Cheat Menu & Server Tweaks v0.0.1 loaded. Initializing...
   [info] SF Cheat Menu: Updated stack size for 312 items (Mode: custom, Signature: custom:5000)
   [info] SF Cheat Menu: Updated container capacity for 14 chest templates (Slots: 64)
   ```

---

## ⚠️ Disclaimer
This modification is designed for private co-op servers, dedicated servers, and singleplayer exploration. Please use responsibly and obtain consent from fellow players when running cheat parameters on shared multiplayer servers.

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).

**Author:** [Adromir](https://github.com/adromir)  
**Website:** [https://github.com/adromir](https://github.com/adromir)
