//! Validates files by attempting to parse or decompress them
//!
//! Copyright © 2025-present Marcos Mazoti

const config  = @import("config");
const core    = @import("core.zig");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");
const std     = @import("std");

/// Parses files according to extension
pub fn parseFiles(args: anytype) !bool {
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".gz"))   return parseGZ(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".json")) return parseJSON(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".lzma")) return parseLZMA(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".tar"))  return parseTAR(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".xz"))   return parseXZ(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".zip"))  return parseZIP(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".zlib")) return parseZLIB(args);
    if (std.ascii.eqlIgnoreCase(std.fs.path.extension(args[0]), ".zst"))  return parseZST(args);

    return false;
}

/// Prints error, set globals state and exits true
fn parseError(args: anytype, err: anytype) !bool {
    core.debugPrintError(err);
    try core.exitCodeFn(args[1], print.err, i18n.PARSE_FILES_ERROR, .{args[0]});
    globals.exit_code = 1;
    return true;
}

/// Prints Stream Too Long Error, set globals state and exits error
fn parseStreamTooLongError(args: anytype, err: anytype) !bool {
    core.debugPrintError(err);

    if (err == error.StreamTooLong) {
        try core.exitCodeFn(args[1], print.err, i18n.ERROR_STREAM_TOO_LONG, .{args[0]});
        return true;
    }

    globals.exit_code = 1;
    return err;
}

/// Parses a JSON file and returns false if no errors were found
fn parseJSON(args: anytype) !bool {
    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.io, args[0], globals.alloc.*,
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
            return parseStreamTooLongError(args, err);
        };
    defer globals.alloc.*.free(file_contents);

    var parsed: std.json.Parsed(std.json.Value) = std.json.parseFromSlice(std.json.Value, globals.alloc.*,
    file_contents, .{}) catch |err| {
        return parseError(args, err);
    };
    defer parsed.deinit();

    return false;
}

/// Parses a TAR file and returns false if no errors were found
fn parseTAR(args: anytype) !bool {
    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.io, args[0], globals.alloc.*,
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
            return parseStreamTooLongError(args, err);
        };
    defer globals.alloc.*.free(file_contents);

    var name_buffer: [std.fs.max_path_bytes]u8 = undefined;
    var link_buffer: [std.fs.max_path_bytes]u8 = undefined;

    // Parse the archive directly from memory.
    var reader = std.Io.Reader.fixed(file_contents);
    var iterator = std.tar.Iterator.init(&reader, .{
          .file_name_buffer = &name_buffer,
          .link_name_buffer = &link_buffer,
    });

    while (iterator.next()) |maybe_entry| {
        const entry = maybe_entry orelse break;
        if (entry.kind != .file) continue;
    } else |err| {
        return parseError(args, err);
    }

    return false;
}

/// Decompress a GZ file and returns false if no errors were found
fn parseGZ(args: anytype) !bool {
    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.io, args[0], globals.alloc.*,
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
            return parseStreamTooLongError(args, err);
        };
    defer globals.alloc.*.free(file_contents);

    // Create a reader over the compressed data.
    var reader = std.Io.Reader.fixed(file_contents);

    // Gzip requires a sliding-window buffer.
    var window: [std.compress.flate.max_window_len]u8 = undefined;

    var decompressor: std.compress.flate.Decompress = .init(&reader, .gzip, &window);

    // Decompress into an allocated RAM buffer.
    const data = decompressor.reader.allocRemaining(globals.alloc.*, .limited(globals.memory_limit)) catch |err| {
        return parseError(args, err);
    };
    defer globals.alloc.*.free(data);

    return false;
}

/// Decompress a ZST file and returns false if no errors were found
fn parseLZMA(args: anytype) !bool {
    const file = try std.Io.Dir.cwd().openFile(globals.io, args[0], .{});
    defer file.close(globals.io);

    var stream = file.reader(globals.io, &globals.io_buffer);

    // Initialize the LZMA decompressor.
    var decompressor = std.compress.lzma.Decompress.initOptions(&stream.interface, globals.alloc.*, &.{}, .{}, globals.memory_limit) catch |err| {
        return parseError(args, err);
    };
    defer decompressor.deinit();

    // Decompress into an allocated RAM buffer
    const file_contents: []u8 = decompressor.reader.allocRemaining(globals.alloc.*, .limited(globals.memory_limit)) catch |err| {
        return parseError(args, err);
    };
    defer globals.alloc.*.free(file_contents);

    return false;
}

