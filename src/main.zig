//! System entry point with configuration and module execution
//! Handles command-line arguments, configuration loading and directory validation
//!
//! Copyright © 2025-present Marcos Mazoti

const ahocorasick     = @import("ahocorasick");
const config          = @import("config");
const core            = @import("core");
const globals         = @import("globals");
const i18n            = @import("i18n");
const print           = @import("print");
const std             = @import("std");

const NoParameterFunc = *const fn () anyerror!void;

/// Changes terminal codepage on Windows
extern "kernel32" fn SetConsoleOutputCP(wCodePageID: std.os.windows.UINT) callconv(.winapi) std.os.windows.BOOL;

const COMPTIME_COMPRESSED_FILES = .{
    .{ "--compressed"    , &core.compressedFiles              },
    .{ "-c"              , &core.compressedFiles              },
    .{ "-C"              , &core.compressedFiles              },
    .{ "compressed"      , &core.compressedFiles              },
    .{ "/C"              , &core.compressedFiles              },
    .{ "COMPRESSED"      , &core.compressedFiles              },
};

const COMPTIME_CONFIDENTIAL_FILES = .{
    .{ "--conf"          , &core.confidentialFiles            },
    .{ "-cf"             , &core.confidentialFiles            },
    .{ "-CF"             , &core.confidentialFiles            },
    .{ "conf"            , &core.confidentialFiles            },
    .{ "/CF"             , &core.confidentialFiles            },
    .{ "CONF"            , &core.confidentialFiles            },
};

const COMPTIME_DEBUG_INFO = .{
    .{ "--debuginfo"     , &core.debugInfo                    },
    .{ "-di"             , &core.debugInfo                    },
    .{ "-DI"             , &core.debugInfo                    },
    .{ "debuginfo"       , &core.debugInfo                    },
    .{ "/DI"             , &core.debugInfo                    },
    .{ "DEBUGINFO"       , &core.debugInfo                    },
};

const COMPTIME_DIRECTORY_FILE_NAME_SIZE = .{
    .{ "--dirsize"       , &core.dirFileNameSize              },
    .{ "-ds"             , &core.dirFileNameSize              },
    .{ "-DS"             , &core.dirFileNameSize              },
    .{ "dirsize"         , &core.dirFileNameSize              },
    .{ "/DS"             , &core.dirFileNameSize              },
    .{ "DIRSIZE"         , &core.dirFileNameSize              },
};

const COMPTIME_DUPLICATE_CHARS_FILES = .{
    .{ "--dupchars"      , &core.duplicateChars               },
    .{ "-dc"             , &core.duplicateChars               },
    .{ "-DC"             , &core.duplicateChars               },
    .{ "dupchars"        , &core.duplicateChars               },
    .{ "/DC"             , &core.duplicateChars               },
    .{ "DUPCHARS"        , &core.duplicateChars               },
};

const COMPTIME_DUPLICATE_FILES_PARALLEL = .{
    .{ "--duplicate_mt"  , &core.duplicateFilesParallel       },
    .{ "-dmt"            , &core.duplicateFilesParallel       },
    .{ "-DMT"            , &core.duplicateFilesParallel       },
    .{ "duplicate_mt"    , &core.duplicateFilesParallel       },
    .{ "/DMT"            , &core.duplicateFilesParallel       },
    .{ "DUPLICATE_MT"    , &core.duplicateFilesParallel       },
};

const COMPTIME_DUPLICATE_FILES = .{
    .{ "--duplicate"     , &core.duplicateFiles               },
    .{ "-d"              , &core.duplicateFiles               },
    .{ "-D"              , &core.duplicateFiles               },
    .{ "duplicate"       , &core.duplicateFiles               },
    .{ "/D"              , &core.duplicateFiles               },
    .{ "DUPLICATE"       , &core.duplicateFiles               },
};

const COMPTIME_EMPTY_FILES = .{
    .{ "--empty"         , &core.emptyFiles                   },
    .{ "-ef"             , &core.emptyFiles                   },
    .{ "-EF"             , &core.emptyFiles                   },
    .{ "empty"           , &core.emptyFiles                   },
    .{ "/EF"             , &core.emptyFiles                   },
    .{ "EMPTY"           , &core.emptyFiles                   },
};

