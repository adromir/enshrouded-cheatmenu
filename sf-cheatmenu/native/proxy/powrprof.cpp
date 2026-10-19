#include <windows.h>
#include <cstdio>
#include <string>

static HINSTANCE g_hinst = NULL;

static void Log(const char* format, ...) {
    char logPath[MAX_PATH];
    if (GetModuleFileNameA(g_hinst, logPath, MAX_PATH)) {
        char* last = strrchr(logPath, '\\');
        if (last) *(last + 1) = '\0';
        strcat(logPath, "proxy.log");
        FILE* f = fopen(logPath, "a");
        if (f) {
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
    }
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

    Log("[Proxy] powrprof.dll proxy initialized in game process (PID: %lu).", GetCurrentProcessId());

    // Give enshrouded.exe a brief moment to finish early CRT/engine initialization
    Sleep(2000);

    // 1. Resolve full path to sf-native.dll
    char sfNativePath[MAX_PATH];
    if (GetModuleFileNameA(g_hinst, sfNativePath, MAX_PATH)) {
        char* last = strrchr(sfNativePath, '\\');
        if (last) *(last + 1) = '\0';
        strcat(sfNativePath, "mods\\sf-cheatmenu\\sf-native.dll");
    } else {
        strcpy(sfNativePath, "mods\\sf-cheatmenu\\sf-native.dll");
    }

    Log("[Proxy] Attempting to load native sidecar: %s", sfNativePath);
    HMODULE hSfNative = LoadLibraryA(sfNativePath);
    if (hSfNative) {
        Log("[Proxy] Successfully loaded %s (Base: 0x%p)!", sfNativePath, (void*)hSfNative);
    } else {
        DWORD err = GetLastError();
        Log("[Proxy] Warning: Could not load %s (Win32 Error: %lu). Trying fallback...", sfNativePath, err);
        hSfNative = LoadLibraryA("sf-native.dll");
        if (hSfNative) {
            Log("[Proxy] Successfully loaded fallback ./sf-native.dll (Base: 0x%p)!", (void*)hSfNative);
        } else {
            Log("[Proxy] Fallback ./sf-native.dll also not found (Win32 Error: %lu).", GetLastError());
        }
    }

    // 2. Also load XHL-Unlimited-Flame-Altars if installed and not already loaded
    if (!GetModuleHandleA("XHL-Unlimited-Flame-Altars.dll")) {
        char xhlPath[MAX_PATH];
        if (GetModuleFileNameA(g_hinst, xhlPath, MAX_PATH)) {
            char* last = strrchr(xhlPath, '\\');
            if (last) *(last + 1) = '\0';
            strcat(xhlPath, "mods\\XHL-Unlimited-Flame-Altars\\XHL-Unlimited-Flame-Altars.dll");
            if (GetFileAttributesA(xhlPath) != INVALID_FILE_ATTRIBUTES) {
                Log("[Proxy] Found %s, loading...", xhlPath);
                HMODULE hXhl = LoadLibraryA(xhlPath);
                if (hXhl) {
                    Log("[Proxy] Successfully loaded %s (Base: 0x%p)!", xhlPath, (void*)hXhl);
                    typedef void (*PluginStartFn)();
                    PluginStartFn startFn = (PluginStartFn)GetProcAddress(hXhl, "XhlNativePluginStart");
                    if (startFn) {
                        Log("[Proxy] Calling XhlNativePluginStart()...");
                        startFn();
                    }
                } else {
                    Log("[Proxy] Failed to load %s (Win32 Error: %lu).", xhlPath, GetLastError());
                }
            }
        }
    }

    Log("[Proxy] Native loader sequence completed.");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hinst = hinstDLL;
        Log("[Proxy] powrprof.dll DllMain attached to process (PID: %lu)", GetCurrentProcessId());
        DisableThreadLibraryCalls(hinstDLL);
        CreateThread(NULL, 0, ProxyLoaderThread, NULL, 0, NULL);
    }
    return TRUE;
}
