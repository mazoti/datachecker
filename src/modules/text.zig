//!
//!
//!
//!

const ahocorasick = @import("ahocorasick");
const core        = @import("core.zig");
const data        = @import("data.zig");
const globals     = @import("globals");
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
        try print.err(i18n.END_OF_LINE_ERROR, .{});
        return true;
    }

    // Set failure links
    try ac.configure();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.init.arena.allocator());
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {

        const lowercase_extension = core.getExtensionLowercase(entry.path) orelse continue;

        if (data.TEXT_EXTENSIONS.has(lowercase_extension)) {
            checkEOL(.{entry.path, total_items, &ac}) catch |err| switch (err) {
                error.AccessDenied => {
                    try core.exitCodeFn(total_items, print.err, i18n.ERROR_ACCESS_DENIED_PATH, .{entry.path});
                    return false;
                },
                error.FileNotFound => {
                    try core.exitCodeFn(total_items, print.err, i18n.ERROR_READING_FILE, .{entry.path});
                    return false;
                },
                else => {
                    globals.exit_error.store(true, .monotonic);
                    return err;
                },
            };
        }
    }

    return false;
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
                    if (args[2].containsBuffer(file_reader.interface.buffer[0..file_reader.interface.end])) {
                        globals.exit_warning.store(true, .monotonic);
                        args[1].* += 1;
                        try print.warning(i18n.END_OF_LINE_WARNING, .{args[0]});
                    }
                    return;
                },
                else => return err,
            };

        if (args[2].containsBuffer(chunk[0..chunk.len])) {
            globals.exit_warning.store(true, .monotonic);
            args[1].* += 1;
            return print.warning(i18n.END_OF_LINE_WARNING, .{args[0]});
        }
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
                    try core.exitCodeFn(args[1], print.err, i18n.ERROR_STREAM_TOO_LONG, .{args[0]});
                    return false;
                }

                globals.exit_error.store(true, .monotonic);
                return err;
          };
    defer globals.init.arena.allocator().free(file_contents);

    if (!std.unicode.utf8ValidateSlice(file_contents)) {
        globals.exit_warning.store(true, .monotonic);
        return print.messageSumReturn(true, args[1], print.warning, i18n.UTF8_ENCODING_WARNING, .{args[0]});
    }

    return false;
}