const COMPTIME_EMPTY_DIRECTORIES = .{
    .{ "--emptydirs"     , &core.emptyDirectories             },
    .{ "-e"              , &core.emptyDirectories             },
    .{ "-E"              , &core.emptyDirectories             },
    .{ "emptydirs"       , &core.emptyDirectories             },
    .{ "/E"              , &core.emptyDirectories             },
    .{ "EMPTYDIRS"       , &core.emptyDirectories             },
};

const COMPTIME_FILES_NEWER_ATIME = .{
    .{ "--fna"           , &core.filesNewerATime              },
    .{ "-fna"            , &core.filesNewerATime              },
    .{ "-FNA"            , &core.filesNewerATime              },
    .{ "fna"             , &core.filesNewerATime              },
    .{ "/FNA"            , &core.filesNewerATime              },
    .{ "FNA"             , &core.filesNewerATime              },
};

const COMPTIME_FILES_NEWER_CTIME = .{
    .{ "--fnc"           , &core.filesNewerCTime              },
    .{ "-fnc"            , &core.filesNewerCTime              },
    .{ "-FNC"            , &core.filesNewerCTime              },
    .{ "fnc"             , &core.filesNewerCTime              },
    .{ "/FNC"            , &core.filesNewerCTime              },
    .{ "FNC"             , &core.filesNewerCTime              },
};

const COMPTIME_FILES_NEWER_MTIME = .{
    .{ "--fnm"           , &core.filesNewerMTime              },
    .{ "-fnm"            , &core.filesNewerMTime              },
    .{ "-FNM"            , &core.filesNewerMTime              },
    .{ "fnm"             , &core.filesNewerMTime              },
    .{ "/FNM"            , &core.filesNewerMTime              },
    .{ "FNM"             , &core.filesNewerMTime              },
};

const COMPTIME_FILES_OLDER_ATIME = .{
    .{ "--foa"           , &core.filesOlderATime              },
    .{ "-foa"            , &core.filesOlderATime              },
    .{ "-FOA"            , &core.filesOlderATime              },
    .{ "foa"             , &core.filesOlderATime              },
    .{ "/FOA"            , &core.filesOlderATime              },
    .{ "FOA"             , &core.filesOlderATime              },
};

const COMPTIME_FILES_OLDER_CTIME = .{
    .{ "--foc"           , &core.filesOlderCTime              },
    .{ "-foc"            , &core.filesOlderCTime              },
    .{ "-FOC"            , &core.filesOlderCTime              },
    .{ "foc"             , &core.filesOlderCTime              },
    .{ "/FOC"            , &core.filesOlderCTime              },
    .{ "FOC"             , &core.filesOlderCTime              },
};

const COMPTIME_FILES_OLDER_MTIME = .{
    .{ "--fom"           , &core.filesOlderMTime              },
    .{ "-fom"            , &core.filesOlderMTime              },
    .{ "-FOM"            , &core.filesOlderMTime              },
    .{ "fom"             , &core.filesOlderMTime              },
    .{ "/FOM"            , &core.filesOlderMTime              },
    .{ "FOM"             , &core.filesOlderMTime              },
};

const COMPTIME_FULL_PATH_SIZE = .{
    .{ "--fullpathsize"  , &core.fullPathSize                 },
    .{ "-f"              , &core.fullPathSize                 },
    .{ "-F"              , &core.fullPathSize                 },
    .{ "fullpathsize"    , &core.fullPathSize                 },
    .{ "/F"              , &core.fullPathSize                 },
    .{ "FULLPATHSIZE"    , &core.fullPathSize                 },
};

const COMPTIME_INTEGRITY_FILES_PARALLEL = .{
    .{ "--integrity_mt"  , &core.integrityFilesParallel       },
    .{ "-imt"            , &core.integrityFilesParallel       },
    .{ "-IMT"            , &core.integrityFilesParallel       },
    .{ "integrity_mt"    , &core.integrityFilesParallel       },
    .{ "/IMT"            , &core.integrityFilesParallel       },
    .{ "INTEGRITY_MT"    , &core.integrityFilesParallel       },
};

const COMPTIME_INTEGRITY_FILES = .{
    .{ "--integrity"     , &core.integrityFiles               },
    .{ "-i"              , &core.integrityFiles               },
    .{ "-I"              , &core.integrityFiles               },
    .{ "integrity"       , &core.integrityFiles               },
    .{ "/I"              , &core.integrityFiles               },
    .{ "INTEGRITY"       , &core.integrityFiles               },
};

