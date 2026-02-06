//! This module implements a multi-strategy pattern matching system to identify
//! temporary, cache or obsolete format files.
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

const ahocorasick = @import("ahocorasick");
const config      = @import("config");
const globals     = @import("globals");
const i18n        = @import("i18n");
const print       = @import("print");

const core        = @import("core.zig");

const StartEndPattern = struct { start: []const u8, end: []const u8 };

/// Array of substrings that indicate temporary files when found anywhere in the path
/// These patterns identify version control, build artifacts, and system temporary locations
const CONTAINS = [_][]const u8{
    "\\$Recycle.bin\\",
    "\\AppData\\Local\\Temp",
    "\\Windows\\Temp",
    "\\AppData\\Local\\Microsoft\\INetCache\\IE",
    "\\AppData\\Local\\Microsoft\\INetCache\\Content.IE5",
    ".~lock.",                                     // LibreOffice/OpenOffice lock files prevent concurrent editing
    ".git/objects/tmp_",                           // Git creates tmp_* during object creation (Unix)
    ".git\\objects\\tmp_",                         // Git creates tmp_* during object creation (Windows)
    ".hg/store/journal",                           // Mercurial transaction journal (Unix)
    ".hg\\store\\journal",                         // Mercurial transaction journal (Windows)
    ".svn/tmp/",                                   // Subversion working copy temp area (Unix)
    ".svn\\tmp\\",                                 // Subversion working copy temp area (Windows)
    ".torrent.",                                   // Torrent metadata/partial files
    "/tmp/",                                       // Standard Unix temp directory
    "\\tmp\\",                                     // Windows temp directory
    "node_modules/",                               // npm dependencies - massive directory, often excluded (Unix)
    "node_modules\\",                              // npm dependencies
    "pycache/",                                    // Python bytecode cache
    "pycache\\",                                   // Python bytecode cache
    "__pycache__",                                 // Python bytecode cache
};

/// Map of exact filenames to their descriptions for system-generated temporary files
const FULL_NAME = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".DS_Store"             , ""                                   },
    .{ "desktop.ini"           , ""                                   },
    .{ "ehthumbs.db"           , "Windows thumbnail cache (enhanced)" },
    .{ "hiberfil.sys"          , ""                                   },
    .{ "Thumbs.db"             , "Windows thumbnail cache"            },
    .{ "THUMBS.DB"             , "Windows thumbnail cache"            },
});

/// Dual-condition pattern matcher for filename prefix/suffix combinations
/// Allows matching files like "~*.docx" (temp Word files) or "*~" (backup files)
/// Empty string means "no constraint" - enabling prefix-only or suffix-only matching
const START_END = [_]StartEndPattern{
    .{ .start = "."            , .end = ""      }, // Unix hidden files
    .{ .start = ".#"           , .end = ""      }, // Emacs lock files (#.#filename)
    .{ .start = ".$"           , .end = ""      }, // Temp file marker
    .{ .start = ".fuse_hidden" , .end = ""      }, // FUSE kernel filesystem hidden files
    .{ .start = ".nfs"         , .end = ""      }, // Network File System temp files (prevent deletion while open)
    .{ .start = ".z"           , .end = ""      }, // Compressed temp files
    .{ .start = ""             , .end = "~"     }, // *~ backup files (emacs, vim, gedit)
    .{ .start = "#"            , .end = "#"     }, // #file# Emacs auto-save pattern
    .{ .start = "~"            , .end = ""      }, // ~file backup files
    .{ .start = "~"            , .end = ".docx" }, // ~file.docx Word temporary
    .{ .start = "~$."          , .end = ""      }, // ~$.file Office owner files
    .{ .start = "~$"           , .end = ".pptx" }, // ~$presentation.pptx PowerPoint temp
    .{ .start = "temp"         , .end = ""      }, // temp* naming convention
    .{ .start = "tmp"          , .end = ""      }, // tmp* naming convention
};


