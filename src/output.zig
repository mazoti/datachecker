//! Collects per-category results (`config.FileResult`) while the program runs
//! and writes them to disk as JSON.
//!
//! Lifecycle: call `init()` once, then `add()` from any thread, then `deinit()`
//! once after the last `add()` has returned. `deinit()` writes `OUTPUT_FILE`
//! (or `OUTPUT_FILE.gz` when compressed output is requested), streaming the
//! JSON straight to the file, and frees the collected results.
//!
//! The categories are the fields of `config.Output`; categories compiled out
//! are `void` and left out of the file. When `config.COMPTIME_JSON_OUTPUT` is
//! off, or no output file was requested, `add`, `init` and `deinit` do nothing.
//!
//! Copyright © 2025-present Marcos Mazoti

const builtin         = @import("builtin");
const config          = @import("config");
const globals         = @import("globals");
const i18n            = @import("i18n");
const print           = @import("print");
const std             = @import("std");

/// ANSI: move the cursor up two lines.
const cursor_up_2_lines = "\x1b[2A";

var buffer_arraylist_mutex: std.Io.Mutex = std.Io.Mutex{.state = std.atomic.Value(std.Io.Mutex.State).init(.unlocked)};

/// JSON results are collected only when the feature is compiled in *and* the
/// user asked for an output file. Because the first half is comptime-known,
/// builds without JSON output never analyze the bodies guarded by this.
inline fn enabled() bool {
    return config.COMPTIME_JSON_OUTPUT and globals.config_parsed.value.OUTPUT_FILE.len != 0;
}

/// Records one formatted message in `file_result`.
/// Safe to call from several threads between `init()` and `deinit()`.
pub fn add(file_result: *std.ArrayList(config.FileResult), message_status: config.Status, comptime fmt_message: []const u8, args: anytype) !void {
    if (!enabled()) return;

    // The process arena is thread-safe, so formatting stays outside the lock.
    const message: []const u8 = try std.fmt.allocPrint(globals.init.arena.allocator(), fmt_message, args);
    errdefer {
        globals.init.arena.allocator().free(message);
        deinit();
    }

    buffer_arraylist_mutex.lock(globals.init.io) catch |err| {
        if (builtin.mode == .debug) {
            std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return err;
        }
    };
    defer buffer_arraylist_mutex.unlock(globals.init.io);

    errdefer deinit();
    try file_result.append(globals.init.arena.allocator(), .{ .status = message_status, .message = message });
}

/// Creates the empty result lists. Call once, before the first `add()`.
pub fn init() !void {
    if (!enabled()) return;

    inline for (comptime std.meta.fieldNames(config.Output)) |name| {
        const Field = @FieldType(config.Output, name);

        if (comptime Field == std.ArrayList(config.FileResult)) {
            @field(globals.output_results, name) = .empty;
        } else if (comptime Field == void) {
            @field(globals.output_results, name) = {}; // category compiled out
        } else if (comptime std.mem.eql(u8, name, "version")) {
            @field(globals.output_results, name) = config.COMPTIME_VERSION;
        } else {
            @compileError("json_output.init: don't know how to initialise config.Output." ++ name);
        }
    }
}

/// Writes the results to `OUTPUT_FILE` (`OUTPUT_FILE.gz` when compressed) and frees them.
/// Call once, after every thread that calls `add()` has finished.
pub fn deinit() void {
    if (!enabled()) return;

    print.stdout(cursor_up_2_lines)       catch {};
    print.header(i18n.JSON_OUTPUT_HEADER) catch {};

    if (config.COMPTIME_JSON_OUTPUT_COMPRESSED) write(globals.config_parsed.value.OUTPUT_FILE_COMPRESSED) else write(false);

    // Frees every list and leaves it empty (never `undefined`).
    inline for (comptime std.meta.fieldNames(config.Output)) |name| {
        if (comptime @FieldType(config.Output, name) == std.ArrayList(config.FileResult)) clean(&@field(globals.output_results, name));
    }

    print.alignedOk(i18n.JSON_OUTPUT_HEADER) catch {};
    print.stdout("\n\n") catch {};
}

fn write(compress: bool) void {
    const path: []const u8 = if (compress) std.fmt.bufPrint(&globals.max_path_buffer, "{s}.gz", .{globals.config_parsed.value.OUTPUT_FILE}) catch return else globals.config_parsed.value.OUTPUT_FILE;

    const file = std.Io.Dir.cwd().createFile(globals.init.io, path, .{}) catch { return; };
    defer file.close(globals.init.io);

    var file_writer = file.writer(globals.init.io, &globals.io_buffer);
    if (compress) {
        // The compressor's history window must be at least flate.max_window_len (64 KiB).
        var window: [std.compress.flate.max_window_len]u8 = undefined;
        var compress_file = std.compress.flate.Compress.init(&file_writer.interface, &window, .gzip, std.compress.flate.Compress.Options.best,) catch return;

        serialize(&compress_file.writer) catch return;
        compress_file.finish()           catch return; // final block (+ footer for .gzip/.zlib)
    } else serialize(&file_writer.interface) catch return;

    file_writer.flush() catch return;
}

fn serialize(w: *std.Io.Writer) std.Io.Writer.Error!void {
    const options: std.json.Stringify.Options = .{ .whitespace = .indent_2 };
    //if (!plain_json_arrays) return std.json.Stringify.value(globals.output_results, options, w);

    var json: std.json.Stringify = .{ .writer = w, .options = options };
    try json.beginObject();

    inline for (comptime std.meta.fieldNames(config.Output)) |name| {
        const Field = @FieldType(config.Output, name);
        if (comptime Field != void) {
            try json.objectField(name);
            if (comptime Field == std.ArrayList(config.FileResult)) {
                try json.write(@field(globals.output_results, name).items);
            } else {
                try json.write(@field(globals.output_results, name));
            }
        }
    }
    try json.endObject();
}

/// With an arena these frees mostly just forget the memory; they keep the code
/// correct if the allocator is ever swapped for a real one.
fn clean(results: *std.ArrayList(config.FileResult)) void {
    for (results.items) |fr| { globals.init.arena.allocator().free(fr.message); }
    results.deinit(globals.init.arena.allocator());
    results.* = .empty;
}