const COMPTIME_PARSE_JSON_FILES = .{
    .{ "--json"          , &core.checkJSON                    },
    .{ "-j"              , &core.checkJSON                    },
    .{ "-J"              , &core.checkJSON                    },
    .{ "json"            , &core.checkJSON                    },
    .{ "/J"              , &core.checkJSON                    },
    .{ "JSON"            , &core.checkJSON                    },
};

const COMPTIME_LARGE_FILES = .{
    .{ "--large"         , &core.largeFiles                   },
    .{ "-lf"             , &core.largeFiles                   },
    .{ "-LF"             , &core.largeFiles                   },
    .{ "large"           , &core.largeFiles                   },
    .{ "/LF"             , &core.largeFiles                   },
    .{ "LARGE"           , &core.largeFiles                   },
};

const COMPTIME_LAST_ACCESS_FILES = .{
    .{ "--last"          , &core.lastAccess                   },
    .{ "-l"              , &core.lastAccess                   },
    .{ "-L"              , &core.lastAccess                   },
    .{ "last"            , &core.lastAccess                   },
    .{ "/L"              , &core.lastAccess                   },
    .{ "LAST"            , &core.lastAccess                   },
};

const COMPTIME_LEGACY_FILES = .{
    .{ "--legacy"        , &core.legacyFiles                  },
    .{ "-legacy"         , &core.legacyFiles                  },
    .{ "/LEGACY"         , &core.legacyFiles                  },
    .{ "legacy"          , &core.legacyFiles                  },
    .{ "LEGACY"          , &core.legacyFiles                  },
};

const COMPTIME_LINKS_SHORTCUTS = .{
    .{ "--links"         , &core.linksShortcuts               },
    .{ "-ls"             , &core.linksShortcuts               },
    .{ "-LS"             , &core.linksShortcuts               },
    .{ "links"           , &core.linksShortcuts               },
    .{ "/LS"             , &core.linksShortcuts               },
    .{ "LINKS"           , &core.linksShortcuts               },
};

const COMPTIME_MAGIC_NUMBERS = .{
    .{ "--magic"         , &core.magicNumbers                 },
    .{ "-m"              , &core.magicNumbers                 },
    .{ "-M"              , &core.magicNumbers                 },
    .{ "magic"           , &core.magicNumbers                 },
    .{ "/M"              , &core.magicNumbers                 },
    .{ "MAGIC"           , &core.magicNumbers                 },
};

const COMPTIME_MANY_ITEMS_DIRECTORY = .{
    .{ "--manyitems"     , &core.manyItemsDirectories         },
    .{ "-mi"             , &core.manyItemsDirectories         },
    .{ "-MI"             , &core.manyItemsDirectories         },
    .{ "manyitems"       , &core.manyItemsDirectories         },
    .{ "/MI"             , &core.manyItemsDirectories         },
    .{ "MANYITEMS"       , &core.manyItemsDirectories         },
};

const COMPTIME_NO_EXTENSION = .{
    .{ "--noext"         , &core.noExtension                  },
    .{ "-n"              , &core.noExtension                  },
    .{ "-N"              , &core.noExtension                  },
    .{ "noext"           , &core.noExtension                  },
    .{ "/N"              , &core.noExtension                  },
    .{ "NOEXT"           , &core.noExtension                  },
};

const COMPTIME_ONE_ITEM_DIRECTORY = .{
    .{ "--oneitem"       , &core.oneItemDirectories           },
    .{ "-o"              , &core.oneItemDirectories           },
    .{ "-O"              , &core.oneItemDirectories           },
    .{ "oneitem"         , &core.oneItemDirectories           },
    .{ "/O"              , &core.oneItemDirectories           },
    .{ "ONEITEM"         , &core.oneItemDirectories           },
};

const COMPTIME_TEMPORARY_FILES = .{
    .{ "--temp"          , &core.temporaryFiles               },
    .{ "-tf"             , &core.temporaryFiles               },
    .{ "-TF"             , &core.temporaryFiles               },
    .{ "temp"            , &core.temporaryFiles               },
    .{ "/TF"             , &core.temporaryFiles               },
    .{ "TEMP"            , &core.temporaryFiles               },
};

const COMPTIME_UNPORTABLE_CHARS = .{
    .{ "--uchars"        , &core.unportableChars              },
    .{ "-u"              , &core.unportableChars              },
    .{ "-U"              , &core.unportableChars              },
    .{ "uchars"          , &core.unportableChars              },
    .{ "/U"              , &core.unportableChars              },
    .{ "UCHARS"          , &core.unportableChars              },
};

