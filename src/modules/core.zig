//! Runs modules using decorators to avoid duplicated code
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");
const builtin = @import("builtin");

const config = @import("config");
const globals = @import("globals");
const i18n = @import("i18n");
const print = @import("print");

const compressed = @import("compressed.zig");
const confidential = @import("confidential.zig");
const duplicates = @import("duplicate_files/core.zig");
const integrity = @import("integrity.zig");
const magic_numbers = @import("magic_numbers.zig");
const parser = @import("parser.zig");
const stats = @import("stats.zig");
const useless = @import("useless.zig");

const Filter = enum { Files, Directories, Both };

/// Enables duplicate files check
pub fn duplicateFiles() !void {
    globals.config_parsed.value.DUPLICATE_FILES = true;
    globals.config_parsed.value.DUPLICATE_FILES_PARALLEL = false;

    try decorateWalker(config.COMPTIME_DUPLICATE_FILES, globals.config_parsed.value.DUPLICATE_FILES, duplicates.check, i18n.DUPLICATE_FILES_HEADER, i18n.DUPLICATE_FILES_TOTAL, i18n.DUPLICATE_FILES_TOTALS);
}

/// Enables duplicate files check in parallel
pub fn duplicateFilesParallel() !void {
    globals.config_parsed.value.DUPLICATE_FILES = true;
    globals.config_parsed.value.DUPLICATE_FILES_PARALLEL = true;

    try decorateWalker(config.COMPTIME_DUPLICATE_FILES, globals.config_parsed.value.DUPLICATE_FILES, duplicates.check, i18n.DUPLICATE_FILES_HEADER, i18n.DUPLICATE_FILES_TOTAL, i18n.DUPLICATE_FILES_TOTALS);
}

/// Enables links and shortcuts check
pub fn linksShortcuts() !void {
    globals.config_parsed.value.LINKS_SHORTCUTS = true;

    try decorateWalker(config.COMPTIME_LINKS_SHORTCUTS, globals.config_parsed.value.LINKS_SHORTCUTS, stats.linkShortcuts, i18n.LINKS_SHORTCUTS_HEADER, i18n.LINKS_SHORTCUTS_TOTAL, i18n.LINKS_SHORTCUTS_TOTALS);
}

/// Enables integrity files check
pub fn integrityFiles() !void {
    globals.config_parsed.value.INTEGRITY_FILES = true;
    globals.config_parsed.value.INTEGRITY_FILES_PARALLEL = false;

    try decorateWalker(config.COMPTIME_INTEGRITY_FILES, globals.config_parsed.value.INTEGRITY_FILES, integrity.checkIntegrity, i18n.INTEGRITY_FILES_HEADER, i18n.INTEGRITY_FILES_TOTAL, i18n.INTEGRITY_FILES_TOTALS);
}

/// Enables integrity files check in parallel
pub fn integrityFilesParallel() !void {
    globals.config_parsed.value.INTEGRITY_FILES = true;
    globals.config_parsed.value.INTEGRITY_FILES_PARALLEL = true;

    try decorateWalker(config.COMPTIME_INTEGRITY_FILES, globals.config_parsed.value.INTEGRITY_FILES, integrity.checkIntegrity, i18n.INTEGRITY_FILES_HEADER, i18n.INTEGRITY_FILES_TOTAL, i18n.INTEGRITY_FILES_TOTALS);
}

