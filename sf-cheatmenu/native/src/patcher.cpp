#include "patcher.h"

namespace sf_native {

bool safe_write_bytes(uintptr_t address, const std::vector<uint8_t>& bytes) {
    if (address == 0 || bytes.empty()) {
        return false;
    }

    DWORD old_protect = 0;
    if (!VirtualProtect(reinterpret_cast<LPVOID>(address), bytes.size(), PAGE_EXECUTE_READWRITE, &old_protect)) {
        return false;
    }

    memcpy(reinterpret_cast<void*>(address), bytes.data(), bytes.size());

    DWORD dummy = 0;
    VirtualProtect(reinterpret_cast<LPVOID>(address), bytes.size(), old_protect, &dummy);
    FlushInstructionCache(GetCurrentProcess(), reinterpret_cast<LPCVOID>(address), bytes.size());

    return true;
}

bool MemoryPatch::apply() {
    if (is_applied || target_address == 0 || patch_bytes.empty()) {
        return false;
    }

    // Save original bytes if not saved
    if (original_bytes.empty()) {
        original_bytes.resize(patch_bytes.size());
        memcpy(original_bytes.data(), reinterpret_cast<const void*>(target_address), patch_bytes.size());
    }

    if (safe_write_bytes(target_address, patch_bytes)) {
        is_applied = true;
        return true;
    }
    return false;
}

bool MemoryPatch::restore() {
    if (!is_applied || target_address == 0 || original_bytes.empty()) {
        return false;
    }

    if (safe_write_bytes(target_address, original_bytes)) {
        is_applied = false;
        return true;
    }
    return false;
}

} // namespace sf_native