const COMPTIME_WRONG_DATES = .{
    .{ "--wrong"         , &core.wrongDates                   },
    .{ "-w"              , &core.wrongDates                   },
    .{ "-W"              , &core.wrongDates                   },
    .{ "wrong"           , &core.wrongDates                   },
    .{ "/W"              , &core.wrongDates                   },
    .{ "WRONG"           , &core.wrongDates                   },
};


const COMPTIME_DUPLICATE_FILES_REMOVE = .{
    .{ "--duplicate_rm"  , &core.duplicateRemoveFiles         },
    .{ "-drm"            , &core.duplicateRemoveFiles         },
    .{ "-DRM"            , &core.duplicateRemoveFiles         },
    .{ "duplicate_rm"    , &core.duplicateRemoveFiles         },
    .{ "/DRM"            , &core.duplicateRemoveFiles         },
    .{ "DUPLICATE_RM"    , &core.duplicateRemoveFiles         },
};

const COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE = .{
    .{ "--duplicate_rmp" , &core.duplicateRemoveFilesParallel },
    .{ "-drmp"           , &core.duplicateRemoveFilesParallel },
    .{ "-DRMP"           , &core.duplicateRemoveFilesParallel },
    .{ "duplicate_rmp"   , &core.duplicateRemoveFilesParallel },
    .{ "/DRMP"           , &core.duplicateRemoveFilesParallel },
    .{ "DUPLICATE_RMP"   , &core.duplicateRemoveFilesParallel },
};

const COMPTIME_EMPTY_FILES_REMOVE = .{
    .{ "--empty_rm"      , &core.emptyRemoveFiles             },
    .{ "-efrm"           , &core.emptyRemoveFiles             },
    .{ "-EFRM"           , &core.emptyRemoveFiles             },
    .{ "empty_rm"        , &core.emptyRemoveFiles             },
    .{ "/EFRM"           , &core.emptyRemoveFiles             },
    .{ "EMPTY_RM"        , &core.emptyRemoveFiles             },
};

const COMPTIME_EMPTY_DIRECTORIES_REMOVE = .{
    .{ "--emptydirs_rm"  , &core.emptyRemoveDirectories       },
    .{ "-erm"            , &core.emptyRemoveDirectories       },
    .{ "-ERM"            , &core.emptyRemoveDirectories       },
    .{ "emptydirs_rm"    , &core.emptyRemoveDirectories       },
    .{ "/ERM"            , &core.emptyRemoveDirectories       },
    .{ "EMPTYDIRS_RM"    , &core.emptyRemoveDirectories       },
};

const COMPTIME_LINKS_SHORTCUTS_REMOVE = .{
    .{ "--links_rm"      , &core.linksRemoveShortcuts         },
    .{ "-lsrm"           , &core.linksRemoveShortcuts         },
    .{ "-LSRM"           , &core.linksRemoveShortcuts         },
    .{ "links_rm"        , &core.linksRemoveShortcuts         },
    .{ "/LSRM"           , &core.linksRemoveShortcuts         },
    .{ "LINKS_RM"        , &core.linksRemoveShortcuts         },
};

const COMPTIME_TEMPORARY_FILES_REMOVE = .{
    .{ "--temp_rm"       , &core.temporaryRemoveFiles         },
    .{ "-tfrm"           , &core.temporaryRemoveFiles         },
    .{ "-TFRM"           , &core.temporaryRemoveFiles         },
    .{ "temp_rm"         , &core.temporaryRemoveFiles         },
    .{ "/TFRM"           , &core.temporaryRemoveFiles         },
    .{ "TEMP_RM"         , &core.temporaryRemoveFiles         },
};

const help_version_map = std.StaticStringMap(NoParameterFunc).initComptime(.{
    .{ "--config"        , &createConfig                      },
    .{ "--configure"     , &createConfig                      },
    .{ "config"          , &createConfig                      },
    .{ "configure"       , &createConfig                      },

    .{ "--help"          , &printHelp                         },
    .{ "-?"              , &printHelp                         },
    .{ "-h"              , &printHelp                         },
    .{ "-H"              , &printHelp                         },
    .{ "/?"              , &printHelp                         },
    .{ "/h"              , &printHelp                         },
    .{ "help"            , &printHelp                         },
    .{ "HELP"            , &printHelp                         },

    .{ "--version"       , &printVersion                      },
    .{ "-v"              , &printVersion                      },
    .{ "-V"              , &printVersion                      },
    .{ "/V"              , &printVersion                      },
    .{ "version"         , &printVersion                      },
    .{ "VERSION"         , &printVersion                      },
});

