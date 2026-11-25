//! System entry point with configuration and module execution
//! Handles command-line arguments, configuration loading and directory validation
//!
//! Copyright © 2025-present Marcos Mazoti

const ahocorasick     = @import("ahocorasick");
const config          = @import("config");
const core            = @import("core");
const globals         = @import("globals");
const i18n            = @import("i18n");
const print           = @import("print");
const output          = @import("output");
const std             = @import("std");

/// Changes terminal codepage on Windows
extern "kernel32" fn SetConsoleOutputCP(wCodePageID: std.os.windows.UINT) callconv(.winapi) std.os.windows.BOOL;

const NoParameterFunc = *const fn () anyerror!void;

/// Command-line spelling -> handler, matched without regard to letter case
const FlagMap = std.StaticStringMapWithEql(NoParameterFunc, std.static_string_map.eqlAsciiIgnoreCase);

/// A command selectable on the command line, followed by the directory to scan.
///
/// Accepted spellings (any letter case): `--name`, `-short`, `name` and `/short`,
/// e.g. `--compressed`, `-c`, `compressed` and `/c`.
const Command = struct {
    name: []const u8,
    short: []const u8,
    /// `null` when the feature is compiled out (config.COMPTIME_*). Written as
    /// `if (flag) &core.handler else null`, so a disabled handler is never analysed.
    run: ?NoParameterFunc,
};

