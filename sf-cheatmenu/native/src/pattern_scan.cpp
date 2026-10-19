#include "pattern_scan.h"
#include <sstream>

namespace sf_native {

Pattern parse_pattern(const std::string& name, const std::string& pattern_str, size_t patch_offset, size_t patch_size) {
    Pattern pat;
    pat.name = name;
    pat.patch_offset = patch_offset;
    pat.patch_size = patch_size;

    std::istringstream stream(pattern_str);
    std::string byte_str;
    while (stream >> byte_str) {
        if (byte_str == "?" || byte_str == "??") {
            pat.bytes.push_back(0);
            pat.mask.push_back(false);
        } else {
            uint8_t byte = static_cast<uint8_t>(std::stoul(byte_str, nullptr, 16));
            pat.bytes.push_back(byte);
            pat.mask.push_back(true);
        }
    }
    return pat;
}

uintptr_t scan_pattern(uintptr_t base_addr, size_t module_size, const Pattern& pattern) {
    const size_t pattern_len = pattern.bytes.size();
    if (pattern_len == 0 || module_size < pattern_len) {
        return 0;
    }

    const uint8_t* scan_start = reinterpret_cast<const uint8_t*>(base_addr);
    const size_t max_offset = module_size - pattern_len;

    for (size_t i = 0; i <= max_offset; ++i) {
        bool match = true;
        for (size_t j = 0; j < pattern_len; ++j) {
            if (pattern.mask[j] && scan_start[i + j] != pattern.bytes[j]) {
                match = false;
                break;
            }
        }
        if (match) {
            return base_addr + i;
        }
    }

    return 0;
}

} // namespace sf_native