/// Map of command-line flags to their corresponding handler functions
/// Supports various help and version flag formats (Unix, Windows, case variations)
const command_map = std.StaticStringMap(NoParameterFunc).initComptime(
    (if (config.COMPTIME_COMPRESSED_FILES               ) COMPTIME_COMPRESSED_FILES                else .{}) ++
    (if (config.COMPTIME_CONFIDENTIAL_FILES             ) COMPTIME_CONFIDENTIAL_FILES              else .{}) ++
    (if (config.COMPTIME_DEBUG_INFO                     ) COMPTIME_DEBUG_INFO                      else .{}) ++
    (if (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE       ) COMPTIME_DIRECTORY_FILE_NAME_SIZE        else .{}) ++
    (if (config.COMPTIME_DUPLICATE_CHARS_FILES          ) COMPTIME_DUPLICATE_CHARS_FILES           else .{}) ++
    (if (config.COMPTIME_DUPLICATE_FILES_PARALLEL       ) COMPTIME_DUPLICATE_FILES_PARALLEL        else .{}) ++
    (if (config.COMPTIME_DUPLICATE_FILES                ) COMPTIME_DUPLICATE_FILES                 else .{}) ++
    (if (config.COMPTIME_EMPTY_FILES                    ) COMPTIME_EMPTY_FILES                     else .{}) ++
    (if (config.COMPTIME_EMPTY_DIRECTORIES              ) COMPTIME_EMPTY_DIRECTORIES               else .{}) ++
    (if (config.COMPTIME_FILES_NEWER_ATIME              ) COMPTIME_FILES_NEWER_ATIME               else .{}) ++
    (if (config.COMPTIME_FILES_NEWER_CTIME              ) COMPTIME_FILES_NEWER_CTIME               else .{}) ++
    (if (config.COMPTIME_FILES_NEWER_MTIME              ) COMPTIME_FILES_NEWER_MTIME               else .{}) ++
    (if (config.COMPTIME_FILES_OLDER_ATIME              ) COMPTIME_FILES_OLDER_ATIME               else .{}) ++
    (if (config.COMPTIME_FILES_OLDER_CTIME              ) COMPTIME_FILES_OLDER_CTIME               else .{}) ++
    (if (config.COMPTIME_FILES_OLDER_MTIME              ) COMPTIME_FILES_OLDER_MTIME               else .{}) ++
    (if (config.COMPTIME_FULL_PATH_SIZE                 ) COMPTIME_FULL_PATH_SIZE                  else .{}) ++
    (if (config.COMPTIME_INTEGRITY_FILES_PARALLEL       ) COMPTIME_INTEGRITY_FILES_PARALLEL        else .{}) ++
    (if (config.COMPTIME_INTEGRITY_FILES                ) COMPTIME_INTEGRITY_FILES                 else .{}) ++
    (if (config.COMPTIME_PARSE_JSON_FILES               ) COMPTIME_PARSE_JSON_FILES                else .{}) ++
    (if (config.COMPTIME_LARGE_FILES                    ) COMPTIME_LARGE_FILES                     else .{}) ++
    (if (config.COMPTIME_LAST_ACCESS_FILES              ) COMPTIME_LAST_ACCESS_FILES               else .{}) ++
    (if (config.COMPTIME_LEGACY_FILES                   ) COMPTIME_LEGACY_FILES                    else .{}) ++
    (if (config.COMPTIME_LINKS_SHORTCUTS                ) COMPTIME_LINKS_SHORTCUTS                 else .{}) ++
    (if (config.COMPTIME_MAGIC_NUMBERS                  ) COMPTIME_MAGIC_NUMBERS                   else .{}) ++
    (if (config.COMPTIME_MANY_ITEMS_DIRECTORY           ) COMPTIME_MANY_ITEMS_DIRECTORY            else .{}) ++
    (if (config.COMPTIME_NO_EXTENSION                   ) COMPTIME_NO_EXTENSION                    else .{}) ++
    (if (config.COMPTIME_ONE_ITEM_DIRECTORY             ) COMPTIME_ONE_ITEM_DIRECTORY              else .{}) ++
    (if (config.COMPTIME_TEMPORARY_FILES                ) COMPTIME_TEMPORARY_FILES                 else .{}) ++
    (if (config.COMPTIME_UNPORTABLE_CHARS               ) COMPTIME_UNPORTABLE_CHARS                else .{}) ++
    (if (config.COMPTIME_WRONG_DATES                    ) COMPTIME_WRONG_DATES                     else .{}) ++

    (if (config.COMPTIME_DUPLICATE_FILES_REMOVE         ) COMPTIME_DUPLICATE_FILES_REMOVE          else .{}) ++
    (if (config.COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE) COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE else .{}) ++
    (if (config.COMPTIME_EMPTY_FILES_REMOVE             ) COMPTIME_EMPTY_FILES_REMOVE              else .{}) ++
    (if (config.COMPTIME_EMPTY_DIRECTORIES_REMOVE       ) COMPTIME_EMPTY_DIRECTORIES_REMOVE        else .{}) ++
    (if (config.COMPTIME_LINKS_SHORTCUTS_REMOVE         ) COMPTIME_LINKS_SHORTCUTS_REMOVE          else .{}) ++
    (if (config.COMPTIME_TEMPORARY_FILES_REMOVE         ) COMPTIME_TEMPORARY_FILES_REMOVE          else .{}),
);