const commands = [_]Command{
    // Checks
    .{ .name = "compressed"        , .short = "c"    , .run = if (config.COMPTIME_COMPRESSED_FILES)                &core.compressedFiles              else null },
    .{ .name = "confidential"      , .short = "conf" , .run = if (config.COMPTIME_CONFIDENTIAL_FILES)              &core.confidentialFiles            else null },
    .{ .name = "debuginfo"         , .short = "di"   , .run = if (config.COMPTIME_DEBUG_INFO)                      &core.debugInfo                    else null },
    .{ .name = "dirsize"           , .short = "ds"   , .run = if (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE)        &core.dirFileNameSize              else null },
    .{ .name = "dupchars"          , .short = "dc"   , .run = if (config.COMPTIME_DUPLICATE_CHARS_FILES)           &core.duplicateChars               else null },
    .{ .name = "duplicate"         , .short = "d"    , .run = if (config.COMPTIME_DUPLICATE_FILES)                 &core.duplicateFiles               else null },
    .{ .name = "duplicate_mt"      , .short = "dmt"  , .run = if (config.COMPTIME_DUPLICATE_FILES_PARALLEL)        &core.duplicateFilesParallel       else null },
    .{ .name = "empty_files"       , .short = "ef"   , .run = if (config.COMPTIME_EMPTY_FILES)                     &core.emptyFiles                   else null },
    .{ .name = "empty_dirs"        , .short = "ed"   , .run = if (config.COMPTIME_EMPTY_DIRECTORIES)               &core.emptyDirectories             else null },
    .{ .name = "end_of_line"       , .short = "eol"  , .run = if (config.COMPTIME_END_OF_LINE)                     &core.endOfLine                    else null },
    .{ .name = "files_newer_atime" , .short = "fna"  , .run = if (config.COMPTIME_FILES_NEWER_ATIME)               &core.filesNewerATime              else null },
    .{ .name = "files_newer_ctime" , .short = "fnc"  , .run = if (config.COMPTIME_FILES_NEWER_CTIME)               &core.filesNewerCTime              else null },
    .{ .name = "files_newer_mtime" , .short = "fnm"  , .run = if (config.COMPTIME_FILES_NEWER_MTIME)               &core.filesNewerMTime              else null },
    .{ .name = "files_older_atime" , .short = "foa"  , .run = if (config.COMPTIME_FILES_OLDER_ATIME)               &core.filesOlderATime              else null },
    .{ .name = "files_older_ctime" , .short = "foc"  , .run = if (config.COMPTIME_FILES_OLDER_CTIME)               &core.filesOlderCTime              else null },
    .{ .name = "files_older_mtime" , .short = "fom"  , .run = if (config.COMPTIME_FILES_OLDER_MTIME)               &core.filesOlderMTime              else null },
    .{ .name = "full_path_size"    , .short = "fps"  , .run = if (config.COMPTIME_FULL_PATH_SIZE)                  &core.fullPathSize                 else null },
    .{ .name = "integrity"         , .short = "i"    , .run = if (config.COMPTIME_INTEGRITY_FILES)                 &core.integrityFiles               else null },
    .{ .name = "integrity_mt"      , .short = "imt"  , .run = if (config.COMPTIME_INTEGRITY_FILES_PARALLEL)        &core.integrityFilesParallel       else null },
    .{ .name = "large_files"       , .short = "lf"   , .run = if (config.COMPTIME_LARGE_FILES)                     &core.largeFiles                   else null },
    .{ .name = "last_access"       , .short = "la"   , .run = if (config.COMPTIME_LAST_ACCESS_FILES)               &core.lastAccess                   else null },
    .{ .name = "legacy_files"      , .short = "lef"  , .run = if (config.COMPTIME_LEGACY_FILES)                    &core.legacyFiles                  else null },
    .{ .name = "links"             , .short = "l"    , .run = if (config.COMPTIME_LINKS_SHORTCUTS)                 &core.linksShortcuts               else null },
    .{ .name = "magic_numbers"     , .short = "mn"   , .run = if (config.COMPTIME_MAGIC_NUMBERS)                   &core.magicNumbers                 else null },
    .{ .name = "many_items"        , .short = "mi"   , .run = if (config.COMPTIME_MANY_ITEMS_DIRECTORIES)          &core.manyItemsDirectories         else null },
    .{ .name = "no_extension"      , .short = "ne"   , .run = if (config.COMPTIME_NO_EXTENSION)                    &core.noExtension                  else null },
    .{ .name = "nonportable_chars" , .short = "nc"   , .run = if (config.COMPTIME_NONPORTABLE_CHARS)               &core.nonPortableChars             else null },
    .{ .name = "one_item_dir"      , .short = "oid"  , .run = if (config.COMPTIME_ONE_ITEM_DIRECTORIES)            &core.oneItemDirectories           else null },
    .{ .name = "parse_files"       , .short = "pf"   , .run = if (config.COMPTIME_PARSE_FILES)                     &core.parseFiles                   else null },
    .{ .name = "temp_files"        , .short = "tf"   , .run = if (config.COMPTIME_TEMPORARY_FILES)                 &core.temporaryFiles               else null },
    .{ .name = "utf8"              , .short = "u"    , .run = if (config.COMPTIME_UTF8_ENCODING)                   &core.utf8Encoding                 else null },
    .{ .name = "wrong_dates"       , .short = "wd"   , .run = if (config.COMPTIME_WRONG_DATES)                     &core.wrongDates                   else null },

    // Removals
    .{ .name = "duplicate_rm"      , .short = "drm"  , .run = if (config.COMPTIME_DUPLICATE_FILES_REMOVE)          &core.duplicateRemoveFiles         else null },
    .{ .name = "duplicate_rmt"     , .short = "drmt" , .run = if (config.COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE) &core.duplicateRemoveFilesParallel else null },
    .{ .name = "empty_rm"          , .short = "efrm" , .run = if (config.COMPTIME_EMPTY_FILES_REMOVE)              &core.emptyRemoveFiles             else null },
    .{ .name = "empty_dirs_rm"     , .short = "edrm" , .run = if (config.COMPTIME_EMPTY_DIRECTORIES_REMOVE)        &core.emptyRemoveDirectories       else null },
    .{ .name = "links_rm"          , .short = "lrm"  , .run = if (config.COMPTIME_LINKS_SHORTCUTS_REMOVE)          &core.linksRemoveShortcuts         else null },
    .{ .name = "temp_rm"           , .short = "trm"  , .run = if (config.COMPTIME_TEMPORARY_FILES_REMOVE)          &core.temporaryRemoveFiles         else null },
};

