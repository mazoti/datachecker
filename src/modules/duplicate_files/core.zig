//! Main entry point for duplicate file checking
//! Delegates to either parallel or sequential implementation based on configurations
//!
//! Copyright © 2025-present Marcos Mazoti

const std          = @import("std");

const config       = @import("config");
const globals      = @import("globals");

const dup_parallel = @import("parallel.zig");
const dup_single   = @import("single.zig");
const modules      = @import("../core.zig");

pub fn check(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    return if (globals.config_parsed.value.DUPLICATE_FILES_PARALLEL) dup_parallel.check(total_items, walker)
        else dup_single.check(total_items, walker);
}

/// Groups files by their size into a hash map
/// Uses cache-first strategy to avoid redundant filesystem stat calls
pub fn groupFileBySize(map: *std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8)),
walker: *std.Io.Dir.Walker) !void {
    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.keyIterator();
        while (iterator.next()) |entry| {
            const cached_stat: std.Io.File.Stat = globals.file_stats.get(entry.*) orelse continue;

            if (cached_stat.kind == std.Io.File.Kind.file) try groupFileBySizeCore(&cached_stat, map, entry.*);
        }
        return;
    }

    while (try walker.next(globals.io)) |entry| {
        if (entry.kind != .file and entry.kind != .directory) continue;

        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
            .{globals.absolute_input_path, std.fs.path.sep, entry.path});

        // Add the file to cache
        const stat: std.Io.File.Stat = try modules.fetchAdd(absolute_path);

        if (entry.kind == .file) try groupFileBySizeCore(&stat, map, absolute_path);
    }
}

fn groupFileBySizeCore(stat: *const std.Io.File.Stat, map: *std.AutoArrayHashMapUnmanaged(u64,
std.ArrayList([]const u8)), absolute_path: []const u8) !void {
    // Ignore empty files
    if (stat.size == 0) return;

    const gop: std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8)).GetOrPutResult
        = try map.getOrPut(globals.alloc.*, stat.size);

    if (!gop.found_existing) gop.value_ptr.* = std.ArrayList([]const u8){};

    const data: []const u8 = try globals.alloc.*.dupe(u8, absolute_path);

    errdefer globals.alloc.free(data);
    try gop.value_ptr.append(globals.alloc.*, data);
}

/// Removes files with unique sizes to reduce memory and processing
pub fn removeUniques(map: *std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8))) !void {
    var i: usize = map.count();
    while (i > 0) {
        i -= 1;
        if (map.values()[i].items.len == 1) {
            const key: u64 = map.keys()[i];
            var removed_list: std.array_list.Aligned([]const u8, null) = map.get(key).?;
            cleanArrayMap(u64, &removed_list, map, &key);
        }
    }
}

/// Groups files that have identical content into lists
/// Files must already have the same size/hash; this does byte-by-byte comparison
///
/// ALGORITHM: Incremental clustering - each file is compared against first file
/// in each existing group. This is O(n*g) where g = number of groups.
/// LIMITATION: Only compares against first file in each group, assuming transitivity
/// (if A==B and B==C then A==C, which holds for file equality)
pub fn groupSameFiles(paths: *const std.ArrayList([]const u8), results: *std.ArrayList(std.ArrayList([]u8)),
total_bytes: *u64) !void {
    outer: for (paths.items) |path| {
        for (results.items) |*result| {
            if (try sameFile(path, result.items[0])) {
                const data: []u8 = try globals.alloc.*.dupe(u8, path);

                errdefer globals.alloc.free(data);
                try result.append(globals.alloc.*, data);

                const stat = try std.Io.Dir.cwd().statFile(globals.io, path, .{});
                total_bytes.* += stat.size;

                continue :outer;
            }
        }

        // Different from all other files, add another result
        var path_list: std.array_list.Aligned([]u8, null) = std.ArrayList([]u8){};

        const data: []u8 = try globals.alloc.*.dupe(u8, path);

        errdefer globals.alloc.free(data);
        try path_list.append(globals.alloc.*, data);

        errdefer cleanList(std.ArrayList([]u8), &path_list);
        try results.append(globals.alloc.*, path_list);
    }
}