/// Creates a config.json with default values in the same directory of the system
fn createConfig() !void {
    try print.stdout(i18n.CONFIG_MESSAGE_CREATE);

    _ = std.Io.Dir.cwd().statFile(globals.io, "config.json", .{}) catch |err| {
        globals.exit_code = 1;
        if (err == error.FileNotFound) {
            const config_file: std.Io.File = try std.Io.Dir.cwd().createFile(globals.io, "config.json", .{});
            defer config_file.close(globals.io);

            var file_writer: std.Io.File.Writer = config_file.writer(globals.io, &globals.io_buffer);
            try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG);
            try file_writer.interface.flush();

            try print.alignedOk(i18n.CONFIG_MESSAGE_CREATE);
            return print.stdout("\n");
        }

        return err;
    };

    globals.exit_code = 1;
    return print.stderr(i18n.ERROR_CONFIG_FILE);
}

/// Common main for all operating systems
fn commonMain(init: std.process.Init) !void {
    // Accessing command line arguments (arena required):
    var check_directory: []u8 = undefined;

    const arena: std.mem.Allocator = init.arena.allocator();
    globals.alloc = &arena;

    const total_memory: u64 = try std.process.totalSystemMemory();
    const half_memory:  u64 = total_memory / 2;

    globals.memory_limit = @intCast(@min(half_memory, std.math.maxInt(usize)));

    globals.io = init.io;

    globals.file_writer_stdout = .init(.stdout(), globals.io, &globals.io_buffer);
    globals.file_writer_stderr = .init(.stderr(), globals.io, &globals.io_buffer);

    globals.file_writer_stdout_interface = globals.file_writer_stdout.interface;
    globals.file_writer_stderr_interface = globals.file_writer_stderr.interface;

    globals.file_stats = globals.FileStatMap.init(globals.alloc.*);
    globals.dir_count  = std.StringHashMap(usize).init(globals.alloc.*);

    globals.ignore_path_patterns = try ahocorasick.AhoCorasick.initEmpty(globals.alloc.*);

    defer {
        globals.ignore_path_patterns.deinit();

        var iterator: std.hash_map.HashMapUnmanaged([]const u8, usize, std.hash_map.StringContext, 80).Iterator = globals.dir_count.iterator();
        while (iterator.next()) |entry| { globals.alloc.*.free(entry.key_ptr.*); }
        globals.dir_count.deinit();

        var iterator2: std.hash_map.HashMapUnmanaged([]const u8, std.Io.File.Stat, std.hash_map.StringContext, 80).Iterator = globals.file_stats.iterator();
        while (iterator2.next()) |entry| { globals.alloc.*.free(entry.key_ptr.*); }
        globals.file_stats.deinit();
    }

    // Prints banner before any processing to provide immediate feedback in slow operations
    try print.stdout(if (config.COMPTIME_EMOJI_COLOR) try std.fmt.bufPrint(&globals.max_path_buffer, "\n🔬\x1b[38;5;255m {s}\x1b[0m\n\n\n", .{i18n.HEADER})
        else try std.fmt.bufPrint(&globals.max_path_buffer, "\n{s}\n\n\n", .{i18n.HEADER}));

    const args: []const [:0]const u8 = try init.minimal.args.toSlice(arena);

    if (args.len == 1) {
        _ = std.Io.Dir.cwd().statFile(globals.io, "config.json", .{}) catch |err| {
            if (err == error.FileNotFound) return printHelp();

            globals.exit_code = 1;
            return err;
        };
    }

    if (args.len == 2) {
        if (help_version_map.get(args[1])) |func| { return func(); }
    }

    // Loads configurations from config.json or uses default values
    const config_message: []const u8 = if (loadLocal(&globals.config_file, &globals.config_parsed, &globals.io, globals.alloc)) i18n.CONFIG_MESSAGE else i18n.CONFIG_MESSAGE_DEFAULT;
    defer config.deinit(&globals.config_file, &globals.config_parsed, globals.alloc);

    try print.alignedOk(config_message);

    // CPU count detection for optimal parallelism
    if (globals.config_parsed.value.MAX_JOBS == 0) {
        const cpu_count: usize = std.Thread.getCpuCount() catch 1;
        globals.config_parsed.value.MAX_JOBS = @max(1, cpu_count);
    }

    if (args.len > 1) {
        check_directory = try globals.alloc.*.dupe(u8, args[args.len - 1]);
    } else {
        if (globals.config_parsed.value.INPUT_FOLDER.len == 1) {
            check_directory = try std.process.currentPathAlloc(globals.io, globals.alloc.*);
        } else {
            if (globals.config_parsed.value.INPUT_FOLDER.len == 0) {
                try print.stderr("\n");
                try print.warning("{s}", .{i18n.CONFIG_MESSAGE_WARNING});
                globals.exit_code = 1;
                check_directory = try std.process.currentPathAlloc(globals.io, globals.alloc.*);
            } else {
                check_directory = try globals.alloc.*.dupe(u8, globals.config_parsed.value.INPUT_FOLDER);
            }
        }
    }

    defer globals.alloc.*.free(check_directory);

    // Ensures path separator at end
    if (check_directory[check_directory.len - 1] == '"') check_directory[check_directory.len - 1] = std.fs.path.sep;

    globals.buffer = try globals.alloc.*.alloc(u8, globals.config_parsed.value.BUFFER_SIZE);
    defer globals.alloc.*.free(globals.buffer);

    // Prevents bugs with odd sizes of buffer
    globals.buffer_size  = globals.config_parsed.value.BUFFER_SIZE / 2;
    globals.buffer_total = globals.buffer_size * 2;

    // Checks input directory
    globals.input_directory = if (std.fs.path.isAbsolute(check_directory))
        std.Io.Dir.openDirAbsolute(globals.io, check_directory, .{ .iterate = true }) catch {
            globals.exit_code = 1;
            return print.errorDirectory(check_directory);
        }
    else
        // Relative paths
        std.Io.Dir.cwd().openDir(globals.io, check_directory, .{ .iterate = true }) catch {
            globals.exit_code = 1;
            return print.errorDirectory(check_directory);
        };

    defer globals.input_directory.close(globals.io);

    // Get absolute path of input directory directory
    globals.absolute_input_path = try globals.input_directory.realPathFileAlloc(globals.io, ".", arena);

    // TODO: remove in future versions (temporary file for stat)
    const file: std.Io.File = try std.Io.Dir.cwd().createFile(globals.io, "datachecker_empty", .{});
    file.close(globals.io);
    globals.now_stat = try std.Io.Dir.cwd().statFile(globals.io, "datachecker_empty", .{});
    std.Io.Dir.cwd().deleteFile(globals.io, "datachecker_empty") catch {};

    globals.semaphore = std.Io.Semaphore{ .permits = globals.config_parsed.value.MAX_JOBS };

    // Initialize and add patterns to trie to ignore paths
    if(config.COMPTIME_IGNORE_PATH_PATTERNS) {
        if(globals.config_parsed.value.IGNORE_PATH_PATTERNS) {
            for (globals.config_parsed.value.IGNORE_PATTERNS) |pattern| { try globals.ignore_path_patterns.add(pattern); }
            try globals.ignore_path_patterns.configure();
        }
    }

    if (args.len > 2) {
        if (command_map.get(args[1])) |func| {
            globals.config_parsed.value.ENABLE_CACHE = false;
            try func();
        } else {
            try print.stderr("\n");
            try print.err(i18n.ERROR_COMMAND_NOT_FOUND, .{args[1]});
            globals.exit_code = 1;
        }
    } else {
        // Runs all enabled check modules
        try core.run();
    }

    if (!globals.config_parsed.value.ENTER_TO_QUIT) return print.stdout("\n\n");

    // Waits for user input before exiting
    try print.stdout(i18n.QUIT_MESSAGE);
    var file_reader: std.Io.File.Reader = std.Io.File.stdin().reader(globals.io, globals.buffer);
    _ = try file_reader.interface.take(1);
}

