//! This module implements operations on files, directories or both
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");
const builtin = @import("builtin");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

/// Forbidden filenames of windows system
const WINDOWS_RESTRICTIONS = std.StaticStringMap([]const u8).initComptime(.{
    .{ "CON"  , "" }, .{ "PRN"  , "" }, .{ "AUX"  , "" }, .{ "NUL"  , "" },
    .{ "COM1" , "" }, .{ "COM2" , "" }, .{ "COM3" , "" }, .{ "COM4" , "" }, .{ "COM5" , "" }, .{ "COM6" , "" },
    .{ "COM7" , "" }, .{ "COM8" , "" }, .{ "COM9" , "" },
    .{ "LPT1" , "" }, .{ "LPT2" , "" }, .{ "LPT3" , "" }, .{ "LPT4" , "" }, .{ "LPT5" , "" }, .{ "LPT6" , "" },
    .{ "LPT7" , "" }, .{ "LPT8" , "" }, .{ "LPT9" , "" },
});

/// Detects possible mistakes typing the same character twice
pub fn duplicateCharacters(args: anytype) !bool {
    // Checks last letter before the extension
    const extension: []const u8 = std.fs.path.extension(args[0]);

    if (extension.len > 0) {
        const path_no_ext: []const u8 = args[0][0..(args[0].len - extension.len)];
        if (path_no_ext.len > 1 and path_no_ext[path_no_ext.len - 1] == path_no_ext[path_no_ext.len - 2])
            return core.messageSum(print.check, args[1], 1, i18n.DUPLICATE_CHARS_FILES_CHECK,
                .{args[0], path_no_ext[path_no_ext.len - 2]});

        // Checks for duplicated extensions
        const index: usize = extension.len + extension.len;
        if (args[0].len >= index) {
            const tmp_extension: []const u8 = args[0][(args[0].len - index)..(args[0].len - extension.len)];
            if (std.mem.eql(u8, extension, tmp_extension)) {
                return core.messageSum(print.check, args[1], 1, i18n.DUPLICATE_CHARS_FILES_CHECK_EXT,
                .{args[0], extension});
            }
        }
    }

    // Checks for duplicate special characters throughout path
    if (args[0].len < 2) return false;

    for (0..args[0].len - 1) |i| {
        if ((args[0][i] == args[0][i + 1]) and (args[0][i] == ' ' or args[0][i] == '-' or args[0][i] == '_'
            or args[0][i] == '.')) return core.messageSum(print.check, args[1], 1,
                i18n.DUPLICATE_CHARS_FILES_CHECK, .{args[0], args[0][i]});
    }

    return false;
}

/// Detects shortcuts and symlinks and checks if symlinks are pointing to nowhere
pub fn linkShortcuts(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    while (true) {
        const entry_tmp: ?std.Io.Dir.Walker.Entry = walker.next(globals.io) catch |err| switch (err) {
            error.AccessDenied => {
                const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
                    .{globals.absolute_input_path, std.fs.path.sep, walker.inner.name_buffer.items});

                _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
                continue;
            },
            else => return err,
        };

        if (entry_tmp) |entry| {
            const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
                .{globals.absolute_input_path, std.fs.path.sep, entry.path});

            // Checks if the target of the symlink exists
            if (comptime builtin.os.tag != .windows) {
                if (entry.kind == .sym_link) {
                    const input_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.io, absolute_path,
                        .{.mode = .read_only, .lock = .shared})
                    catch |err| {
                        _ = switch (err) {
                            error.FileNotFound => try core.messageSum(print.err, total_items, 1,
                                i18n.LINKS_SHORTCUTS_ERROR, .{absolute_path}),
                            else => try core.messageSum(print.err, total_items, 1,
                                i18n.ERROR_READING_FILE, .{absolute_path}),
                        };

                        continue;
                    };
                    defer input_file.close(globals.io);
                }
            }

            // Skips entries like pipes and sockets
            if (entry.kind != .file and entry.kind != .directory) {
                _ = try core.messageSum(print.warning, total_items, 1,
                    i18n.LINKS_SHORTCUTS_WARNING, .{absolute_path});
                continue;
            }

            // Adds the file or directory to cache
            _ = core.fetchAdd(absolute_path) catch |err| switch (err) {
                error.AccessDenied => {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
                    continue;
                },
                error.FileBusy => {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_FILE_BUSY, .{absolute_path});
                    continue;
                },
                else => return err,
            };

            if (std.ascii.eqlIgnoreCase(std.fs.path.extension(absolute_path), ".lnk")) {
                const input_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, absolute_path,
                    .{.mode = .read_only, .lock = .shared});
                defer input_file.close(globals.io);

                var file_reader: std.Io.File.Reader = input_file.reader(globals.io, globals.buffer);
                const chunk = try file_reader.interface.take(4);

                if (chunk.len != 4) {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{absolute_path});
                    continue;
                }

                if (!std.mem.eql(u8, globals.buffer[0..4], "\x4C\x00\x00\x00")) {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{absolute_path});
                    continue;
                }

                _ = try core.messageSum(print.warning, total_items, 1,
                    i18n.LINKS_SHORTCUTS_WARNING, .{absolute_path});
            }
            continue;
        }
        return;
    }
}

/// Detects files with zero bytes
pub fn emptyFiles(args: anytype) !bool {
    return if (args[2].size == 0) core.messageSum(print.warning, args[1], 1,
        i18n.EMPTY_FILES_WARNING, .{args[0]}) else false;
}

