#include <windows.h>
#include <cstdio>

static void Log(const char* format, ...) {
    FILE* f = fopen("proxy.log", "a");
    if (!f) return;

    SYSTEMTIME st;
    GetLocalTime(&st);
    fprintf(f, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);

    va_list args;
    va_start(args, format);
    vfprintf(f, format, args);
    va_end(args);

    fprintf(f, "\n");
    fflush(f);
    fclose(f);
}

static DWORD WINAPI ProxyLoaderThread(LPVOID) {
    char exePath[MAX_PATH];
    if (GetModuleFileNameA(NULL, exePath, MAX_PATH)) {
        for (int i = 0; exePath[i]; ++i) {
            exePath[i] = (char)tolower(exePath[i]);
        }
        if (strstr(exePath, "server") != nullptr) {
            Log("[Proxy] Dedicated server process detected (%s). Skipping native client hooks.", exePath);
            return 0;
        }
    }

    Log("[Proxy] version.dll initialized in game process (PID: %lu).", GetCurrentProcessId());

    // Give enshrouded.exe a brief moment to finish early CRT/engine initialization
    Sleep(2000);

    // 1. Load SF Cheat Menu native binary DLL
    LPCWSTR sfNativePath = L"mods\\sf-cheatmenu\\sf-native.dll";
    Log("[Proxy] Attempting to load native sidecar: %ls", sfNativePath);
    HMODULE hSfNative = LoadLibraryW(sfNativePath);
    if (hSfNative) {
        Log("[Proxy] Successfully loaded %ls (Base: 0x%p)!", sfNativePath, (void*)hSfNative);
    } else {
        DWORD err = GetLastError();
        Log("[Proxy] Warning: Could not load %ls (Win32 Error: %lu). Trying fallback...", sfNativePath, err);
        hSfNative = LoadLibraryW(L"sf-native.dll");
        if (hSfNative) {
            Log("[Proxy] Successfully loaded fallback ./sf-native.dll (Base: 0x%p)!", (void*)hSfNative);
        } else {
            Log("[Proxy] Fallback ./sf-native.dll also not found (Win32 Error: %lu).", GetLastError());
        }
    }

    // 2. Also load XHL-Unlimited-Flame-Altars if installed
    LPCWSTR xhlPath = L"mods\\XHL-Unlimited-Flame-Altars\\XHL-Unlimited-Flame-Altars.dll";
    if (GetFileAttributesW(xhlPath) != INVALID_FILE_ATTRIBUTES) {
        Log("[Proxy] Found %ls, loading...", xhlPath);
        HMODULE hXhl = LoadLibraryW(xhlPath);
        if (hXhl) {
            Log("[Proxy] Successfully loaded %ls (Base: 0x%p)!", xhlPath, (void*)hXhl);
            // If it exports a start function, call it
            typedef void (*PluginStartFn)();
            PluginStartFn startFn = (PluginStartFn)GetProcAddress(hXhl, "XhlNativePluginStart");
            if (startFn) {
                Log("[Proxy] Calling XhlNativePluginStart()...");
                startFn();
            }
        } else {
            Log("[Proxy] Failed to load %ls (Win32 Error: %lu).", xhlPath, GetLastError());
        }
    }

    Log("[Proxy] Native loader sequence completed.");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinstDLL);
        CreateThread(NULL, 0, ProxyLoaderThread, NULL, 0, NULL);
    }
    return TRUE;
}
