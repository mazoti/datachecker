//! Validates JSON files by attempting to parse them
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");

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
            core.debugPrintError(err);

            if (err == error.StreamTooLong) {
                try print.err(i18n.ERROR_STREAM_TOO_LONG, .{args[0]});
                args[1].* += 1;
                return true;
            }

            return err;
        };
    defer globals.alloc.*.free(file_contents);

    var parsed: std.json.Parsed(std.json.Value) = std.json.parseFromSlice(std.json.Value, globals.alloc.*,
    file_contents, .{}) catch |err| {
        core.debugPrintError(err);

        try print.err(i18n.PARSE_JSON_FILES_ERROR, .{args[0]});
        args[1].* += 1;
        return true;
    };
    defer parsed.deinit();

    return false;
}
