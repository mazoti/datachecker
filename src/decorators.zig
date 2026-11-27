//! Drivers that run a check over the input path: `decorate` for per-entry checks (sharing a
//! stat cache between checks) and `decorateWalker` for checks that do their own traversal.
//!
//! Copyright © 2025-present Marcos Mazoti

const globals       = @import("globals");
const file_iterator = @import("file_iterator");
const print         = @import("print");
const std           = @import("std");

pub const Filter = enum { Files, Directories, Both };

/// Runs `process_fn` on every file system entry under the input directory that passes `filter`,
/// framed by `print.header` and `print.results`. Does nothing unless both flags are set.
///
/// `process_fn` is called as `process_fn(.{ path, &total_items, &stat })`. `path` is borrowed and
/// only valid during the call. With `early_exit`, the input path itself is processed first and
/// `process_fn` must return `!bool`: `true` ends the run.
///
/// Stats are cached in `globals.file_stats`, so later checks reuse the first one's traversal. The
/// cache holds every non-ignored file and directory, whatever the filter. `process_fn` must not
/// modify the cache. Not thread-safe.
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

    defer {
        clearCache();
        print.results(total_items, header, total, totals) catch {};
    }

    // Handle functions that can exit early
    if (early_exit) {
        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}",
            .{globals.absolute_input_path});

        if (file_iterator.ignorePath(absolute_path)) return;

        const stat_tmp: ?std.Io.File.Stat = try file_iterator.fetchStatWithErrorHandling(absolute_path, &total_items);
        if (stat_tmp) |stat| {
            if (try process_fn(.{ absolute_path, &total_items, &stat })) return;
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

        return;
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
}

/// Like `decorate`, for checks that do their own traversal: `process_fn(&total_items)` runs once.
/// Returning `true` ends the run without printing a results line.
pub fn decorateWalker(
    comptime comptime_flag: bool,
    runtime_flag:           bool,
    process_fn:             anytype,
    comptime header:        []const u8,
    comptime total:         []const u8,
    comptime totals:        []const u8,
) !void {
    if (!comptime_flag) return;
    if (!runtime_flag)  return print.alignedDisabled(header);

    try print.header(header);
    defer clearCache();

    var total_items: u64 = 0;
    if (try process_fn(&total_items)) return;

    try print.results(total_items, header, total, totals);
}

fn clearCache() void {
    if (globals.clear_cache.load(.monotonic)) {
        globals.file_stats.clearRetainingCapacity();
        globals.clear_cache.store(false, .monotonic);
    }
}