/// Stand-alone commands: used when they are the only argument
pub const help_version_map = FlagMap.initComptime(.{
    .{ "--config"    , &core.createConfig },
    .{ "--configure" , &core.createConfig },
    .{ "config"      , &core.createConfig },
    .{ "configure"   , &core.createConfig },

    .{ "--help"      , &print.printHelp    },
    .{ "-?"          , &print.printHelp    },
    .{ "-h"          , &print.printHelp    },
    .{ "/?"          , &print.printHelp    },
    .{ "/h"          , &print.printHelp    },
    .{ "help"        , &print.printHelp    },

    .{ "--version"   , &print.printVersion },
    .{ "-v"          , &print.printVersion },
    .{ "/v"          , &print.printVersion },
    .{ "version"     , &print.printVersion },
});

/// Enabled commands, four spellings each
pub const command_map = blk: {
    const Entry = struct { []const u8, NoParameterFunc };

    var entries: [commands.len * 4]Entry = undefined;
    var count: usize = 0;

    for (commands) |command| {
        const run = command.run orelse continue;

        for ([_][]const u8{ "--" ++ command.name, "-" ++ command.short, command.name, "/" ++ command.short }) |spelling| {
            entries[count] = .{ spelling, run };
            count += 1;
        }
    }

    break :blk FlagMap.initComptime(entries[0..count].*);
};

/// Returns system exit code: 0 (no problems), 1 (errors), 2 (warnings)
fn exitCode() u8 {
    if (globals.exit_error.load(.monotonic))   return 1;
    if (globals.exit_warning.load(.monotonic)) return 2;
    return 0;
}

