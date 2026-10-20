# Build script for SF Native Sidecar DLL and version.dll proxy loader
$ErrorActionPreference = "Stop"

$ClangBin = "C:\TheRock\build\lib\llvm\bin\clang++.exe"
if (-not (Test-Path $ClangBin)) {
    $Command = Get-Command clang++ -ErrorAction SilentlyContinue
    if ($Command) {
        $ClangBin = $Command.Source
    } else {
        Write-Error "No suitable C++ compiler found (clang++)."
        exit 1
    }
}

Push-Location $PSScriptRoot
try {
    Write-Host "Compiling sf-native.dll using $ClangBin..."
    $Sources = @("src/main.cpp", "src/pattern_scan.cpp", "src/patcher.cpp")
    $IncludeDir = "-Iinclude"
    $OutNative = "sf-native.dll"

    & $ClangBin -fuse-ld=lld -shared -O2 -std=c++17 $IncludeDir $Sources -luser32 -o $OutNative
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation of sf-native.dll failed."
        exit $LASTEXITCODE
    }
    Write-Host "Successfully compiled $OutNative!" -ForegroundColor Green

    Write-Host "Compiling proxy powrprof.dll using $ClangBin..."
    $ProxySrc = "proxy/powrprof.cpp"
    $ProxyDef = "proxy/powrprof.def"
    $OutProxy = "proxy/powrprof.dll"

    & $ClangBin -fuse-ld=lld -shared -O2 -D_CRT_SECURE_NO_WARNINGS $ProxySrc "-Wl,-def:$ProxyDef" -o $OutProxy
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation of powrprof.dll failed."
        exit $LASTEXITCODE
    }
    Write-Host "Successfully compiled $OutProxy!" -ForegroundColor Green
}
finally {
    Pop-Location
}
