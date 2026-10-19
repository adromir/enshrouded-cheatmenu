#!/usr/bin/env bash
# ==============================================================================
# Enshrouded Cheat Menu & ShroudForge One-Click Installer (Linux / SteamOS / Wine)
# Author: Adromir (https://github.com/adromir) | Version: 0.0.1
# ==============================================================================

set -euo pipefail

# Color palette
C_RESET='\033[0m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_MAGENTA='\033[0;35m'
C_GRAY='\033[0;90m'

print_step()    { printf "${C_CYAN}\n[*] %s${C_RESET}\n" "$1"; }
print_success() { printf "${C_GREEN}[+] %s${C_RESET}\n" "$1"; }
print_warn()    { printf "${C_YELLOW}[!] %s${C_RESET}\n" "$1"; }
print_err()     { printf "${C_RED}[-] %s${C_RESET}\n" "$1"; }

print_banner() {
    printf "${C_MAGENTA}================================================================${C_RESET}\n"
    printf "${C_MAGENTA}     Enshrouded Cheat Menu & ShroudForge One-Click Installer    ${C_RESET}\n"
    printf "${C_MAGENTA}         Author: Adromir  |  Platform: Linux / SteamOS         ${C_RESET}\n"
    printf "${C_MAGENTA}================================================================${C_RESET}\n"
}

# HTTP Downloader (curl or wget)
download_file() {
    local url="$1"
    local output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$output" "$url"
    else
        print_err "Neither 'curl' nor 'wget' was found. Please install one of them."
        exit 1
    fi
}

# Safe Zip Extractor (unzip or python3)
extract_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    mkdir -p "$dest_dir"

    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$zip_file" -d "$dest_dir"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m zipfile -e "$zip_file" "$dest_dir"
    else
        print_err "Neither 'unzip' nor 'python3' was found. Please install unzip."
        exit 1
    fi
}