/// Remove groups that only contain a single file (no duplicates found)
pub fn removeUniquesArrayList(array_list: *std.ArrayList(std.ArrayList([]u8))) void {
    var i: usize = array_list.items.len;
    while (i > 0) {
        i -= 1;
        if (array_list.items[i].items.len == 1) {
            var removed: std.array_list.Aligned([]u8,null) = array_list.orderedRemove(i);
            cleanList(std.ArrayList([]u8), &removed);
        }
    }
}

/// Cleans up an array list and free all its memory
pub fn cleanArrayList(array_list: *std.ArrayList(std.ArrayList([]u8))) void {
    for (array_list.items) |*value| { cleanList(std.ArrayList([]u8), value); }
    array_list.deinit(globals.alloc.*);
}

/// Cleans up a hash map and free all its memory
pub fn cleanHashMap(comptime T: type, map: *std.AutoArrayHashMapUnmanaged(T, std.ArrayList([]const u8)),) void {
    var iter = map.iterator();
    while (iter.next()) |entry| { cleanList(std.ArrayList([]const u8), entry.value_ptr); }
    map.deinit(globals.alloc.*);
}

/// Cleans up and removes a specific entry from the map
/// Used during removeUniques to clean up single-file entries
pub fn cleanArrayMap(comptime T: type, removed_list: *std.ArrayList([]const u8),
same_size_files_map: *std.AutoArrayHashMapUnmanaged(T, std.ArrayList([]const u8)),
key: *const T) void {
    cleanList(std.ArrayList([]const u8), removed_list);
    _ = same_size_files_map.swapRemove(key.*);
}

/// Free all strings in a list and deinitialize the list
fn cleanList(comptime T: type, list: *T) void {
    for (list.items) |value| { globals.alloc.*.free(value); }
    list.deinit(globals.alloc.*);
}

/// Compares two files byte-by-byte to determine if they're identical
/// Files are assumed to already have the same size (enforced by grouping strategy)
///
/// PERFORMANCE: Uses chunked reading to handle large files without loading into memory
/// CORRECTNESS: Compares byte-for-byte, not just hashes - eliminates hash collision risk
fn sameFile(filepath1: []const u8, filepath2: []const u8) !bool {
    const file1: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, filepath1,
        .{.mode = .read_only, .lock = .shared});
    defer file1.close(globals.io);

    const file2: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, filepath2,
        .{.mode = .read_only, .lock = .shared});
    defer file2.close(globals.io);

    var file_reader1: std.Io.File.Reader = file1.reader(globals.io, globals.buffer[0..globals.buffer_size]);
    var file_reader2: std.Io.File.Reader = file2.reader(globals.io, globals.buffer[globals.buffer_size..
        globals.buffer_total]);

    // Compare files in chunks to handle large files efficiently
    while (true) {
        const chunk1: []u8 = file_reader1.interface.take(globals.buffer_size) catch |err| blk: switch (err) {
            error.EndOfStream => break :blk file_reader1.interface.buffer[0..file_reader1.interface.end],
            else => return err,
        };

        const chunk2: []u8 = file_reader2.interface.take(globals.buffer_size) catch |err| blk: switch (err) {
            error.EndOfStream => break :blk file_reader2.interface.buffer[0..file_reader2.interface.end],
            else => return err,
        };

        // Check if it reads the expected amount
        if (chunk1.len != chunk2.len) return false;

        // Compare the chunks
        if (!std.mem.eql(u8, chunk1[0..chunk1.len], chunk2[0..chunk2.len])) return false;

        // Last chunk, end of stream
        if (chunk1.len < globals.buffer_size) return true;
    }

    unreachable;
}