/// Common main for all operating systems
fn commonMain(init: *const std.process.Init) !void {
    // Accessing command line arguments (arena required):
    var check_directory: []u8 = undefined;

    globals.init = init;

    const total_memory: u64 = try std.process.totalSystemMemory();
    const half_memory:  u64 = total_memory / 2;

    globals.memory_limit = @intCast(@min(half_memory, std.math.maxInt(usize)));

    globals.file_writer_stdout           = .init(.stdout(), globals.init.io, &globals.io_buffer);
    globals.file_writer_stdout_interface = &globals.file_writer_stdout.interface;

    globals.file_stats = globals.FileStatMap.init(globals.init.arena.allocator());
    globals.dir_count  = std.StringHashMap(usize).init(globals.init.arena.allocator());

    globals.ignore_path_patterns = try ahocorasick.AhoCorasick.initEmpty(globals.init.arena.allocator());

    defer {
        globals.ignore_path_patterns.deinit();

        var iterator = globals.dir_count.iterator();
        while (iterator.next()) |entry| { globals.init.arena.allocator().free(entry.key_ptr.*); }
        globals.dir_count.deinit();

        var iterator2 = globals.file_stats.iterator();
        while (iterator2.next()) |entry| { globals.init.arena.allocator().free(entry.key_ptr.*); }
        globals.file_stats.deinit();
    }

    // Prints banner before any processing to provide immediate feedback in slow operations
    try print.banner();

    const args: []const [:0]const u8 = try init.minimal.args.toSlice(globals.init.arena.allocator());

    if (args.len == 1) {
        _ = std.Io.Dir.cwd().statFile(globals.init.io, config.COMPTIME_CONFIG_FILE_NAME, .{}) catch |err| {
            if (err == error.FileNotFound) {
                try print.printHelp();
                return print.waitForEnter();
            }
            try print.waitForEnter();
            return err;
        };
    }

    if (args.len == 2) {
        if (help_version_map.get(args[1])) |func| {
            try func();
            return print.waitForEnter();
        }
    }

    // Loads configurations from config.json or uses default values
    const must_clean: bool = loadLocal(&globals.config_file, config.COMPTIME_CONFIG_FILE_NAME, &globals.config_parsed, globals.init.io, globals.init.arena.allocator()) catch |err| {
        try print.stopError(i18n.ERROR_CONFIG_FILE_PARSE);
        try print.waitForEnter();
        return err;
    };

    defer config.deinit(&globals.config_file, &globals.config_parsed, globals.init.arena.allocator(), must_clean);

    if (must_clean) try print.alignedOk(i18n.CONFIG_MESSAGE_HEADER) else try print.alignedOk(i18n.CONFIG_MESSAGE_HEADER_DEFAULT);

    // CPU count detection for optimal parallelism
    if (globals.config_parsed.value.MAX_JOBS == 0) {
        const cpu_count: usize = std.Thread.getCpuCount() catch 1;
        globals.config_parsed.value.MAX_JOBS = @max(1, cpu_count);
    }

    if (args.len > 1) {
        check_directory = try globals.init.arena.allocator().dupe(u8, args[args.len - 1]);
    } else {
        if (std.mem.eql(u8, globals.config_parsed.value.INPUT_FOLDER, ".")) {
            check_directory = try std.process.currentPathAlloc(globals.init.io, globals.init.arena.allocator());
        } else {
            if (globals.config_parsed.value.INPUT_FOLDER.len == 0) {
                globals.exit_error.store(true, .monotonic);
                return print.stopWaitError(i18n.ERROR_EMPTY_PATH);
            }

            check_directory = try globals.init.arena.allocator().dupe(u8, globals.config_parsed.value.INPUT_FOLDER);
        }
    }
    defer globals.init.arena.allocator().free(check_directory);

    if (check_directory.len == 0) {
        globals.exit_error.store(true, .monotonic);
        return print.stopWaitError(i18n.ERROR_EMPTY_PATH);
    }

    // Replaces a trailing ".
    if (check_directory[check_directory.len - 1] == '"') check_directory[check_directory.len - 1] = std.fs.path.sep;

    globals.buffer = try globals.init.arena.allocator().alloc(u8, globals.config_parsed.value.BUFFER_SIZE);
    defer globals.init.arena.allocator().free(globals.buffer);

    // Prevents bugs with odd sizes of buffer
    globals.buffer_size  = globals.config_parsed.value.BUFFER_SIZE / 2;
    globals.buffer_total = globals.buffer_size * 2;

    // Checks input directory
    globals.input_directory = if (std.fs.path.isAbsolute(check_directory))
        std.Io.Dir.openDirAbsolute(globals.init.io, check_directory, .{ .iterate = true }) catch |err| {
            try print.stopWaitError(i18n.ERROR_INPUT_DIRECTORY);
            return err;
        }
    else
        // Relative paths
        std.Io.Dir.cwd().openDir(globals.init.io, check_directory, .{ .iterate = true }) catch |err| {
            try print.stopWaitError(i18n.ERROR_INPUT_DIRECTORY);
            return err;
        };

    defer globals.input_directory.close(globals.init.io);

    // Get absolute path of input directory directory
    globals.absolute_input_path = try globals.input_directory.realPathFileAlloc(globals.init.io, ".", globals.init.arena.allocator());
    globals.now = std.Io.Clock.real.now(globals.init.io);
    globals.semaphore = std.Io.Semaphore{ .permits = globals.config_parsed.value.MAX_JOBS };

    // Initializes and add patterns to trie to ignore paths
    if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
        if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
            for (globals.config_parsed.value.IGNORE_PATTERNS) |pattern| { try globals.ignore_path_patterns.add(pattern); }
            try globals.ignore_path_patterns.configure();
        }
    }

    // Enables JSON output results to a file in disk
    try output.init();
    defer output.deinit();

    if (args.len > 2) {
        if (command_map.get(args[1])) |func| {
            globals.config_parsed.value.ENABLE_CACHE = false;
            try func();
        } else {
            try print.stdout("\x1b[2K\r\t");
            try print.err(i18n.ERROR_COMMAND_NOT_FOUND, .{args[1]});
            globals.exit_error.store(true, .monotonic);
        }
    } else {
        // Runs all enabled check modules
        try core.run();
    }

    return print.waitForEnter();
}