/// Attempts to load configuration from a local "config.json" file in the current working directory
pub fn loadLocal(config_file: *[]const u8, config_parsed: *std.json.Parsed(config.Config), io: *std.Io, alloc: *const std.mem.Allocator) bool {
    config_file.* = std.Io.Dir.cwd().readFileAlloc(io.*, "config.json", alloc.*, std.Io.Limit.limited(config.COMPTIME_IO_BUFFER_SIZE)) catch |err| blk: {
        core.debugPrintError(err);
        break :blk "";
    };

    // Parses JSON with enum support, on error sets default values
    var result: bool = (config_file.*.len > 0);
    const data: []const u8 = if (result) config_file.* else config.DEFAULT_JSON_CONFIG;

    config_parsed.* = parseJSON(data, alloc, config_file, &result) catch {
        std.debug.panic("\n\n\nPANIC: DEFAULT_JSON_CONFIG IS INVALID AND THIS SHOULD NEVER HAPPEN\n\n\n", .{});
    };

    return result;
}

pub fn main(init: std.process.Init) !void {
    if (@import("builtin").os.tag == .windows) {
        if (!SetConsoleOutputCP(65001).toBool()) return error.SetConsoleOutputCPFailed;
    }

    try commonMain(init);
    std.process.exit(globals.exit_code);
}

