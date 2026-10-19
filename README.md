# SF Cheat Menu & Dedicated Server Tweaks for Enshrouded

[![Game: Enshrouded](https://img.shields.io/badge/Game-Enshrouded-d97706.svg)](https://store.steampowered.com/app/1203630/Enshrouded/)
[![Mod Loader: ShroudForge](https://img.shields.io/badge/Mod%20Loader-ShroudForge-854d0e.svg)](https://github.com/bonsaibauer/shroudforge)
[![Latest Release](https://img.shields.io/github/v/release/adromir/enshrouded-cheatmenu?color=blue)](https://github.com/adromir/enshrouded-cheatmenu/releases/latest)
[![Targets: Client & Server](https://img.shields.io/badge/Targets-Client%20%26%20Dedicated%20Server-22c55e.svg)](#installation)
[![Web Configurator: Live](https://img.shields.io/badge/Web%20Configurator-Live%20Editor-ff7a18.svg)](https://adromir.github.io/enshrouded-cheatmenu/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Author: Adromir](https://img.shields.io/badge/Author-Adromir-6366f1.svg)](https://github.com/adromir)

A clean, high-performance, modular cheat and quality-of-life suite for **Enshrouded**, designed specifically for the **ShroudForge** and **EML** mod loader ecosystem.

The suite is cleanly separated into two distinct, specialized packages:
1. **`sf-cheatmenu` (Pure Live Runtime Menu):** In-game F9 cheat menu (`capabilities: ["runtime"]`) with a high-performance C++ native sidecar (`sf-native.dll` via `powrprof.dll`). Instant toggles in real-time, zero restart requirements, and never blocked on startup.
2. **`sf-cheatmenu-assets` (Static KFC Asset Patches):** Dedicated pregame asset patcher (`capabilities: ["patch"]`) compiling deep binary alterations into `enshrouded.kfc` for 9,999 item stacks, 160 chest slots, flame altar build radius, unlimited altars, and steep cliff walking.

> 🌐 **Interactive Web Configurator Available:**  
> Create, customize, and export your custom `extended.mod.json` visually in your browser for both packages with real-time JSON preview, one-click presets, and direct download:  
> 👉 **[Open Live Web Configurator](https://adromir.github.io/enshrouded-cheatmenu/)**

---

## ⚡ Package 1: `sf-cheatmenu` (Live Runtime Cheats)

Pure live in-game cheat menu operating dynamically via ECS attributes, `GameSettings` service overrides, and the C++ native sidecar. **Press F9 in-game to toggle all options instantly!**

### 1. Movement & Flight Cheats
| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **Infinite Gliding** | Checkbox | Off | Eliminates glider stamina consumption for indefinite flight across the map. |
| **No Fall Damage** | Checkbox | Off | Intercepts engine fall damage calculations (`fallDamage.infliction`). Immune to lethal falls from any height. |
| **Infinite Air-Jump / Multi-Jump** | Checkbox | Off | Bypasses the double-jump limit (`locomotion.airJumpGate` & counter reset). Unlimited jumps mid-air to ascend or fly. |
| **Creative Mode Hovering & Vertical Flight** | Checkbox | Off | Freezes vertical gravity degradation mid-air (`locomotion.fallSkip`) and enables smooth vertical ascent/descent. **Hotkey: Ctrl+H** (Space to ascend, C to descend). |
| **Hover Speed Multiplier %** | Slider (50%–500%) | 100% | Adjusts vertical ascent and descent flight speed. |

### 2. Player Attributes & God Mode
| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **Infinite Health (God Mode)** | Checkbox | Off | Clamps `Health_Min` to `Health_Max` and zeroes incoming enemy/boss damage factors in `GameSettings`. Total invincibility. |
| **Health Regen Multiplier** | Slider (1x–500x) | 1x | Scales `Health_Recharge` attribute up to the engine clamp (65,536). |
| **Infinite Stamina** | Checkbox | Off | Locks `Stamina_Min` to maximum; completely disables stamina drain for sprinting, fighting, and climbing. |
| **Stamina Regen Multiplier** | Slider (1x–500x) | 1x | Multiplies natural stamina regeneration rate up to 65,536. |
| **Infinite Mana** | Checkbox | Off | Locks `Mana_Min` to maximum; spells, wands, and magical abilities consume zero mana. |
| **Mana Regen Multiplier** | Slider (1x–500x) | 1x | Multiplies natural mana recovery rate up to 65,536. |
| **Cold Immunity / No Hypothermia** | Checkbox | Off | Clamps `BodyHeat_Min` to `BodyHeat_Max`; eliminates freezing damage in snowy and mountain biomes. |
| **Infinite Oxygen / Diving Breath** | Checkbox | Off | Clamps `Oxygen_Min` to `Oxygen_Max`; unlimited underwater breathing without drowning. |
| **Infinite Consumables** | Checkbox | Off | Bypasses `consumables.usedRemoval`; potions, bandages, and food are never depleted upon consumption. |
| **Infinite Shroud Fog Timer** | Checkbox | Off | Bypasses engine fog checks (`debug_god_mode_fogresistance`) and sets `shroudTimeFactor = 10000.0`. Shroud time never decreases. |

### 3. Combat Amplifiers & Archery
| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **One-Hit Kill** | Checkbox | Off | Applies extreme multipliers across melee, ranged, magic, and crit channels for instant defeats. |
| **Critical Hit Chance %** | Slider (0%–100%) | 0% | Increases base critical strike probability via `CritChance`. |
| **Critical Damage %** | Slider (100%–2000%) | 100% | Scales critical strike damage multiplier via `CritDamageMod`. |
| **Melee Damage %** | Slider (100%–2000%) | 100% | Multiplies melee weapon attack damage via `MeleeDamageMod`. |
| **Ranged Damage %** | Slider (100%–2000%) | 100% | Multiplies bow and thrown weapon damage via `RangedDamageMod`. |
| **Magic Damage %** | Slider (100%–2000%) | 100% | Multiplies staff and wand spell damage via `MagicDamageMod`. |
| **Rapid Bow Draw Speed** | Checkbox | Off | Reduces bow draw duration in weapon definitions by 80% for rapid-fire archery. |
| **Infinite Arrows** | Checkbox | Off | Patches `consumables.firedRemoval` (+0x2208FD); zero arrows deducted from quiver when firing any bow. |

### 4. World Rules, Crafting & Durability (Server Authoritative)
| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **Infinite Item Durability** | Checkbox | Off | Sets `enableDurability = false` in `ecs::GameSettings` and patches `durability_loss`. Weapons, pickaxes, and armor never break. |
| **Free Crafting & Building** | Checkbox | Off | Patches native `actor.payUsageCost` (+0x223440) and zeroes recipe inputs. Build with the hammer or craft without materials. |
| **Unlock All Blueprints** | Checkbox | Off | Unlocks all hidden crafting blueprints and station recipes safely without recipe corruption. |
| **Free Reskill** | Checkbox | Off | Sets respec perk costs to 0; reset your skill tree freely at any Flame Altar. |
| **Resource Drop Multiplier** | Slider (1x–100x) | 1x | Multiplies harvest, mining, and enemy drop quantities via `resourceDropStackAmountFactor`. |

### 5. World Difficulty, XP & Production
| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **Pacify World Enemies** | Checkbox | Off | Sets `pacifyAllEnemies = true`, `threatBonus = -9999.0`, and neutralizes enemy aggro. |
| **Enemy Perception Multiplier %** | Slider (0%–200%) | 100% | Fine-tunes enemy detection and vision cone radius (`enemyPerceptionRangeFactor`). |
| **XP Multiplier** | Slider (1x–100x) | 1x | Multiplies XP gains across combat, exploration, quests, and mining (`experienceCombatFactor` etc.). |
| **Production Speed Multiplier** | Slider (1x–50x) | 1x | Accelerates smelting, kilns, and drying racks via `factoryProductionSpeedFactor`. |
| **Plant Growth Multiplier** | Slider (1x–50x) | 1x | Speeds up crop and seedling development via `plantGrowthSpeedFactor`. |

---

## 📦 Package 2: `sf-cheatmenu-assets` (Static KFC Patches)

Dedicated pregame asset patcher (`capabilities: ["patch"]`) compiled during startup into `enshrouded.kfc` via `shroudforge prepare`.

| Feature | Control | Default | Technical Details |
|---|---|---|---|
| **Max Item & Ammo Stack Size** | Slider (0–9999) | 9500 | Overrides `maxStackSize` on all stackable items, ores, ammo, and arrows up to 9,999. |
| **Extra Chest Storage Slots (160 Slots)** | Checkbox | On | Expands capacity of all crafted storage chests to 160 slots (20 rows) via `keen::ecs::InventorySetup`. |
| **Walk on Steep Slopes (No Slope Slide)** | Checkbox | On | Adjusts `SlopeConfig.slopeDefinition` angles to 89°. Run up sheer vertical cliffs and mountains without sliding. |
| **Movement Speed Multiplier %** | Slider (100%–500%) | 100% | Scales player baseline run and sprint locomotion on `keen::ecs::Movement.dataStorage[5/6]`. |
| **Jump Height Multiplier %** | Slider (100%–500%) | 100% | Multiplies vertical jump launch height on `keen::ecs::JumpParameters.jumpHeight`. |
| **Flame Altar Build Radius %** | Slider (100%–1000%) | 100% | Expands base protection zone in `BalancingTable.buildzoneSizesPerAltarLevel` up to 320m. |
| **Unlimited Flame Altars Placement** | Checkbox | On | Sets `altarsPerFlameLevel = 255` and clears `requiresAltarSlot` from Flame Altar items. Build unlimited bases. |
| **Comfort & Rested Buff Multiplier** | Slider (1x–100x) | 1x | Multiplies `comfortSetup.base` and `factor` in `BalancingTable` for hours of shelter rested buff. |
| **Extended Base Shroud Timer** | Slider (1x–100x) | 1x | Extends authoritative `playerBaseFogResistance` in `BalancingTable` (1x = 90s, up to ~2.5 hours). |
| **Terraform Rake Everywhere** | Checkbox | Off | Clears `buildZoneRequired` and placement restrictions on rakes. Level terrain anywhere in the world. |
| **Unlock Best Tier 3 Backpack** | Checkbox | On | Directs backpack crafting recipes to create the Tier 3 +32 slot backpack for 1 simple ingredient. |
| **Fast Travel to All Map Markers** | Checkbox | On | Sets `isFastTravelDestination = true` on shrines, obelisks, dungeons, and POIs across the map. |
| **Free Skill Tree Node Perks** | Checkbox | On | Sets skill node costs to 0 and grants 10 skill points per level in `SkillTreeResource` / `BalancingTable`. |

---

## 📂 Repository Structure

Both mods are cleanly separated as dedicated top-level packages:

```text
enshrouded-cheatmenu/
├── sf-cheatmenu/                <-- Package 1: Live In-Game Cheat Menu (F9) & Runtime Sidecar
│   ├── mod.json                 <-- ShroudForge manifest (capabilities: ["runtime"])
│   ├── extended.mod.json        <-- 33 configurable live cheats
│   ├── icon.svg                 <-- In-game mod icon
│   ├── src/
│   │   └── mod.lua              <-- Live runtime script (ECS attributes & GameSettings)
│   └── native/                  <-- C++ Native Sidecar & Proxy Source Code
│       ├── include/             <-- Hooking & pattern scan headers
│       ├── src/                 <-- Trampoline hooks, memory patches, hover physics
│       ├── proxy/               <-- powrprof.dll proxy export forwarder
│       ├── build.ps1            <-- Local Clang++ compilation script
│       └── native-plugin.ini    <-- ShroudForge native plugin definition
├── sf-cheatmenu-assets/         <-- Package 2: Static KFC World & Inventory Patches
│   ├── mod.json                 <-- ShroudForge manifest (capabilities: ["patch"])
│   ├── extended.mod.json        <-- 13 static asset patches (stacks, chests, altars, slope)
│   ├── icon.svg                 <-- Asset mod icon
│   └── src/
│       └── mod.lua              <-- Pregame asset pass (Template & BalancingTable mutations)
├── docs/                        <-- Interactive Web Configurator (GitHub Pages)
│   ├── index.html
│   ├── app.js
│   ├── schema-data.js
│   └── style.css
├── .github/workflows/
│   └── release.yml              <-- Multi-package CI/CD release pipeline
├── install.ps1                  <-- One-click automated installer for Windows
├── install.sh                   <-- One-click automated installer for Linux / SteamOS
├── README.md
└── LICENSE
```

---

## 🚀 Installation


### Option A: One-Click Automated Installer (Recommended)

#### Windows (PowerShell)
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.ps1 | iex
```
*The installer automatically locates your Enshrouded folder across all Steam libraries, installs ShroudForge if needed, deploys both packages and the native sidecar, and compiles the static asset patches.*

#### Linux / SteamOS / Steam Deck (Bash)
Open a terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.sh | bash
```

---

### Option B: Manual Installation (All-in-One Bundle)

1. Install [ShroudForge](https://github.com/bonsaibauer/shroudforge).
2. Download `sf-cheatmenu-bundle-v*.zip` from the [Releases](https://github.com/adromir/enshrouded-cheatmenu/releases) page.
3. Extract the contents directly into your Enshrouded game root directory:
   ```text
   <Enshrouded Game Directory>/
   ├── powrprof.dll               <-- Native proxy loader (in game root)
   └── mods/
       ├── sf-cheatmenu/          <-- Live Runtime Cheat Menu
       └── sf-cheatmenu-assets/   <-- Static KFC Asset Patches
   ```
4. **Linux / Steam Deck / Proton Users:**  
   Set Launch Options in Steam (**Enshrouded -> Properties -> General -> Launch Options**):
   ```bash
   WINEDLLOVERRIDES="powrprof=n,b;winmm=n,b" %command%
   ```
5. Launch the game and press **F9** in-game to open the cheat menu!

---

### Option C: Dedicated Server Setup (Windows, Linux, Docker & Wine)

Dedicated servers run headless and do not render a GUI. The suite runs in pure Lua runtime mode on the server:
1. Copy the `mods/sf-cheatmenu` (and optionally `mods/sf-cheatmenu-assets`) folders into the server's `mods` folder:
   ```text
   <Server Root Directory>/mods/sf-cheatmenu/
   ```
2. **Server Safety:** Do **not** place `powrprof.dll` into dedicated server directories. (If placed by mistake, built-in process detection detects `enshrouded_server.exe` and disables client native hooks automatically).
3. **Configure Server Rules:** Open `<Server Root>/mods/sf-cheatmenu/extended.mod.json` or configure it via the [Web Configurator](https://adromir.github.io/enshrouded-cheatmenu/).
4. Launch `enshrouded_server.exe`. All connected players automatically inherit the authoritative server rules (XP, drops, free crafting, durability).

---

## ⚠️ Disclaimer

This modification is intended for single-player exploration, creative building, and private cooperative servers. Use responsibly in multiplayer environments. Always back up your save games before applying major world or inventory alterations.

---

## 📄 License & Credits

- **Author:** [Adromir](https://github.com/adromir)  
- **Website:** [https://github.com/adromir](https://github.com/adromir)  
- **Web Configurator:** [https://adromir.github.io/enshrouded-cheatmenu/](https://adromir.github.io/enshrouded-cheatmenu/)  
- **License:** [MIT License](LICENSE)
