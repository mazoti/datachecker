//! Checks files for sensitive content like private keys
//!
//! Copyright © 2025-present Marcos Mazoti

const ahocorasick = @import("ahocorasick");
const config      = @import("config");
const core        = @import("core.zig");
const globals     = @import("globals");
const i18n        = @import("i18n");
const print       = @import("print");
const std         = @import("std");

/// Scans a directory tree for confidential files
pub fn checkConfidential(total_items: *u64) !bool {
    // Initializes Aho-Corasick trie
    var ac: ahocorasick.AhoCorasick = try ahocorasick.AhoCorasick.initEmpty(globals.init.arena.allocator());
    defer ac.deinit();

    // Converts each hex pattern to bytes and add to trie
    for (globals.config_parsed.value.PATTERN_BASE64_BYTES) |encoded| {
        // Calculate the size needed for decoding
        const decode_size: usize = try std.base64.standard.Decoder.calcSizeForSlice(encoded);

        // Allocate buffer for decoded data
        const decoded: []u8 = try globals.init.arena.allocator().alloc(u8, decode_size);
        defer globals.init.arena.allocator().free(decoded);

        // Decode the base64 string
        try std.base64.standard.Decoder.decode(decoded, encoded);
        try ac.add(decoded);
    }

    for (globals.config_parsed.value.PATTERNS) |pattern| { try ac.add(pattern); }

    // Set failure links
    try ac.configure();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.init.arena.allocator());
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        checkConfidentialFiles(.{entry.path, total_items, &ac}) catch |err| switch (err) {
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
    return false;
}

/// Scans file contents for any string or byte pattern defined in config.json
fn checkConfidentialFiles(args: anytype) !void {
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
                        try print.warning(i18n.CONFIDENTIAL_FILES_WARNING, .{args[0]});
                        args[1].* += 1;
                    }
                    return;
                },
                else => return err,
            };

        if (args[2].containsBuffer(chunk[0..chunk.len])) {
            globals.exit_warning.store(true, .monotonic);
            try print.warning(i18n.CONFIDENTIAL_FILES_WARNING, .{args[0]});
            args[1].* += 1;
            return;
        }
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}
