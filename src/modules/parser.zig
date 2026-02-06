//! Validates JSON files by attempting to parse them
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");
const builtin = @import("builtin");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

/// Parses a JSON file and returns false if no errors were found
pub fn checkJSON(args: anytype) !bool {
    if (!std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".json")) return true;

    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.io, args[0], globals.alloc.*,
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });

            if (err == error.StreamTooLong) return core.messageSum(print.err, args[1], 1,
                i18n.ERROR_STREAM_TOO_LONG, .{args[0]});

            return err;
        };
    defer globals.alloc.*.free(file_contents);

    var parsed: std.json.Parsed(std.json.Value) = std.json.parseFromSlice(std.json.Value, globals.alloc.*,
    file_contents, .{}) catch |err| {
        if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
        return core.messageSum(print.err, args[1], 1, i18n.PARSE_JSON_FILES_ERROR, .{args[0]});
    };
    defer parsed.deinit();

    return false;
}
