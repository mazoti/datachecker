//! This module implements operations on files, directories or both
//!
//! Copyright © 2025-present Marcos Mazoti

const builtin = @import("builtin");
const config  = @import("config");
const core    = @import("core.zig");
const data    = @import("data.zig");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");
const std     = @import("std");

/// Detects files with timestamps in the future
pub fn checkWrongDates(args: anytype) !bool {
    if ((args[2].*.atime.?.nanoseconds > globals.now.nanoseconds) or
        (args[2].*.ctime.nanoseconds   > globals.now.nanoseconds)   or
        (args[2].*.mtime.nanoseconds   > globals.now.nanoseconds)) {

        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(true, args[1], print.warning, i18n.WRONG_DATES_WARNING, .{args[0]});
    }

    return false;
}

/// Helper function to count the number of items in a directory
fn countItems(base_path: []const u8) !u64 {
    if (globals.dir_count.get(base_path)) |result_count| { return result_count; }

    var result: usize = 0;

    var input_dir: std.Io.Dir = try std.Io.Dir.openDirAbsolute(globals.init.io, base_path, .{ .iterate = true });
    defer input_dir.close(globals.init.io);

    var iterator: std.Io.Dir.Iterator = input_dir.iterate();
    while (try iterator.next(globals.init.io)) |_| { result += 1; }

    // Not in cache, store the result
    if (globals.config_parsed.value.ENABLE_CACHE) {
        const key: []const u8 = try globals.init.arena.allocator().dupe(u8, base_path);

        errdefer globals.init.arena.allocator().free(key);
        try globals.dir_count.put(key, result);
    }

    return result;
}

/// Checks if directory or file names exceed the maximum allowed size
pub fn dirFileNameSize(args: anytype) !bool {
    const dir_file_name: []const u8 = std.fs.path.basename(args[0]);

    if (dir_file_name.len > globals.config_parsed.value.MAX_DIR_FILE_NAME_SIZE) {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(false, args[1], print.warning, i18n.DIR_FILE_NAME_SIZE_WARNING, .{dir_file_name, globals.config_parsed.value.MAX_DIR_FILE_NAME_SIZE});
    }

    return false;
}

/// Detects possible mistakes typing the same character twice
pub fn duplicateCharacters(args: anytype) !bool {
    // Checks last letter before the extension
    const extension: []const u8 = std.fs.path.extension(args[0]);

    if (extension.len > 0) {
        const path_no_ext: []const u8 = args[0][0..(args[0].len - extension.len)];

        if (path_no_ext.len > 1 and path_no_ext[path_no_ext.len - 1] == path_no_ext[path_no_ext.len - 2]) {
            return print.messageSumReturn(true, args[1], print.check, i18n.DUPLICATE_CHARS_FILES_CHECK, .{args[0]});
        }

        // Checks for duplicated extensions
        const index: usize = extension.len + extension.len;
        if (args[0].len >= index) {
            const tmp_extension: []const u8 = args[0][(args[0].len - index)..(args[0].len - extension.len)];
            if (std.mem.eql(u8, extension, tmp_extension)) {
                return print.messageSumReturn(true, args[1], print.check, i18n.DUPLICATE_CHARS_FILES_CHECK_EXT, .{args[0]});
            }
        }
    }

    // Checks for duplicate special characters throughout path
    if (args[0].len < 2) return false;

    for (0..args[0].len - 1) |i| {
        if ((args[0][i] == args[0][i + 1]) and (args[0][i] == ' ' or args[0][i] == '-' or
            args[0][i] == '_' or args[0][i] == '.')) {
            return print.messageSumReturn(true, args[1], print.check, i18n.DUPLICATE_CHARS_FILES_CHECK, .{args[0]});
        }
    }

    return false;
}

/// Identifies empty directories
pub fn emptyDirectories(args: anytype) !bool {
    if (try countItems(args[0]) != 0) return false;
    globals.exit_warning.store(true, .monotonic);
    return print.messageSumReturn(true, args[1], print.warning, i18n.EMPTY_WARNING, .{args[0]});
}

/// Detects files with zero bytes
pub fn emptyFiles(args: anytype) !bool {
    if (args[2].size != 0) return false;
    globals.exit_warning.store(true, .monotonic);
    return print.messageSumReturn(true, args[1], print.warning, i18n.EMPTY_WARNING, .{args[0]});
}

/// Removes empty directories
pub fn emptyRemoveDirectories(args: anytype) !bool {
    if (try countItems(args[0]) != 0) return false;

    globals.clear_cache.store(true, .monotonic);

    try std.Io.Dir.deleteDirAbsolute(globals.init.io, args[0]);
    return print.messageSumReturn(true, args[1], print.removing, "\"{s}\"", .{args[0]});
}