/// Map of file extensions to descriptions for temporary and cache files
/// Covers a wide range of temporary files from various applications and systems
const TEMPORARY_EXTENSIONS = std.StaticStringMap([]const u8).initComptime(.{
    // System metadata and cache
    .{ "._.ds_store"          , "MacOS directory metadata"             },
    .{ ".~tmp"                , ""                                     },
    .{ ".$$$"                 , ""                                     },
    .{ ".$$tmp"               , ""                                     },
    .{ ".autosave"            , "Auto-saved documents"                 },
    .{ ".cache"               , "Cached data files"                    },
    .{ ".chk"                 , "Disk check fragments"                 },
    .{ ".dmp"                 , "Memory dump files"                    },
    .{ ".ds_store"            , "MacOS directory metadata"             },
    .{ ".ffs_tmp"             , "FreeFileSync"                         },
    .{ ".frm"                 , "MySQL table format"                   },
    .{ ".fseventsd"           , "MacOS file system events"             },
    .{ ".ftg"                 , "Help full-text search"                },
    .{ ".gid"                 , "Help index"                           },
    .{ ".gvfs"                , "GNOME Virtual File System"            },
    .{ ".iceauthority"        , "X11 ICE authentication"               },
    .{ ".localized"           , "MacOS folder localization"            },
    .{ ".mdmp"                , "Crash dumps"                          },
    .{ ".myd"                 , "MySQL temp"                           },
    .{ ".myi"                 , "MySQL index files"                    },
    .{ ".ncb"                 , "Visual C++ IntelliSense"              },
    .{ ".old"                 , "Old versions of files"                },
    .{ ".orig"                , "Merge conflict originals"             },
    .{ ".peak"                , "Audio waveform cache"                 },
    .{ ".pf"                  , "Windows prefetch files"               },
    .{ ".pid"                 , "Process ID files"                     },
    .{ ".recently-used"       , "GTK recent files list"                },
    .{ ".recovery"            , "Firefox"                              },
    .{ ".rej"                 , "Patch reject files"                   },
    .{ ".sample"              , "GitHub example"                       },
    .{ ".scc"                 , "Scene cache"                          },
    .{ ".spotlight-v100"      , "MacOS Spotlight index"                },
    .{ ".suo"                 , "Visual Studio user options"           },
    .{ ".swap"                , ""                                     },
    .{ ".swo"                 , "Vim editor swap files"                },
    .{ ".swp"                 , ""                                     },
    .{ ".t"                   , ""                                     },
    .{ ".t$m"                 , ""                                     },
    .{ ".temp"                , ""                                     },
    .{ ".temporary"           , ""                                     },
    .{ ".temporaryitems"      , ""                                     },
    .{ ".tmp"                 , ""                                     },
    .{ ".tpm"                 , ""                                     },
    .{ ".trashes"             , "MacOS trash metadata"                 },
    .{ ".user"                , "User-specific settings"               },
    .{ ".vmsn"                , "VMware snapshot"                      },
    .{ ".vmss"                , "VMware suspend state"                 },
    .{ ".xauthority"          , "X11 authentication"                   },
    .{ ".xsession-errors"     , "X session error log"                  },

    // Downloads
    .{ ".!ut"                 , "uTorrent incomplete"                  },
    .{ ".crdownload"          , "Chrome partial download"              },
    .{ ".download"            , "Safari download"                      },
    .{ ".downloading"         , "Download in progress"                 },
    .{ ".filepart"            , "Partial download file"                },
    .{ ".opdownload"          , "Opera partial download"               },
    .{ ".part"                , "Firefox partial download"             },
    .{ ".partial"             , "Incomplete download"                  },

    // Logs
    .{ ".blf"                 , "Windows registry transaction logs"    },
    .{ ".etl"                 , "Windows event trace logs"             },
    .{ ".ldf"                 , "SQL Server log"                       },
    .{ ".log"                 , "Log files"                            },
    .{ ".plg"                 , "Visual Studio build log"              },
    .{ ".regtrans-ms"         , "Windows registry transaction logs"    },
    .{ ".tlog"                , "Build log files"                      },

    // Development files
    .{ ".a"                   , "Static library"                       },
    .{ ".aps"                 , "Visual Studio resource cache"         },
    .{ ".cmi"                 , "OCaml compiled interface"             },
    .{ ".cmo"                 , "OCaml compiled object"                },
    .{ ".db-journal"          , "SQLite rollback journal"              },
    .{ ".dylib"               , "Dynamic library"                      },
    .{ ".elc"                 , "Emacs Lisp compiled"                  },
    .{ ".exp"                 , "Export file"                          },
    .{ ".fasl"                , "Lisp compiled file"                   },
    .{ ".gch"                 , "GCC precompiled headers"              },
    .{ ".hi"                  , "Haskell interface"                    },
    .{ ".idb"                 , "Intermediate database files"          },
    .{ ".ilk"                 , "Incremental link files"               },
    .{ ".lastbuildstate"      , "MSBuild state tracking"               },
    .{ ".lib"                 , "Static library (Windows)"             },
    .{ ".map"                 , "Linker map files"                     },
    .{ ".mdf-journal"         , "SQLite journal"                       },
    .{ ".o"                   , "Object file (ELF/Mach-O)"             },
    .{ ".obj"                 , "Object file (COFF/PE)"                },
    .{ ".opt"                 , "Visual Studio workspace options"      },
    .{ ".pdb"                 , "Program database files"               },
    .{ ".pyc"                 , "Python compiled"                      },
    .{ ".pyd"                 , "Python dynamic module"                },
    .{ ".pyo"                 , "Python optimized"                     },
    .{ ".rbc"                 , "Ruby bytecode"                        },
    .{ ".res"                 , "Compiled resources"                   },
    .{ ".sassc"               , "Sass cache"                           },
    .{ ".scratch"             , "Scratch programming temporary"        },
    .{ ".sqlite-shm"          , "Browser databases"                    },
    .{ ".sqlite-wal"          , "Browser databases"                    },
    .{ ".unsuccessfulbuild"   , ""                                     },

    // Thumbnails files
    .{ ".thumbnails"          , "Thumbnail cache directory"            },
    .{ ".thumbs"              , "Thumbnail cache"                      },

    // Backup files
    .{ ".bak"                 , "Backup files"                         },

    // Lock files
    .{ ".lck"                 , "VMware lock files"                    },
    .{ ".lock"                , ""                                     },
    .{ ".lok"                 , ""                                     },
});

