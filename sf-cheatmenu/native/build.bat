@echo off
setlocal enabledelayedexpansion

echo Building SF Native Sidecar DLL...

set CLANG_BIN=C:\TheRock\build\lib\llvm\bin\clang++.exe

if exist "%CLANG_BIN%" (
    echo Using Clang: %CLANG_BIN%
    "%CLANG_BIN%" -shared -O2 -std=c++17 -Iinclude src/main.cpp src/pattern_scan.cpp src/patcher.cpp -o sf-native.dll
    if %errorlevel% neq 0 (
        echo Compilation failed!
        exit /b %errorlevel%
    )
    echo Build succeeded: sf-native.dll
    exit /b 0
)

where clang++ >nul 2>&1
if %errorlevel% equ 0 (
    echo Using PATH clang++
    clang++ -shared -O2 -std=c++17 -Iinclude src/main.cpp src/pattern_scan.cpp src/patcher.cpp -o sf-native.dll
    if %errorlevel% neq 0 (
        echo Compilation failed!
        exit /b %errorlevel%
    )
    echo Build succeeded: sf-native.dll
    exit /b 0
)

echo No suitable C++ compiler found (clang++).
exit /b 1
