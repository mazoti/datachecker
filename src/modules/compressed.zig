//! Checks compressed files for improvements
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");
const core    = @import("core.zig");

const CompressFunction = *const fn ([]const u8, *u64, *std.Io.File.Reader) anyerror!bool;

const command_map = std.StaticStringMap(CompressFunction).initComptime(.{
    .{ ".bz2"  , checkBZIP2 },
    .{ ".docx" , checkZIP   },
    .{ ".epub" , checkZIP   },
    .{ ".gz"   , checkGZ    },
    .{ ".png"  , checkPNG   },
    .{ ".pptx" , checkZIP   },
    .{ ".xlsx" , checkZIP   },
    .{ ".zip"  , checkZIP   },
});

/// Core checking logic for a single file
pub fn check(args: anytype) !bool {
    if (core.getExtensionLowercase(args[0])) |lowercase| {
        const checker: CompressFunction = command_map.get(lowercase) orelse return true;

        const input_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, args[0],
            .{.mode = .read_only, .lock = .shared});
        defer input_file.close(globals.io);

        var file_reader: std.Io.File.Reader = input_file.reader(globals.io, globals.buffer);

        return checker(args[0], args[1], &file_reader);
    }

    return true;
}

fn checkBZIP2(fullpath: []const u8, total_items: *u64, file_reader: *std.Io.File.Reader) !bool {
    if (try core.readExactChunk(file_reader, 4, fullpath, total_items)) |chunk| {
        // Check the 4th byte: BZIP2 uses compression levels 1-9
        if(chunk[3] != '9') return core.messageSum(print.warning, total_items, 1,
            i18n.COMPRESSED_FILES_WARNING, .{fullpath});
        return false;
    }
    return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{fullpath});
}

fn checkGZ(fullpath: []const u8, total_items: *u64, file_reader: *std.Io.File.Reader) !bool {
    if (try core.readExactChunk(file_reader, 9, fullpath, total_items)) |chunk| {
        if(chunk[8] != 2) return core.messageSum(print.warning, total_items, 1,
            i18n.COMPRESSED_FILES_WARNING, .{fullpath});
        return false;
    }
    return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{fullpath});
}

fn checkPNG(fullpath: []const u8, total_items: *u64, file_reader: *std.Io.File.Reader) !bool {
    if (try core.readExactChunk(file_reader, 8, fullpath, total_items)) |chunk| {
        // Wrong magic number
        if (!std.mem.eql(u8, chunk[0..8], "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A")) return core.messageSum(print.err,
            total_items, 1, i18n.ERROR_READING_FILE, .{fullpath});

        if (try core.readExactChunk(file_reader, 128, fullpath, total_items)) |chunk2| {
            if (std.mem.indexOf(u8, chunk2[0..128], "IDAT")) |pos| {
                // FLEVEL = 11xx xxxx == max compression
                if (chunk2[pos+5] & 0xC0 != 0xC0) return core.messageSum(print.warning, total_items, 1,
                    i18n.COMPRESSED_FILES_WARNING, .{fullpath});
            }
            return false;
        }
    }
    return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{fullpath});
}

fn checkZIP(fullpath: []const u8, total_items: *u64, file_reader: *std.Io.File.Reader) !bool {
    if (try core.readExactChunk(file_reader, 16, fullpath, total_items)) |chunk| {
        // If compression method > 8, it's a special/enhanced method
        if(chunk[8] > 8) return core.messageSum(print.check, total_items, 1,
            i18n.COMPRESSED_FILES_CHECK, .{fullpath});

        // If compression method is between 1-7, it's suboptimal
        if(chunk[8] < 8 and chunk[8] > 0) return core.messageSum(print.warning, total_items, 1,
            i18n.COMPRESSED_FILES_WARNING, .{fullpath});

        return false;
    }
    return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE, .{fullpath});
}
