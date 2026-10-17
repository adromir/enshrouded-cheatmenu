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
             Author: Adromir  |  Version: 2.0.0                
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

# Install / Update sf-cheatmenu
Write-Step "Fetching latest SF Cheat Menu & Server Tweaks release..."
$modInfo = Get-ReleaseAssetUrl `
    -Repo "adromir/enshrouded-cheatmenu" `
    -Pattern "*sf-cheatmenu*.zip" `
    -StaticFallbackUrl "https://github.com/adromir/enshrouded-cheatmenu/releases/download/v2.0.0/sf-cheatmenu-v2.0.0.zip" `
    -StaticFallbackVersion "v2.0.0"

$modsDir = Join-Path $installDir "mods"
if (-not (Test-Path $modsDir)) {
    [System.IO.Directory]::CreateDirectory($modsDir) | Out-Null
}

$modTargetDir = Join-Path $modsDir "sf-cheatmenu"
$existingConfig = Join-Path $modTargetDir "extended.mod.json"
$hasCustomConfig = Test-Path $existingConfig
$tempConfigBackup = $null

if ($hasCustomConfig -and -not $NoBackup) {
    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $backupPath = Join-Path $modTargetDir "extended.mod.json.bak-$timestamp"
    Copy-Item -Path $existingConfig -Destination $backupPath -Force
    Write-Warn "Existing configuration backed up to: extended.mod.json.bak-$timestamp"
    
    # Keep temp copy to restore after archive extraction
    $tempConfigBackup = [System.IO.Path]::GetTempFileName()
    Copy-Item -Path $existingConfig -Destination $tempConfigBackup -Force
}

Write-Host "  Downloading sf-cheatmenu ($($modInfo.Version))..." -ForegroundColor Gray
$modTempZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "sf-cheatmenu-$([System.Guid]::NewGuid().ToString('N')).zip")

try {
    Invoke-WebRequest -Uri $modInfo.Url -OutFile $modTempZip -UseBasicParsing
    Write-Host "  Extracting mod into mods directory..." -ForegroundColor Gray
    Extract-ZipArchive -ZipPath $modTempZip -DestinationDir $modsDir
    
    # If user had custom settings, restore their config
    if ($tempConfigBackup -and (Test-Path $tempConfigBackup)) {
        Copy-Item -Path $tempConfigBackup -Destination $existingConfig -Force
        Remove-Item -Path $tempConfigBackup -Force -ErrorAction SilentlyContinue
        Write-Success "Preserved existing custom extended.mod.json settings."
    }

    Write-Success "SF Cheat Menu $($modInfo.Version) installed successfully!"
}
finally {
    if (Test-Path $modTempZip) { Remove-Item $modTempZip -Force -ErrorAction SilentlyContinue }
    if ($tempConfigBackup -and (Test-Path $tempConfigBackup)) { Remove-Item $tempConfigBackup -Force -ErrorAction SilentlyContinue }
}

# Final Validation
$finalModLua = Join-Path $modTargetDir "src\mod.lua"
$finalModJson = Join-Path $modTargetDir "mod.json"

if ((Test-Path $finalModLua) -and (Test-Path $finalModJson)) {
    Write-Host @"

================================================================
                Installation Completed Successfully!            
================================================================
 Mod Location: $modTargetDir
 Mod Version:  $($modInfo.Version)

 Quick Start Guide:
 1. Launch Enshrouded normally (via Steam or shortcut).
 2. In-game, press F9 to toggle the ShroudForge Mod Menu.
 3. Select 'SF Cheat Menu & Server Tweaks' to customize all cheats.

 Interactive Web Configurator:
   https://adromir.github.io/enshrouded-cheatmenu/

 Dedicated Server Note:
   Edit '$existingConfig'
   to authoritatively configure world multipliers and stack sizes.
================================================================
"@ -ForegroundColor Green
} else {
    Write-Warn "Installation completed, but some mod files could not be verified."
    Write-Warn "Please check: $modTargetDir"
}
