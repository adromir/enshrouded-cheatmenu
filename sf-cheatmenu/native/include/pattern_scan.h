#pragma once
#include <windows.h>
#include <vector>
#include <string>
#include <cstdint>

namespace sf_native {

struct Pattern {
    std::string name;
    std::vector<uint8_t> bytes;
    std::vector<bool> mask;
    size_t patch_offset;
    size_t patch_size;
};

Pattern parse_pattern(const std::string& name, const std::string& pattern_str, size_t patch_offset, size_t patch_size);

uintptr_t scan_pattern(uintptr_t base_addr, size_t module_size, const Pattern& pattern);

} // namespace sf_native
