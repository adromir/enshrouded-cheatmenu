<#
.SYNOPSIS
    One-Click Installer for ShroudForge and Enshrouded Cheat Menu (sf-cheatmenu).

.DESCRIPTION
    Automatically detects the Enshrouded game or dedicated server directory (including multi-drive
    Steam libraries), verifies and installs ShroudForge mod loader, and installs the latest
    release of sf-cheatmenu. Preserves existing configuration files.

.EXAMPLE
    # One-liner execution from PowerShell:
    irm https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.ps1 | iex

.EXAMPLE
    # Explicit target directory:
    .\install.ps1 -TargetDir "D:\SteamLibrary\steamapps\common\Enshrouded"

.EXAMPLE
    # Force reinstall of ShroudForge mod loader:
    .\install.ps1 -ForceShroudForge
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [switch]$Server,
    [switch]$ForceShroudForge,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

# Ensure modern TLS protocols for GitHub downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Output styling helpers
function Write-Step {
    param([string]$Message)
    Write-Host "`n[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Write-Banner {
    Write-Host @"
================================================================
     Enshrouded Cheat Menu & ShroudForge One-Click Installer    
             Author: Adromir  |  Version: 0.0.1                
================================================================
"@ -ForegroundColor Magenta
}

# Safe Zip Extraction with Overwrite
function Extract-ZipArchive {
    param(
        [string]$ZipPath,
        [string]$DestinationDir
    )

    if (-not (Test-Path $DestinationDir)) {
        [System.IO.Directory]::CreateDirectory($DestinationDir) | Out-Null
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $destPath = [System.IO.Path]::Combine($DestinationDir, $entry.FullName)
            if ($entry.FullName.EndsWith("/") -or $entry.FullName.EndsWith("\")) {
                if (-not (Test-Path $destPath)) {
                    [System.IO.Directory]::CreateDirectory($destPath) | Out-Null
                }
            } else {
                $parent = [System.IO.Path]::GetDirectoryName($destPath)
                if (-not (Test-Path $parent)) {
                    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
                }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}

# Fetch GitHub Release Info with Triple-Layer Fallback
function Get-ReleaseAssetUrl {
    param(
        [string]$Repo,
        [string]$Pattern,
        [string]$StaticFallbackUrl,
        [string]$StaticFallbackVersion
    )

    $headers = @{
        "User-Agent" = "Enshrouded-CheatMenu-Installer/2.0"
        "Accept"     = "application/vnd.github.v3+json"
    }

    # Layer 1: GitHub REST API
    try {
        $apiUri = "https://api.github.com/repos/$Repo/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUri -Headers $headers -ErrorAction Stop
        if ($release -and $release.assets) {
            $asset = $release.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
            if ($asset -and $asset.browser_download_url) {
                return @{
                    Version = $release.tag_name
                    Url     = $asset.browser_download_url
                    Name    = $asset.name
                }
            }
        }
    }
    catch {
        Write-Verbose "GitHub API call failed for $($Repo): $_"
    }

    # Layer 2: HTTP Redirect Location Header
    try {
        $req = [System.Net.WebRequest]::Create("https://github.com/$Repo/releases/latest")
        $req.AllowAutoRedirect = $false
        $req.UserAgent = "Enshrouded-CheatMenu-Installer/2.0"
        $resp = $req.GetResponse()
        $loc = $resp.Headers["Location"]
        $resp.Close()

        if ($loc -and $loc -match "/tag/([^/]+)$") {
            $tag = $matches[1]
            if ($Repo -eq "adromir/enshrouded-cheatmenu") {
                return @{
                    Version = $tag
                    Url     = "https://github.com/$Repo/releases/download/$tag/sf-cheatmenu-$tag.zip"
                    Name    = "sf-cheatmenu-$tag.zip"
                }
            }
        }
    }
    catch {
        Write-Verbose "HTTP redirect lookup failed for $($Repo): $_"
    }

    # Layer 3: Pinned Reliable Static Fallback
    return @{
        Version = $StaticFallbackVersion
        Url     = $StaticFallbackUrl
        Name    = [System.IO.Path]::GetFileName($StaticFallbackUrl)
    }
}

# Auto-Detect Enshrouded Game or Server Directory
function Find-EnshroudedDirectory {
    param(
        [string]$ExplicitPath,
        [switch]$PreferServer
    )

    # 1. Explicit path parameter
    if ($ExplicitPath) {
        $resolved = $ExplicitPath.Trim('"', "'")
        if (Test-Path $resolved) {
            return (Resolve-Path $resolved).Path
        }
    }

    # 2. Environment variables
    foreach ($varName in @("ENSHROUDED_PATH", "ENSHROUDED_DIR", "ENSHROUDED_HOME")) {
        $envVal = [Environment]::GetEnvironmentVariable($varName)
        if ($envVal -and (Test-Path $envVal)) {
            return (Resolve-Path $envVal).Path
        }
    }

    # 3. Current Working Directory
    $cwd = (Get-Location).Path
    if (Test-Path (Join-Path $cwd "enshrouded.exe") -or Test-Path (Join-Path $cwd "enshrouded_server.exe")) {
        return $cwd
    }

    # 4. Steam Libraries Auto-Detection via Registry and libraryfolders.vdf
    $steamRoots = @()
    $registryKeys = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    )

    foreach ($regKey in $registryKeys) {
        if (Test-Path $regKey) {
            $regProp = Get-ItemProperty -Path $regKey -ErrorAction SilentlyContinue
            if ($regProp.SteamPath) { $steamRoots += $regProp.SteamPath }
            if ($regProp.InstallPath) { $steamRoots += $regProp.InstallPath }
        }
    }

    $defaultSteamPaths = @(
        "C:\Program Files (x86)\Steam",
        "C:\Program Files\Steam",
        "D:\Steam",
        "D:\SteamLibrary",
        "E:\Steam",
        "E:\SteamLibrary"
    )
    $steamRoots += $defaultSteamPaths

    $steamRoots = $steamRoots | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

    $libraryPaths = @()
    foreach ($sr in $steamRoots) {
        $libraryPaths += $sr
        $vdfPath = Join-Path $sr "steamapps\libraryfolders.vdf"
        if (Test-Path $vdfPath) {
            try {
                $vdfContent = Get-Content -Path $vdfPath -Raw -ErrorAction SilentlyContinue
                if ($vdfContent) {
                    $regex = [regex]'"path"\s+"([^"]+)"'
                    $matches = $regex.Matches($vdfContent)
                    foreach ($m in $matches) {
                        $p = $m.Groups[1].Value.Replace('\\', '\')
                        if (Test-Path $p) {
                            $libraryPaths += $p
                        }
                    }
                }
            } catch {}
        }
    }
    $libraryPaths = $libraryPaths | Select-Object -Unique

    $discovered = @()
    foreach ($lib in $libraryPaths) {
        $clientCandidate = Join-Path $lib "steamapps\common\Enshrouded"
        if (Test-Path (Join-Path $clientCandidate "enshrouded.exe")) {
            $discovered += [PSCustomObject]@{
                Type = "Client"
                Path = (Resolve-Path $clientCandidate).Path
            }
        }
        $serverCandidate = Join-Path $lib "steamapps\common\EnshroudedServer"
        if (Test-Path (Join-Path $serverCandidate "enshrouded_server.exe")) {
            $discovered += [PSCustomObject]@{
                Type = "Server"
                Path = (Resolve-Path $serverCandidate).Path
            }
        }
    }

    if ($discovered.Count -eq 1) {
        return $discovered[0].Path
    }
    elseif ($discovered.Count -gt 1) {
        if ($PreferServer) {
            $srv = $discovered | Where-Object { $_.Type -eq "Server" } | Select-Object -First 1
            if ($srv) { return $srv.Path }
        }
        $cli = $discovered | Where-Object { $_.Type -eq "Client" } | Select-Object -First 1
        if ($cli) { return $cli.Path }
        return $discovered[0].Path
    }

    return $null
}

# Main Execution Flow
Write-Banner

Write-Step "Detecting Enshrouded installation..."

$installDir = Find-EnshroudedDirectory -ExplicitPath $TargetDir -PreferServer:$Server

if (-not $installDir) {
    if ([Environment]::UserInteractive) {
        Write-Warn "Could not automatically locate Enshrouded directory."
        $manualPath = Read-Host "Please enter the full path to your Enshrouded directory"
        if ($manualPath -and (Test-Path $manualPath.Trim('"', "'"))) {
            $installDir = (Resolve-Path $manualPath.Trim('"', "'")).Path
        }
    }
}

if (-not $installDir -or -not (Test-Path $installDir)) {
    Write-Err "Enshrouded directory not found!"
    Write-Host @"
Usage:
  # With explicit path:
  .\install.ps1 -TargetDir "D:\SteamLibrary\steamapps\common\Enshrouded"

  # Or set environment variable before running:
  `$env:ENSHROUDED_PATH = "D:\SteamLibrary\steamapps\common\Enshrouded"
  irm https://raw.githubusercontent.com/adromir/enshrouded-cheatmenu/main/install.ps1 | iex
"@ -ForegroundColor Yellow
    exit 1
}

Write-Success "Target Enshrouded Directory: $installDir"

# Verify/Install ShroudForge Mod Loader
$shroudforgeDll = Join-Path $installDir "winmm.dll"
$shroudforgeFolder = Join-Path $installDir "shroudforge"
$needsShroudForge = $ForceShroudForge -or (-not (Test-Path $shroudforgeDll)) -or (-not (Test-Path $shroudforgeFolder))

if ($needsShroudForge) {
    Write-Step "Fetching latest ShroudForge mod loader..."
    $sfInfo = Get-ReleaseAssetUrl `
        -Repo "bonsaibauer/shroudforge" `
        -Pattern "*shroudforge*.zip" `
        -StaticFallbackUrl "https://github.com/bonsaibauer/shroudforge/releases/download/v1.7.0-build.39026384728/shroudforge-1.7.0-39026384728.zip" `
        -StaticFallbackVersion "v1.7.0"

    Write-Host "  Downloading ShroudForge ($($sfInfo.Version))..." -ForegroundColor Gray
    $sfTempZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "shroudforge-$([System.Guid]::NewGuid().ToString('N')).zip")

    try {
        Invoke-WebRequest -Uri $sfInfo.Url -OutFile $sfTempZip -UseBasicParsing
        Write-Host "  Extracting ShroudForge into game directory..." -ForegroundColor Gray
        Extract-ZipArchive -ZipPath $sfTempZip -DestinationDir $installDir
        Write-Success "ShroudForge $($sfInfo.Version) successfully installed!"
    }
    finally {
        if (Test-Path $sfTempZip) { Remove-Item $sfTempZip -Force -ErrorAction SilentlyContinue }
    }
} else {
    Write-Success "ShroudForge mod loader is already installed."
}

# Install / Update sf-cheatmenu & sf-cheatmenu-assets
Write-Step "Fetching latest SF Cheat Menu package releases..."

$modsDir = Join-Path $installDir "mods"
if (-not (Test-Path $modsDir)) {
    [System.IO.Directory]::CreateDirectory($modsDir) | Out-Null
}

$runtimeDir = Join-Path $modsDir "sf-cheatmenu"
$assetsDir = Join-Path $modsDir "sf-cheatmenu-assets"

# Preserve existing configuration files
$existingRuntimeConfig = Join-Path $runtimeDir "extended.mod.json"
$existingAssetsConfig = Join-Path $assetsDir "extended.mod.json"
$tempRuntimeBak = $null
$tempAssetsBak = $null

if ((Test-Path $existingRuntimeConfig) -and -not $NoBackup) {
    $tempRuntimeBak = [System.IO.Path]::GetTempFileName()
    Copy-Item -Path $existingRuntimeConfig -Destination $tempRuntimeBak -Force
    Write-Warn "Preserving existing sf-cheatmenu extended.mod.json configuration."
}
if ((Test-Path $existingAssetsConfig) -and -not $NoBackup) {
    $tempAssetsBak = [System.IO.Path]::GetTempFileName()
    Copy-Item -Path $existingAssetsConfig -Destination $tempAssetsBak -Force
    Write-Warn "Preserving existing sf-cheatmenu-assets extended.mod.json configuration."
}

# Check if running locally inside the repository workspace
$localRepoRoot = $PSScriptRoot
$isLocalRepo = (Test-Path (Join-Path $localRepoRoot "sf-cheatmenu\mod.json")) -and (Test-Path (Join-Path $localRepoRoot "sf-cheatmenu-assets\mod.json"))

if ($isLocalRepo) {
    Write-Step "Installing directly from local repository workspace..."
    New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
    New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

    Copy-Item -Path (Join-Path $localRepoRoot "sf-cheatmenu\*") -Destination $runtimeDir -Recurse -Force
    Copy-Item -Path (Join-Path $localRepoRoot "sf-cheatmenu-assets\*") -Destination $assetsDir -Recurse -Force

    $localProxy = Join-Path $localRepoRoot "sf-cheatmenu\native\proxy\powrprof.dll"
    if (Test-Path $localProxy) {
        Copy-Item -Path $localProxy -Destination $installDir -Force
        Write-Success "Installed native proxy loader (powrprof.dll) into game root."
    }
    Write-Success "Local workspace mods copied to $modsDir!"
} else {
    # Attempt downloading complete release bundle first
    $bundleInfo = $null
    try {
        $bundleInfo = Get-ReleaseAssetUrl `
            -Repo "adromir/enshrouded-cheatmenu" `
            -Pattern "*bundle*.zip" `
            -StaticFallbackUrl "" `
            -StaticFallbackVersion ""
    } catch {
        $bundleInfo = $null
    }

    if ($bundleInfo -and $bundleInfo.Url) {
        Write-Host "  Downloading complete bundle ($($bundleInfo.Version))..." -ForegroundColor Gray
        $bundleZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "sf-bundle-$([System.Guid]::NewGuid().ToString('N')).zip")
        try {
            Invoke-WebRequest -Uri $bundleInfo.Url -OutFile $bundleZip -UseBasicParsing
            Write-Host "  Extracting bundle into game directory..." -ForegroundColor Gray
            Extract-ZipArchive -ZipPath $bundleZip -DestinationDir $installDir
            Write-Success "All-in-one bundle extracted successfully!"
        }
        finally {
            if (Test-Path $bundleZip) { Remove-Item $bundleZip -Force -ErrorAction SilentlyContinue }
        }
    } else {
        # Fallback to individual mod zip downloads
        Write-Host "  Downloading sf-cheatmenu release..." -ForegroundColor Gray
        $modInfo = Get-ReleaseAssetUrl `
            -Repo "adromir/enshrouded-cheatmenu" `
            -Pattern "*sf-cheatmenu-v*.zip" `
            -StaticFallbackUrl "https://github.com/adromir/enshrouded-cheatmenu/releases/download/v0.0.1/sf-cheatmenu-v0.0.1.zip" `
            -StaticFallbackVersion "v0.0.1"

        $modTempZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "sf-cheatmenu-$([System.Guid]::NewGuid().ToString('N')).zip")
        try {
            Invoke-WebRequest -Uri $modInfo.Url -OutFile $modTempZip -UseBasicParsing
            Extract-ZipArchive -ZipPath $modTempZip -DestinationDir $modsDir
            Write-Success "sf-cheatmenu extracted successfully!"
        }
        finally {
            if (Test-Path $modTempZip) { Remove-Item $modTempZip -Force -ErrorAction SilentlyContinue }
        }

        # Try downloading sf-cheatmenu-assets
        try {
            $assetsInfo = Get-ReleaseAssetUrl `
                -Repo "adromir/enshrouded-cheatmenu" `
                -Pattern "*sf-cheatmenu-assets*.zip" `
                -StaticFallbackUrl "" `
                -StaticFallbackVersion ""
            if ($assetsInfo -and $assetsInfo.Url) {
                Write-Host "  Downloading sf-cheatmenu-assets ($($assetsInfo.Version))..." -ForegroundColor Gray
                $assetsTempZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "sf-assets-$([System.Guid]::NewGuid().ToString('N')).zip")
                try {
                    Invoke-WebRequest -Uri $assetsInfo.Url -OutFile $assetsTempZip -UseBasicParsing
                    Extract-ZipArchive -ZipPath $assetsTempZip -DestinationDir $modsDir
                    Write-Success "sf-cheatmenu-assets extracted successfully!"
                }
                finally {
                    if (Test-Path $assetsTempZip) { Remove-Item $assetsTempZip -Force -ErrorAction SilentlyContinue }
                }
            }
        } catch {
            Write-Warn "Note: sf-cheatmenu-assets zip not found in release assets."
        }
    }

    # Proxy handling for client target
    $isServer = $Server -or (Test-Path (Join-Path $installDir "enshrouded_server.exe"))
    $extractedProxy = Join-Path $runtimeDir "powrprof.dll"
    if ((Test-Path $extractedProxy) -and -not $isServer) {
        Copy-Item -Path $extractedProxy -Destination (Join-Path $installDir "powrprof.dll") -Force
        Write-Success "Installed native proxy loader (powrprof.dll) into game root directory."
    }
}

# Restore user configuration files if they were backed up
if ($tempRuntimeBak -and (Test-Path $tempRuntimeBak)) {
    Copy-Item -Path $tempRuntimeBak -Destination $existingRuntimeConfig -Force
    Remove-Item -Path $tempRuntimeBak -Force -ErrorAction SilentlyContinue
    Write-Success "Restored existing sf-cheatmenu configuration."
}
if ($tempAssetsBak -and (Test-Path $tempAssetsBak)) {
    Copy-Item -Path $tempAssetsBak -Destination $existingAssetsConfig -Force
    Remove-Item -Path $tempAssetsBak -Force -ErrorAction SilentlyContinue
    Write-Success "Restored existing sf-cheatmenu-assets configuration."
}

# Run ShroudForge Prepare to compile KFC static asset patches
$sfCli = Join-Path $shroudforgeFolder "shroudforge.exe"
if (Test-Path $sfCli) {
    Write-Step "Compiling static asset patches into enshrouded.kfc via ShroudForge..."
    try {
        & $sfCli prepare $installDir
        Write-Success "Pregame asset preparation completed successfully!"
    } catch {
        Write-Warn "Could not execute automatic prepare pass: $_"
    }
}

$finalRuntimeLua = Join-Path $runtimeDir "src\mod.lua"
$finalRuntimeJson = Join-Path $runtimeDir "mod.json"
$finalAssetsLua = Join-Path $assetsDir "src\mod.lua"

if ((Test-Path $finalRuntimeLua) -and (Test-Path $finalRuntimeJson)) {
    if ($isServer) {
        Write-Host @"

================================================================
          Dedicated Server Installation Completed!              
================================================================
 Installed Packages:
  - SF Cheat Menu:        $runtimeDir
  - SF Cheat Menu Assets: $assetsDir

 Server Configuration:
 1. Edit '$existingRuntimeConfig'
    to authoritatively configure server rules (XP, drops, durability, free crafting).
 2. Start 'enshrouded_server.exe'. ShroudForge automatically loads the mod.
 3. All connected clients inherit the authoritative server settings.
 4. Native DLLs (powrprof.dll) are intentionally not needed on the server.
================================================================"
"@ -ForegroundColor Green
    } else {
        Write-Host @"

================================================================
             Client Installation Completed Successfully!        
================================================================
 Installed Packages:
  - SF Cheat Menu (Runtime): $runtimeDir
  - SF Cheat Menu Assets:    $assetsDir

 Quick Start Guide:
 1. Launch Enshrouded normally (via Steam or shortcut).
 2. In-game, press F9 to toggle the ShroudForge Mod Menu.
 3. Select 'SF Cheat Menu' to customize live cheats (toggles in real-time).
 4. Static asset patches (9999 stacks, 160 chest slots, cliff walking)
    have been compiled into enshrouded.kfc!

 Interactive Web Configurator:
   https://adromir.github.io/enshrouded-cheatmenu/
================================================================"
"@ -ForegroundColor Green
    }
} else {
    Write-Warn "Installation completed, but some mod files could not be verified."
    Write-Warn "Please check: $runtimeDir"
}
