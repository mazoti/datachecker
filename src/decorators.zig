//!
//! Copyright © 2025-present Marcos Mazoti

const globals       = @import("globals");
const file_iterator = @import("file_iterator");
const print         = @import("print");
const std           = @import("std");

pub const Filter = enum { Files, Directories, Both };

/// Conditionally runs a check in every item if both compile-time and runtime flags are enabled
pub fn decorate(
    comptime comptime_flag: bool,
    runtime_flag:           bool,
    comptime early_exit:    bool,
    comptime filter:        Filter,
    comptime process_fn:    anytype,
    comptime header:        []const u8,
    comptime total:         []const u8,
    comptime totals:        []const u8,
) !void {
    if (!comptime comptime_flag) return;
    if (!runtime_flag)           return print.alignedDisabled(header);

    try print.header(header);

    var total_items: u64 = 0;

    // Handle functions that can exit early
    if (early_exit) {
        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}",
            .{globals.absolute_input_path});

        if (file_iterator.ignorePath(absolute_path)) return print.results(total_items, header, total, totals);

        const stat_tmp: ?std.Io.File.Stat = try file_iterator.fetchStatWithErrorHandling(absolute_path, &total_items);
        if (stat_tmp) |stat| {
            if (try process_fn(.{ absolute_path, &total_items, &stat })) {
                clearCache();
                return print.results(total_items, header, total, totals);
            }
        }
    }

    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.iterator();

        while (iterator.next()) |entry| {
            const cached_stat: std.Io.File.Stat = entry.value_ptr.*;

            if (comptime filter == .Files) {       if (cached_stat.kind != std.Io.File.Kind.file)      continue;  }
            if (comptime filter == .Directories) { if (cached_stat.kind != std.Io.File.Kind.directory) continue;  }
            if (comptime filter == .Both) {        if (cached_stat.kind != std.Io.File.Kind.directory and cached_stat.kind != std.Io.File.Kind.file) continue; }

            if (file_iterator.ignorePath(entry.key_ptr.*)) continue;

            _ = try process_fn(.{ entry.key_ptr.*, &total_items, &cached_stat });
        }

        clearCache();
        return print.results(total_items, header, total, totals);
    }

    var walker: std.Io.Dir.Walker = try globals.input_directory.walk(globals.init.arena.allocator());
    defer walker.deinit(globals.init.io);

    // If no cached stats, walk the directory tree
    while (true) {
        var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
        if (try file_iterator.nextEntry(&walker, &total_items, &entry_tmp)) continue;

        const entry = entry_tmp orelse break;

        if (comptime filter == .Files)       { if (entry.kind != .file)      continue; }
        if (comptime filter == .Directories) { if (entry.kind != .directory) continue; }
        if (comptime filter == .Both)        { if (entry.kind != .directory and entry.kind != .file) continue; }

        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });
        if (file_iterator.ignorePath(absolute_path)) continue;

        // Adds the file or folder to cache
        const stat_tmp: ?std.Io.File.Stat = try file_iterator.fetchStatWithErrorHandling(absolute_path, &total_items);
        if (stat_tmp) |stat| { _ = try process_fn(.{ absolute_path, &total_items, &stat }); }

        continue;
    }

    clearCache();
    return print.results(total_items, header, total, totals);
}

/// Conditionally runs a check in every item if both compile-time and runtime flags are enabled
pub fn decorateWalker(
    comptime comptime_flag: bool,
    runtime_flag:           bool,
    process_fn:             anytype,
    comptime header:        []const u8,
    comptime total:         []const u8,
    comptime totals:        []const u8,
) !void {
    if (!comptime comptime_flag) return;
    if (!runtime_flag)           return print.alignedDisabled(header);

    var total_items: u64 = 0;
    _ = try print.header(header);

    if (try process_fn(&total_items)) {
        return clearCache();
    }

    _ = try print.results(total_items, header, total, totals);
    clearCache();
}

fn clearCache() void {
    if (globals.clear_cache.load(.monotonic)) {
        globals.file_stats.clearRetainingCapacity();
        globals.clear_cache.store(false, .monotonic);
    }
}
