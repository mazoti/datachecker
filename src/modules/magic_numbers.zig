//! Validates file type by checking magic numbers against file extensions
//!
//! Copyright © 2025-present Marcos Mazoti

const config  = @import("config");
const core    = @import("core.zig");
const data    = @import("data.zig");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");
const std     = @import("std");

const FormatConfig = struct {
    size:      usize,
    offset:    usize,
    validator: *const fn ([]const u8) bool,
};

const format_config_map = std.StaticStringMap(FormatConfig).initComptime(.{
    .{ ".avi"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkAVI      }},
    .{ ".avif" , FormatConfig{ .size = 8  , .offset = 4     , .validator = &checkAVIF     }},
    .{ ".cue"  , FormatConfig{ .size = 9  , .offset = 0     , .validator = &checkCUE      }},
    .{ ".dcm"  , FormatConfig{ .size = 4  , .offset = 128   , .validator = &checkDICOM    }},
    .{ ".docx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP      }},
    .{ ".eot"  , FormatConfig{ .size = 2  , .offset = 34    , .validator = &checkEOT      }},
    .{ ".gif"  , FormatConfig{ .size = 6  , .offset = 0     , .validator = &checkGIF      }},
    .{ ".htm"  , FormatConfig{ .size = 15 , .offset = 0     , .validator = &checkHTML     }},
    .{ ".html" , FormatConfig{ .size = 15 , .offset = 0     , .validator = &checkHTML     }},
    .{ ".iso"  , FormatConfig{ .size = 5  , .offset = 32769 , .validator = &checkISO      }},
    .{ ".jar"  , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP      }},
    .{ ".mov"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkMOV      }},
    .{ ".mp3"  , FormatConfig{ .size = 3  , .offset = 0     , .validator = &checkMP3      }},
    .{ ".mp4"  , FormatConfig{ .size = 8  , .offset = 0     , .validator = &checkMP4      }},
    .{ ".opus" , FormatConfig{ .size = 36 , .offset = 0     , .validator = &checkOPUS     }},
    .{ ".pfr"  , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkPFR      }},
    .{ ".pptx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP      }},
    .{ ".tar"  , FormatConfig{ .size = 5  , .offset = 257   , .validator = &checkTar      }},
    .{ ".tiff" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkTIFF     }},
    .{ ".wav"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkWAV      }},
    .{ ".webp" , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkWebp     }},
    .{ ".xlsx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP      }},
    .{ ".zip"  , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP      }},
});

/// Validates file format by checking magic numbers against file extension
pub fn check(args: anytype) !bool {
    const file_check: std.Io.File = try std.Io.Dir.cwd().openFile(globals.init.io, args[0],
        .{.mode = .read_only, .lock = .shared});
    defer file_check.close(globals.init.io);

    if (core.getExtensionLowercase(args[0])) |lowercase| {
        // Checks for simple magic numbers (single signature at start of file)
        var total_items: u64 = 0;

        if (data.MAGIC_NUMBERS.get(lowercase)) |magic_number| {

            var file_reader: std.Io.File.Reader = file_check.reader(globals.init.io, globals.buffer[lowercase.len..
                (lowercase.len + magic_number.len)]);

            if (try core.readExactChunk(&file_reader, magic_number.len, args[0], &total_items)) |chunk| {
                if (!std.mem.eql(u8, chunk, magic_number)) {
                    try core.exitCodeFn(args[1], print.err, i18n.MAGIC_NUMBERS_ERROR, .{args[0]});
                    return true;
                }
            }

            return false;
        }

        // Handles files with complex magic numbers (multiple signatures or offset positions)
        if (format_config_map.get(lowercase)) |size_start_func| {

            var file_reader: std.Io.File.Reader = file_check.reader(globals.init.io, globals.buffer[lowercase.len..
                (lowercase.len + size_start_func.size)]);

            if (size_start_func.offset > 0) try file_reader.seekTo(size_start_func.offset);

            if (try core.readExactChunk(&file_reader, size_start_func.size, args[0], &total_items)) |_| {
                if (!size_start_func.validator(globals.buffer[lowercase.len..(lowercase.len + size_start_func.size)])) {
                    try core.exitCodeFn(args[1], print.err, i18n.MAGIC_NUMBERS_ERROR, .{args[0]});
                    return true;
                }

                return false;
            }

            try core.exitCodeFn(args[1], print.err, i18n.ERROR_READING_FILE, .{args[0]});
            return true;
        }
    }

    return false;
}

/// Core checking logic for a single file
pub fn checkNoExtension(args: anytype) !bool {
    // Extract extension and normalize to lowercase for case-insensitive matching
    const extension: []const u8 = std.fs.path.extension(args[0]);
    if (extension.len > 0) return true;

    args[1].* += 1;

    if (findType(args[0], globals.buffer)) |filetype| {
        _ = try print.check(i18n.NO_EXTENSION_CHECK, .{args[0], filetype});
        return true;
    }

    globals.exit_warning.store(true, .monotonic);
    _ = try print.warning(i18n.NO_EXTENSION_WARNING, .{args[0]});
    return false;
}

const checkAVI = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x41\x56\x49\x20" },
});

