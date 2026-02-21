//! Validates file type by checking magic numbers against file extensions
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

const MAGIC_NUMBERS = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".7z"         , "\x37\x7A\xBC\xAF\x27\x1C"                                          }, // 7-Zip archive
    .{ ".bmp"        , "\x42\x4D"                                                          }, // Windows Bitmap
    .{ ".bz2"        , "\x42\x5A\x68"                                                      }, // BZIP2 compressed file
    .{ ".cab"        , "\x4D\x53\x43\x46"                                                  }, // Microsoft Cabinet file
    .{ ".class"      , "\xCA\xFE\xBA\xBE"                                                  }, // Java compiled class file
    .{ ".chm"        , "\x49\x54\x53\x46\x03\x00\x00\x00"                                  }, // Compiled HTML Help
    .{ ".db"         , "\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33\x00"  }, // SQLite database
    .{ ".dll"        , "\x4D\x5A"                                                          }, // Windows Dynamic Link Library
    .{ ".doc"        , "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                  }, // Microsoft Word Document
    .{ ".elf"        , "\x7F\x45\x4C\x46"                                                  }, // Linux Executable and Linkable Format (.elf DOES NOT EXISTS)
    .{ ".exe"        , "\x4D\x5A"                                                          }, // Windows Portable Executable
    .{ ".flac"       , "\x66\x4C\x61\x43\x00\x00\x00\x22"                                  }, // Free Lossless Audio Codec
    .{ ".gz"         , "\x1F\x8B"                                                          }, // GZIP compressed file
    .{ ".ico"        , "\x00\x00\x01\x00"                                                  }, // Windows Icon
    .{ ".jpg"        , "\xFF\xD8\xFF"                                                      }, // JPEG image files
    .{ ".lnk"        , "\x4C\x00\x00\x00"                                                  }, // Windows shortcut
    .{ ".ogg"        , "\x4F\x67\x67\x53"                                                  }, // Ogg multimedia container
    .{ ".pdf"        , "\x25\x50\x44\x46"                                                  }, // Portable Document Format
    .{ ".png"        , "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"                                  }, // Portable Network Graphics
    .{ ".ppt"        , "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                  }, // Microsoft PowerPoint
    .{ ".ps"         , "\x25\x21\x50\x53"                                                  }, // PostScript document
    .{ ".psd"        , "\x38\x42\x50\x53"                                                  }, // Adobe Photoshop Document
    .{ ".rar"        , "\x52\x61\x72\x21\x1A\x07\x01\x00"                                  }, // RAR archive
    .{ ".rtf"        , "\x7B\x5C\x72\x74\x66\x31"                                          }, // Rich Text Format
    .{ ".svg"        , "\x3C\x73\x76\x67"                                                  }, // Scalable Vector Graphics
    .{ ".ttf"        , "\x00\x01\x00\x00"                                                  }, // TrueType Font
    .{ ".utf8bom"    , "\xEF\xBB\xBF"                                                      }, // UTF-8 Byte Order Mark (Does not exists .utf8bom)
    .{ ".utf16bebom" , "\xFE\xFF"                                                          }, // UTF-16 Big Endian BOM (Does not exists .utf16bebom)
    .{ ".utf16lebom" , "\xFF\xFE"                                                          }, // UTF-16 Little Endian BOM (Does not exists .utf16lebom)
    .{ ".xml"        , "\x3C\x3F\x78\x6D\x6C"                                              }, // XML document
    .{ ".woff"       , "\x77\x4F\x46\x46"                                                  }, // Web Open Font Format
});