/// Decompress a XZ file and returns false if no errors were found
fn parseXZ(args: anytype) !bool {
    const file_contents: []u8 = std.Io.Dir.cwd().readFileAlloc(globals.io, args[0], globals.alloc.*,
        std.Io.Limit.limited64(globals.memory_limit)) catch |err| {
            return parseStreamTooLongError(args, err);
        };
    defer globals.alloc.*.free(file_contents);

    // Create a reader over the compressed data.
    var reader = std.Io.Reader.fixed(file_contents);

    // Initialize the standard-library XZ decompressor.
    var decompressor = std.compress.xz.Decompress.init(&reader, globals.alloc.*, &.{}) catch |err| {
        return parseError(args, err);
    };
    defer decompressor.deinit();

    // Decompress everything into a RAM buffer.
    const data = decompressor.reader.allocRemaining(globals.alloc.*, .limited(globals.memory_limit)) catch |err| {
        return parseError(args, err);
    };
    defer globals.alloc.*.free(data);

    return false;
}

/// Decompress a ZIP file and returns false if no errors were found
fn parseZIP(args: anytype) !bool {
    const file = try std.Io.Dir.cwd().openFile(globals.io, args[0], .{});
    defer file.close(globals.io);

    var stream = file.reader(globals.io, &globals.io_buffer);

    var iterator = std.zip.Iterator.init(&stream) catch |err| {
        return parseError(args, err);
    };

    while (iterator.next()) |maybe_entry| {
        const entry = maybe_entry orelse break;

        if (entry.uncompressed_size > globals.memory_limit) {
            return parseError(args, error.EntryTooLarge);
        }

        const size: usize = @intCast(entry.uncompressed_size);
        const output = try globals.alloc.*.alloc(u8, size);
        defer globals.alloc.*.free(output);

        // Read the local file header.
        try stream.seekTo(entry.file_offset);

        const header = try stream.interface.takeStruct(std.zip.LocalFileHeader, .little);

        if (!std.mem.eql(u8, &header.signature, &std.zip.local_file_header_sig)) {
            return parseError(args, error.BadLocalHeader);
        }

        if (@as(u32, header.filename_len) != entry.filename_len) {
            return parseError(args, error.BadLocalHeader);
        }

        // Skip the local header, filename, and extra fields.
        const data_offset =
            entry.file_offset +
            @sizeOf(std.zip.LocalFileHeader) +
            @as(u64, header.filename_len) +
            @as(u64, header.extra_len);

        try stream.seekTo(data_offset);

        // Write decompressed bytes directly to RAM.
        var writer = std.Io.Writer.fixed(output);

        switch (entry.compression_method) {
            .store => try stream.interface.streamExact64(&writer, entry.uncompressed_size),
            .deflate => {
                var flate_buffer: [std.compress.flate.max_window_len]u8 = undefined;
                var decompressor: std.compress.flate.Decompress = .init(&stream.interface, .raw, &flate_buffer);

                try decompressor.reader.streamExact64(&writer, entry.uncompressed_size);
            },
            else => return parseError(args, error.UnsupportedCompressionMethod),
        }

        // Verify the uncompressed data's CRC-32.
        var crc: std.hash.Crc32 = .init();
        crc.update(output);

        if (crc.final() != entry.crc32) {
            return parseError(args, error.BadCrc);
        }
    } else |err| {
        return parseError(args, err);
    }

    return false;
}

/// Decompress a ZLIB file and returns false if no errors were found
fn parseZLIB(args: anytype) !bool {
    const file = try std.Io.Dir.cwd().openFile(globals.io, args[0], .{});
    defer file.close(globals.io);

    var stream = file.reader(globals.io, &globals.io_buffer);

    // Allocate the DEFLATE history window.
    var decompress_buffer: [std.compress.flate.max_window_len]u8 = undefined;

    // Initialize the ZLIB-wrapped DEFLATE decompressor.
    var decompressor = std.compress.flate.Decompress.init(&stream.interface, .zlib, &decompress_buffer);

    // Decompress into RAM
    const file_contents: []u8 = decompressor.reader.allocRemaining(globals.alloc.*, .limited(globals.memory_limit)) catch |err| {
        return parseError(args, err);
    };
    defer globals.alloc.*.free(file_contents);

    return false;
}

/// Decompress a ZST file and returns false if no errors were found
fn parseZST(args: anytype) !bool {
    const file = try std.Io.Dir.cwd().openFile(globals.io, args[0], .{});
    defer file.close(globals.io);

    var stream = file.reader(globals.io, &globals.io_buffer);

    // Accumulate decompressed data in RAM
    var output: std.Io.Writer.Allocating = .init(globals.alloc.*);
    defer output.deinit();

    var decompressor = std.compress.zstd.Decompress.init(&stream.interface, &.{}, .{});

    // Decompress until the input stream ends.
    _ = decompressor.reader.streamRemaining(&output.writer) catch |err| {
        return parseError(args, err);
    };

    return false;
}