const checkAVIF = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x66\x74\x79\x70\x61\x76\x69\x66" },
});

const checkCUE = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "CATALOG"   },
    .{ .offset = 0, .bytes = "FILE"      },
    .{ .offset = 0, .bytes = "INDEX"     },
    .{ .offset = 0, .bytes = "PERFORMER" },
    .{ .offset = 0, .bytes = "REM"       },
    .{ .offset = 0, .bytes = "TITLE"     },
    .{ .offset = 0, .bytes = "TRACK"     },
});

const checkDICOM = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "DICM" },
});

const checkEOT = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x4C\x50" },
});

const checkGIF = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x47\x49\x46\x38\x37\x61" },
    .{ .offset = 0, .bytes = "\x47\x49\x46\x38\x39\x61" },
});

const checkHTML = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x3C\x68\x74\x6D\x6C\x3E" },
    .{ .offset = 0, .bytes = "\x3C\x48\x54\x4D\x4C\x3E" },
    .{ .offset = 0, .bytes = "\x3C\x21\x44\x4F\x43\x54\x59\x50\x45\x20\x68\x74\x6D\x6C\x3E" },
});

const checkISO = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x43\x44\x30\x30\x31" },
});

const checkMOV = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x00\x00\x00"                     },
    .{ .offset = 4, .bytes = "\x66\x74\x79\x70\x71\x74\x20\x20" },
});

const checkMP3 = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\xFF\xF3"     },
    .{ .offset = 0, .bytes = "\xFF\xFB"     },
    .{ .offset = 0, .bytes = "\xFF\xF2"     },
    .{ .offset = 0, .bytes = "\x49\x44\x33" },
});

const checkMP4 = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x00\x00\x00"     },
    .{ .offset = 4, .bytes = "\x66\x74\x79\x70" },
});

const checkOPUS = makeCheckerAND(&.{
    .{ .offset = 0,  .bytes = "OggS"     },
    .{ .offset = 28, .bytes = "OpusHead" },
});

const checkPFR = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x50\x46\x52\x30" },
    .{ .offset = 0, .bytes = "\x50\x46\x52\x31" },
});

const checkTar = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x75\x73\x74\x61\x72" },
});

const checkTIFF = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x49\x49\x2A\x00" },
    .{ .offset = 0, .bytes = "\x4D\x4D\x00\x2A" },
});

const checkWAV = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x57\x41\x56\x45" },
});

const checkWebp = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x57\x45\x42\x50" },
});

const checkZIP = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x50\x4B\x03\x04" },
    .{ .offset = 0, .bytes = "\x50\x4B\x05\x06" },
});

/// Attempts to identify file type by reading and matching magic numbers
fn findType(filepath: []const u8, buffer: []u8) ?[]const u8 {
    const input_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.init.io, filepath,
        .{.mode = .read_only, .lock = .shared}) catch |err| {
            return nullErr(err);
        };
    defer input_file.close(globals.init.io);

    var file_reader: std.Io.File.Reader = input_file.reader(globals.init.io, buffer);

    var total_items: u64 = 0;

    const chunk_tmp: ?[]const u8 = core.readExactChunk(&file_reader, 16, filepath, &total_items) catch |err| {
        return nullErr(err);
    };

    const chunk = chunk_tmp orelse return null;

    // Try matching against simple magic numbers of increasing sizes
    for (2..chunk.len) |size| {
        if (data.MAGIC_NUMBERS_KEY.get(buffer[0..size])) |filetype| { return filetype; }
    }

    // Try matching against complex format validators
    for (format_config_map.keys()) |key| {
        file_reader.seekTo(0) catch |err| {
            return nullErr(err);
        };

        const value: FormatConfig = format_config_map.get(key).?;

        if (value.offset > 0) file_reader.seekTo(value.offset) catch |err| {
            return nullErr(err);
        };

        const chunk_tmp2: ?[]const u8 = core.readExactChunk(&file_reader, value.size, filepath, &total_items)
            catch |err| {
                return nullErr(err);
            };

        if (chunk_tmp2) |_| { if (value.validator(buffer)) return key; }
    }

    return null;
}

fn makeCheckerAND(comptime signatures: []const struct{ offset: usize, bytes: []const u8 }) fn([]const u8) bool {
    return struct {
        fn check(buffer: []const u8) bool {
            inline for (signatures) |sig| {
                if (!std.mem.eql(u8, buffer[sig.offset..sig.offset + sig.bytes.len], sig.bytes)) {
                    return false;
                }
            }
            return true;
        }
    }.check;
}

fn makeCheckerOR(comptime signatures: []const struct{ offset: usize, bytes: []const u8 }) fn([]const u8) bool {
    return struct {
        fn check(buffer: []const u8) bool {
            inline for (signatures) |sig| {
                if (std.mem.eql(u8, buffer[sig.offset..sig.offset + sig.bytes.len], sig.bytes)) {
                    return true;
                }
            }
            return false;
        }
    }.check;
}

fn nullErr(err: anytype) ?[]const u8 {
    core.debugPrintError(err);
    globals.exit_error.store(true, .monotonic);
    return null;
}
