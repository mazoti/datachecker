//! Iterates over the regular files of the input directory.
//!
//! `FileIterator` yields one `Entry` (absolute path + `std.Io.File.Stat`) for every
//! regular file below `globals.input_directory`. `init` picks one of two modes:
//!
//!   * cache mode:  `globals.file_stats` already has entries, so those are replayed
//!                  without touching the file system.
//!   * walker mode: the tree is walked recursively with `std.Io.Dir.Walker`; each
//!                  file is stat'ed and, when `ENABLE_CACHE` is on, stored in
//!                  `globals.file_stats` for later passes.
//!
//! Paths matched by `ignorePath` are skipped. Ignoring only happens when both
//! `config.COMPTIME_IGNORE_PATH_PATTERNS` and the runtime `IGNORE_PATH_PATTERNS`
//! option are enabled.
//!
//! Error handling: unreadable (access denied) paths, busy files and unexpected walker
//! errors are reported with `print.err`, set `globals.exit_error` and are counted in
//! `total_items`; iteration then continues. Any other error also sets `exit_error`,
//! stops the iteration and is returned to the caller.
//!
//! `Entry.path` is only guaranteed to stay valid until the next call to `next`;
//! copy it if you need to keep it. Not thread-safe: the module shares
//! `globals.max_path_buffer` and `globals.file_stats`.
//!
//! Copyright © 2025-present Marcos Mazoti

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");
const std     = @import("std");

pub const FileIterator = struct {
    cache_iterator: ?@TypeOf(globals.file_stats).Iterator = null,
    using_cache:    bool,
    walker:         ?std.Io.Dir.Walker = null,

    pub const Entry = struct {
        path: []const u8,
        stat: std.Io.File.Stat,
    };

    pub fn deinit(self: *FileIterator) void { if (self.walker) |*w| w.deinit(globals.init.io); }

    pub fn init(alloc: std.mem.Allocator) !FileIterator {
        return FileIterator {
            .cache_iterator = globals.file_stats.iterator(),
            .using_cache    = (globals.file_stats.count() > 0),
            .walker         = try globals.input_directory.walk(alloc),
        };
    }

    pub fn next(self: *FileIterator, total_items: *u64) !?Entry {
        if (self.using_cache) {
            while (self.cache_iterator.?.next()) |entry| {
                const stat = entry.value_ptr.*;

                if (stat.kind != .file) continue;
                if (ignorePath(entry.key_ptr.*)) continue;

                return Entry { .path = entry.key_ptr.*, .stat = stat };
            }
            return null;
        }

        while (true) {
            var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
            if (try nextEntry(&self.walker.?, total_items, &entry_tmp)) continue;

            const entry = entry_tmp orelse return null;

            if (entry.kind != .file and entry.kind != .directory) continue;

            const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });
            if (ignorePath(absolute_path)) continue;

            const stat = try fetchStatWithErrorHandling(absolute_path, total_items) orelse continue;

            if (entry.kind != .file) continue;
            return Entry { .path = absolute_path, .stat = stat };
        }
    }
};

/// Gets the next entry or ignores AccessDenied, PermissionDenied and Unexpected errors
pub fn nextEntry(walker: *std.Io.Dir.Walker, total_items: *u64, entry: *?std.Io.Dir.Walker.Entry) !bool {
    entry.* = walker.next(globals.init.io) catch |err| {
        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, walker.inner.name_buffer.items });
        switch (err) {
            error.AccessDenied     => _ = try file_iterator_error(total_items, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path}),
            error.PermissionDenied => _ = try file_iterator_error(total_items, i18n.ERROR_PERMISSION_DENIED,  .{absolute_path}),
            error.Unexpected       => _ = try file_iterator_error(total_items, i18n.ERROR_UNEXPECTED_FILE,    .{absolute_path}),
            else                   => return global_error(err),
        }
        return true; // Signal to continue
    };
    return false;
}

/// Fetch path or ignores AccessDenied, PermissionDenied and FileBusy errors
pub fn fetchStatWithErrorHandling(absolute_path: []const u8, total_items: *u64) !?std.Io.File.Stat {
    return fetchAdd(absolute_path) catch |err| switch (err) {
        error.AccessDenied     => return file_iterator_error(total_items, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path}),
        error.PermissionDenied => return file_iterator_error(total_items, i18n.ERROR_PERMISSION_DENIED,  .{absolute_path}),
        error.FileBusy         => return file_iterator_error(total_items, i18n.ERROR_FILE_BUSY,          .{absolute_path}),
        else                   => return global_error(err),
    };
}

/// Fetch file statistics with optional caching
fn fetchAdd(absolute_path: []const u8) !std.Io.File.Stat {
    if (globals.file_stats.get(absolute_path)) |retrieved_stat| { return retrieved_stat; }

    const stat: std.Io.File.Stat = try statFileOrDirectory(absolute_path);

    // Not in cache, fetch and store
    if (globals.config_parsed.value.ENABLE_CACHE) {
        const key: []const u8 = try globals.init.arena.allocator().dupe(u8, absolute_path);
        errdefer globals.init.arena.allocator().free(key);

        try globals.file_stats.put(key, stat);
    }

    return stat;
}

/// Helper function to stat a file or directory
fn statFileOrDirectory(path: []const u8) !std.Io.File.Stat {
    return std.Io.Dir.cwd().statFile(globals.init.io, path, .{}) catch |err| {
        if (err == error.IsDir) {
            var dir_stat: std.Io.File.Stat = std.mem.zeroes(std.Io.File.Stat);
            dir_stat.kind = .directory;
            return dir_stat;
        }
        return global_error(err);
    };
}

pub fn ignorePath(filepath: []const u8) bool {
    if(!config.COMPTIME_IGNORE_PATH_PATTERNS)             return false;
    if(!globals.config_parsed.value.IGNORE_PATH_PATTERNS) return false;

    return globals.ignore_path_patterns.contains(filepath);
}

fn file_iterator_error(total_items: *u64, comptime msg_fmt: []const u8, args: anytype) !?std.Io.File.Stat {
    try print.err(msg_fmt, args);
    globals.exit_error.store(true, .monotonic);
    total_items.* += 1;
    return null;
}

fn global_error(err: anyerror) anyerror {
    globals.exit_error.store(true, .monotonic);
    return err;
}
