//! Runs modules using decorators to avoid duplicated code
//!
//! Copyright © 2025-present Marcos Mazoti

const compressed    = @import("compressed.zig");
const confidential  = @import("confidential.zig");
const duplicates    = @import("duplicate_files/core.zig");
const decorators    = @import("decorators");
const builtin       = @import("builtin");
const config        = @import("config");
const file_iterator = @import("file_iterator");
const globals       = @import("globals");
const i18n          = @import("i18n");
const integrity     = @import("integrity.zig");
const magic_numbers = @import("magic_numbers.zig");
const parser        = @import("parser.zig");
const print         = @import("print");
const stats         = @import("stats.zig");
const std           = @import("std");
const txt           = @import("text.zig");
const useless       = @import("useless.zig");

/// Enables compressed files check
pub fn compressedFiles() !void {
    try decorators.decorate(config.COMPTIME_COMPRESSED_FILES, true, false, decorators.Filter.Files, compressed.check, i18n.COMPRESSED_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables confidential files check
pub fn confidentialFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_CONFIDENTIAL_FILES, true, confidential.checkConfidential, i18n.CONFIDENTIAL_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables debug information check
pub fn debugInfo() !void {
    try decorators.decorate(config.COMPTIME_DEBUG_INFO, true, false, decorators.Filter.Files, useless.debugInfo, i18n.DEBUG_INFO_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables directory and filename size check
pub fn dirFileNameSize() !void {
    try decorators.decorate(config.COMPTIME_DIRECTORY_FILE_NAME_SIZE, true, true, decorators.Filter.Both, stats.dirFileNameSize, i18n.DIR_FILE_NAME_SIZE_HEADER, i18n.DIR_FILE_NAME_SIZE_TOTAL, i18n.DIR_FILE_NAME_SIZE_TOTALS);
}

/// Enables duplicate characters check
pub fn duplicateChars() !void {
    try decorators.decorate(config.COMPTIME_DUPLICATE_CHARS_FILES, true, false, decorators.Filter.Files, stats.duplicateCharacters, i18n.DUPLICATE_CHARS_FILES_HEADER, i18n.DUPLICATE_CHARS_FILES_TOTAL, i18n.DUPLICATE_CHARS_FILES_TOTALS);
}

/// Enables duplicate files check in parallel
pub fn duplicateFilesParallel() !void {
    try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES_PARALLEL, true, duplicates.check_parallel, i18n.DUPLICATE_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables duplicate files check
pub fn duplicateFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES, true, duplicates.check, i18n.DUPLICATE_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables empty files check
pub fn emptyFiles() !void {
    try decorators.decorate(config.COMPTIME_EMPTY_FILES, true, false, decorators.Filter.Files, stats.emptyFiles, i18n.EMPTY_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables empty directories check
pub fn emptyDirectories() !void {
    try decorators.decorate(config.COMPTIME_EMPTY_DIRECTORIES, true, true, decorators.Filter.Directories, stats.emptyDirectories, i18n.EMPTY_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL, i18n.DIRECTORIES_TOTALS);
}

/// Enables end of line check
pub fn endOfLine() !void {
    try decorators.decorateWalker(config.COMPTIME_END_OF_LINE, true, txt.endOfLine, i18n.END_OF_LINE_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with newer access time
pub fn filesNewerATime() !void {
    try decorators.decorate(config.COMPTIME_FILES_NEWER_ATIME, true, true, decorators.Filter.Files, stats.filesNewerATime, i18n.FILES_NEWER_ATIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with newer change time
pub fn filesNewerCTime() !void {
    try decorators.decorate(config.COMPTIME_FILES_NEWER_CTIME, true, true, decorators.Filter.Files, stats.filesNewerCTime, i18n.FILES_NEWER_CTIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with newer modified time
pub fn filesNewerMTime() !void {
    try decorators.decorate(config.COMPTIME_FILES_NEWER_MTIME, true, true, decorators.Filter.Files, stats.filesNewerMTime, i18n.FILES_NEWER_MTIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with older access time
pub fn filesOlderATime() !void {
    try decorators.decorate(config.COMPTIME_FILES_OLDER_ATIME, true, true, decorators.Filter.Files, stats.filesOlderATime, i18n.FILES_OLDER_ATIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with older modified time
pub fn filesOlderCTime() !void {
    try decorators.decorate(config.COMPTIME_FILES_OLDER_CTIME, true, true, decorators.Filter.Files, stats.filesOlderCTime, i18n.FILES_OLDER_CTIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables file search with older modified time
pub fn filesOlderMTime() !void {
    try decorators.decorate(config.COMPTIME_FILES_OLDER_MTIME, true, true, decorators.Filter.Files, stats.filesOlderMTime, i18n.FILES_OLDER_MTIME_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables full path size check
pub fn fullPathSize() !void {
    try decorators.decorate(config.COMPTIME_FULL_PATH_SIZE, true, true, decorators.Filter.Both, stats.fullPathSize, i18n.FULL_PATH_SIZE_HEADER, i18n.FULL_PATH_SIZE_TOTAL, i18n.FULL_PATH_SIZE_TOTALS);
}

/// Enables integrity files check in parallel
pub fn integrityFilesParallel() !void {
    try decorators.decorateWalker(config.COMPTIME_INTEGRITY_FILES_PARALLEL, true, integrity.checkParallel, i18n.INTEGRITY_FILES_HEADER, i18n.INTEGRITY_FILES_TOTAL, i18n.INTEGRITY_FILES_TOTALS);
}

/// Enables integrity files check
pub fn integrityFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_INTEGRITY_FILES, true, integrity.checkSingle, i18n.INTEGRITY_FILES_HEADER, i18n.INTEGRITY_FILES_TOTAL, i18n.INTEGRITY_FILES_TOTALS);
}

/// Enables large files check
pub fn largeFiles() !void {
    try decorators.decorate(config.COMPTIME_LARGE_FILES, true, false, decorators.Filter.Files, stats.largeFiles, i18n.LARGE_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables last access files
pub fn lastAccess() !void {
    try decorators.decorate(config.COMPTIME_LAST_ACCESS_FILES, true, false, decorators.Filter.Files, stats.lastAccess, i18n.LAST_ACCESS_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables legacy files check
pub fn legacyFiles() !void {
    try decorators.decorate(config.COMPTIME_LEGACY_FILES, true, false, decorators.Filter.Files, useless.legacyFiles, i18n.LEGACY_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables links and shortcuts check
pub fn linksShortcuts() !void {
    try decorators.decorateWalker(config.COMPTIME_LINKS_SHORTCUTS, true, stats.linkShortcuts, i18n.LINKS_SHORTCUTS_HEADER, i18n.LINKS_SHORTCUTS_TOTAL, i18n.LINKS_SHORTCUTS_TOTALS);
}

/// Enables magic numbers check
pub fn magicNumbers() !void {
    try decorators.decorate(config.COMPTIME_MAGIC_NUMBERS, true, false, decorators.Filter.Files, magic_numbers.check, i18n.MAGIC_NUMBERS_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables many items directory check
pub fn manyItemsDirectories() !void {
    try decorators.decorate(config.COMPTIME_MANY_ITEMS_DIRECTORIES, true, true, decorators.Filter.Directories, stats.manyItemsDirectories, i18n.MANY_ITEMS_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL, i18n.DIRECTORIES_TOTALS);
}

/// Enables no extension check
pub fn noExtension() !void {
    try decorators.decorate(config.COMPTIME_NO_EXTENSION, true, false, decorators.Filter.Files, magic_numbers.checkNoExtension, i18n.NO_EXTENSION_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables one item directory check
pub fn oneItemDirectories() !void {
    try decorators.decorate(config.COMPTIME_ONE_ITEM_DIRECTORIES, true, true, decorators.Filter.Directories, stats.oneItemDirectories, i18n.ONE_ITEM_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL, i18n.DIRECTORIES_TOTALS);
}

/// Enables files and folders ownerships and permissions checks
pub fn ownershipsPermissions() !void {
    try decorators.decorate(config.COMPTIME_OWNERSHIPS_PERMISSIONS, true, false, decorators.Filter.Both, stats.ownershipsPermissions, i18n.OWNERSHIPS_PERMISSIONS_HEADER, i18n.DIR_FILE_NAME_SIZE_TOTAL, i18n.DIR_FILE_NAME_SIZE_TOTALS);
}

/// Enables parse files
pub fn parseFiles() !void {
    try decorators.decorate(config.COMPTIME_PARSE_FILES, true, false, decorators.Filter.Files, parser.parseFiles, i18n.PARSE_FILES_HEADER, i18n.PARSE_FILES_TOTAL, i18n.PARSE_FILES_TOTALS);
}

/// Enables temporary files check
pub fn temporaryFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_TEMPORARY_FILES, true, useless.temporaryFiles, i18n.TEMPORARY_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables non-portable characters check
pub fn nonPortableChars() !void {
    try decorators.decorate(config.COMPTIME_NONPORTABLE_CHARS, true, true, decorators.Filter.Both, stats.nonPortableCharacters, i18n.NONPORTABLE_CHARS_HEADER, i18n.NONPORTABLE_CHARS_TOTAL, i18n.NONPORTABLE_CHARS_TOTALS);
}

/// Enables wrong dates check
pub fn wrongDates() !void {
    try decorators.decorate(config.COMPTIME_WRONG_DATES, true, false, decorators.Filter.Files, stats.checkWrongDates, i18n.WRONG_DATES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Removes duplicate files in parallel
pub fn duplicateRemoveFilesParallel() !void {
    try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE, true, duplicates.remove_parallel, i18n.DUPLICATE_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Removes duplicate files
pub fn duplicateRemoveFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES_REMOVE, true, duplicates.remove, i18n.DUPLICATE_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Removes empty directories, runs until no empty directory is found
pub fn emptyRemoveDirectories() !void {
    if (!config.COMPTIME_EMPTY_DIRECTORIES_REMOVE) return;

    try print.header(i18n.EMPTY_DIRECTORIES_HEADER);

    var total_items: u64 = 0;

    // Handle functions that can exit early
    if (try stats.emptyRemoveDirectories(.{ globals.absolute_input_path, &total_items })) {
        return print.results(total_items, i18n.EMPTY_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL, i18n.DIRECTORIES_TOTALS);
    }

    if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
        if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
            if(globals.ignore_path_patterns.contains(globals.absolute_input_path)) return;
        }
    }

    var folder_removed: bool = true;

    while (folder_removed) {
        folder_removed = false;

        var walker: std.Io.Dir.Walker = try globals.input_directory.walk(globals.init.arena.allocator());
        defer walker.deinit(globals.init.io);

        while (true) {
            var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
            if (try file_iterator.nextEntry(&walker, &total_items, &entry_tmp)) continue;

            const entry = entry_tmp orelse break;
            if (entry.kind != .directory) continue;

            const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });

            if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
                if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
                    if(globals.ignore_path_patterns.contains(absolute_path)) continue;
                }
            }

            if (try stats.emptyRemoveDirectories(.{ absolute_path, &total_items })) folder_removed = true;
        }
    }

    // Remove root if it is empty
    _ = try stats.emptyRemoveDirectories(.{ globals.absolute_input_path, &total_items });

    return print.results(total_items, i18n.EMPTY_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL, i18n.DIRECTORIES_TOTALS);
}

/// Enables remove empty files
pub fn emptyRemoveFiles() !void {
    if (!config.COMPTIME_EMPTY_FILES_REMOVE) return;

    try print.header(i18n.EMPTY_FILES_HEADER);

    var total_items: u64 = 0;
    var walker: std.Io.Dir.Walker = try globals.input_directory.walk(globals.init.arena.allocator());
    defer walker.deinit(globals.init.io);

    // No cached stats, walk the directory tree
    while (true) {
        var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
        if (try file_iterator.nextEntry(&walker, &total_items, &entry_tmp)) continue;

        const entry = entry_tmp orelse break;

        if (entry.kind != .file) continue;
        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });

        if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
            if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
                if(globals.ignore_path_patterns.contains(absolute_path)) continue;
            }
        }

        _ = try stats.emptyRemoveFiles(.{ absolute_path, &total_items });
    }

    return print.results(total_items, i18n.EMPTY_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Removes links and shortcuts
pub fn linksRemoveShortcuts() !void {
    try decorators.decorateWalker(config.COMPTIME_LINKS_SHORTCUTS_REMOVE, true, stats.linkRemoveShortcuts, i18n.LINKS_SHORTCUTS_HEADER, i18n.LINKS_SHORTCUTS_TOTAL, i18n.LINKS_SHORTCUTS_TOTALS);
}

/// Removes temporary files
pub fn temporaryRemoveFiles() !void {
    try decorators.decorateWalker(config.COMPTIME_TEMPORARY_FILES_REMOVE, true, useless.temporaryRemoveFiles, i18n.TEMPORARY_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables file search with non-UTF8 encoding
pub fn utf8Encoding() !void {
    try decorators.decorate(config.COMPTIME_UTF8_ENCODING, true, false, decorators.Filter.Files, txt.utf8Encoding, i18n.UTF8_ENCODING_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Executes all file/directory check modules based on configurations
pub fn run() !void {
    try decorators.decorate      (config.COMPTIME_COMPRESSED_FILES,         globals.config_parsed.value.COMPRESSED_FILES,         false,                          decorators.Filter.Files,                    compressed.check,               i18n.COMPRESSED_FILES_HEADER,       i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorateWalker(config.COMPTIME_CONFIDENTIAL_FILES,       globals.config_parsed.value.CONFIDENTIAL_FILES,       confidential.checkConfidential, i18n.CONFIDENTIAL_FILES_HEADER,  i18n.FILES_TOTAL,               i18n.FILES_TOTALS                                                                                      );
    try decorators.decorate      (config.COMPTIME_DEBUG_INFO,               globals.config_parsed.value.DEBUG_INFO,               false,                           decorators.Filter.Files,                    useless.debugInfo,              i18n.DEBUG_INFO_HEADER,             i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE, globals.config_parsed.value.DIRECTORY_FILE_NAME_SIZE, true,                           decorators.Filter.Both,                     stats.dirFileNameSize,          i18n.DIR_FILE_NAME_SIZE_HEADER,     i18n.DIR_FILE_NAME_SIZE_TOTAL,    i18n.DIR_FILE_NAME_SIZE_TOTALS   );
    try decorators.decorate      (config.COMPTIME_DUPLICATE_CHARS_FILES,    globals.config_parsed.value.DUPLICATE_CHARS_FILES,    false,                          decorators.Filter.Files,                    stats.duplicateCharacters,      i18n.DUPLICATE_CHARS_FILES_HEADER,  i18n.DUPLICATE_CHARS_FILES_TOTAL, i18n.DUPLICATE_CHARS_FILES_TOTALS);

    if(globals.config_parsed.value.DUPLICATE_FILES_PARALLEL == true) {
        try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES_PARALLEL, globals.config_parsed.value.DUPLICATE_FILES_PARALLEL, duplicates.check_parallel,      i18n.DUPLICATE_FILES_HEADER,     i18n.BYTES_TOTAL,               i18n.BYTES_TOTALS                                                                                  );
    } else {
        try decorators.decorateWalker(config.COMPTIME_DUPLICATE_FILES,          globals.config_parsed.value.DUPLICATE_FILES,          duplicates.check,               i18n.DUPLICATE_FILES_HEADER,     i18n.BYTES_TOTAL,               i18n.BYTES_TOTALS                                                                                  );
    }

    try decorators.decorate      (config.COMPTIME_EMPTY_FILES,              globals.config_parsed.value.EMPTY_FILES,              false,                          decorators.Filter.Files,                    stats.emptyFiles,               i18n.EMPTY_FILES_HEADER,            i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_EMPTY_DIRECTORIES,        globals.config_parsed.value.EMPTY_DIRECTORIES,        true,                           decorators.Filter.Directories,              stats.emptyDirectories,         i18n.EMPTY_DIRECTORIES_HEADER,      i18n.DIRECTORIES_TOTAL,           i18n.DIRECTORIES_TOTALS          );
    try decorators.decorateWalker(config.COMPTIME_END_OF_LINE,              globals.config_parsed.value.END_OF_LINE,              txt.endOfLine,                  i18n.END_OF_LINE_HEADER,         i18n.FILES_TOTAL,               i18n.FILES_TOTALS);
    try decorators.decorate      (config.COMPTIME_FILES_NEWER_ATIME,        globals.config_parsed.value.FILES_NEWER_ATIME,        true,                           decorators.Filter.Files,                    stats.filesNewerATime,          i18n.FILES_NEWER_ATIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FILES_NEWER_CTIME,        globals.config_parsed.value.FILES_NEWER_CTIME,        true,                           decorators.Filter.Files,                    stats.filesNewerCTime,          i18n.FILES_NEWER_CTIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FILES_NEWER_MTIME,        globals.config_parsed.value.FILES_NEWER_MTIME,        true,                           decorators.Filter.Files,                    stats.filesNewerMTime,          i18n.FILES_NEWER_MTIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FILES_OLDER_ATIME,        globals.config_parsed.value.FILES_OLDER_ATIME,        true,                           decorators.Filter.Files,                    stats.filesOlderATime,          i18n.FILES_OLDER_ATIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FILES_OLDER_CTIME,        globals.config_parsed.value.FILES_OLDER_CTIME,        true,                           decorators.Filter.Files,                    stats.filesOlderCTime,          i18n.FILES_OLDER_CTIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FILES_OLDER_MTIME,        globals.config_parsed.value.FILES_OLDER_MTIME,        true,                           decorators.Filter.Files,                    stats.filesOlderMTime,          i18n.FILES_OLDER_MTIME_HEADER,      i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_FULL_PATH_SIZE,           globals.config_parsed.value.FULL_PATH_SIZE,           true,                           decorators.Filter.Both,                     stats.fullPathSize,             i18n.FULL_PATH_SIZE_HEADER,         i18n.FULL_PATH_SIZE_TOTAL,        i18n.FULL_PATH_SIZE_TOTALS       );

    if (globals.config_parsed.value.INTEGRITY_FILES_PARALLEL == true) {
        try decorators.decorateWalker(config.COMPTIME_INTEGRITY_FILES_PARALLEL, globals.config_parsed.value.INTEGRITY_FILES_PARALLEL, integrity.checkParallel,        i18n.INTEGRITY_FILES_HEADER,     i18n.INTEGRITY_FILES_TOTAL,     i18n.INTEGRITY_FILES_TOTALS                                                                            );
    } else {
        try decorators.decorateWalker(config.COMPTIME_INTEGRITY_FILES,          globals.config_parsed.value.INTEGRITY_FILES,          integrity.checkSingle,          i18n.INTEGRITY_FILES_HEADER,     i18n.INTEGRITY_FILES_TOTAL,     i18n.INTEGRITY_FILES_TOTALS                                                                            );
    }

    try decorators.decorate      (config.COMPTIME_LARGE_FILES,              globals.config_parsed.value.LARGE_FILES,              false,                          decorators.Filter.Files,                    stats.largeFiles,               i18n.LARGE_FILES_HEADER,            i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_LAST_ACCESS_FILES,        globals.config_parsed.value.LAST_ACCESS_FILES,        false,                          decorators.Filter.Files,                    stats.lastAccess,               i18n.LAST_ACCESS_HEADER,            i18n.BYTES_TOTAL,                 i18n.BYTES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_LEGACY_FILES,             globals.config_parsed.value.LEGACY_FILES,             false,                          decorators.Filter.Files,                    useless.legacyFiles,            i18n.LEGACY_FILES_HEADER,           i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorateWalker(config.COMPTIME_LINKS_SHORTCUTS,          globals.config_parsed.value.LINKS_SHORTCUTS,          stats.linkShortcuts,            i18n.LINKS_SHORTCUTS_HEADER,     i18n.LINKS_SHORTCUTS_TOTAL,     i18n.LINKS_SHORTCUTS_TOTALS                                                                            );
    try decorators.decorate      (config.COMPTIME_MAGIC_NUMBERS,            globals.config_parsed.value.MAGIC_NUMBERS,            false,                          decorators.Filter.Files,                    magic_numbers.check,            i18n.MAGIC_NUMBERS_HEADER,          i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_MANY_ITEMS_DIRECTORIES,   globals.config_parsed.value.MANY_ITEMS_DIRECTORIES,   true,                           decorators.Filter.Directories,              stats.manyItemsDirectories,     i18n.MANY_ITEMS_DIRECTORIES_HEADER, i18n.DIRECTORIES_TOTAL,           i18n.DIRECTORIES_TOTALS          );
    try decorators.decorate      (config.COMPTIME_NO_EXTENSION,             globals.config_parsed.value.NO_EXTENSION,             false,                          decorators.Filter.Files,                    magic_numbers.checkNoExtension, i18n.NO_EXTENSION_HEADER,           i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
    try decorators.decorate      (config.COMPTIME_ONE_ITEM_DIRECTORIES,     globals.config_parsed.value.ONE_ITEM_DIRECTORIES,     true,                           decorators.Filter.Directories,              stats.oneItemDirectories,       i18n.ONE_ITEM_DIRECTORIES_HEADER,   i18n.DIRECTORIES_TOTAL,           i18n.DIRECTORIES_TOTALS          );
    try decorators.decorateWalker(config.COMPTIME_TEMPORARY_FILES,          globals.config_parsed.value.TEMPORARY_FILES,          useless.temporaryFiles,         i18n.TEMPORARY_FILES_HEADER,     i18n.BYTES_TOTAL,               i18n.BYTES_TOTALS                                                                                      );
    try decorators.decorate      (config.COMPTIME_NONPORTABLE_CHARS,        globals.config_parsed.value.NONPORTABLE_CHARS,        true,                           decorators.Filter.Both,                     stats.nonPortableCharacters,    i18n.NONPORTABLE_CHARS_HEADER,      i18n.NONPORTABLE_CHARS_TOTAL,     i18n.NONPORTABLE_CHARS_TOTALS    );
    try decorators.decorate      (config.COMPTIME_OWNERSHIPS_PERMISSIONS,   globals.config_parsed.value.OWNERSHIPS_PERMISSIONS,   false,                          decorators.Filter.Both,                     stats.ownershipsPermissions,    i18n.OWNERSHIPS_PERMISSIONS_HEADER, i18n.DIR_FILE_NAME_SIZE_TOTAL,    i18n.DIR_FILE_NAME_SIZE_TOTALS   );

    try decorators.decorate      (config.COMPTIME_UTF8_ENCODING,            globals.config_parsed.value.UTF8_ENCODING,            false,                          decorators.Filter.Files,                    txt.utf8Encoding,               i18n.UTF8_ENCODING_HEADER,          i18n.FILES_TOTAL,                 i18n.FILES_TOTALS);
    try decorators.decorate      (config.COMPTIME_WRONG_DATES,              globals.config_parsed.value.WRONG_DATES,              false,                          decorators.Filter.Files,                    stats.checkWrongDates,          i18n.WRONG_DATES_HEADER,            i18n.FILES_TOTAL,                 i18n.FILES_TOTALS                );
}

// Prints error, file and line in debug mode
pub inline fn debugPrintError(err: anyerror) void {
    if (!config.COMPTIME_STDOUT) return;

    if (builtin.mode == .debug) {
        std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
    }
}

pub fn exitCodeFn(total_items: *u64, comptime process_fn: anytype,comptime msg_fmt: []const u8, args: anytype) !void {
    try process_fn(msg_fmt, args);
    globals.exit_error.store(true, .monotonic);
    total_items.* += 1;
}

// Extracts extension and normalize to lowercase for case-insensitive matching
pub fn getExtensionLowercase(filepath: []const u8) ?[]const u8 {
    const extension = std.fs.path.extension(filepath);

    // Bounds check before lowercasing
    if (extension.len == 0 or extension.len > globals.buffer.len) return null;

    return std.ascii.lowerString(globals.buffer[0..extension.len], extension);
}

/// Compute cryptographic hash of file by processesing file in chunks
pub fn hashFile(comptime Hash: type, filepath: []const u8, final_hash: *[Hash.digest_length]u8) !void {
    const file: std.Io.File = std.Io.Dir.cwd().openFile(globals.init.io, filepath, .{ .mode = .read_only, .lock = .shared }) catch |err| switch (err) {
        error.AccessDenied => {
            globals.exit_error.store(true, .monotonic);
            return print.err(i18n.ERROR_ACCESS_DENIED_PATH, .{filepath});
        },
        error.FileNotFound => {
            globals.exit_error.store(true, .monotonic);
            return print.err(i18n.ERROR_READING_FILE, .{filepath});
        },
        else => {
            globals.exit_error.store(true, .monotonic);
            return err;
        },
    };
    defer file.close(globals.init.io);

    const local_buffer: []u8 = try globals.init.arena.allocator().alloc(u8, globals.config_parsed.value.BUFFER_SIZE);
    defer globals.init.arena.allocator().free(local_buffer);

    var hasher: Hash = Hash.init(.{});
    var file_reader: std.Io.File.Reader = file.reader(globals.init.io, local_buffer);

    while (true) {
        const chunk: []const u8 = file_reader.interface.take(globals.config_parsed.value.BUFFER_SIZE) catch |err| switch (err) {
            error.EndOfStream => {
                hasher.update(file_reader.interface.buffer[0..file_reader.interface.end]);
                return hasher.final(final_hash);
            },
            else => {
                globals.exit_error.store(true, .monotonic);
                return err;
            },
        };
        hasher.update(chunk[0..chunk.len]);
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}

pub fn readExactChunk(reader: *std.Io.File.Reader, size: usize, filepath: []const u8, total_items: *u64) !?[]const u8 {
    const chunk = reader.interface.take(size) catch |err| switch (err) {
        error.EndOfStream => {
            try exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{filepath});
            return null;
        },
        else => {
            globals.exit_error.store(true, .monotonic);
            return err;
        },
    };

    if (chunk.len != size) {
        try exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{filepath});
        return null;
    }

    return chunk;
}

/// Creates a config.json with default values in the same directory of the system
pub fn createConfig() !void {
    try print.stdout("\t\t");
    try print.stdout(i18n.CONFIG_MESSAGE_CREATE);
    try print.stdout("\x1b[2K\r");

    _ = std.Io.Dir.cwd().statFile(globals.init.io, config.COMPTIME_CONFIG_FILE_NAME, .{}) catch |err| {
        if (err == error.FileNotFound) {
            const config_file: std.Io.File = try std.Io.Dir.cwd().createFile(globals.init.io, config.COMPTIME_CONFIG_FILE_NAME, .{});
            defer config_file.close(globals.init.io);

            var file_writer: std.Io.File.Writer = config_file.writer(globals.init.io, &globals.io_buffer);
            try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG);
            try file_writer.interface.flush();

            try print.alignedOk(i18n.CONFIG_MESSAGE_CREATE);
            try print.stdout("\x1b[1A\x1b[1A");
            return print.waitForEnter();
        }

        try print.stdout("\x1b[1A\x1b[1A");
        try print.waitForEnter();
        return err;
    };

    try print.stopError(i18n.ERROR_CONFIG_FILE);
    try print.stdout("\x1b[1A\x1b[1A");
    return print.waitForEnter();
}