/// Map of legacy/obsolete file extensions to their descriptions
/// Contains formats from older software, operating systems, and file formats
const LEGACY_EXTENSIONS_DESCRIPTION = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".123"                 , "Lotus 1-2-3"                          },
    .{ ".669"                 , "Composer 669"                         },
    .{ ".8svx"                , "Amiga 8-bit sound"                    },
    .{ ".adf"                 , "Amiga Disk File"                      },
    .{ ".aiff"                , "Audio Interchange File Format"        },
    .{ ".arc"                 , "ARC archive"                          },
    .{ ".arj"                 , "ARJ compressed archive"               },
    .{ ".asf"                 , "Advanced Systems Format"              },
    .{ ".au"                  , "Sun Audio file"                       },
    .{ ".b64"                 , "Base64 encoded"                       },
    .{ ".bas"                 , "BASIC source code"                    },
    .{ ".bat"                 , "Batch file"                           },
    .{ ".binhex"              , "BinHex encoded"                       },
    .{ ".bmp"                 , "Bitmap"                               },
    .{ ".cgm"                 , "Computer Graphics Metafile"           },
    .{ ".cmf"                 , "Creative Music File"                  },
    .{ ".com"                 , "DOS executable"                       },
    .{ ".cut"                 , "Dr. Halo"                             },
    .{ ".cwk"                 , "ClarisWorks document"                 },
    .{ ".d64"                 , "Commodore 64 disk"                    },
    .{ ".dbf"                 , "dBASE database file"                  },
    .{ ".dif"                 , "Data Interchange Format"              },
    .{ ".dl"                  , "DL Animation"                         },
    .{ ".doc"                 , "Microsoft Word 97-2003"               },
    .{ ".dsk"                 , "Disk image"                           },
    .{ ".dxf"                 , "AutoCAD exchange"                     },
    .{ ".far"                 , "Farandole Composer"                   },
    .{ ".fdi"                 , "Formatted Disk Image"                 },
    .{ ".fla"                 , "Adobe Flash source"                   },
    .{ ".flc"                 , "Autodesk Animator"                    },
    .{ ".fli"                 , "Autodesk Animator"                    },
    .{ ".fon"                 , "Font file"                            },
    .{ ".frm"                 , "FoxPro form"                          },
    .{ ".gem"                 , "GEM Metafile"                         },
    .{ ".gl"                  , "Grasp GL"                             },
    .{ ".grp"                 , "Program Group"                        },
    .{ ".hqx"                 , "BinHex - Mac"                         },
    .{ ".iff"                 , "Interchange File Format - Amiga"      },
    .{ ".ima"                 , "Disk image"                           },
    .{ ".it"                  , "Impulse Tracker"                      },
    .{ ".lbm"                 , "Deluxe Paint"                         },
    .{ ".lha"                 , "LHArc"                                },
    .{ ".lzh"                 , "LZH compressed archive"               },
    .{ ".manuscript"          , "WriteNow"                             },
    .{ ".mcw"                 , "MacWrite"                             },
    .{ ".mdb"                 , "Microsoft Access Database"            },
    .{ ".mdx"                 , "Multiple index"                       },
    .{ ".mid"                 , "Musical Instrument Digital Interface" },
    .{ ".midi"                , "Musical Instrument Digital Interface" },
    .{ ".mime"                , "MIME encoded"                         },
    .{ ".mov"                 , "QuickTime movie"                      },
    .{ ".msp"                 , "Microsoft Paint"                      },
    .{ ".mtm"                 , "MultiTracker"                         },
    .{ ".nb"                  , "Nota Bene"                            },
    .{ ".ndx"                 , "dBASE index"                          },
    .{ ".ntx"                 , "Clipper index"                        },
    .{ ".nuv"                 , "NuppelVideo"                          },
    .{ ".ovl"                 , "Overlay file"                         },
    .{ ".pak"                 , "PAK archive"                          },
    .{ ".pas"                 , "Pascal source code"                   },
    .{ ".pct"                 , "PICT image"                           },
    .{ ".pcx"                 , "PC Paintbrush image"                  },
    .{ ".pic"                 , "PC Paint/Pictor"                      },
    .{ ".pif"                 , "Program Information File"             },
    .{ ".pit"                 , "PackIt archive - Mac"                 },
    .{ ".plt"                 , "HPGL plotter"                         },
    .{ ".prg"                 , "dBASE program"                        },
    .{ ".psw"                 , "Pocket Word"                          },
    .{ ".pwl"                 , "Password List"                        },
    .{ ".pxl"                 , "Pocket Excel"                         },
    .{ ".qpd"                 , "Quattro Pro"                          },
    .{ ".ra"                  , "RealAudio"                            },
    .{ ".rm"                  , "RealMedia file"                       },
    .{ ".rol"                 , "AdLib ROL file"                       },
    .{ ".rtf"                 , "Rich Text Format"                     },
    .{ ".s3m"                 , "ScreamTracker 3"                      },
    .{ ".sam"                 , "Samna Word"                           },
    .{ ".scr"                 , "Screen saver"                         },
    .{ ".scx"                 , "FoxPro screen"                        },
    .{ ".sdw"                 , "StarOffice Writer document"           },
    .{ ".sgi"                 , "Silicon Graphics Image"               },
    .{ ".sit"                 , "StuffIt archive"                      },
    .{ ".snd"                 , "Sound file"                           },
    .{ ".sqz"                 , "Squeeze"                              },
    .{ ".sun"                 , "Sun Raster"                           },
    .{ ".sylk"                , "Symbolic Link"                        },
    .{ ".targa"               , "TARGA image"                          },
    .{ ".td0"                 , "Teledisk"                             },
    .{ ".tga"                 , "TARGA image"                          },
    .{ ".tiff"                , "Tagged Image File Format"             },
    .{ ".tsr"                 , "Terminate and Stay Resident"          },
    .{ ".ult"                 , "Ultra Tracker"                        },
    .{ ".uue"                 , "UUEncoded"                            },
    .{ ".voc"                 , "Creative Voice File"                  },
    .{ ".wav"                 , "Waveform Audio File Format"           },
    .{ ".wk1"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wk3"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wk4"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wks"                 , "Microsoft Works spreadsheet"          },
    .{ ".wmf"                 , "Windows Metafile"                     },
    .{ ".wmv"                 , "Windows Media Video"                  },
    .{ ".wpd"                 , "WordPerfect Document"                 },
    .{ ".wpg"                 , "WordPerfect Graphics"                 },
    .{ ".wps"                 , "Microsoft Works Word Processor"       },
    .{ ".wri"                 , "Windows Write"                        },
    .{ ".xls"                 , "Microsoft Excel 97-2003"              },
    .{ ".xm"                  , "FastTracker 2"                        },
    .{ ".xy"                  , "XyWrite"                              },
    .{ ".yuv"                 , "Raw YUV video"                        },
    .{ ".zoo"                 , "ZOO compressed archive"               },
});