/// Identifies files that exceed the configured large file size threshold
pub fn largeFiles(args: anytype) !bool {
    return if (args[2].size > globals.config_parsed.value.LARGE_FILE_SIZE) core.messageSum(print.warning, args[1],
        1, i18n.LARGE_FILES_WARNING, .{args[0], globals.config_parsed.value.LARGE_FILE_SIZE}) else false;
}

/// Identifies files that haven't been accessed within the configured time threshold
pub fn lastAccess(args: anytype) !bool {
    const last_access: i96 = globals.now_stat.atime.?.nanoseconds - args[2].atime.?.nanoseconds;
    return if (last_access > globals.config_parsed.value.LAST_ACCESS_TIME) core.messageSum(print.warning,
        args[1], args[2].size, i18n.LAST_ACCESS_WARNING, .{args[0], globals.config_parsed.value.LAST_ACCESS_TIME})
        else false;
}

/// Detects files with timestamps in the future
pub fn checkWrongDates(args: anytype) !bool {
    if ((args[2].*.atime.?.nanoseconds > globals.now_stat.atime.?.nanoseconds) or
        (args[2].*.ctime.nanoseconds   > globals.now_stat.ctime.nanoseconds)   or
        (args[2].*.mtime.nanoseconds   > globals.now_stat.mtime.nanoseconds))
            return core.messageSum(print.warning, args[1], 1, i18n.WRONG_DATES_WARNING, .{args[0]});

    return false;
}

/// Identifies empty directories
pub fn emptyDirectories(args: anytype) !bool {
    return if (try countItems(args[0]) == 0) core.messageSum(print.warning, args[1], 1,
        i18n.EMPTY_DIRECTORIES_WARNING, .{args[0]}) else false;
}

/// Detects directories exceeding configured maximum
pub fn manyItemsDirectory(args: anytype) !bool {
    return if (try countItems(args[0]) > globals.config_parsed.value.MAX_ITEMS_DIRECTORY)
        !(try core.messageSum(print.warning, args[1], 1, i18n.MANY_ITEMS_DIRECTORIES_WARNING,
        .{args[0], globals.config_parsed.value.MAX_ITEMS_DIRECTORY})) else false;
}

/// Detects directories with one item only
pub fn oneItemDirectory(args: anytype) !bool {
    return if (try countItems(args[0]) == 1) !(try core.messageSum(print.warning, args[1], 1,
        i18n.ONE_ITEM_DIRECTORIES_WARNING, .{args[0]})) else false;
}

/// Checks if directory or file names exceed the maximum allowed size
pub fn dirFileNameSize(args: anytype) !bool {
    const dir_file_name: []const u8 = std.fs.path.basename(args[0]);

    if (dir_file_name.len > globals.config_parsed.value.MAX_DIR_FILE_NAME_SIZE)
        return !(try core.messageSum(print.warning, args[1], 1, i18n.DIR_FILE_NAME_SIZE_WARNING,
       .{dir_file_name, globals.config_parsed.value.MAX_DIR_FILE_NAME_SIZE}));

    return false;
}

/// Checks if full path length exceeds maximum allowed size
pub fn fullPathSize(args: anytype) !bool {
    if (args[0].len > globals.config_parsed.value.MAX_FULL_PATH_SIZE)
        return core.messageSum(print.warning, args[1], 1, i18n.FULL_PATH_SIZE_WARNING,
        .{args[0], globals.config_parsed.value.MAX_FULL_PATH_SIZE});

    return false;
}

/// Checks for unportable characters and names
pub fn unportableCharacters(args: anytype) !bool {
    const extension: []const u8 = std.fs.path.extension(args[0]);
    const basename:  []const u8 = std.fs.path.basename(args[0]);
    const filename:  []const u8 = basename[0..(basename.len - extension.len)];

    // Windows filename restrictions
    if (WINDOWS_RESTRICTIONS.has(filename)) return !(try core.messageSum(print.warning,
        args[1], 1, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]}));

    // Windows silently strips trailing dots and spaces
    if (args[0][args[0].len - 1] == '.' or args[0][args[0].len - 1] == ' ')
        return !(try core.messageSum(print.warning, args[1], 1, i18n.UNPORTABLE_CHARS_WARNING, .{args[0]}));

    // < > : " | ? * and chars below ASCII 32
    for (0..args[0].len) |i| {
        if (args[0][i] < 32) return !(try core.messageSum(print.warning, args[1], 1,
            i18n.UNPORTABLE_CHARS_WARNING, .{args[0]}));

        if (args[0][i] == '<' or args[0][i] == '>' or args[0][i] == '"' or args[0][i] == '|' or args[0][i] == '?'
            or args[0][i] == '*') return !(try core.messageSum(print.warning, args[1], 1,
            i18n.UNPORTABLE_CHARS_WARNING, .{args[0]}));

        // Special handling for colon (allowed only in Windows drive letters)
        if (args[0][i] == ':') {
            if (i < (args[0].len - 1) and args[0][i + 1] == '\\') continue;
            return !(try core.messageSum(print.warning, args[1], 1, i18n.UNPORTABLE_CHARS_WARNING,
                .{args[0]}));
        }
    }
    return false;
}

/// Helper function to count the number of items in a directory
fn countItems(base_path: []const u8) !usize {
    var result: usize = 0;

    var input_dir: std.Io.Dir = try std.Io.Dir.openDirAbsolute(globals.io, base_path, .{ .iterate = true });
    defer input_dir.close(globals.io);

    var iterator: std.Io.Dir.Iterator = input_dir.iterate();
    while (try iterator.next(globals.io)) |_| { result += 1; }

    return result;
}
