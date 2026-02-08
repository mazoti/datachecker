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
pub fn checkConfidential(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    // Initializes Aho-Corasick trie
    var ac: ahocorasick.AhoCorasick() = try ahocorasick.AhoCorasick().initEmpty(globals.alloc.*);
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

    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.keyIterator();

        while (iterator.next()) |entry| {
            // skips directories
            const cached_stat: std.Io.File.Stat = globals.file_stats.get(entry.*) orelse continue;

            if (cached_stat.kind == std.Io.File.Kind.file) checkConfidentialFiles(.{entry.*,
                total_items, &cached_stat, &ac}) catch |err| switch (err) {
                    error.FileNotFound => {
                        _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{entry.*});
                        continue;
                    },
                    else => return err,
                };
        }

        return;
    }

    while (true) {
        const entry_tmp: ?std.Io.Dir.Walker.Entry = walker.next(globals.io) catch |err| switch (err) {
            error.AccessDenied => {
                const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
                    .{globals.absolute_input_path, std.fs.path.sep, walker.inner.name_buffer.items});

                _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
                continue;
            },
            else => return err,
        };

        if (entry_tmp) |entry| {
            if (entry.kind != .file and entry.kind != .directory) continue;

            const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
                .{globals.absolute_input_path, std.fs.path.sep, entry.path});

            // Add the file or folder to cache
            const stat: std.Io.File.Stat = core.fetchAdd(absolute_path) catch |err| switch (err) {
                error.AccessDenied => {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_ACCESS_DENIED_PATH, .{absolute_path});
                    continue;
                },
                error.FileBusy => {
                    _ = try core.messageSum(print.err, total_items, 1, i18n.ERROR_FILE_BUSY, .{absolute_path});
                    continue;
                },
                else => return err,
            };

            if (entry.kind == .file) try checkConfidentialFiles(.{absolute_path, total_items, &stat, &ac});
            continue;
        }
        return;
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
                error.EndOfStream => return,
                else => return err,
            };

        if (args[3].containsBuffer(chunk[0..chunk.len])) {
            _ = try core.messageSum(print.warning, args[1], 1, i18n.CONFIDENTIAL_FILES_WARNING, .{args[0]});
            return;
        }
    }

    std.debug.panic("SHOULD NEVER PASS HERE");
}
