#!/usr/bin/env bash
# ==============================================================================
# Enshrouded Cheat Menu & ShroudForge One-Click Installer (Linux / SteamOS / Wine)
# Author: Adromir (https://github.com/adromir) | Version: 2.0.0
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

# Install sf-cheatmenu Mod
print_step "Fetching latest SF Cheat Menu & Server Tweaks release..."
read -r MOD_TAG MOD_URL <<< "$(fetch_release_asset "adromir/enshrouded-cheatmenu" "sf-cheatmenu" "https://github.com/adromir/enshrouded-cheatmenu/releases/download/v2.0.0/sf-cheatmenu-v2.0.0.zip" "v2.0.0")"

MODS_DIR="$TARGET_DIR/mods"
MOD_TARGET_DIR="$MODS_DIR/sf-cheatmenu"
EXISTING_CONFIG="$MOD_TARGET_DIR/extended.mod.json"
TEMP_BACKUP=""

mkdir -p "$MODS_DIR"

if [ -f "$EXISTING_CONFIG" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_FILE="${MOD_TARGET_DIR}/extended.mod.json.bak-${TIMESTAMP}"
    cp -f "$EXISTING_CONFIG" "$BACKUP_FILE"
    print_warn "Existing configuration backed up to: extended.mod.json.bak-${TIMESTAMP}"

    TEMP_BACKUP=$(mktemp /tmp/sf_config_bak-XXXXXX.json)
    cp -f "$EXISTING_CONFIG" "$TEMP_BACKUP"
fi

printf "  ${C_GRAY}Downloading sf-cheatmenu (%s)...${C_RESET}\n" "$MOD_TAG"
TMP_MOD_ZIP=$(mktemp /tmp/sf-cheatmenu-XXXXXX.zip)
download_file "$MOD_URL" "$TMP_MOD_ZIP"

printf "  ${C_GRAY}Extracting mod into mods directory...${C_RESET}\n"
extract_zip "$TMP_MOD_ZIP" "$MODS_DIR"
rm -f "$TMP_MOD_ZIP"

if [ -n "$TEMP_BACKUP" ] && [ -f "$TEMP_BACKUP" ]; then
    cp -f "$TEMP_BACKUP" "$EXISTING_CONFIG"
    rm -f "$TEMP_BACKUP"
    print_success "Preserved existing custom extended.mod.json configuration."
fi

print_success "SF Cheat Menu $MOD_TAG installed successfully!"

# Post-install verification and instructions
FINAL_LUA="$MOD_TARGET_DIR/src/mod.lua"
FINAL_JSON="$MOD_TARGET_DIR/mod.json"

if [ -f "$FINAL_LUA" ] && [ -f "$FINAL_JSON" ]; then
    printf "${C_GREEN}\n"
    printf "================================================================\n"
    printf "                Installation Completed Successfully!            \n"
    printf "================================================================\n"
    printf " Mod Location: %s\n" "$MOD_TARGET_DIR"
    printf " Mod Version:  %s\n\n" "$MOD_TAG"
    printf " [IMPORTANT FOR LINUX / PROTON / STEAM DECK / DEDICATED SERVER]\n"
    printf " Wine/Proton disables custom native DLLs by default.\n"
    printf " You MUST enable the DLL override for ShroudForge to load:\n\n"
    printf " 1. Steam Client (Steam Deck / Desktop Linux):\n"
    printf "    Right-click Enshrouded -> Properties -> General -> Launch Options:\n"
    printf "    WINEDLLOVERRIDES=\"winmm=n,b\" %%command%%\n\n"
    printf " 2. Dedicated Server / Wine CLI:\n"
    printf "    export WINEDLLOVERRIDES=\"winmm=n,b\"\n\n"
    printf " In-game Hotkey: Press F9 to open ShroudForge Mod Menu\n"
    printf " Web Configurator: https://adromir.github.io/enshrouded-cheatmenu/\n"
    printf "================================================================${C_RESET}\n"
else
    print_warn "Installation finished, but some mod files could not be verified."
    print_warn "Check directory: $MOD_TARGET_DIR"
fi