/// Scans a directory tree for legacy file formats
pub fn legacyFiles(args: anytype) !bool {
    // Extract extension and normalize to lowercase for case-insensitive matching
    const extension: []const u8 = std.fs.path.extension(args[0]);
    if (extension.len == 0) return false;

    // Bounds check before lowercasing
    if (extension.len > globals.buffer.len) return false;

    const lowercase: []const u8 = std.ascii.lowerString(globals.buffer[0..extension.len], extension);
    const description = LEGACY_EXTENSIONS_DESCRIPTION.get(lowercase) orelse return false;

    // Checks if the extension matches any known legacy format
    return core.messageSum(print.warning, args[1], 1, i18n.LEGACY_FILES_WARNING, .{ args[0], description });
}

/// Scans a directory tree for temporary files
pub fn temporaryFiles(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    // Initializes Aho-Corasick trie
    var ac = try ahocorasick.AhoCorasick().init(globals.alloc.*, &CONTAINS);
    defer ac.deinit();

    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.keyIterator();

        while (iterator.next()) |entry| {
            // skips directories
            const cached_stat: std.Io.File.Stat = globals.file_stats.get(entry.*) orelse continue;
            if (cached_stat.kind == std.Io.File.Kind.file) _ = try checkTempFiles(.{entry.*,
                total_items, &cached_stat, &ac});
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

            if (entry.kind == .file) _ = try checkTempFiles(.{absolute_path, total_items, &stat, &ac});
            continue;
        }
        return;
    }
}

