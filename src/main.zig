//! System entry point with configuration and module execution
//! Handles command-line arguments, configuration loading and directory validation
//!
//! Copyright © 2025-present Marcos Mazoti

const std              = @import("std");

const config           = @import("config");
const core             = @import("core");
const globals          = @import("globals");
const i18n             = @import("i18n");
const print            = @import("print");

const HelpVersionConfig = *const fn() anyerror!void;

/// Map of command-line flags to their corresponding handler functions
/// Supports various help and version flag formats (Unix, Windows, case variations)
const help_version_map = std.StaticStringMap(HelpVersionConfig).initComptime(.{
    .{ "--config"    , &createConfig },
    .{ "--configure" , &createConfig },
    .{ "-c"          , &createConfig },
    .{ "-C"          , &createConfig },
    .{ "-config"     , &createConfig },
    .{ "-configure"  , &createConfig },
    .{ "config"      , &createConfig },
    .{ "configure"   , &createConfig },

    .{ "--help"      , &printHelp    },
    .{ "-?"          , &printHelp    },
    .{ "-h"          , &printHelp    },
    .{ "-H"          , &printHelp    },
    .{ "-help"       , &printHelp    },
    .{ "/?"          , &printHelp    },
    .{ "/h"          , &printHelp    },
    .{ "help"        , &printHelp    },
    .{ "HELP"        , &printHelp    },

    .{ "--version"   , &printVersion },
    .{ "-v"          , &printVersion },
    .{ "-V"          , &printVersion },
    .{ "-version"    , &printVersion },
    .{ "/V"          , &printVersion },
    .{ "version"     , &printVersion },
    .{ "VERSION"     , &printVersion },
});

/// Prints help and exits
fn printHelp() !void { try print.stdout(i18n.HELP); }

/// Do nothing: version already is on system header
fn printVersion() !void {}

/// Creates a config.json with default values in the same directory of the system
fn createConfig() !void {
    try print.stdout(i18n.CONFIG_MESSAGE_CREATE);

    _ = std.Io.Dir.cwd().statFile(globals.io, "config.json", .{}) catch |err| {
        if (err == error.FileNotFound) {
            const config_file: std.Io.File = try std.Io.Dir.cwd().createFile(globals.io, "config.json", .{});
            defer config_file.close(globals.io);

            var file_writer: std.Io.File.Writer = config_file.writer(globals.io, &globals.io_buffer);
            try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG);
            try file_writer.interface.flush();

            try print.alignedOk(i18n.CONFIG_MESSAGE_CREATE);
            return print.stdout("\n");
        }
        return err;
    };

    return print.err("{s}\n", .{i18n.ERROR_CONFIG_FILE});
}

/// Changes terminal codepage on Windows
pub fn main(init: std.process.Init) !void {
    if (@import("builtin").os.tag != .windows) return commonMain(init);

    // Changes the console codepage to UTF-8 and restores it back on exit
    const kernel32 = std.os.windows.kernel32;
    const original_cp: c_uint = std.os.windows.kernel32.GetConsoleOutputCP();

    defer _ = kernel32.SetConsoleOutputCP(original_cp);

    if (kernel32.SetConsoleOutputCP(65001) == 0) return error.SetConsoleOutputCPFailed;

    return commonMain(init);
}

