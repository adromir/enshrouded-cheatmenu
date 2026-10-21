#include <windows.h>
#pragma comment(lib, "user32.lib")
#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <atomic>
#include "pattern_scan.h"
#include "patcher.h"

static HMODULE g_dll_module = nullptr;
static std::atomic<bool> g_running{true};

struct FeatureHook {
    std::string key;         // Key in extended.mod.json (e.g. "infiniteArrows")
    std::string ini_key;     // Key in native-plugin.ini (e.g. "InfiniteArrows")
    std::string name;        // Friendly display name
    std::vector<sf_native::MemoryPatch> patches;
    bool is_active = false;
    bool ready = false;
};

static std::vector<FeatureHook> g_features;

static void log_message(const std::string& msg) {
    char path[MAX_PATH];
    if (GetModuleFileNameA(g_dll_module, path, MAX_PATH)) {
        std::string dir = path;
        size_t last_slash = dir.find_last_of("\\/");
        if (last_slash != std::string::npos) {
            dir = dir.substr(0, last_slash + 1);
        }
        std::ofstream log(dir + "sf-native.log", std::ios::app);
        if (log.is_open()) {
            SYSTEMTIME st;
            GetLocalTime(&st);
            char time_buf[64];
            snprintf(time_buf, sizeof(time_buf), "[%02d:%02d:%02d.%03d] ",
                     st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
            log << time_buf << msg << std::endl;
        }
    }
}

static std::string get_dll_dir() {
    char path[MAX_PATH];
    if (GetModuleFileNameA(g_dll_module, path, MAX_PATH)) {
        std::string dir = path;
        size_t last_slash = dir.find_last_of("\\/");
        if (last_slash != std::string::npos) {
            return dir.substr(0, last_slash + 1);
        }
    }
    return ".\\";
}

static std::string read_file_safely(const std::string& path) {
    for (int retry = 0; retry < 5; ++retry) {
        HANDLE hFile = CreateFileA(path.c_str(), GENERIC_READ,
                                   FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                                   nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (hFile != INVALID_HANDLE_VALUE) {
            DWORD size = GetFileSize(hFile, nullptr);
            if (size > 0 && size < 10 * 1024 * 1024) {
                std::string content(size, '\0');
                DWORD bytes_read = 0;
                if (ReadFile(hFile, &content[0], size, &bytes_read, nullptr)) {
                    CloseHandle(hFile);
                    content.resize(bytes_read);
                    return content;
                }
            }
            CloseHandle(hFile);
        }
        Sleep(40);
    }
    return "";
}

static std::atomic<bool> g_creative_hover_enabled{false};
static std::atomic<int> g_hover_speed_multiplier{100};
static std::atomic<int> g_hover_ascend_vk{'R'};
static std::atomic<int> g_hover_descend_vk{'F'};
static void* g_hover_trampoline = nullptr;

extern "C" void HandleCreativeHover(float* pPosZ, float computedNewZ) {
    if (!g_creative_hover_enabled.load()) {
        *pPosZ = computedNewZ;
        return;
    }

    HWND fg = GetForegroundWindow();
    if (fg) {
        DWORD pid = 0;
        GetWindowThreadProcessId(fg, &pid);
        if (pid != GetCurrentProcessId()) {
            return;
        }
    }

    int ascend_vk = g_hover_ascend_vk.load();
    int descend_vk = g_hover_descend_vk.load();

    bool up = (GetAsyncKeyState(ascend_vk) & 0x8000) != 0;
    bool down = (GetAsyncKeyState(descend_vk) & 0x8000) != 0;

    float speed = 0.20f * (static_cast<float>(g_hover_speed_multiplier.load()) / 100.0f);

    if (up && !down) {
        *pPosZ += speed;
    } else if (down && !up) {
        *pPosZ -= speed;
    } else {
        // Zero vertical motion: freeze altitude in mid-air
    }
}

static void* allocate_page_near(uintptr_t target) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    uintptr_t min_addr = (target > 0x70000000) ? (target - 0x70000000) : 0x10000;
    uintptr_t max_addr = target + 0x70000000;

    for (uintptr_t addr = (target & ~0xFFFF) - 0x10000; addr >= min_addr; addr -= 0x10000) {
        void* p = VirtualAlloc(reinterpret_cast<void*>(addr), 4096, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
        if (p) return p;
    }
    for (uintptr_t addr = (target & ~0xFFFF) + 0x10000; addr < max_addr; addr += 0x10000) {
        void* p = VirtualAlloc(reinterpret_cast<void*>(addr), 4096, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
        if (p) return p;
    }
    return nullptr;
}

static std::vector<uint8_t> create_hover_trampoline(uintptr_t handler_addr) {
    std::vector<uint8_t> code = {
        // Save volatile GPRs
        0x50,                               // push rax
        0x51,                               // push rcx
        0x52,                               // push rdx
        0x41, 0x50,                         // push r8
        0x41, 0x51,                         // push r9
        0x41, 0x52,                         // push r10
        0x41, 0x53,                         // push r11

        // Align stack and save xmm0-xmm3 (0x40 = 64 bytes; 7 * 8 + 64 = 120 + 8 = 128 bytes, 16-aligned)
        0x48, 0x83, 0xEC, 0x40,             // sub rsp, 0x40
        0x0F, 0x29, 0x04, 0x24,             // movaps [rsp], xmm0
        0x0F, 0x29, 0x4C, 0x24, 0x10,       // movaps [rsp+0x10], xmm1
        0x0F, 0x29, 0x54, 0x24, 0x20,       // movaps [rsp+0x20], xmm2
        0x0F, 0x29, 0x5C, 0x24, 0x30,       // movaps [rsp+0x30], xmm3

        // Argument 1: rcx = r15 + 8 (pointer to pos.z)
        0x49, 0x8D, 0x4F, 0x08,             // lea rcx, [r15+8]
        // Argument 2: xmm1 = xmm0 (computed new Z from engine)
        0x0F, 0x28, 0xC8,                   // movaps xmm1, xmm0

        // Shadow space (32 bytes, maintains 16-byte alignment)
        0x48, 0x83, 0xEC, 0x20,             // sub rsp, 0x20

        // Call handler: mov rax, <64-bit absolute address>; call rax
        0x48, 0xB8                          // mov rax, imm64
    };

    // Insert 64-bit handler address
    for (int i = 0; i < 8; ++i) {
        code.push_back(static_cast<uint8_t>((handler_addr >> (i * 8)) & 0xFF));
    }

    // Call and restore
    std::vector<uint8_t> tail = {
        0xFF, 0xD0,                         // call rax
        0x48, 0x83, 0xC4, 0x20,             // add rsp, 0x20

        // Restore xmm0-xmm3
        0x0F, 0x28, 0x5C, 0x24, 0x30,       // movaps xmm3, [rsp+0x30]
        0x0F, 0x28, 0x54, 0x24, 0x20,       // movaps xmm2, [rsp+0x20]
        0x0F, 0x28, 0x4C, 0x24, 0x10,       // movaps xmm1, [rsp+0x10]
        0x0F, 0x28, 0x04, 0x24,             // movaps xmm0, [rsp]
        0x48, 0x83, 0xC4, 0x40,             // add rsp, 0x40

        // Restore GPRs
        0x41, 0x5B,                         // pop r11
        0x41, 0x5A,                         // pop r10
        0x41, 0x59,                         // pop r9
        0x41, 0x58,                         // pop r8
        0x5A,                               // pop rdx
        0x59,                               // pop rcx
        0x58,                               // pop rax

        0xC3                                // ret
    };

    code.insert(code.end(), tail.begin(), tail.end());
    return code;
}

static int resolve_vk(const std::string& key_name, int default_vk) {
    if (key_name == "Space") return VK_SPACE;
    if (key_name == "C") return 'C';
    if (key_name == "LeftControl" || key_name == "Ctrl") return VK_LCONTROL;
    if (key_name == "LeftShift" || key_name == "Shift") return VK_LSHIFT;
    if (key_name == "E") return 'E';
    if (key_name == "X") return 'X';
    if (key_name == "Q") return 'Q';
    if (key_name == "R") return 'R';
    if (key_name == "F") return 'F';
    if (key_name == "Up") return VK_UP;
    if (key_name == "Down") return VK_DOWN;
    return default_vk;
}

static int parse_json_int_setting(const std::string& json, const std::string& key, int default_val) {
    std::string needle = "\"" + key + "\"";
    size_t key_pos = json.find(needle);
    if (key_pos == std::string::npos) return default_val;

    size_t val_pos = json.find("\"value\"", key_pos);
    if (val_pos == std::string::npos || val_pos - key_pos > 250) return default_val;

    size_t colon_pos = json.find(':', val_pos);
    if (colon_pos == std::string::npos) return default_val;

    size_t start = colon_pos + 1;
    while (start < json.length() && (json[start] == ' ' || json[start] == '\t' || json[start] == '\r' || json[start] == '\n')) {
        start++;
    }
    size_t end = start;
    while (end < json.length() && (isdigit(static_cast<unsigned char>(json[end])) || json[end] == '-')) {
        end++;
    }
    if (end > start) {
        try {
            return std::stoi(json.substr(start, end - start));
        } catch (...) {}
    }
    return default_val;
}

static std::string parse_json_string_setting(const std::string& json, const std::string& key, const std::string& default_val) {
    std::string needle = "\"" + key + "\"";
    size_t key_pos = json.find(needle);
    if (key_pos == std::string::npos) return default_val;

    size_t val_pos = json.find("\"value\"", key_pos);
    if (val_pos == std::string::npos || val_pos - key_pos > 250) return default_val;

    size_t colon_pos = json.find(':', val_pos);
    if (colon_pos == std::string::npos) return default_val;

    size_t q1 = json.find('"', colon_pos);
    if (q1 == std::string::npos) return default_val;

    size_t q2 = json.find('"', q1 + 1);
    if (q2 == std::string::npos) return default_val;

    return json.substr(q1 + 1, q2 - q1 - 1);
}

static bool parse_json_bool_setting(const std::string& json, const std::string& key, bool default_val) {
    std::string needle = "\"" + key + "\"";
    size_t search_pos = 0;
    while (true) {
        size_t key_pos = json.find(needle, search_pos);
        if (key_pos == std::string::npos) {
            return default_val;
        }

        size_t post = key_pos + needle.length();
        while (post < json.length() && (json[post] == ' ' || json[post] == '\t' || json[post] == '\r' || json[post] == '\n')) {
            post++;
        }

        if (post < json.length() && json[post] == ':') {
            post++;
            while (post < json.length() && (json[post] == ' ' || json[post] == '\t' || json[post] == '\r' || json[post] == '\n')) {
                post++;
            }
            if (post < json.length() && json[post] == '{') {
                size_t block_start = post + 1;
                size_t block_end = json.find('}', block_start);
                if (block_end == std::string::npos) block_end = json.length();
                std::string block = json.substr(block_start, block_end - block_start);

                size_t val_pos = block.find("\"value\"");
                size_t check_start = (val_pos != std::string::npos) ? val_pos : 0;
                size_t true_pos = block.find("true", check_start);
                size_t false_pos = block.find("false", check_start);

                if (true_pos != std::string::npos && (false_pos == std::string::npos || true_pos < false_pos)) {
                    return true;
                }
                if (false_pos != std::string::npos && (true_pos == std::string::npos || false_pos < true_pos)) {
                    return false;
                }
                return default_val;
            }
        }
        search_pos = key_pos + needle.length();
    }
}

static void sync_feature(FeatureHook& feat, bool desired_state) {
    if (!feat.ready) return;
    if (desired_state == feat.is_active) return;

    if (desired_state) {
        bool all_ok = true;
        for (auto& p : feat.patches) {
            if (!p.apply()) {
                all_ok = false;
            }
        }
        feat.is_active = all_ok;
        if (feat.key == "creativeHover") {
            g_creative_hover_enabled.store(all_ok);
        }
        log_message("[F9 MENU TOGGLE] " + feat.name + " -> ACTIVATED in memory");
    } else {
        for (auto& p : feat.patches) {
            p.restore();
        }
        feat.is_active = false;
        if (feat.key == "creativeHover") {
            g_creative_hover_enabled.store(false);
        }
        log_message("[F9 MENU TOGGLE] " + feat.name + " -> DEACTIVATED (Original game code restored)");
    }
}

static DWORD WINAPI WorkerThread(LPVOID lpParam) {
    char exePath[MAX_PATH];
    if (GetModuleFileNameA(NULL, exePath, MAX_PATH)) {
        for (int i = 0; exePath[i]; ++i) {
            exePath[i] = (char)tolower(exePath[i]);
        }
        if (strstr(exePath, "server") != nullptr) {
            log_message("[SF Native] Dedicated server process detected. Native binary sidecar disabled on dedicated server.");
            return 0;
        }
    }

    // Delay to ensure enshrouded.exe module is fully mapped and unpacked
    Sleep(1500);

    log_message("=== SF Native Sidecar Initializing (Live F9 Mod Menu Bridge) ===");

    HMODULE exe_module = GetModuleHandleA(nullptr);
    if (!exe_module) {
        log_message("Error: Unable to acquire enshrouded.exe module handle.");
        return 1;
    }

    uintptr_t base_addr = reinterpret_cast<uintptr_t>(exe_module);
    PIMAGE_DOS_HEADER dos_header = reinterpret_cast<PIMAGE_DOS_HEADER>(base_addr);
    if (dos_header->e_magic != IMAGE_DOS_SIGNATURE) {
        log_message("Error: Invalid DOS signature on main executable.");
        return 1;
    }

    PIMAGE_NT_HEADERS nt_headers = reinterpret_cast<PIMAGE_NT_HEADERS>(base_addr + dos_header->e_lfanew);
    if (nt_headers->Signature != IMAGE_NT_SIGNATURE) {
        log_message("Error: Invalid NT signature on main executable.");
        return 1;
    }

    size_t module_size = nt_headers->OptionalHeader.SizeOfImage;
    char buf[512];
    snprintf(buf, sizeof(buf), "Executable Base: 0x%llX, Size: 0x%zX",
             static_cast<unsigned long long>(base_addr), module_size);
    log_message(buf);

    std::string mod_dir = get_dll_dir();
    std::string json_path = mod_dir + "extended.mod.json";
    std::string ini_path = mod_dir + "native-plugin.ini";

    // =========================================================================
    // 1. Scan and register all native binary features
    // =========================================================================

    // 1. Infinite Arrows Hook
    {
        FeatureHook feat;
        feat.key = "infiniteArrows";
        feat.ini_key = "InfiniteArrows";
        feat.name = "Infinite Arrows & Quiver";

        sf_native::Pattern pat = sf_native::parse_pattern(
            "consumables.firedRemoval",
            "44 8B 00 E8 ?? ?? ?? ?? 80 BD E0 00 00 00 00 0F 85",
            3, 5
        );
        uintptr_t match = sf_native::scan_pattern(base_addr, module_size, pat);
        if (match) {
            sf_native::MemoryPatch p;
            p.name = feat.name;
            p.target_address = match + pat.patch_offset;
            p.patch_bytes = { 0x90, 0x90, 0x90, 0x90, 0x90 }; // 5x NOP
            feat.patches.push_back(p);
            feat.ready = true;
            snprintf(buf, sizeof(buf), "[SCAN READY] %s found at 0x%llX", feat.name.c_str(),
                     static_cast<unsigned long long>(p.target_address));
            log_message(buf);
        } else {
            log_message("[WARNING] consumables.firedRemoval pattern not found.");
        }
        g_features.push_back(feat);
    }

    // 2. Infinite Shroud / Shroud Freezer Hook
    {
        FeatureHook feat;
        feat.key = "infiniteShroud";
        feat.ini_key = "InfiniteShroud";
        feat.name = "Freeze Shroud Timer (Fog God Mode)";

        sf_native::Pattern pat = sf_native::parse_pattern(
            "fogresistance.godModeGate",
            "BA 2F D8 4A B3 E8 ?? ?? ?? ?? 44 38 7D F7 0F 85",
            14, 6
        );
        uintptr_t match = sf_native::scan_pattern(base_addr, module_size, pat);
        if (match) {
            sf_native::MemoryPatch p1;
            p1.name = "Shroud Gate 1";
            p1.target_address = match + 14;
            p1.patch_bytes = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
            feat.patches.push_back(p1);

            sf_native::MemoryPatch p2;
            p2.name = "Shroud Gate 2";
            p2.target_address = match + 22;
            p2.patch_bytes = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
            feat.patches.push_back(p2);

            sf_native::MemoryPatch p3;
            p3.name = "Shroud Gate 3";
            p3.target_address = match + 32;
            p3.patch_bytes = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
            feat.patches.push_back(p3);

            feat.ready = true;
            snprintf(buf, sizeof(buf), "[SCAN READY] %s found at 0x%llX", feat.name.c_str(),
                     static_cast<unsigned long long>(match + 14));
            log_message(buf);
        } else {
            log_message("[WARNING] fogresistance.godModeGate pattern not found.");
        }
        g_features.push_back(feat);
    }


    // 6. Free Crafting & Building Hook (Native)
    {
        FeatureHook feat;
        feat.key = "freeCrafting";
        feat.ini_key = "FreeCrafting";
        feat.name = "Free Crafting & Building (Native)";

        // Target 1: actor.payUsageCost (legacy usage cost)
        sf_native::Pattern pat_usage = sf_native::parse_pattern(
            "actor.payUsageCost",
            "40 55 57 48 8D AC 24 B8 FE FF FF 48 81 EC 48 02 00 00 41 B8 40 01 00 00",
            0, 3
        );
        uintptr_t m_usage = sf_native::scan_pattern(base_addr, module_size, pat_usage);
        if (m_usage) {
            sf_native::MemoryPatch p;
            p.name = "actor.payUsageCost";
            p.target_address = m_usage;
            p.patch_bytes = { 0xB0, 0x01, 0xC3 }; // mov al, 1; ret (success)
            feat.patches.push_back(p);
            snprintf(buf, sizeof(buf), "[SCAN READY] %s (payUsageCost) found at 0x%llX", feat.name.c_str(),
                     static_cast<unsigned long long>(m_usage));
            log_message(buf);
        } else {
            log_message("[WARNING] actor.payUsageCost pattern not found.");
        }

        // Target 2: inventory.checkRequirements (bypasses missing blocks / items check in hammer building & crafting)
        sf_native::Pattern pat_check = sf_native::parse_pattern(
            "inventory.checkRequirements",
            "48 89 5C 24 08 48 89 74 24 18 48 89 7C 24 20 48 89 54 24 10 55 41 54 41 55 41 56 41 57 48 8D AC 24 20",
            0, 19
        );
        uintptr_t m_check = sf_native::scan_pattern(base_addr, module_size, pat_check);
        if (m_check) {
            sf_native::MemoryPatch p;
            p.name = "inventory.checkRequirements";
            p.target_address = m_check;
            // mov qword ptr [rcx], 0; mov qword ptr [rcx+8], 0; mov rax, rcx; ret
            p.patch_bytes = {
                0x48, 0xC7, 0x01, 0x00, 0x00, 0x00, 0x00,
                0x48, 0xC7, 0x41, 0x08, 0x00, 0x00, 0x00, 0x00,
                0x48, 0x89, 0xC8,
                0xC3
            };
            feat.patches.push_back(p);
            snprintf(buf, sizeof(buf), "[SCAN READY] %s (checkRequirements) found at 0x%llX", feat.name.c_str(),
                     static_cast<unsigned long long>(m_check));
            log_message(buf);
        } else {
            log_message("[WARNING] inventory.checkRequirements pattern not found.");
        }

        if (!feat.patches.empty()) {
            feat.ready = true;
        }
        g_features.push_back(feat);
    }

    // 7. Infinite Consumables Hook
    {
        FeatureHook feat;
        feat.key = "infiniteConsumables";
        feat.ini_key = "InfiniteConsumables";
        feat.name = "Infinite Consumables (Native)";

        sf_native::Pattern pat = sf_native::parse_pattern(
            "consumables.usedRemoval",
            "40 38 74 24 68 75 52 39 74 24 70 75 4C",
            5, 2
        );
        uintptr_t match = sf_native::scan_pattern(base_addr, module_size, pat);
        if (match) {
            sf_native::MemoryPatch p;
            p.name = feat.name;
            p.target_address = match + pat.patch_offset;
            p.patch_bytes = { 0x90, 0x90 }; // 2x NOP
            feat.patches.push_back(p);
            feat.ready = true;
            snprintf(buf, sizeof(buf), "[SCAN READY] %s found at 0x%llX", feat.name.c_str(),
                     static_cast<unsigned long long>(p.target_address));
            log_message(buf);
        } else {
            log_message("[WARNING] consumables.usedRemoval pattern not found.");
        }
        g_features.push_back(feat);
    }

    // 8. Creative Mode Hovering & Vertical Flight Hook
    {
        FeatureHook feat;
        feat.key = "creativeHover";
        feat.ini_key = "CreativeHover";
        feat.name = "Creative Mode Hovering & Flight";

        sf_native::Pattern pat_pos = sf_native::parse_pattern(
            "locomotion.hoverPositionHook",
            "0F 57 C9 F3 41 0F 58 47 08 F3 41 0F 11 47 08 49 8B 46 58",
            9, 6
        );
        uintptr_t match_pos = sf_native::scan_pattern(base_addr, module_size, pat_pos);
        if (match_pos) {
            uintptr_t target_addr = match_pos + pat_pos.patch_offset;
            if (!g_hover_trampoline) {
                g_hover_trampoline = allocate_page_near(target_addr);
                if (g_hover_trampoline) {
                    auto tramp_code = create_hover_trampoline(reinterpret_cast<uintptr_t>(HandleCreativeHover));
                    memcpy(g_hover_trampoline, tramp_code.data(), tramp_code.size());
                    DWORD old_protect;
                    VirtualProtect(g_hover_trampoline, 4096, PAGE_EXECUTE_READ, &old_protect);
                    snprintf(buf, sizeof(buf), "[TRAMPOLINE ALLOC] Allocated hover trampoline at 0x%p", g_hover_trampoline);
                    log_message(buf);
                } else {
                    log_message("[ERROR] Failed to allocate trampoline near hover target address.");
                }
            }

            if (g_hover_trampoline) {
                sf_native::MemoryPatch p_pos;
                p_pos.name = "Locomotion Hover Position Hook";
                p_pos.target_address = target_addr;

                int32_t disp = static_cast<int32_t>(reinterpret_cast<uintptr_t>(g_hover_trampoline) - (target_addr + 5));
                p_pos.patch_bytes = {
                    0xE8,
                    static_cast<uint8_t>(disp & 0xFF),
                    static_cast<uint8_t>((disp >> 8) & 0xFF),
                    static_cast<uint8_t>((disp >> 16) & 0xFF),
                    static_cast<uint8_t>((disp >> 24) & 0xFF),
                    0x90 // 1x NOP to pad to 6 bytes
                };
                feat.patches.push_back(p_pos);
                snprintf(buf, sizeof(buf), "[SCAN READY] %s found at 0x%llX", feat.name.c_str(),
                         static_cast<unsigned long long>(target_addr));
                log_message(buf);
            }
        } else {
            log_message("[WARNING] locomotion.hoverPositionHook pattern not found.");
        }

        if (!feat.patches.empty()) {
            feat.ready = true;
        }
        g_features.push_back(feat);
    }

    log_message("=== All Native Patterns Scanned. Starting Live F9 Synchronization Loop ===");

    // =========================================================================
    // 2. Synchronization function for extended.mod.json and native-plugin.ini
    // =========================================================================
    auto sync_all_from_disk = [&]() {
        std::string json_content = read_file_safely(json_path);
        bool has_json = !json_content.empty();

        if (has_json) {
            g_hover_speed_multiplier.store(parse_json_int_setting(json_content, "hoverSpeed", 100));
            std::string up_key = parse_json_string_setting(json_content, "hoverAscendKey", "R");
            std::string down_key = parse_json_string_setting(json_content, "hoverDescendKey", "F");
            g_hover_ascend_vk.store(resolve_vk(up_key, 'R'));
            g_hover_descend_vk.store(resolve_vk(down_key, 'F'));
        }

        for (auto& feat : g_features) {
            if (!feat.ready) continue;

            bool desired = false;
            if (has_json && json_content.find("\"" + feat.key + "\"") != std::string::npos) {
                desired = parse_json_bool_setting(json_content, feat.key, false);
            } else {
                // Fallback to native-plugin.ini
                desired = (GetPrivateProfileIntA("Features", feat.ini_key.c_str(), 0, ini_path.c_str()) != 0);
            }

            if (feat.key == "freeCrafting" && !desired && has_json) {
                desired = parse_json_bool_setting(json_content, "freeBuilding", false) ||
                          parse_json_bool_setting(json_content, "freeCrafting", false) ||
                          parse_json_bool_setting(json_content, "freeRecipeCrafting", false) ||
                          parse_json_bool_setting(json_content, "freeReskill", false);
            }

            sync_feature(feat, desired);
        }
    };

    // Perform initial synchronization immediately
    sync_all_from_disk();

    // =========================================================================
    // 3. Background Watcher: Polls file timestamps and hotkeys
    // =========================================================================
    FILETIME last_json_time = { 0, 0 };
    FILETIME last_ini_time = { 0, 0 };

    WIN32_FILE_ATTRIBUTE_DATA fad;
    if (GetFileAttributesExA(json_path.c_str(), GetFileExInfoStandard, &fad)) {
        last_json_time = fad.ftLastWriteTime;
    }
    if (GetFileAttributesExA(ini_path.c_str(), GetFileExInfoStandard, &fad)) {
        last_ini_time = fad.ftLastWriteTime;
    }

    int poll_counter = 0;
    while (g_running.load()) {
        Sleep(50); // Responsive 50ms tick for hotkey detection

        // Hotkey: Ctrl + H to toggle Creative Hovering on the fly
        if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) && (GetAsyncKeyState('H') & 1)) {
            HWND fg = GetForegroundWindow();
            if (fg) {
                DWORD pid = 0;
                GetWindowThreadProcessId(fg, &pid);
                if (pid == GetCurrentProcessId()) {
                    for (auto& feat : g_features) {
                        if (feat.key == "creativeHover" && feat.ready) {
                            sync_feature(feat, !feat.is_active);
                            break;
                        }
                    }
                }
            }
        }

        poll_counter++;
        if (poll_counter >= 4) { // Check file changes every 200ms
            poll_counter = 0;
            bool changed = false;

            if (GetFileAttributesExA(json_path.c_str(), GetFileExInfoStandard, &fad)) {
                if (CompareFileTime(&fad.ftLastWriteTime, &last_json_time) != 0) {
                    last_json_time = fad.ftLastWriteTime;
                    changed = true;
                }
            }

            if (GetFileAttributesExA(ini_path.c_str(), GetFileExInfoStandard, &fad)) {
                if (CompareFileTime(&fad.ftLastWriteTime, &last_ini_time) != 0) {
                    last_ini_time = fad.ftLastWriteTime;
                    changed = true;
                }
            }

            if (changed) {
                sync_all_from_disk();
            }
        }
    }

    log_message("=== SF Native Sidecar Worker Loop Terminated ===");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_dll_module = hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);
        HANDLE thread = CreateThread(nullptr, 0, WorkerThread, nullptr, 0, nullptr);
        if (thread) {
            CloseHandle(thread);
        }
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        g_running.store(false);
        for (auto& feat : g_features) {
            if (feat.is_active) {
                for (auto& p : feat.patches) {
                    p.restore();
                }
            }
        }
    }
    return TRUE;
}
