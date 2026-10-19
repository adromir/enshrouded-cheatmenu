#pragma once
#include <windows.h>
#include <vector>
#include <cstdint>
#include <string>

namespace sf_native {

struct MemoryPatch {
    std::string name;
    uintptr_t target_address = 0;
    std::vector<uint8_t> original_bytes;
    std::vector<uint8_t> patch_bytes;
    bool is_applied = false;

    bool apply();
    bool restore();
};

bool safe_write_bytes(uintptr_t address, const std::vector<uint8_t>& bytes);

} // namespace sf_native