/// Removes files with zero bytes
pub fn emptyRemoveFiles(args: anytype) !bool {
    const file_stat: std.Io.File.Stat = try std.Io.Dir.cwd().statFile(globals.init.io, args[0], .{});

    if (file_stat.size != 0) return false;

    globals.clear_cache.store(true, .monotonic);

    try std.Io.Dir.deleteFileAbsolute(globals.init.io, args[0]);
    return print.messageSumReturn(true, args[1], print.removing, "\"{s}\"", .{args[0]});
}

/// Compares file times and prints a message
fn filesCheck(newer: bool, time_ns: i96, args: anytype) !bool {
    if (globals.config_parsed.value.FILE_TIME == 0) return true;

    if ((newer == true  and time_ns > globals.config_parsed.value.FILE_TIME) or
        (newer == false and time_ns < globals.config_parsed.value.FILE_TIME)) {
        return print.messageSumReturn(false, args[1], print.found, "\"{s}\"", .{args[0]});
    }

    return false;
}

/// Enables file search with newer access time
pub fn filesNewerATime(args: anytype) !bool {
    return filesCheck(true, args[2].*.atime.?.nanoseconds, args);
}

/// Enables file search with newer change time
pub fn filesNewerCTime(args: anytype) !bool {
    return filesCheck(true, args[2].*.ctime.nanoseconds, args);
}

/// Enables file search with newer modified time
pub fn filesNewerMTime(args: anytype) !bool {
    return filesCheck(true, args[2].*.mtime.nanoseconds, args);
}

/// Enables file search with older modified time
pub fn filesOlderATime(args: anytype) !bool {
    return filesCheck(false, args[2].*.atime.?.nanoseconds, args);
}

/// Enables file search with older change time
pub fn filesOlderCTime(args: anytype) !bool {
    return filesCheck(false, args[2].*.ctime.nanoseconds, args);
}

/// Enables file search with older modified time
pub fn filesOlderMTime(args: anytype) !bool {
    return filesCheck(false, args[2].*.mtime.nanoseconds, args);
}

/// Checks if full path length exceeds maximum allowed size
pub fn fullPathSize(args: anytype) !bool {
    if (args[0].len <= globals.config_parsed.value.MAX_FULL_PATH_SIZE) return false;

    globals.exit_warning.store(true, .monotonic);
    return print.messageSumReturn(true, args[1], print.warning, i18n.FULL_PATH_SIZE_WARNING, .{args[0], globals.config_parsed.value.MAX_FULL_PATH_SIZE});
}

/// Identifies files that exceed the configured large file size threshold
pub fn largeFiles(args: anytype) !bool {
    if (args[2].size <= globals.config_parsed.value.LARGE_FILE_SIZE) return false;

    globals.exit_warning.store(true, .monotonic);
    return print.messageSumReturn(true, args[1], print.warning, i18n.LARGE_FILES_WARNING, .{args[0], globals.config_parsed.value.LARGE_FILE_SIZE});
}

/// Identifies files that haven't been accessed within the configured time threshold
pub fn lastAccess(args: anytype) !bool {
    const last_access: i96 = globals.now.nanoseconds - args[2].atime.?.nanoseconds;

    if (last_access <= globals.config_parsed.value.LAST_ACCESS_TIME) return false;

    globals.exit_warning.store(true, .monotonic);
    try print.warning(i18n.LAST_ACCESS_WARNING, .{args[0], globals.config_parsed.value.LAST_ACCESS_TIME});
    args[1].* += args[2].size;
    return true;
}

/// Removes shortcuts and symlinks
pub fn linkRemoveShortcuts(total_items: *u64) !bool {
    try linkShortcutsOrRemove(total_items, true);
    return false;
}