fn checkTempFiles(args: anytype) !bool {
    // Extract and normalize extension for case-insensitive matching
    const filename: []const u8 = std.fs.path.basename(args[0]);

    // Extract extension and normalize to lowercase for case-insensitive matching
    const extension: []const u8 = std.fs.path.extension(args[0]);
    if (extension.len == 0) return false;

    // Bounds check before lowercasing
    if (extension.len > globals.buffer.len) return false;
    const lowercase: []const u8 = std.ascii.lowerString(globals.buffer[0..extension.len], extension);

    // Checks if the file extension is in the temporary extensions map
    if (TEMPORARY_EXTENSIONS.has(lowercase)) return core.messageSum(print.warning, args[1], args[2].size,
        i18n.TEMPORARY_FILES_WARNING, .{args[0]});

    // Checks if the full filename matches exactly
    if (FULL_NAME.has(filename)) return core.messageSum(print.warning, args[1], args[2].size,
        i18n.TEMPORARY_FILES_WARNING, .{args[0]});

    // Checks if filename matches start/end patterns
    for (START_END) |pattern| {
        if ((pattern.start.len > 0 and !std.mem.startsWith(u8, filename, pattern.start)) or
            (pattern.end.len   > 0 and !std.mem.endsWith(  u8, filename, pattern.end))) continue;

        return core.messageSum(print.warning, args[1], args[2].size,
            i18n.TEMPORARY_FILES_WARNING, .{args[0]});
    }

    // Checks if the path contains any of the known temporary patterns
    if (args[3].contains(args[0])) return core.messageSum(print.warning, args[1], args[2].size,
        i18n.TEMPORARY_FILES_WARNING, .{args[0]});

    return false;
}
