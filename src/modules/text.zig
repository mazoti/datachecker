//!
//!
//!
//!

const ahocorasick = @import("ahocorasick");
const config      = @import("config");
const core        = @import("core.zig");
const data        = @import("data");
const globals     = @import("globals");
const output      = @import("output");
const i18n        = @import("i18n");
const print       = @import("print");
const std         = @import("std");

///
pub fn endOfLine(total_items: *u64) !bool {
    // Initializes Aho-Corasick trie
    var ac: ahocorasick.AhoCorasick = try ahocorasick.AhoCorasick.initEmpty(globals.init.arena.allocator());
    defer ac.deinit();

    var terminator_found: bool = false;
    for (data.LINE_TERMINATORS) |terminator| {
        if (std.mem.eql(u8, terminator, globals.config_parsed.value.EOL_CHARS)) {
            terminator_found = true;
            continue;
        }

        try ac.add(terminator);
    }

    if (!terminator_found) {
        globals.exit_error.store(true, .monotonic);
        return eol_error(true, i18n.END_OF_LINE_ERROR, .{});
    }

    // Set failure links
    try ac.configure();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.init.arena.allocator());
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {

        const lowercase_extension = core.getExtensionLowercase(entry.path) orelse continue;

        if (data.TEXT_EXTENSIONS.has(lowercase_extension)) {
            checkEOL(.{entry.path, total_items, &ac}) catch |err| switch (err) {
                error.AccessDenied => return eol_error(false, i18n.ERROR_ACCESS_DENIED_PATH, .{entry.path}),
                error.FileNotFound => return eol_error(false, i18n.ERROR_READING_FILE, .{entry.path}),
                else => {
                    globals.exit_error.store(true, .monotonic);
                    return err;
                },
            };
        }
    }

    return false;
}

fn eol_error(ret_value: bool, comptime fmt_msg: []const u8, args: anytype) !bool {
    try output.add(&globals.output_results.end_of_line, config.Status.ERROR, fmt_msg, args);
    try print.err(fmt_msg, args);
    return ret_value;
}

fn eol_warning(args: anytype) !void {
    globals.exit_warning.store(true, .monotonic);
    args[1].* += 1;
    try output.add(&globals.output_results.end_of_line, config.Status.WARNING, i18n.END_OF_LINE_WARNING, .{args[0]});
    return print.warning(i18n.END_OF_LINE_WARNING, .{args[0]});
}

/// Scans file contents for
fn checkEOL(args: anytype) !void {
    const input_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.init.io, args[0],
        .{.mode = .read_only, .lock = .shared});
    defer input_file.close(globals.init.io);

    args[2].start();

    var file_reader: std.Io.File.Reader = input_file.reader(globals.init.io, globals.buffer);

    while (true) {
        const chunk: []u8 = file_reader.interface.take(globals.config_parsed.value.BUFFER_SIZE)
            catch |err| switch (err) {
                error.EndOfStream => {
                    if (!args[2].containsBuffer(file_reader.interface.buffer[0..file_reader.interface.end])) return;
                    return eol_warning(args);
                },
                else => return err,
            };

        if (args[2].containsBuffer(chunk[0..chunk.len])) return eol_warning(args);
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}

///
pub fn utf8Encoding(args: anytype) !bool {
    const lowercase_extension = core.getExtensionLowercase(args[0]) orelse return false;
    if (!data.TEXT_EXTENSIONS.has(lowercase_extension)) return false;

    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.init.io, args[0], globals.init.arena.allocator(),
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
                core.debugPrintError(err);

                if (err == error.StreamTooLong) {
                    try output.add(&globals.output_results.utf8_encoding, config.Status.ERROR, i18n.ERROR_STREAM_TOO_LONG, .{args[0]});
                    try core.exitCodeFn(args[1], print.err, i18n.ERROR_STREAM_TOO_LONG, .{args[0]});
                    return false;
                }

                globals.exit_error.store(true, .monotonic);
                return err;
          };
    defer globals.init.arena.allocator().free(file_contents);

    if (!std.unicode.utf8ValidateSlice(file_contents)) {
        globals.exit_warning.store(true, .monotonic);
        try output.add(&globals.output_results.utf8_encoding, config.Status.WARNING, i18n.UTF8_ENCODING_WARNING, .{args[0]});
        return print.messageSumReturn(true, args[1], print.warning, i18n.UTF8_ENCODING_WARNING, .{args[0]});
    }

    return false;
}