fn parseJSON(data: []const u8, alloc: *const std.mem.Allocator, config_file: *[]const u8, result: *bool) !std.json.Parsed(config.Config) {
    return std.json.parseFromSlice(config.Config, alloc.*, data, .{}) catch |err| {
        // Invalid config.json
        result.* = false;
        alloc.*.free(config_file.*);
        config_file.* = "";

        core.debugPrintError(err);
        try print.stderr(i18n.ERROR_CONFIG_FILE_PARSE);
        globals.exit_code = 1;

        return std.json.parseFromSlice(config.Config, alloc.*, config.DEFAULT_JSON_CONFIG, .{});
    };
}

/// Prints help and exits
fn printHelp() !void { try print.stdout(config.HELP); }

/// Do nothing: version already is on system header
fn printVersion() !void {}

test "No config file" {
    var gpa: std.heap.DebugAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = &gpa.allocator();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io = tmp.io();

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer config.deinit(&config_file, &config_parsed, alloc);

    try std.testing.expect(!result);
}

test "Valid config file" {
    var gpa: std.heap.DebugAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = &gpa.allocator();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io = tmp.io();
    var io_buffer: [65536]u8 = undefined;

    const file: std.Io.File = try std.Io.Dir.cwd().createFile(io, "config.json", .{});
    defer {
        file.close(io);
        std.Io.Dir.cwd().deleteFile(io, "config.json") catch {};
    }

    var file_writer: std.Io.File.Writer = file.writer(io, &io_buffer);
    try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG);
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer config.deinit(&config_file, &config_parsed, alloc);

    try std.testing.expect(result);
}

test "Invalid config file" {
    var gpa: std.heap.DebugAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = &gpa.allocator();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io = tmp.io();
    var io_buffer: [65536]u8 = undefined;

    const file: std.Io.File = try std.Io.Dir.cwd().createFile(io, "config.json", .{});
    defer {
        file.close(io);
        std.Io.Dir.cwd().deleteFile(io, "config.json") catch {};
    }

    var file_writer: std.Io.File.Writer = file.writer(io, &io_buffer);
    try file_writer.interface.writeAll(config.DEFAULT_JSON_CONFIG[1..]);
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(config.Config) = undefined;
    var config_file: []const u8 = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer config.deinit(&config_file, &config_parsed, alloc);

    try std.testing.expect(result);
}