fn linkShortcutsOrRemove(total_items: *u64, remove_entry: bool) !void {
    var walker: std.Io.Dir.Walker = try globals.input_directory.walk(globals.init.arena.allocator());
    defer walker.deinit();

    while (true) {
        var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
        if (try core.nextEntry(&walker, total_items, &entry_tmp)) continue;

        const entry = entry_tmp orelse return;

        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
            .{globals.absolute_input_path, std.fs.path.sep, entry.path});

        if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
            if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
                if(globals.ignore_path_patterns.contains(absolute_path)) continue;
            }
        }

        // Checks if the target of the symlink exists
        if (comptime builtin.os.tag != .windows) {
            if (entry.kind == .sym_link) {
                if (remove_entry) {
                    try std.Io.Dir.deleteFileAbsolute(globals.init.io, absolute_path);
                    total_items.* += 1;
                    try print.removing("\"{s}\"", .{absolute_path});
                    continue;
                }

                const input_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.init.io, absolute_path,
                    .{.mode = .read_only, .lock = .shared})
                catch |err| {
                    _ = switch (err) {
                        error.FileNotFound => try core.exitCodeFn(total_items, print.err, i18n.LINKS_SHORTCUTS_ERROR, .{absolute_path}),
                        else => try core.exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{absolute_path}),
                    };
                    continue;
                };
                defer input_file.close(globals.init.io);
            }
        }

        // Skips entries like pipes and sockets
        if (entry.kind != .file and entry.kind != .directory) {
            globals.exit_warning.store(true, .monotonic);
            try print.warning(i18n.LINKS_SHORTCUTS_WARNING, .{absolute_path});
            total_items.* += 1;
            continue;
        }

        // Adds the file or folder to cache
        if (remove_entry == false) {
            if (try core.fetchStatWithErrorHandling(absolute_path, total_items) == null) continue;
        }

        if (std.ascii.eqlIgnoreCase(std.fs.path.extension(absolute_path), ".lnk")) {
            const input_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.init.io, absolute_path,
                .{.mode = .read_only, .lock = .shared});
            defer input_file.close(globals.init.io);

            var file_reader: std.Io.File.Reader = input_file.reader(globals.init.io, globals.buffer);
            const chunk = try file_reader.interface.take(4);

            if (chunk.len != 4) {
                try core.exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{absolute_path});
                continue;
            }

            if (!std.mem.eql(u8, globals.buffer[0..4], "\x4C\x00\x00\x00")) {
                try core.exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{absolute_path});
                continue;
            }

            total_items.* += 1;

            if (remove_entry) {
                globals.clear_cache.store(true, .monotonic);
                try std.Io.Dir.deleteFileAbsolute(globals.init.io, absolute_path);
                try print.removing("\"{s}\"", .{absolute_path});
                continue;
            }

            globals.exit_warning.store(true, .monotonic);
            try print.warning(i18n.LINKS_SHORTCUTS_WARNING, .{absolute_path});
        }
    }
}

/// Detects shortcuts and symlinks and checks if symlinks are pointing to nowhere
pub fn linkShortcuts(total_items: *u64) !bool {
    try linkShortcutsOrRemove(total_items, false);
    return false;
}

/// Detects directories exceeding configured maximum
pub fn manyItemsDirectory(args: anytype) !bool {
    if (try countItems(args[0]) > globals.config_parsed.value.MAX_ITEMS_DIRECTORY) {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(false, args[1], print.warning, i18n.MANY_ITEMS_DIRECTORIES_WARNING, .{args[0], globals.config_parsed.value.MAX_ITEMS_DIRECTORY});
    }
    return false;
}

/// Detects directories with one item only
pub fn oneItemDirectory(args: anytype) !bool {
    if (try countItems(args[0]) == 1) {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(false, args[1], print.warning, i18n.ONE_ITEM_DIRECTORIES_WARNING, .{args[0]});
    }
    return false;
}

/// Checks for unportable characters and names
pub fn unportableCharacters(args: anytype) !bool {
    const extension: []const u8 = std.fs.path.extension(args[0]);
    const basename:  []const u8 = std.fs.path.basename(args[0]);
    const filename:  []const u8 = basename[0..(basename.len - extension.len)];

    // Windows filename restrictions
    if (data.WINDOWS_RESTRICTIONS.has(filename)) {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(false, args[1], print.warning, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]});
    }

    // Windows silently strips trailing dots and spaces
    if (args[0][args[0].len - 1] == '.' or args[0][args[0].len - 1] == ' ') {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(false, args[1], print.warning, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]});
    }

    // < > : " | ? * and chars below ASCII 32
    for (0..args[0].len) |i| {
        if (args[0][i] < 32) {
            globals.exit_warning.store(true, .monotonic);
            return print.messageSumReturn(false, args[1], print.warning, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]});
        }

        if (args[0][i] == '<' or args[0][i] == '>' or args[0][i] == '"' or args[0][i] == '|' or args[0][i] == '?' or args[0][i] == '*') {
            globals.exit_warning.store(true, .monotonic);
            return print.messageSumReturn(false, args[1], print.warning, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]});
        }

        // Special handling for colon (allowed only in Windows drive letters)
        if (args[0][i] == ':') {
            if (i < (args[0].len - 1) and (args[0][i + 1] == '\\' or args[0][i + 1] == '/')) continue;
            globals.exit_warning.store(true, .monotonic);
            return print.messageSumReturn(false, args[1], print.warning, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]});
        }
    }
    return false;
}
