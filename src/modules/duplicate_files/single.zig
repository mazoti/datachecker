//! Checks for duplicate files by comparing file sizes and contents
//!
//! Copyright © 2025-present Marcos Mazoti

const std    = @import("std");

const config = @import("config");
const i18n   = @import("i18n");
const print  = @import("print");

const core   = @import("core.zig");

// Finds all duplicated files using a single thread
pub fn check(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    // Creates a map to group files by their size (key: file size, value: list of file paths)
    var same_size_files_map: std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8))
        = std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8)){};
    defer core.cleanHashMap(u64, &same_size_files_map);

    // Puts files with same sizes in the same array
    try core.groupFileBySize(&same_size_files_map, walker);

    // Removes entries where only one file has a given size (no duplicates possible)
    try core.removeUniques(&same_size_files_map);

    // Iterates through the map in reverse order, this way the list can be removed after processing
    var i: usize = same_size_files_map.count();
    while (i > 0) {
        i -= 1;

        const key: u64 = same_size_files_map.keys()[i];
        var removed_list: std.array_list.Aligned([]const u8, null) = same_size_files_map.get(key).?;
        defer core.cleanArrayMap(u64, &removed_list, &same_size_files_map, &key);

        var results: std.array_list.Aligned(std.array_list.Aligned([]u8, null), null)
            = std.ArrayList(std.ArrayList([]u8)){};
        defer core.cleanArrayList(&results);

        // Second pass: perform byte-by-byte comparison among same-sized files
        // This populates results with groups of truly identical files (not just same size)
        try core.groupSameFiles(&removed_list, &results, total_items);
        core.removeUniquesArrayList(&results);

        try print.duplicateFiles(&results);
    }
}
