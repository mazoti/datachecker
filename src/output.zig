//!
//! Copyright © 2025-present Marcos Mazoti

const builtin         = @import("builtin");
const config          = @import("config");
const globals         = @import("globals");
const i18n            = @import("i18n");
const print           = @import("print");
const std             = @import("std");

var buffer_arraylist_mutex: std.Io.Mutex = std.Io.Mutex{.state = std.atomic.Value(std.Io.Mutex.State).init(.unlocked)};

pub fn add(file_result: *std.ArrayList(config.FileResult), message_status: config.Status, comptime fmt_message: []const u8, args: anytype) !void {
    // Enables JSON output results to a file in disk
    if(!config.COMPTIME_JSON_OUTPUT) return;
    if(globals.config_parsed.value.OUTPUT_FILE.len == 0) return;

    buffer_arraylist_mutex.lock(globals.init.io) catch |err| {
        if (builtin.mode == .debug) {
            std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return err;
        }
    };
    defer buffer_arraylist_mutex.unlock(globals.init.io);


    const buffer_msg: []const u8 = try std.fmt.bufPrint(globals.buffer, fmt_message, args);

    const message = try globals.init.arena.allocator().dupe(u8, buffer_msg);
    errdefer {
        globals.init.arena.allocator().free(message);
        deinit();
    }

    const fr = config.FileResult{ .status = message_status, .message = message };

    errdefer deinit();
    try file_result.*.append(globals.init.arena.allocator(), fr);
}

pub fn deinit() void {
    // Enables JSON output results to a file in disk
    if(!config.COMPTIME_JSON_OUTPUT) return;
    if(globals.config_parsed.value.OUTPUT_FILE.len == 0) return;

    print.stdout("\x1b[2A") catch {};
    print.header(i18n.JSON_OUTPUT_HEADER) catch {};

    writeJSON() catch |err| {
        if (!config.COMPTIME_STDOUT) return;
        if (builtin.mode == .debug) {
            std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
        }
    };

    if (config.COMPTIME_COMPRESSED_FILES)         clean(&globals.output_results.compressed_files);
    if (config.COMPTIME_CONFIDENTIAL_FILES)       clean(&globals.output_results.confidential_files);
    if (config.COMPTIME_DEBUG_INFO)               clean(&globals.output_results.debug_information);
    if (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE) clean(&globals.output_results.directory_file_name_size);
    if (config.COMPTIME_DUPLICATE_CHARS_FILES)    clean(&globals.output_results.duplicate_chars_files);
    if (config.COMPTIME_EMPTY_FILES)              clean(&globals.output_results.empty_files);
    if (config.COMPTIME_END_OF_LINE)              clean(&globals.output_results.end_of_line);
    if (config.COMPTIME_EMPTY_DIRECTORIES)        clean(&globals.output_results.empty_directories);
    if (config.COMPTIME_FILES_NEWER_ATIME)        clean(&globals.output_results.files_newer_atime);
    if (config.COMPTIME_FILES_NEWER_CTIME)        clean(&globals.output_results.files_newer_ctime);
    if (config.COMPTIME_FILES_NEWER_MTIME)        clean(&globals.output_results.files_newer_mtime);
    if (config.COMPTIME_FILES_OLDER_ATIME)        clean(&globals.output_results.files_older_atime);
    if (config.COMPTIME_FILES_OLDER_CTIME)        clean(&globals.output_results.files_older_ctime);
    if (config.COMPTIME_FILES_OLDER_MTIME)        clean(&globals.output_results.files_older_mtime);
    if (config.COMPTIME_FULL_PATH_SIZE)           clean(&globals.output_results.full_path_size);
    if (config.COMPTIME_LARGE_FILES)              clean(&globals.output_results.large_files);
    if (config.COMPTIME_LAST_ACCESS_FILES)        clean(&globals.output_results.last_access_files);















    print.alignedOk(i18n.JSON_OUTPUT_HEADER) catch {};
    print.stdout("\n\n") catch {};
}