const MAGIC_NUMBERS_KEY = std.StaticStringMap([]const u8).initComptime(.{
    .{ "\x00\x00\x01\x00"                                                 , ".ico"         }, // Windows Icon
    .{ "\x00\x01\x00\x00"                                                 , ".ttf"         }, // TrueType Font
    .{ "\x1F\x8B"                                                         , ".gz"          }, // GZIP compressed file
    .{ "\x25\x21\x50\x53"                                                 , ".ps"          }, // PostScript document
    .{ "\x25\x50\x44\x46"                                                 , ".pdf"         }, // Portable Document Format
    .{ "\x37\x7A\xBC\xAF\x27\x1C"                                         , ".7z"          }, // 7-Zip archive
    .{ "\x38\x42\x50\x53"                                                 , ".psd"         }, // Adobe Photoshop Document
    .{ "\x3C\x3F\x78\x6D\x6C"                                             , ".xml"         }, // XML document
    .{ "\x3C\x73\x76\x67"                                                 , ".svg"         }, // Scalable Vector Graphics
    .{ "\x42\x4D"                                                         , ".bmp"         }, // Windows Bitmap
    .{ "\x42\x5A\x68"                                                     , ".bz2"         }, // BZIP2 compressed file
    .{ "\x49\x54\x53\x46\x03\x00\x00\x00"                                 , ".chm"         }, // Compiled HTML Help
    .{ "\x4C\x00\x00\x00"                                                 , ".lnk"         }, // Windows shortcut
    .{ "\x4D\x53\x43\x46"                                                 , ".cab"         }, // Microsoft Cabinet file
    .{ "\x4D\x5A"                                                         , ".dll/exe"     }, // Windows Dynamic Link Library/Windows Portable Executable
    .{ "\x4F\x67\x67\x53"                                                 , ".ogg"         }, // Ogg multimedia container
    .{ "\x52\x61\x72\x21\x1A\x07\x01\x00"                                 , ".rar"         }, // RAR archive
    .{ "\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33\x00" , ".db"          }, // SQLite database
    .{ "\x66\x4C\x61\x43\x00\x00\x00\x22"                                 , ".flac"        }, // Free Lossless Audio Codec
    .{ "\x77\x4F\x46\x46"                                                 , ".woff"        }, // Web Open Font Format
    .{ "\x7B\x5C\x72\x74\x66\x31"                                         , ".rtf"         }, // Rich Text Format
    .{ "\x7F\x45\x4C\x46"                                                 , "elf"         }, // Linux Executable and Linkable Format (.elf DOES NOT EXISTS)
    .{ "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"                                 , ".png"         }, // Portable Network Graphics
    .{ "\xCA\xFE\xBA\xBE"                                                 , ".class"       }, // Java compiled class file
    .{ "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                 , ".doc/ppt/xls" }, // Microsoft Word/PowerPoint/XML Document
    .{ "\xEF\xBB\xBF"                                                     , ".utf8bom"     }, // UTF-8 Byte Order Mark (Does not exists .utf8bom)
    .{ "\xFE\xFF"                                                         , ".utf16bebom"  }, // UTF-16 Big Endian BOM (Does not exists .utf16bebom)
    .{ "\xFF\xD8\xFF"                                                     , ".jpg"         }, // JPEG image files
    .{ "\xFF\xFE"                                                         , ".utf16lebom"  }, // UTF-16 Little Endian BOM (Does not exists .utf16lebom)
});

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

const checkAVI = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x41\x56\x49\x20" },
});

const checkWAV = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x57\x41\x56\x45" },
});

const checkWebp = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x52\x49\x46\x46" },
    .{ .offset = 8, .bytes = "\x57\x45\x42\x50" },
});

const checkMP4 = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x00\x00\x00" },
    .{ .offset = 4, .bytes = "\x66\x74\x79\x70" },
});

const checkMOV = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x00\x00\x00" },
    .{ .offset = 4, .bytes = "\x66\x74\x79\x70\x71\x74\x20\x20" },
});

const checkAVIF = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x66\x74\x79\x70\x61\x76\x69\x66" },
});

const checkISO = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x43\x44\x30\x30\x31" },
});

const checkTar = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x75\x73\x74\x61\x72" },
});

const checkEOT = makeCheckerAND(&.{
    .{ .offset = 0, .bytes = "\x4C\x50" },
});

const checkGIF = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x47\x49\x46\x38\x37\x61" },
    .{ .offset = 0, .bytes = "\x47\x49\x46\x38\x39\x61" },
});

const checkTIFF = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x49\x49\x2A\x00" },
    .{ .offset = 0, .bytes = "\x4D\x4D\x00\x2A" },
});

const checkZIP = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x50\x4B\x03\x04" },
    .{ .offset = 0, .bytes = "\x50\x4B\x05\x06" },
});

const checkMP3 = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\xFF\xF3"     },
    .{ .offset = 0, .bytes = "\xFF\xFB"     },
    .{ .offset = 0, .bytes = "\xFF\xF2"     },
    .{ .offset = 0, .bytes = "\x49\x44\x33" },
});

const checkHTML = makeCheckerOR(&.{
    .{ .offset = 0, .bytes = "\x3C\x68\x74\x6D\x6C\x3E" },
    .{ .offset = 0, .bytes = "\x3C\x48\x54\x4D\x4C\x3E" },
    .{ .offset = 0, .bytes = "\x3C\x21\x44\x4F\x43\x54\x59\x50\x45\x20\x68\x74\x6D\x6C\x3E" },

});

const FormatConfig = struct {
    size:      usize,
    offset:    usize,
    validator: *const fn ([]const u8) bool,
};