/// Enables temporary files check
pub fn temporaryFiles() !void {
    globals.config_parsed.value.TEMPORARY_FILES = true;

    try decorateWalker(config.COMPTIME_TEMPORARY_FILES, globals.config_parsed.value.TEMPORARY_FILES, useless.temporaryFiles, i18n.TEMPORARY_FILES_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables confidential files check
pub fn confidentialFiles() !void {
    globals.config_parsed.value.CONFIDENTIAL_FILES = true;

    try decorateWalker(config.COMPTIME_CONFIDENTIAL_FILES, globals.config_parsed.value.CONFIDENTIAL_FILES, confidential.checkConfidential, i18n.CONFIDENTIAL_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables compressed files check
pub fn compressedFiles() !void {
    globals.config_parsed.value.COMPRESSED_FILES = true;

    try decorate(config.COMPTIME_COMPRESSED_FILES, globals.config_parsed.value.COMPRESSED_FILES, false, Filter.Files, compressed.check, i18n.COMPRESSED_FILES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables duplicate characters check
pub fn duplicateChars() !void {
    globals.config_parsed.value.DUPLICATE_CHARS_FILES = true;

    try decorate(config.COMPTIME_DUPLICATE_CHARS_FILES, globals.config_parsed.value.DUPLICATE_CHARS_FILES, false, Filter.Files, stats.duplicateCharacters, i18n.DUPLICATE_CHARS_FILES_HEADER, i18n.DUPLICATE_CHARS_FILES_TOTAL, i18n.DUPLICATE_CHARS_FILES_TOTALS);
}

/// Enables empty files check
pub fn emptyFiles() !void {
    globals.config_parsed.value.EMPTY_FILES = true;

    try decorate(config.COMPTIME_EMPTY_FILES, globals.config_parsed.value.EMPTY_FILES, false, Filter.Files, stats.emptyFiles, i18n.EMPTY_FILES_HEADER, i18n.EMPTY_FILES_TOTAL, i18n.EMPTY_FILES_TOTALS);
}

/// Enables large files check
pub fn largeFiles() !void {
    globals.config_parsed.value.LARGE_FILES = true;

    try decorate(config.COMPTIME_LARGE_FILES, globals.config_parsed.value.LARGE_FILES, false, Filter.Files, stats.largeFiles, i18n.LARGE_FILES_HEADER, i18n.LARGE_FILES_TOTAL, i18n.LARGE_FILES_TOTALS);
}

/// Enables last access files
pub fn lastAccess() !void {
    globals.config_parsed.value.LAST_ACCESS_FILES = true;

    try decorate(config.COMPTIME_LAST_ACCESS_FILES, globals.config_parsed.value.LAST_ACCESS_FILES, false, Filter.Files, stats.lastAccess, i18n.LAST_ACCESS_HEADER, i18n.BYTES_TOTAL, i18n.BYTES_TOTALS);
}

/// Enables legacy files check
pub fn legacyFiles() !void {
    globals.config_parsed.value.LEGACY_FILES = true;

    try decorate(config.COMPTIME_LEGACY_FILES, globals.config_parsed.value.LEGACY_FILES, false, Filter.Files, useless.legacyFiles, i18n.LEGACY_FILES_HEADER, i18n.LEGACY_FILES_TOTAL, i18n.LEGACY_FILES_TOTALS);
}

/// Enables magic numbers check
pub fn magicNumbers() !void {
    globals.config_parsed.value.MAGIC_NUMBERS = true;

    try decorate(config.COMPTIME_MAGIC_NUMBERS, globals.config_parsed.value.MAGIC_NUMBERS, false, Filter.Files, magic_numbers.check, i18n.MAGIC_NUMBERS_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables no extension check
pub fn noExtension() !void {
    globals.config_parsed.value.NO_EXTENSION = true;

    try decorate(config.COMPTIME_NO_EXTENSION, globals.config_parsed.value.NO_EXTENSION, false, Filter.Files, magic_numbers.checkNoExtension, i18n.NO_EXTENSION_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables JSON files check
pub fn checkJSON() !void {
    globals.config_parsed.value.PARSE_JSON_FILES = true;

    try decorate(config.COMPTIME_PARSE_JSON_FILES, globals.config_parsed.value.PARSE_JSON_FILES, false, Filter.Files, parser.checkJSON, i18n.PARSE_JSON_FILES_HEADER, i18n.PARSE_JSON_FILES_TOTAL, i18n.PARSE_JSON_FILES_TOTALS);
}

/// Enables wrong dates check
pub fn wrongDates() !void {
    globals.config_parsed.value.WRONG_DATES = true;

    try decorate(config.COMPTIME_WRONG_DATES, globals.config_parsed.value.WRONG_DATES, false, Filter.Files, stats.checkWrongDates, i18n.WRONG_DATES_HEADER, i18n.FILES_TOTAL, i18n.FILES_TOTALS);
}

/// Enables empty directories check
pub fn emptyDirectories() !void {
    globals.config_parsed.value.EMPTY_DIRECTORIES = true;

    try decorate(config.COMPTIME_EMPTY_DIRECTORIES, globals.config_parsed.value.EMPTY_DIRECTORIES, true, Filter.Directories, stats.emptyDirectories, i18n.EMPTY_DIRECTORIES_HEADER, i18n.EMPTY_DIRECTORIES_TOTAL, i18n.EMPTY_DIRECTORIES_TOTALS);
}

/// Enables many items directory check
pub fn manyItemsDirectories() !void {
    globals.config_parsed.value.MANY_ITEMS_DIRECTORY = true;

    try decorate(config.COMPTIME_MANY_ITEMS_DIRECTORY, globals.config_parsed.value.MANY_ITEMS_DIRECTORY, true, Filter.Directories, stats.manyItemsDirectory, i18n.MANY_ITEMS_DIRECTORIES_HEADER, i18n.MANY_ITEMS_DIRECTORIES_TOTAL, i18n.MANY_ITEMS_DIRECTORIES_TOTALS);
}

/// Enables one item directory check
pub fn oneItemDirectories() !void {
    globals.config_parsed.value.ONE_ITEM_DIRECTORY = true;

    try decorate(config.COMPTIME_ONE_ITEM_DIRECTORY, globals.config_parsed.value.ONE_ITEM_DIRECTORY, true, Filter.Directories, stats.oneItemDirectory, i18n.ONE_ITEM_DIRECTORIES_HEADER, i18n.ONE_ITEM_DIRECTORIES_TOTAL, i18n.ONE_ITEM_DIRECTORIES_TOTALS);
}

/// Enables directory and filename size check
pub fn dirFileNameSize() !void {
    globals.config_parsed.value.DIRECTORY_FILE_NAME_SIZE = true;

    try decorate(config.COMPTIME_DIRECTORY_FILE_NAME_SIZE, globals.config_parsed.value.DIRECTORY_FILE_NAME_SIZE, true, Filter.Both, stats.dirFileNameSize, i18n.DIR_FILE_NAME_SIZE_HEADER, i18n.DIR_FILE_NAME_SIZE_TOTAL, i18n.DIR_FILE_NAME_SIZE_TOTALS);
}

/// Enables full path size check
pub fn fullPathSize() !void {
    globals.config_parsed.value.FULL_PATH_SIZE = true;

    try decorate(config.COMPTIME_FULL_PATH_SIZE, globals.config_parsed.value.FULL_PATH_SIZE, true, Filter.Both, stats.fullPathSize, i18n.FULL_PATH_SIZE_HEADER, i18n.FULL_PATH_SIZE_TOTAL, i18n.FULL_PATH_SIZE_TOTALS);
}

/// Enables unportable characters check
pub fn unportableChars() !void {
    globals.config_parsed.value.UNPORTABLE_CHARS = true;

    try decorate(config.COMPTIME_UNPORTABLE_CHARS, globals.config_parsed.value.UNPORTABLE_CHARS, true, Filter.Both, stats.unportableCharacters, i18n.UNPORTABLE_CHARS_HEADER, i18n.UNPORTABLE_CHARS_TOTAL, i18n.UNPORTABLE_CHARS_TOTALS);
}

/// Disables colored output
pub fn noColors() !void {
    globals.config_parsed.value.COLOR = false;

    try run();
}

/// Executes all file/directory check modules based on configurations
pub fn run() !void {
    if (globals.config_parsed.value.DUPLICATE_FILES_PARALLEL) try duplicateFilesParallel() else try duplicateFiles();

    try linksShortcuts();

    if (globals.config_parsed.value.INTEGRITY_FILES_PARALLEL) try integrityFilesParallel() else try integrityFiles();

    try temporaryFiles();
    try confidentialFiles();
    try compressedFiles();
    try duplicateChars();
    try emptyFiles();
    try largeFiles();
    try lastAccess();
    try legacyFiles();
    try magicNumbers();
    try noExtension();
    try checkJSON();
    try wrongDates();
    try emptyDirectories();
    try manyItemsDirectories();
    try oneItemDirectories();
    try dirFileNameSize();
    try fullPathSize();
    try unportableChars();
}

/// Fetchs file statistics with optional caching
fn fetchAdd(absolute_path: []const u8) !std.Io.File.Stat {
    if (globals.file_stats.get(absolute_path)) |retrieved_stat| {
        return retrieved_stat;
    }

    const stat: std.Io.File.Stat = try statFileOrDirectory(absolute_path);

    // Not in cache, fetch and store
    if (globals.config_parsed.value.ENABLE_CACHE) {
        const key: []const u8 = try globals.alloc.*.dupe(u8, absolute_path);
        errdefer globals.alloc.free(key);

        try globals.file_stats.put(key, stat);
    }

    return stat;
}

/// Fetchs path or ignores AccessDenied and FileBusy errors
pub fn fetchStatWithErrorHandling(absolute_path: []const u8, total_items: *u64) !?std.Io.File.Stat {
    return fetchAdd(absolute_path) catch |err| switch (err) {
        error.AccessDenied => {
            try print.err(i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
            total_items.* += 1;
            return null;
        },
        error.FileBusy => {
            try print.err(i18n.ERROR_FILE_BUSY, .{absolute_path});
            total_items.* += 1;
            return null;
        },
        else => return err,
    };
}

/// Helper function to stat a file or directory
fn statFileOrDirectory(path: []const u8) !std.Io.File.Stat {
    return std.Io.Dir.cwd().statFile(globals.io, path, .{}) catch |err| {
        if (err == error.IsDir) {
            var dir_stat: std.Io.File.Stat = std.mem.zeroes(std.Io.File.Stat);
            dir_stat.kind = .directory;
            return dir_stat;
        }
        return err;
    };
}

/// Conditionally runs a check in every item if both compile-time and runtime flags are enabled
fn decorate(
    comptime comptime_flag: bool,
    runtime_flag: bool,
    comptime early_exit: bool,
    comptime filter: Filter,
    comptime process_fn: anytype,
    comptime header: []const u8,
    comptime total: []const u8,
    comptime totals: []const u8,
) !void {
    if (comptime comptime_flag) {
        if (runtime_flag) {
            try print.stdout(header);

            var total_items: u64 = 0;

            // Handle functions that can exit early
            if (early_exit) {
                if (try process_fn(.{ globals.absolute_input_path, &total_items, null }))
                    return print.results(total_items, header, total, totals);
            }

            // First check if there are cached file statistics
            if (globals.file_stats.count() > 0) {
                var iterator = globals.file_stats.iterator();

                while (iterator.next()) |entry| {
                    const cached_stat: std.Io.File.Stat = entry.value_ptr.*;

                    if (comptime filter == .Files) {
                        if (cached_stat.kind != std.Io.File.Kind.file) continue;
                    }

                    if (comptime filter == .Directories) {
                        if (cached_stat.kind != std.Io.File.Kind.directory) continue;
                    }

                    if (comptime filter == .Both) {
                        if (cached_stat.kind != std.Io.File.Kind.directory and cached_stat.kind != std.Io.File.Kind.file)
                            continue;
                    }

                    _ = try process_fn(.{ entry.key_ptr.*, &total_items, &cached_stat });
                }

                return print.results(total_items, header, total, totals);
            }

            var walker: std.Io.Dir.Walker = try globals.input_directory.walk(globals.alloc.*);
            defer walker.deinit();

            // If no cached stats, walk the directory tree
            while (true) {
                var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
                if (try nextEntry(&walker, &total_items, &entry_tmp)) continue;

                if (entry_tmp) |entry| {
                    if (comptime filter == .Files) {
                        if (entry.kind != .file) continue;
                    }
                    if (comptime filter == .Directories) {
                        if (entry.kind != .directory) continue;
                    }
                    if (comptime filter == .Both) {
                        if (entry.kind != .directory and entry.kind != .file) continue;
                    }

                    const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });

                    // Adds the file or folder to cache
                    const stat_tmp: ?std.Io.File.Stat = try fetchStatWithErrorHandling(absolute_path, &total_items);
                    if (stat_tmp) |stat| {
                        _ = try process_fn(.{ absolute_path, &total_items, &stat });
                    }

                    continue;
                }
                break;
            }

            return print.results(total_items, header, total, totals);
        }
    }
}

/// Conditionally runs a check in every item if both compile-time and runtime flags are enabled
fn decorateWalker(
    comptime comptime_flag: bool,
    runtime_flag: bool,
    process_fn: *const fn (total_items: *u64) anyerror!void,
    comptime header: []const u8,
    comptime total: []const u8,
    comptime totals: []const u8,
) !void {
    if (comptime comptime_flag) {
        if (runtime_flag) {
            var total_items: u64 = 0;

            _ = try print.stdout(header);
            try process_fn(&total_items);

            _ = try print.results(total_items, header, total, totals);
        }
    }
}

/// Compute cryptographic hash of file by processesing file in chunks
pub fn hashFile(comptime Hash: type, filepath: []const u8, final_hash: *[Hash.digest_length]u8) !void {
    const file: std.Io.File = std.Io.Dir.cwd().openFile(globals.io, filepath, .{ .mode = .read_only, .lock = .shared }) catch |err| switch (err) {
        error.AccessDenied => {
            return print.err(i18n.ERROR_ACCESS_DENIED_PATH, .{filepath});
        },
        error.FileNotFound => {
            return print.err(i18n.ERROR_READING_FILE, .{filepath});
        },
        else => return err,
    };
    defer file.close(globals.io);

    const local_buffer: []u8 = try globals.alloc.*.alloc(u8, globals.config_parsed.value.BUFFER_SIZE);
    defer globals.alloc.*.free(local_buffer);

    var hasher: Hash = Hash.init(.{});
    var file_reader: std.Io.File.Reader = file.reader(globals.io, local_buffer);

    while (true) {
        const chunk: []const u8 = file_reader.interface.take(globals.config_parsed.value.BUFFER_SIZE) catch |err| switch (err) {
            error.EndOfStream => {
                hasher.update(file_reader.interface.buffer[0..file_reader.interface.end]);
                return hasher.final(final_hash);
            },
            else => return err,
        };
        hasher.update(chunk[0..chunk.len]);
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}

/// Gets the next entry or ignores AccessDenied error
pub fn nextEntry(walker: *std.Io.Dir.Walker, total_items: *u64, entry: *?std.Io.Dir.Walker.Entry) !bool {
    entry.* = walker.next(globals.io) catch |err| switch (err) {
        error.AccessDenied => {
            const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, walker.inner.name_buffer.items });
            try print.err(i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
            total_items.* += 1;
            return true; // Signal to continue
        },
        else => return err,
    };

    return false;
}

// Extracts extension and normalize to lowercase for case-insensitive matching
pub fn getExtensionLowercase(filepath: []const u8) ?[]const u8 {
    const extension = std.fs.path.extension(filepath);

    // Bounds check before lowercasing
    if (extension.len == 0 or extension.len > globals.buffer.len) return null;

    return std.ascii.lowerString(globals.buffer[0..extension.len], extension);
}

// Prints error, file and line in debug mode
pub inline fn debugPrintError(err: anyerror) void {
    if (builtin.mode == .Debug) {
        std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
    }
}

pub fn readExactChunk(reader: *std.Io.File.Reader, size: usize, filepath: []const u8, total_items: *u64) !?[]const u8 {
    const chunk = reader.interface.take(size) catch |err| switch (err) {
        error.EndOfStream => {
            try print.err(i18n.ERROR_READING_FILE, .{filepath});
            total_items.* += 1;
            return null;
        },
        else => return err,
    };

    if (chunk.len != size) {
        try print.err(i18n.ERROR_READING_FILE, .{filepath});
        total_items.* += 1;
        return null;
    }

    return chunk;
}

pub const FileIterator = struct {
    cache_iterator: ?std.hash_map.HashMapUnmanaged([]const u8, std.Io.File.Stat, std.hash_map.StringContext, 80).Iterator = null,
    walker: ?std.Io.Dir.Walker = null,
    using_cache: bool,

    pub const Entry = struct {
        path: []const u8,
        stat: std.Io.File.Stat,
    };

    pub fn init(alloc: std.mem.Allocator) !FileIterator {
        if (globals.file_stats.count() > 0) {
            return FileIterator{
                .cache_iterator = globals.file_stats.iterator(),
                .using_cache = true,
            };
        } else {
            return FileIterator{
                .walker = try globals.input_directory.walk(alloc),
                .using_cache = false,
            };
        }
    }

    pub fn deinit(self: *FileIterator) void {
        if (self.walker) |*w| w.deinit();
    }

    pub fn next(self: *FileIterator, total_items: *u64) !?Entry {
        if (self.using_cache) {
            while (self.cache_iterator.?.next()) |entry| {
                const stat = entry.value_ptr.*;

                if (stat.kind != .file) continue;
                return Entry{ .path = entry.key_ptr.*, .stat = stat };
            }
            return null;
        } else {
            while (true) {
                var entry_tmp: ?std.Io.Dir.Walker.Entry = null;
                if (try nextEntry(&self.walker.?, total_items, &entry_tmp)) continue;

                const entry = entry_tmp orelse return null;

                if (entry.kind != .file and entry.kind != .directory) continue;

                const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}", .{ globals.absolute_input_path, std.fs.path.sep, entry.path });

                const stat = try fetchStatWithErrorHandling(absolute_path, total_items) orelse continue;

                if (entry.kind != .file) continue;
                return Entry{ .path = absolute_path, .stat = stat };
            }
        }
    }
};