/// Attempts to load configuration from a local "config.json" file in the current working directory
fn loadLocal(config_file: *[]const u8, config_file_path: []const u8, config_parsed: *std.json.Parsed(config.Config), io: std.Io, alloc: std.mem.Allocator) !bool {
    config_file.* = std.Io.Dir.cwd().readFileAlloc(io, config_file_path, alloc, std.Io.Limit.limited(config.COMPTIME_IO_BUFFER_SIZE)) catch |err| blk: {
        if (err == error.FileNotFound) break :blk "";
        return err;
    };

    // Parses JSON with enum support, on error returns default values
    const must_clean: bool = if (config_file.*.len > 0) true else false;
    const default_config_data: []const u8 = if (must_clean) config_file.* else config.DEFAULT_JSON_CONFIG;

    config_parsed.* = std.json.parseFromSlice(config.Config, alloc, default_config_data, .{}) catch |err| {        // Invalid config.json
        if (must_clean) alloc.free(config_file.*);
        return err;
    };

    return must_clean;
}

pub fn main(init: std.process.Init) !void {
    if (@import("builtin").os.tag == .windows) {
        if (!SetConsoleOutputCP(65001).toBool()) return error.SetConsoleOutputCPFailed;
    }

    commonMain(&init) catch |err| blk:{
        globals.exit_error.store(true, .monotonic);
        core.debugPrintError(err);
        break :blk;
    };

    std.process.exit(exitCode());
}

// ==============================================================================================================================================

test "Empty config file loads default configuration" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init_single_threaded;

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "";

    const loaded = try loadLocal(
        &config_file,
        "config_test.json",
        &config_parsed,
        threaded.io(),
        gpa.allocator(),
    );

    defer {
        config_parsed.deinit();
        std.Io.Dir.cwd().deleteFile(threaded.io(), config.COMPTIME_CONFIG_FILE_NAME) catch {};
    }

    try std.testing.expect(!loaded);
    try std.testing.expectEqualStrings("", config_file);
}

test "Invalid config file" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io_buffer: [65536]u8 = undefined;

    const cwd = std.Io.Dir.cwd();

    const file = try cwd.createFile(tmp.io(), "config_invalid.json", .{});
    defer {
        file.close(tmp.io());
        cwd.deleteFile(tmp.io(), "config_invalid.json") catch {};
    }

    var file_writer = file.writer(tmp.io(), &io_buffer);

    try file_writer.interface.writeAll("[]");
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "";

    try std.testing.expectError(
        error.UnexpectedToken,
        loadLocal(
            &config_file,
            "config_invalid.json",
            &config_parsed,
            tmp.io(),
            gpa.allocator(),
        ),
    );
}

test "Valid config file" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io_buffer: [65536]u8 = undefined;

    const file: std.Io.File = try std.Io.Dir.cwd().createFile(tmp.io(), "config_valid.json", .{});
    defer {
        file.close(tmp.io());
        std.Io.Dir.cwd().deleteFile(tmp.io(), "config_valid.json") catch {};
    }

    var file_writer: std.Io.File.Writer = file.writer(tmp.io(), &io_buffer);
    try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG);
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "empty";

    const result: bool = try loadLocal(&config_file, "config_valid.json", &config_parsed, tmp.io(), gpa.allocator());
    defer config.deinit(&config_file, &config_parsed, gpa.allocator(), result);

    try std.testing.expect(result);
}

test "Command spellings are unique" {
    // StaticStringMap does not complain about duplicate keys, so they are checked here
    const keys = command_map.keys();

    for (keys, 0..) |key, index| {
        for (keys[index + 1 ..]) |other| try std.testing.expect(!std.ascii.eqlIgnoreCase(key, other));
    }
}

test "Stand-alone commands ignore letter case" {
    const accepted = [_][]const u8{ "--help", "-H", "/h", "/H", "HELP", "-?", "--VERSION", "-v", "/V", "Version", "--Config", "configure" };

    for (accepted) |flag| try std.testing.expect(help_version_map.get(flag) != null);

    try std.testing.expect(help_version_map.get("--nope") == null);
}
