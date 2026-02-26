//! Checks files for sensitive content like private keys
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

const ahocorasick = @import("ahocorasick");
const config      = @import("config");
const globals     = @import("globals");
const i18n        = @import("i18n");
const print       = @import("print");

const core        = @import("core.zig");

/// Scans a directory tree for confidential files
pub fn checkConfidential(total_items: *u64) !void {
    // Initializes Aho-Corasick trie
    var ac: ahocorasick.AhoCorasick = try ahocorasick.AhoCorasick.initEmpty(globals.alloc.*);
    defer ac.deinit();

    // Converts each hex pattern to bytes and add to trie
    for (globals.config_parsed.value.PATTERN_BASE64_BYTES) |encoded| {
        // Calculate the size needed for decoding
        const decode_size: usize = try std.base64.standard.Decoder.calcSizeForSlice(encoded);

        // Allocate buffer for decoded data
        const decoded: []u8 = try globals.alloc.*.alloc(u8, decode_size);
        defer globals.alloc.*.free(decoded);

        // Decode the base64 string
        try std.base64.standard.Decoder.decode(decoded, encoded);
        try ac.add(decoded);
    }

    for (globals.config_parsed.value.PATTERNS) |pattern| { try ac.add(pattern); }

    // Set failure links
    try ac.configure();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.alloc.*);
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        checkConfidentialFiles(.{entry.path, total_items, &entry.stat, &ac}) catch |err| switch (err) {
            error.AccessDenied => {
                _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_ACCESS_DENIED_PATH, .{entry.path});
                return;
            },
            error.FileNotFound => {
                _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{entry.path});
                return;
            },
            else => return err,
        };
    }
}

/// Scans file contents for any string or byte pattern defined in config.json
fn checkConfidentialFiles(args: anytype) !void {
    const input_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, args[0],
        .{.mode = .read_only, .lock = .shared});
    defer input_file.close(globals.io);

    args[3].start();

    var file_reader: std.Io.File.Reader = input_file.reader(globals.io, globals.buffer);

    while (true) {
        const chunk: []u8 = file_reader.interface.take(globals.config_parsed.value.BUFFER_SIZE)
            catch |err| switch (err) {
                error.EndOfStream => {
                    if (args[3].containsBuffer(file_reader.interface.buffer[0..file_reader.interface.end]))
                        _ = try core.messageSum(print.warning, args[1], 1,
                            i18n.CONFIDENTIAL_FILES_WARNING, .{args[0]});
                    return;
                },
                else => return err,
            };

        if (args[3].containsBuffer(chunk[0..chunk.len])) {
            _ = try core.messageSum(print.warning, args[1], 1, i18n.CONFIDENTIAL_FILES_WARNING, .{args[0]});
            return;
        }
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}