# Fetch GitHub Release Asset URL
fetch_release_asset() {
    local repo="$1"
    local pattern="$2"
    local static_url="$3"
    local static_version="$4"

    local asset_url=""
    local tag_name=""

    # Layer 1: GitHub REST API
    if command -v curl >/dev/null 2>&1; then
        local api_json
        api_json=$(curl -fsSL -H "User-Agent: Enshrouded-CheatMenu-Installer/2.0" "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || true)
        if [ -n "$api_json" ]; then
            asset_url=$(echo "$api_json" | grep -o "https://github.com/${repo}/releases/download/[^\"]*${pattern}[^\"]*\.zip" | grep -v '\.sha256' | head -n1 || true)
            tag_name=$(echo "$api_json" | grep -o '"tag_name": *"[^"]*"' | head -n1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)
        fi
    fi

    # Layer 2: HTTP Redirect fallback
    if [ -z "$asset_url" ] && command -v curl >/dev/null 2>&1; then
        local redirect_url
        redirect_url=$(curl -sI -o /dev/null -w '%{redirect_url}' "https://github.com/${repo}/releases/latest" 2>/dev/null || true)
        if [ -n "$redirect_url" ]; then
            tag_name="${redirect_url##*/}"
            if [ "$repo" = "adromir/enshrouded-cheatmenu" ]; then
                asset_url="https://github.com/${repo}/releases/download/${tag_name}/sf-cheatmenu-${tag_name}.zip"
            fi
        fi
    fi

    # Layer 3: Pinned Static Fallback
    if [ -z "$asset_url" ]; then
        asset_url="$static_url"
        tag_name="$static_version"
    fi

    printf "%s %s" "$tag_name" "$asset_url"
}

# Locate Enshrouded Installation
find_enshrouded_dir() {
    local explicit="${1:-}"

    # 1. Explicit argument
    if [ -n "$explicit" ] && [ -d "$explicit" ]; then
        echo "$explicit"
        return 0
    fi

    # 2. Environment variable
    if [ -n "${ENSHROUDED_DIR:-}" ] && [ -d "$ENSHROUDED_DIR" ]; then
        echo "$ENSHROUDED_DIR"
        return 0
    fi
    if [ -n "${ENSHROUDED_PATH:-}" ] && [ -d "$ENSHROUDED_PATH" ]; then
        echo "$ENSHROUDED_PATH"
        return 0
    fi

    # 3. Current directory
    if [ -f "./enshrouded.exe" ] || [ -f "./enshrouded_server.exe" ]; then
        pwd
        return 0
    fi

    # 4. Standard Linux / SteamOS / Steam Deck paths
    local candidate_paths=(
        "${HOME}/.steam/steam/steamapps/common/Enshrouded"
        "${HOME}/.steam/steam/steamapps/common/EnshroudedServer"
        "${HOME}/.local/share/Steam/steamapps/common/Enshrouded"
        "${HOME}/.local/share/Steam/steamapps/common/EnshroudedServer"
        "${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps/common/Enshrouded"
        "${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Enshrouded"
        "/steamapps/common/Enshrouded"
        "/steamapps/common/EnshroudedServer"
        "/home/steam/enshrouded-server"
        "/home/steam/enshrouded"
        "/opt/enshrouded"
        "/opt/enshrouded-server"
    )

    for p in "${candidate_paths[@]}"; do
        if [ -d "$p" ] && ([ -f "$p/enshrouded.exe" ] || [ -f "$p/enshrouded_server.exe" ]); then
            echo "$p"
            return 0
        fi
    done

    # 5. Search Steam libraryfolders.vdf (for MicroSD / second drive on Steam Deck)
    local vdf_files=(
        "${HOME}/.steam/steam/steamapps/libraryfolders.vdf"
        "${HOME}/.local/share/Steam/steamapps/libraryfolders.vdf"
        "${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps/libraryfolders.vdf"
    )

    for vdf in "${vdf_files[@]}"; do
        if [ -f "$vdf" ]; then
            while IFS= read -r line; do
                if echo "$line" | grep -q '"path"'; then
                    local lib_path
                    lib_path=$(echo "$line" | sed -E 's/.*"path"[[:space:]]+"([^"]+)".*/\1/')
                    local test_p="${lib_path}/steamapps/common/Enshrouded"
                    if [ -d "$test_p" ] && [ -f "$test_p/enshrouded.exe" ]; then
                        echo "$test_p"
                        return 0
                    fi
                fi
            done < "$vdf"
        fi
    done

    return 1
}

# --- Main Script ---
print_banner

TARGET_ARG="${1:-}"
FORCE_SF="${FORCE_SHROUDFORGE:-0}"

print_step "Detecting Enshrouded installation..."

TARGET_DIR=""
if TARGET_DIR=$(find_enshrouded_dir "$TARGET_ARG"); then
    print_success "Found Enshrouded directory: $TARGET_DIR"
else
    if [ -t 0 ]; then
        print_warn "Could not automatically locate Enshrouded installation."
        read -r -p "Please enter the full path to your Enshrouded directory: " USER_INPUT
        if [ -d "$USER_INPUT" ]; then
            TARGET_DIR="$USER_INPUT"
        fi
    fi
fi

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
    print_err "Enshrouded directory not found!"
    printf "\n${C_YELLOW}Usage:${C_RESET}\n"
    printf "  curl -fsSL https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.sh | bash -s -- /path/to/Enshrouded\n"
    printf "  Or: ENSHROUDED_DIR=/path/to/Enshrouded bash install.sh\n\n"
    exit 1
fi

# Verify / Install ShroudForge Mod Loader
SF_DLL="$TARGET_DIR/winmm.dll"
SF_DIR="$TARGET_DIR/shroudforge"

if [ "$FORCE_SF" = "1" ] || [ ! -f "$SF_DLL" ] || [ ! -d "$SF_DIR" ]; then
    print_step "Fetching latest ShroudForge mod loader..."
    read -r SF_TAG SF_URL <<< "$(fetch_release_asset "bonsaibauer/shroudforge" "shroudforge" "https://github.com/bonsaibauer/shroudforge/releases/download/v1.7.0-build.39026384728/shroudforge-1.7.0-39026384728.zip" "v1.7.0")"

    printf "  ${C_GRAY}Downloading ShroudForge (%s)...${C_RESET}\n" "$SF_TAG"
    TMP_SF_ZIP=$(mktemp /tmp/shroudforge-XXXXXX.zip)
    download_file "$SF_URL" "$TMP_SF_ZIP"

    printf "  ${C_GRAY}Extracting ShroudForge into game directory...${C_RESET}\n"
    extract_zip "$TMP_SF_ZIP" "$TARGET_DIR"
    rm -f "$TMP_SF_ZIP"
    print_success "ShroudForge $SF_TAG successfully installed!"
else
    print_success "ShroudForge mod loader is already installed."
fi

# Install sf-cheatmenu and sf-cheatmenu-assets
print_step "Fetching latest SF Cheat Menu package releases..."

MODS_DIR="$TARGET_DIR/mods"
RUNTIME_DIR="$MODS_DIR/sf-cheatmenu"
ASSETS_DIR="$MODS_DIR/sf-cheatmenu-assets"
mkdir -p "$MODS_DIR"

EXISTING_RUNTIME_CONFIG="$RUNTIME_DIR/extended.mod.json"
EXISTING_ASSETS_CONFIG="$ASSETS_DIR/extended.mod.json"
TEMP_RUNTIME_BAK=""
TEMP_ASSETS_BAK=""

if [ -f "$EXISTING_RUNTIME_CONFIG" ]; then
    TEMP_RUNTIME_BAK=$(mktemp /tmp/sf_runtime_bak-XXXXXX.json)
    cp -f "$EXISTING_RUNTIME_CONFIG" "$TEMP_RUNTIME_BAK"
    print_warn "Preserving existing sf-cheatmenu extended.mod.json configuration."
fi
if [ -f "$EXISTING_ASSETS_CONFIG" ]; then
    TEMP_ASSETS_BAK=$(mktemp /tmp/sf_assets_bak-XXXXXX.json)
    cp -f "$EXISTING_ASSETS_CONFIG" "$TEMP_ASSETS_BAK"
    print_warn "Preserving existing sf-cheatmenu-assets extended.mod.json configuration."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/sf-cheatmenu/mod.json" ] && [ -f "$SCRIPT_DIR/sf-cheatmenu-assets/mod.json" ]; then
    print_step "Installing directly from local repository workspace..."
    mkdir -p "$RUNTIME_DIR" "$ASSETS_DIR"
    cp -rf "$SCRIPT_DIR/sf-cheatmenu/"* "$RUNTIME_DIR/"
    cp -rf "$SCRIPT_DIR/sf-cheatmenu-assets/"* "$ASSETS_DIR/"
    if [ -f "$SCRIPT_DIR/sf-cheatmenu/native/proxy/powrprof.dll" ]; then
        cp -f "$SCRIPT_DIR/sf-cheatmenu/native/proxy/powrprof.dll" "$TARGET_DIR/powrprof.dll"
        print_success "Installed native proxy loader (powrprof.dll) into game root."
    fi
    print_success "Local workspace mods copied to $MODS_DIR!"
else
    # Try downloading bundle first
    BUNDLE_URL=""
    BUNDLE_TAG=""
    if read -r B_TAG B_URL <<< "$(fetch_release_asset "adromir/enshrouded-cheatmenu" "bundle" "" "")"; then
        if [ -n "$B_URL" ]; then
            BUNDLE_TAG="$B_TAG"
            BUNDLE_URL="$B_URL"
        fi
    fi

    if [ -n "$BUNDLE_URL" ]; then
        printf "  ${C_GRAY}Downloading all-in-one bundle (%s)...${C_RESET}\n" "$BUNDLE_TAG"
        TMP_BUNDLE_ZIP=$(mktemp /tmp/sf-bundle-XXXXXX.zip)
        download_file "$BUNDLE_URL" "$TMP_BUNDLE_ZIP"
        extract_zip "$TMP_BUNDLE_ZIP" "$TARGET_DIR"
        rm -f "$TMP_BUNDLE_ZIP"
        print_success "Extracted complete bundle!"
    else
        # Fallback to individual mod downloads
        read -r MOD_TAG MOD_URL <<< "$(fetch_release_asset "adromir/enshrouded-cheatmenu" "sf-cheatmenu-v" "https://github.com/adromir/enshrouded-cheatmenu/releases/download/v0.0.1/sf-cheatmenu-v0.0.1.zip" "v0.0.1")"

    printf "  ${C_GRAY}Downloading sf-cheatmenu (%s)...${C_RESET}\n" "$MOD_TAG"
    TMP_MOD_ZIP=$(mktemp /tmp/sf-cheatmenu-XXXXXX.zip)
    download_file "$MOD_URL" "$TMP_MOD_ZIP"
    extract_zip "$TMP_MOD_ZIP" "$MODS_DIR"
    rm -f "$TMP_MOD_ZIP"

    read -r ASSETS_TAG ASSETS_URL <<< "$(fetch_release_asset "adromir/enshrouded-cheatmenu" "sf-cheatmenu-assets" "" "")"
    if [ -n "$ASSETS_URL" ]; then
        printf "  ${C_GRAY}Downloading sf-cheatmenu-assets (%s)...${C_RESET}\n" "$ASSETS_TAG"
        TMP_ASSETS_ZIP=$(mktemp /tmp/sf-assets-XXXXXX.zip)
        download_file "$ASSETS_URL" "$TMP_ASSETS_ZIP"
        extract_zip "$TMP_ASSETS_ZIP" "$MODS_DIR"
        rm -f "$TMP_ASSETS_ZIP"
    fi
fi

# Restore configurations if saved
if [ -n "$TEMP_RUNTIME_BAK" ] && [ -f "$TEMP_RUNTIME_BAK" ]; then
    cp -f "$TEMP_RUNTIME_BAK" "$EXISTING_RUNTIME_CONFIG"
    rm -f "$TEMP_RUNTIME_BAK"
    print_success "Restored custom sf-cheatmenu configuration."
fi
if [ -n "$TEMP_ASSETS_BAK" ] && [ -f "$TEMP_ASSETS_BAK" ]; then
    cp -f "$TEMP_ASSETS_BAK" "$EXISTING_ASSETS_CONFIG"
    rm -f "$TEMP_ASSETS_BAK"
    print_success "Restored custom sf-cheatmenu-assets configuration."
fi

IS_SERVER=0
if [ -f "$TARGET_DIR/enshrouded_server.exe" ] || [ "${SERVER:-0}" = "1" ]; then
    IS_SERVER=1
fi

if [ "$IS_SERVER" = "0" ] && [ -f "$RUNTIME_DIR/powrprof.dll" ]; then
    cp -f "$RUNTIME_DIR/powrprof.dll" "$TARGET_DIR/powrprof.dll"
    print_success "Installed native proxy loader (powrprof.dll) into game root directory."
fi

# Post-install verification and instructions
FINAL_LUA="$RUNTIME_DIR/src/mod.lua"
FINAL_JSON="$RUNTIME_DIR/mod.json"

if [ -f "$FINAL_LUA" ] && [ -f "$FINAL_JSON" ]; then
    printf "${C_GREEN}\n"
    printf "================================================================\n"
    if [ "$IS_SERVER" = "1" ]; then
        printf "          Dedicated Server Installation Completed!              \n"
        printf "================================================================\n"
        printf " Installed Packages:\n"
        printf "  - SF Cheat Menu (Runtime): %s\n" "$RUNTIME_DIR"
        printf "  - SF Cheat Menu Assets:    %s\n\n" "$ASSETS_DIR"
        printf " Dedicated Server Setup (Linux / Wine / Docker):\n"
        printf " 1. Configure server rules in: %s/extended.mod.json\n" "$RUNTIME_DIR"
        printf "    (Set XP multipliers, item yields, durability, free crafting, etc.)\n"
        printf " 2. Ensure ShroudForge winmm override is enabled in your server launch script:\n"
        printf "    export WINEDLLOVERRIDES=\"winmm=n,b\"\n"
        printf " 3. Launch enshrouded_server.exe. The server runs the pure Lua runtime mod.\n"
        printf "    Native DLLs (powrprof.dll) are intentionally not needed on the server.\n"
    else
        printf "             Client Installation Completed Successfully!        \n"
        printf "================================================================\n"
        printf " Installed Packages:\n"
        printf "  - SF Cheat Menu (Runtime): %s\n" "$RUNTIME_DIR"
        printf "  - SF Cheat Menu Assets:    %s\n\n" "$ASSETS_DIR"
        printf " [IMPORTANT FOR LINUX / PROTON / STEAM DECK CLIENT]\n"
        printf " Wine/Proton disables custom native DLLs by default.\n"
        printf " Set Launch Options in Steam (Enshrouded -> Properties -> General):\n"
        printf "    WINEDLLOVERRIDES=\"powrprof=n,b;winmm=n,b\" %%command%%\n\n"
        printf " In-game Hotkey: Press F9 to open ShroudForge Mod Menu\n"
        printf " Web Configurator: https://adromir.github.io/enshrouded-cheatmenu/\n"
    fi
    printf "================================================================${C_RESET}\n"
else
    print_warn "Installation finished, but some mod files could not be verified."
    print_warn "Check directory: $RUNTIME_DIR"
fi