const format_config_map = std.StaticStringMap(FormatConfig).initComptime(.{
    .{ ".avi"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkAVI  }},
    .{ ".avif" , FormatConfig{ .size = 8  , .offset = 4     , .validator = &checkAVIF }},
    .{ ".docx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP  }},
    .{ ".eot"  , FormatConfig{ .size = 2  , .offset = 34    , .validator = &checkEOT  }},
    .{ ".gif"  , FormatConfig{ .size = 6  , .offset = 0     , .validator = &checkGIF  }},
    .{ ".htm"  , FormatConfig{ .size = 15 , .offset = 0     , .validator = &checkHTML }},
    .{ ".html" , FormatConfig{ .size = 15 , .offset = 0     , .validator = &checkHTML }},
    .{ ".iso"  , FormatConfig{ .size = 5  , .offset = 32769 , .validator = &checkISO  }},
    .{ ".jar"  , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP  }},
    .{ ".mov"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkMOV  }},
    .{ ".mp3"  , FormatConfig{ .size = 3  , .offset = 0     , .validator = &checkMP3  }},
    .{ ".mp4"  , FormatConfig{ .size = 8  , .offset = 0     , .validator = &checkMP4  }},
    .{ ".pptx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP  }},
    .{ ".tar"  , FormatConfig{ .size = 5  , .offset = 257   , .validator = &checkTar  }},
    .{ ".tiff" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkTIFF }},
    .{ ".wav"  , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkWAV  }},
    .{ ".webp" , FormatConfig{ .size = 12 , .offset = 0     , .validator = &checkWebp }},
    .{ ".xlsx" , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP  }},
    .{ ".zip"  , FormatConfig{ .size = 4  , .offset = 0     , .validator = &checkZIP  }},
});

/// Validates file format by checking magic numbers against file extension
pub fn check(args: anytype) !bool {
    const file_check: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, args[0],
        .{.mode = .read_only, .lock = .shared});
    defer file_check.close(globals.io);

    if (core.getExtensionLowercase(args[0])) |lowercase| {
        // Checks for simple magic numbers (single signature at start of file)

        var total_items: u64 = 0;

        if (MAGIC_NUMBERS.get(lowercase)) |magic_number| {

            var file_reader: std.Io.File.Reader = file_check.reader(globals.io, globals.buffer[lowercase.len..
                (lowercase.len + magic_number.len)]);

            if (try core.readExactChunk(&file_reader, magic_number.len, args[0], &total_items)) |chunk| {
                if (!std.mem.eql(u8, chunk, magic_number)) return core.messageSum(print.err, args[1],
                    1, i18n.MAGIC_NUMBERS_ERROR, .{args[0]});
            }

            return false;
        }

        // Handles files with complex magic numbers (multiple signatures or offset positions)
        if (format_config_map.get(lowercase)) |size_start_func| {

            var file_reader: std.Io.File.Reader = file_check.reader(globals.io, globals.buffer[lowercase.len..
                (lowercase.len + size_start_func.size)]);

            if (size_start_func.offset > 0) try file_reader.seekTo(size_start_func.offset);

            if (try core.readExactChunk(&file_reader, size_start_func.size, args[0], &total_items)) |_| {
                if (!size_start_func.validator(globals.buffer[lowercase.len..(lowercase.len + size_start_func.size)]))
                   return core.messageSum(print.err, args[1], 1, i18n.MAGIC_NUMBERS_ERROR, .{args[0]});
               return false;
            }

            return core.messageSum(print.err, args[1], 1, i18n.ERROR_READING_FILE, .{args[0]});
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

    _ = try print.warning(i18n.NO_EXTENSION_WARNING, .{args[0]});
    return false;
}

/// Attempts to identify file type by reading and matching magic numbers
fn findType(filepath: []const u8, buffer: []u8) ?[]const u8 {
    const input_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.io, filepath,
        .{.mode = .read_only, .lock = .shared}) catch |err| {
            core.debugPrintError(err);
            return null;
        };
    defer input_file.close(globals.io);

    var file_reader: std.Io.File.Reader = input_file.reader(globals.io, buffer[0..17]);

    var total_items: u64 = 0;
    const chunk_tmp: ?[]const u8 = core.readExactChunk(&file_reader, 16, filepath, &total_items) catch |err| {
        core.debugPrintError(err);
        return null;
    };

    if (chunk_tmp) |chunk| {
        // Try matching against simple magic numbers of increasing sizes
        for (2..chunk.len) |size| {
            if (MAGIC_NUMBERS_KEY.get(buffer[0..size])) |filetype| { return filetype; }
        }

        // Try matching against complex format validators
        for (format_config_map.keys()) |key| {
            file_reader.seekTo(0) catch |err| {
                core.debugPrintError(err);
                return null;
            };

            const value: FormatConfig = format_config_map.get(key).?;

            if (value.offset > 0) file_reader.seekTo(value.offset) catch |err| {
                core.debugPrintError(err);
                return null;
            };

            const chunk_tmp2: ?[]const u8 = core.readExactChunk(&file_reader, value.size, filepath, &total_items)
                catch |err| {
                    core.debugPrintError(err);
                    return null;
                };

            if (chunk_tmp2) |_| { if (value.validator(buffer)) return key; }
        }
    }

    return null;
}