pub fn init() !void {
    // Enables JSON output results to a file in disk
    if(!config.COMPTIME_JSON_OUTPUT) return;
    if(globals.config_parsed.value.OUTPUT_FILE.len == 0) return;

    globals.output_results = config.Output {
        .version = config.COMPTIME_VERSION,
        .compressed_files         = if (config.COMPTIME_COMPRESSED_FILES)         std.ArrayList(config.FileResult).empty else {},
        .confidential_files       = if (config.COMPTIME_CONFIDENTIAL_FILES)       std.ArrayList(config.FileResult).empty else {},
        .debug_information        = if (config.COMPTIME_DEBUG_INFO)               std.ArrayList(config.FileResult).empty else {},
        .directory_file_name_size = if (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE) std.ArrayList(config.FileResult).empty else {},
        .duplicate_chars_files    = if (config.COMPTIME_DUPLICATE_CHARS_FILES)    std.ArrayList(config.FileResult).empty else {},
        .empty_files              = if (config.COMPTIME_EMPTY_FILES)              std.ArrayList(config.FileResult).empty else {},
        .end_of_line              = if (config.COMPTIME_END_OF_LINE)              std.ArrayList(config.FileResult).empty else {},
        .empty_directories        = if (config.COMPTIME_EMPTY_DIRECTORIES)        std.ArrayList(config.FileResult).empty else {},
        .files_newer_atime        = if (config.COMPTIME_FILES_NEWER_ATIME)        std.ArrayList(config.FileResult).empty else {},
        .files_newer_ctime        = if (config.COMPTIME_FILES_NEWER_CTIME)        std.ArrayList(config.FileResult).empty else {},
        .files_newer_mtime        = if (config.COMPTIME_FILES_NEWER_MTIME)        std.ArrayList(config.FileResult).empty else {},
        .files_older_atime        = if (config.COMPTIME_FILES_OLDER_ATIME)        std.ArrayList(config.FileResult).empty else {},
        .files_older_ctime        = if (config.COMPTIME_FILES_OLDER_CTIME)        std.ArrayList(config.FileResult).empty else {},
        .files_older_mtime        = if (config.COMPTIME_FILES_OLDER_MTIME)        std.ArrayList(config.FileResult).empty else {},
        .full_path_size           = if (config.COMPTIME_FULL_PATH_SIZE)           std.ArrayList(config.FileResult).empty else {},
        .large_files              = if (config.COMPTIME_LARGE_FILES)              std.ArrayList(config.FileResult).empty else {},
        .last_access_files        = if (config.COMPTIME_LAST_ACCESS_FILES)        std.ArrayList(config.FileResult).empty else {},








    };
}

fn writeJSON() !void {
    const json_str: []const u8 = try std.json.Stringify.valueAlloc(globals.init.arena.allocator(), globals.output_results, .{ .whitespace = .indent_2 });
    defer globals.init.arena.allocator().free(json_str);

    std.Io.Dir.cwd().writeFile(globals.init.io, .{ .sub_path = globals.config_parsed.value.OUTPUT_FILE, .data = json_str }) catch |err| {
        globals.exit_error.store(true, .monotonic);
        switch (err) {
            error.AccessDenied => {
                try print.err(i18n.ERROR_ACCESS_DENIED_PATH, .{globals.config_parsed.value.OUTPUT_FILE});
                print.waitForEnter() catch {};
                return;
            },
            error.FileBusy => {
                try print.err(i18n.ERROR_FILE_BUSY, .{globals.config_parsed.value.OUTPUT_FILE});
                print.waitForEnter() catch {};
                return;
            },
            else => {
                try print.waitForEnter();
                return;
            },
        }
    };
}

fn clean(results: *std.ArrayList(config.FileResult)) void {
    for (results.items) |fr| { globals.init.arena.allocator().free(fr.message); }
    results.deinit(globals.init.arena.allocator());
}