/// Common main for all operating systems
fn commonMain(init: std.process.Init) !void {
    // Accessing command line arguments (arena required):
    var check_directory: []u8 = undefined;

    const arena: std.mem.Allocator = init.arena.allocator();
    var gpa: std.heap.DebugAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    globals.alloc = &gpa.allocator();

    globals.io = init.io;

    globals.file_writer_stdout = .init(.stdout(), globals.io, &globals.io_buffer);
    globals.file_writer_stderr = .init(.stderr(), globals.io, &globals.io_buffer);

    globals.file_writer_stdout_interface = globals.file_writer_stdout.interface;
    globals.file_writer_stderr_interface = globals.file_writer_stderr.interface;

    globals.file_stats = globals.FileStatMap.init(globals.alloc.*);
    defer {
        var iterator: std.hash_map.HashMapUnmanaged([]const u8, std.Io.File.Stat, std.hash_map.StringContext,
            80).Iterator = globals.file_stats.iterator();
        while (iterator.next()) |entry| { globals.alloc.*.free(entry.key_ptr.*); }
        globals.file_stats.deinit();
    }

    // Prints banner before any processing to provide immediate feedback in slow operations
    try print.stdout(i18n.HEADER);

    const args: []const [:0]const u8 = try init.minimal.args.toSlice(arena);

    if (args.len == 1) {
        _ = std.Io.Dir.cwd().statFile(globals.io, "config.json", .{}) catch |err| {
            return if (err == error.FileNotFound) printHelp() else err;
        };
   }

    if (args.len == 2) {
        if (help_version_map.get(args[1])) |func| { return func(); }
    }

    // Loads configurations from config.json or uses default values
    const config_message: []const u8 = if (config.loadLocal(&globals.config_file, &globals.config_parsed, &globals.io, globals.alloc)) i18n.CONFIG_MESSAGE else i18n.CONFIG_MESSAGE_DEFAULT;
    defer config.deinit(&globals.config_file, &globals.config_parsed, globals.alloc);

    try print.alignedOk(config_message);

    // CPU count detection for optimal parallelism
    if (globals.config_parsed.value.MAX_JOBS == 0) {
        const cpu_count: usize = std.Thread.getCpuCount() catch 1;
        globals.config_parsed.value.MAX_JOBS = @max(1, cpu_count);
    }

    if (args.len > 1) {
        check_directory = try globals.alloc.*.dupe(u8, args[1]);
    } else {
        if (globals.config_parsed.value.INPUT_FOLDER.len == 1) {
            check_directory = try std.process.getCwdAlloc(globals.alloc.*);
        } else {
            if (globals.config_parsed.value.INPUT_FOLDER.len == 0) {
                try print.stderr("\n");
                try print.warning("{s}", .{i18n.CONFIG_MESSAGE_WARNING});
                check_directory = try std.process.getCwdAlloc(globals.alloc.*);
            } else {
                check_directory = try globals.alloc.*.dupe(u8, globals.config_parsed.value.INPUT_FOLDER);
            }
        }
    }

    defer globals.alloc.*.free(check_directory);

    // Ensures path separator at end
    if (check_directory[check_directory.len - 1] == '"') check_directory[check_directory.len - 1] = std.fs.path.sep;

    globals.buffer = try globals.alloc.*.alloc(u8, globals.config_parsed.value.BUFFER_SIZE);
    defer globals.alloc.*.free(globals.buffer);

    // Prevents bugs with odd sizes of buffer
    globals.buffer_size  = globals.config_parsed.value.BUFFER_SIZE / 2;
    globals.buffer_total = globals.buffer_size * 2;

    // Checks input directory
    globals.input_directory = if (std.fs.path.isAbsolute(check_directory))
        std.Io.Dir.openDirAbsolute(globals.io, check_directory, .{ .iterate = true }) catch {
            return print.errorDirectory(check_directory);
        }
    else 
        // Relative paths
        std.Io.Dir.cwd().openDir(globals.io, check_directory, .{ .iterate = true }) catch {
            return print.errorDirectory(check_directory);
        };

    defer globals.input_directory.close(globals.io);

    // Get absolute path of input directory directory
    globals.absolute_input_path = try globals.input_directory.realPathFileAlloc(globals.io, ".", arena);

    // TODO: remove in future versions (temporary file for stat)
    const file: std.Io.File = try std.Io.Dir.cwd().createFile(globals.io, "datachecker_empty", .{});
    file.close(globals.io);
    globals.now_stat = try std.Io.Dir.cwd().statFile(globals.io, "datachecker_empty", .{});
    std.Io.Dir.cwd().deleteFile(globals.io, "datachecker_empty") catch {};

    globals.semaphore = std.Thread.Semaphore{ .permits = globals.config_parsed.value.MAX_JOBS };

    // Runs all enabled check modules
    core.run() catch |err| switch (err) {
        error.AccessDenied => {
            try print.err("\n{s}", .{i18n.ERROR_ACCESS_DENIED});
            std.process.exit(3);
        },
        else => return err,
    };

    if (!globals.config_parsed.value.ENTER_TO_QUIT) return print.stdout("\n\n");

    // Waits for user input before exiting
    try print.stdout(i18n.QUIT_MESSAGE);
    var file_reader: std.Io.File.Reader = std.Io.File.stdin().reader(globals.io, globals.buffer);
    _ = try file_reader.interface.take(1);
}
