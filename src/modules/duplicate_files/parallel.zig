//! Main duplicate file detection pipeline with three-stage filtering:
//! 1. Size-based grouping (fast, eliminates most non-duplicates)
//! 2. Hash-based grouping (CPU-intensive, identifies potential duplicates)
//! 3. Byte-by-byte comparison (I/O-intensive, confirms true duplicates)
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");
const builtin = @import("builtin");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

const modules = @import("../core.zig");

pub fn check(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    var same_size_files_map: std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8))
        = std.AutoArrayHashMapUnmanaged(u64, std.ArrayList([]const u8)){};
    defer core.cleanHashMap(u64, &same_size_files_map);

    try core.groupFileBySize(&same_size_files_map, walker);
    try core.removeUniques(&same_size_files_map);

    var i: usize = same_size_files_map.count();

    while (i > 0) {
        i -= 1;

        // Eager cleanup after processing each size group to reduce peak memory usage
        const key: u64 = same_size_files_map.keys()[i];

        var removed_list: std.array_list.Aligned([]const u8, null) = same_size_files_map.get(key).?;
        defer core.cleanArrayMap(u64, &removed_list, &same_size_files_map, &key);

        var sizeAndHash: std.AutoArrayHashMapUnmanaged([32]u8, std.ArrayList([]const u8))
            = std.AutoArrayHashMapUnmanaged([32]u8, std.ArrayList([]const u8)){};
        defer core.cleanHashMap([32]u8, &sizeAndHash);

        // Parallel hashing: most CPU-intensive phase, benefits greatly from multi-threading
        try hashFiles(&removed_list, &sizeAndHash);
        try removeUniquesHash(&sizeAndHash);

        // Processes each group of files sharing both size AND hash
        var j: usize = sizeAndHash.count();
        while (j > 0) {
            j -= 1;
            var removed_list_map: std.array_list.Aligned([]const u8, null) = sizeAndHash.get(sizeAndHash.keys()[j]).?;

            var results: std.ArrayList(std.ArrayList([]u8)) = std.ArrayList(std.ArrayList([]u8)){};
            defer core.cleanArrayList(&results);

            try core.groupSameFiles(&removed_list_map, &results, total_items);
            core.removeUniquesArrayList(&results);
            try print.duplicateFiles(&results);
        }
    }
}

/// Orchestrates parallel file hashing using a thread pool pattern
fn hashFiles(input: *std.ArrayList([]const u8), map_hash: *std.AutoArrayHashMapUnmanaged([32]u8,
std.ArrayList([]const u8))) !void {
    if (input.items.len == 0) return;

    const max_jobs_limit: std.Io.Limit = std.Io.Limit.limited64(globals.config_parsed.value.MAX_JOBS);

    var parallel_threaded: std.Io.Threaded = std.Io.Threaded.init(globals.alloc.*, .{.async_limit = max_jobs_limit,
        .concurrent_limit = max_jobs_limit, .environ = std.process.Environ.empty });
    defer parallel_threaded.deinit();

    const io: std.Io = parallel_threaded.io();

    globals.group = std.Io.Group.init;
    defer globals.group.cancel(io);

    for (input.items) |filepath| {
        globals.semaphore.wait();
        globals.group.async(io, parallelHash, .{filepath, map_hash});
    }

    try globals.group.await(io);
}

/// Thread-safe worker function that hashes one file and updates shared state
/// Each worker operates independently until the critical section (map update)
fn parallelHash(filepath: []const u8, map_hash: *std.AutoArrayHashMapUnmanaged([32]u8, std.ArrayList([]const u8)))
void {
    defer globals.semaphore.post();

    var file_hash: [32]u8 = undefined;

    // Blake3 chosen for: fast performance, strong collision resistance, streaming capability
    modules.hashFile(std.crypto.hash.Blake3, filepath, &file_hash) catch |err| {
        _ = print.err(i18n.ERROR_HASH_FILE, .{filepath, err}) catch |err_inside| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n",
                .{ @src().file, @src().line, err_inside });
                return;
            };
        return;
    };

    const append_data: []const u8 = globals.alloc.*.dupe(u8, filepath) catch |err| {
        _ = print.err(i18n.ERROR_ALLOC_MEM, .{filepath, err}) catch |err_inside| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n",
                .{ @src().file, @src().line, err_inside });
                return;
            };
        return;
    };

    errdefer globals.alloc.free(append_data);

    globals.mutex.lock();
    defer globals.mutex.unlock();

        // Case 1: Hash already exists - append to existing list (duplicate detected)
        if (map_hash.getPtr(file_hash)) |paths| {
            paths.append(globals.alloc.*, append_data) catch |err| {
                _ = print.err(i18n.ERROR_APPEND_PATH, .{err}) catch |err_inside| {
                    if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n",
                        .{ @src().file, @src().line, err_inside });
                    return;
                };
            };
            return;
        } 

        // Case 2: New hash - create entry. This is the first file with this hash value
        var path_list: std.array_list.Aligned([]const u8, null) = std.ArrayList([]const u8){};
        path_list.append(globals.alloc.*, append_data) catch |err| {
            _ = print.err(i18n.ERROR_APPEND_PATH, .{err}) catch |err_inside| {
                if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n",
                    .{ @src().file, @src().line, err_inside });
                return;
            };
            return;
        };

        // Insert new hash entry into map - subsequent files with same hash will hit Case 1
        map_hash.put(globals.alloc.*, file_hash, path_list) catch |err| {
            _ = print.err(i18n.ERROR_INSERT_HASHMAP, .{err}) catch |err_inside| {
                if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n",
                    .{ @src().file, @src().line, err_inside });
                return;
            };
            return;
        };
}

/// Prune the hash map by removing singleton entries (files with unique hashes)
/// Optimization: files that hash to a unique value cannot have duplicates, so exclude from further processing
/// Memory benefit: early removal reduces peak memory usage before expensive byte comparison phase
fn removeUniquesHash(map_hash: *std.AutoArrayHashMapUnmanaged([32]u8, std.ArrayList([]const u8))) !void {
    var i: usize = map_hash.count();
    while (i > 0) {
        i -= 1;

        if (map_hash.values()[i].items.len == 1) {
            const key: [32]u8 = map_hash.keys()[i];
            var removed_list: std.array_list.Aligned([]const u8, null) = map_hash.get(key).?;
            core.cleanArrayMap([32]u8, &removed_list, map_hash, &key);
        }
    }
}
