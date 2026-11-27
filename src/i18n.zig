//! UTF-8 strings for English language
//!
//! Strings a build does not need are compiled out. Three helpers decide that at compile time:
//!
//!   console(text)       kept only when console output is built in (COMPTIME_STDOUT)
//!   report(check, text) also kept when the check that uses it is built in, because its
//!                       results may be reported without a console (e.g. as JSON)
//!   header(text)        console(text), plus a build error if it is wider than ALIGNED_SPACES
//!
//! Format strings take {s} for a path or name, {d} for a number and {} for an error value.
//!
//! Copyright © 2025-present Marcos Mazoti

const config = @import("config");
const std    = @import("std");

/// One command: its aliases are derived as `--long, -short, long, /short`, so they cannot drift apart
const Command = struct {
    on:    bool, // built in? (config.COMPTIME_*)
    long:  []const u8,
    short: []const u8,
    info:  []const u8,
    cfg:   []const u8 = "", // what config.json can customize, if anything
};

// A message stays available when any command that can print it is built in; the
// multithreaded (_mt) and removal (_rm) variants count as their base command.
const empty_on:     bool = config.COMPTIME_EMPTY_FILES     or config.COMPTIME_EMPTY_DIRECTORIES or config.COMPTIME_EMPTY_FILES_REMOVE or config.COMPTIME_EMPTY_DIRECTORIES_REMOVE;
const integrity_on: bool = config.COMPTIME_INTEGRITY_FILES or config.COMPTIME_INTEGRITY_FILES_PARALLEL;
const links_on:     bool = config.COMPTIME_LINKS_SHORTCUTS or config.COMPTIME_LINKS_SHORTCUTS_REMOVE;
const temp_on:      bool = config.COMPTIME_TEMPORARY_FILES or config.COMPTIME_TEMPORARY_FILES_REMOVE;

/// Spacing constant for alignment - matches the largest header string size in output
pub const ALIGNED_SPACES: u32 = 52;

pub const HEADER_START = if (config.COMPTIME_STDOUT) "DataChecker v"                                            else "";
pub const HEADER_END   = if (config.COMPTIME_STDOUT) " by Marcos Mazoti - https://mazoti.github.io/datachecker" else "";

pub const USAGE = if (config.COMPTIME_STDOUT)
    \\Usage:
    \\
    \\    datachecker <folder>
    \\              or
    \\    datachecker <command> <folder>
    \\              or
    \\    datachecker config
    \\        Create a config.json file with the default configuration
    \\
    \\Commands/Aliases:
    \\
    \\
    else "";

// The order of this table is the order of the help text.
const commands = [_]Command {
    .{ .on = config.COMPTIME_COMPRESSED_FILES,                .long = "compressed",             .short = "c",    .info = "Search for optimization opportunities in lossless compressed files"                          },
    .{ .on = config.COMPTIME_CONFIDENTIAL_FILES,              .long = "confidential",           .short = "conf", .info = "Search for confidential data in files",                       .cfg = "search patterns"       },
    .{ .on = config.COMPTIME_DEBUG_INFO,                      .long = "debuginfo",              .short = "di",   .info = "Search for binary files with debug information"                                              },
    .{ .on = config.COMPTIME_DIRECTORY_FILE_NAME_SIZE,        .long = "dirsize",                .short = "ds",   .info = "Search for directories or files with excessively long names", .cfg = "length threshold"      },
    .{ .on = config.COMPTIME_DUPLICATE_CHARS_FILES,           .long = "dupchars",               .short = "dc",   .info = "Search for duplicate characters in file names"                                               },
    .{ .on = config.COMPTIME_DUPLICATE_FILES_PARALLEL,        .long = "duplicate_mt",           .short = "dmt",  .info = "Search for duplicate files using multithreading"                                             },
    .{ .on = config.COMPTIME_DUPLICATE_FILES_REMOVE,          .long = "duplicate_rm",           .short = "drm",  .info = "Remove duplicate files"                                                                      },
    .{ .on = config.COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE, .long = "duplicate_rmt",          .short = "drmt", .info = "Remove duplicate files using multithreading"                                                 },
    .{ .on = config.COMPTIME_DUPLICATE_FILES,                 .long = "duplicate",              .short = "d",    .info = "Search for duplicate files"                                                                  },
    .{ .on = config.COMPTIME_EMPTY_FILES_REMOVE,              .long = "empty_rm",               .short = "efrm", .info = "Remove empty files"                                                                          },
    .{ .on = config.COMPTIME_EMPTY_FILES,                     .long = "empty_files",            .short = "ef",   .info = "Search for empty files"                                                                      },
    .{ .on = config.COMPTIME_EMPTY_DIRECTORIES_REMOVE,        .long = "empty_dirs_rm",          .short = "edrm", .info = "Remove empty directories"                                                                    },
    .{ .on = config.COMPTIME_EMPTY_DIRECTORIES,               .long = "empty_dirs",             .short = "ed",   .info = "Search for empty directories"                                                                },
    .{ .on = config.COMPTIME_END_OF_LINE,                     .long = "end_of_line",            .short = "eol",  .info = "Search for wrong line terminator in text files",              .cfg = "terminator"            },
    .{ .on = config.COMPTIME_FILES_NEWER_ATIME,               .long = "files_newer_atime",      .short = "fna",  .info = "Search for files with newer access time",                     .cfg = "time"                  },
    .{ .on = config.COMPTIME_FILES_NEWER_CTIME,               .long = "files_newer_ctime",      .short = "fnc",  .info = "Search for files with newer change time",                     .cfg = "time"                  },
    .{ .on = config.COMPTIME_FILES_NEWER_MTIME,               .long = "files_newer_mtime",      .short = "fnm",  .info = "Search for files with newer modified time",                   .cfg = "time"                  },
    .{ .on = config.COMPTIME_FILES_OLDER_ATIME,               .long = "files_older_atime",      .short = "foa",  .info = "Search for files with older access time",                     .cfg = "time"                  },
    .{ .on = config.COMPTIME_FILES_OLDER_CTIME,               .long = "files_older_ctime",      .short = "foc",  .info = "Search for files with older change time",                     .cfg = "time"                  },
    .{ .on = config.COMPTIME_FILES_OLDER_MTIME,               .long = "files_older_mtime",      .short = "fom",  .info = "Search for files with older modified time",                   .cfg = "time"                  },
    .{ .on = config.COMPTIME_FULL_PATH_SIZE,                  .long = "full_path_size",         .short = "fps",  .info = "Search for excessively long absolute paths",                  .cfg = "path length threshold" },
    .{ .on = config.COMPTIME_INTEGRITY_FILES_PARALLEL,        .long = "integrity_mt",           .short = "imt",  .info = "Create/verify file hashes using multithreading"                                              },
    .{ .on = config.COMPTIME_INTEGRITY_FILES,                 .long = "integrity",              .short = "i",    .info = "Create/verify file hashes"                                                                   },
    .{ .on = config.COMPTIME_LARGE_FILES,                     .long = "large_files",            .short = "lf",   .info = "Search for large files",                                      .cfg = "size threshold"        },
    .{ .on = config.COMPTIME_LAST_ACCESS_FILES,               .long = "last_access",            .short = "la",   .info = "Search for files not accessed recently",                      .cfg = "time period"           },
    .{ .on = config.COMPTIME_LEGACY_FILES,                    .long = "legacy_files",           .short = "lef",  .info = "Search for files using outdated formats"                                                     },
    .{ .on = config.COMPTIME_LINKS_SHORTCUTS_REMOVE,          .long = "links_rm",               .short = "lrm",  .info = "Remove links and shortcuts"                                                                  },
    .{ .on = config.COMPTIME_LINKS_SHORTCUTS,                 .long = "links",                  .short = "l",    .info = "Search for links and shortcuts"                                                              },
    .{ .on = config.COMPTIME_MAGIC_NUMBERS,                   .long = "magic_numbers",          .short = "mn",   .info = "Search for files with mismatched magic numbers"                                              },
    .{ .on = config.COMPTIME_MANY_ITEMS_DIRECTORIES,          .long = "many_items",             .short = "mi",   .info = "Search for directories with an excessive number of items",    .cfg = "item threshold"        },
    .{ .on = config.COMPTIME_NO_EXTENSION,                    .long = "no_extension",           .short = "ne",   .info = "Search for files without extensions and attempt to identify them"                            },
    .{ .on = config.COMPTIME_NONPORTABLE_CHARS,               .long = "nonportable_chars",      .short = "nc",   .info = "Search for non-portable characters in absolute paths"                                        },
    .{ .on = config.COMPTIME_ONE_ITEM_DIRECTORIES,            .long = "one_item_dir",           .short = "oid",  .info = "Search for directories containing only one item"                                             },
    .{ .on = config.COMPTIME_OWNERSHIPS_PERMISSIONS,          .long = "ownerships_permissions", .short = "op",   .info = "Search for invalid user, group or overly permissive items (e.g., 777)"                       },
    .{ .on = config.COMPTIME_PARSE_FILES,                     .long = "parse_files",            .short = "pf",   .info = "Parse files looking for errors"                                                              },
    .{ .on = config.COMPTIME_TEMPORARY_FILES_REMOVE,          .long = "temp_rm",                .short = "trm",  .info = "Remove temporary files"                                                                      },
    .{ .on = config.COMPTIME_TEMPORARY_FILES,                 .long = "temp_files",             .short = "tf",   .info = "Search for temporary files"                                                                  },
    .{ .on = config.COMPTIME_UTF8_ENCODING,                   .long = "utf8",                   .short = "u",    .info = "Search for non-UTF8 encoded text files"                                                      },
    .{ .on = config.COMPTIME_WRONG_DATES,                     .long = "wrong_dates",            .short = "wd",   .info = "Search for files with timestamps in the future"                                              },
};

comptime {
    // No two commands may share a name or an alias
    @setEvalBranchQuota(100_000);
    for (commands, 0..) |a, i| {
        for (commands[i + 1 ..]) |b| {
            if (std.mem.eql(u8, a.long, b.long))   @compileError("duplicate command: --" ++ a.long);
            if (std.mem.eql(u8, a.short, b.short)) @compileError("duplicate alias: -"    ++ a.short);
        }
    }
}

/// Usage followed by one entry for every command that is built in.
pub const HELP = blk: {
    if (!config.COMPTIME_STDOUT) break :blk "";
    var text: []const u8 = USAGE;
    for (commands) |c| { if (c.on) text = text ++ helpEntry(c); }
    break :blk text;
};

pub const CONFIG_MESSAGE_CREATE              = console("Creating config.json...");

// Summary messages
pub const BYTES_TOTAL                        = console("byte");
pub const BYTES_TOTALS                       = console("bytes");

pub const DIRECTORIES_TOTAL                  = console("directory");
pub const DIRECTORIES_TOTALS                 = console("directories");

pub const FILES_TOTAL                        = console("file");
pub const FILES_TOTALS                       = console("files");

pub const DIR_FILE_NAME_SIZE_TOTAL           = console("file or directory");
pub const DIR_FILE_NAME_SIZE_TOTALS          = console("files or directories");

pub const DUPLICATE_CHARS_FILES_TOTAL        = console("item with duplicate characters");
pub const DUPLICATE_CHARS_FILES_TOTALS       = console("items with duplicate characters");

pub const LINKS_SHORTCUTS_TOTAL              = console("link/shortcut");
pub const LINKS_SHORTCUTS_TOTALS             = console("links/shortcuts");

pub const FULL_PATH_SIZE_TOTAL               = console("path found");
pub const FULL_PATH_SIZE_TOTALS              = console("paths found");

pub const INTEGRITY_FILES_TOTAL              = console("hash processed");
pub const INTEGRITY_FILES_TOTALS             = console("hashes processed");

pub const NONPORTABLE_CHARS_TOTAL            = console("item with non-portable characters");
pub const NONPORTABLE_CHARS_TOTALS           = console("items with non-portable characters");

pub const PARSE_FILES_TOTAL                  = console("error found");
pub const PARSE_FILES_TOTALS                 = console("errors found");

// Header messages
pub const CONFIG_MESSAGE_HEADER              = header("Loading config.json...");
pub const CONFIG_MESSAGE_HEADER_DEFAULT      = header("Loading default configuration...");
pub const COMPRESSED_FILES_HEADER            = header("Looking for compressed files...");
pub const CONFIDENTIAL_FILES_HEADER          = header("Looking for confidential files...");
pub const DEBUG_INFO_HEADER                  = header("Looking for debug info in binary files...");
pub const DIR_FILE_NAME_SIZE_HEADER          = header("Looking for long names...");
pub const DUPLICATE_CHARS_FILES_HEADER       = header("Looking for duplicate characters...");
pub const DUPLICATE_FILES_HEADER             = header("Looking for duplicate files...");
pub const FILES_NEWER_ATIME_HEADER           = header("Looking for files with newer access time...");
pub const FILES_NEWER_CTIME_HEADER           = header("Looking for files with newer change time...");
pub const FILES_NEWER_MTIME_HEADER           = header("Looking for files with newer modified time...");
pub const FILES_OLDER_ATIME_HEADER           = header("Looking for files with older access time...");
pub const FILES_OLDER_CTIME_HEADER           = header("Looking for files with older change time...");
pub const FILES_OLDER_MTIME_HEADER           = header("Looking for files with older modified time...");
pub const LINKS_SHORTCUTS_HEADER             = header("Looking for links and shortcuts...");
pub const EMPTY_DIRECTORIES_HEADER           = header("Looking for empty directories...");
pub const EMPTY_FILES_HEADER                 = header("Looking for empty files...");
pub const END_OF_LINE_HEADER                 = header("Looking for wrong line terminators in text files...");
pub const INTEGRITY_FILES_HEADER             = header("Checking file integrity...");
pub const FULL_PATH_SIZE_HEADER              = header("Looking for long paths...");
pub const JSON_OUTPUT_HEADER                 = header("Writing results in JSON output...");
pub const LARGE_FILES_HEADER                 = header("Looking for large files...");
pub const LAST_ACCESS_HEADER                 = header("Looking for files accessed a long time ago...");
pub const LEGACY_FILES_HEADER                = header("Looking for legacy files...");
pub const MAGIC_NUMBERS_HEADER               = header("Looking for files with wrong magic numbers...");
pub const MANY_ITEMS_DIRECTORIES_HEADER      = header("Looking for directories with many items...");
pub const NO_EXTENSION_HEADER                = header("Looking for files with no extension...");
pub const NONPORTABLE_CHARS_HEADER           = header("Looking for non-portable characters...");
pub const OWNERSHIPS_PERMISSIONS_HEADER      = header("Checking ownerships and permissions...");
pub const ONE_ITEM_DIRECTORIES_HEADER        = header("Looking for directories with one item...");
pub const PARSE_FILES_HEADER                 = header("Looking for errors while parsing files...");
pub const TEMPORARY_FILES_HEADER             = header("Looking for temporary files...");
pub const UTF8_ENCODING_HEADER               = header("Looking for text files not encoded in UTF-8...");
pub const WRONG_DATES_HEADER                 = header("Looking for files with wrong dates...");

// Warning messages
pub const COMPRESSED_FILES_WARNING           = report(config.COMPTIME_COMPRESSED_FILES,         "\"{s}\" compression could be improved");
pub const CONFIDENTIAL_FILES_WARNING         = report(config.COMPTIME_CONFIDENTIAL_FILES,       "\"{s}\" has confidential data");
pub const DEBUG_INFO_WARNING                 = report(config.COMPTIME_DEBUG_INFO,               "\"{s}\" has debug/symbol information");
pub const DIRECTORY_FILE_NAME_SIZE_WARNING   = report(config.COMPTIME_DIRECTORY_FILE_NAME_SIZE, "\"{s}\" is longer than {d} characters");
pub const EMPTY_WARNING                      = report(empty_on,                                 "\"{s}\" is empty");
pub const END_OF_LINE_WARNING                = report(config.COMPTIME_END_OF_LINE,              "\"{s}\" has an invalid end-of-line terminator");
pub const FULL_PATH_SIZE_WARNING             = report(config.COMPTIME_FULL_PATH_SIZE,           "Path \"{s}\" is longer than {d} characters");
pub const LINKS_SHORTCUTS_WARNING            = report(links_on,                                 "\"{s}\" is not portable");
pub const LARGE_FILES_WARNING                = report(config.COMPTIME_LARGE_FILES,              "File \"{s}\" is larger than {d} bytes");
pub const LAST_ACCESS_FILES_WARNING          = report(config.COMPTIME_LAST_ACCESS_FILES,        "\"{s}\" last access was {d} ns ago");
pub const LEGACY_FILES_WARNING               = report(config.COMPTIME_LEGACY_FILES,             "\"{s}\" has a legacy format \"{s}\"");
pub const MANY_ITEMS_DIRECTORIES_WARNING     = report(config.COMPTIME_MANY_ITEMS_DIRECTORIES,   "\"{s}\" has more than {d} items");
pub const NO_EXTENSION_WARNING               = report(config.COMPTIME_NO_EXTENSION,             "Format of \"{s}\" was not found");
pub const NONPORTABLE_CHARS_WARNING          = report(config.COMPTIME_NONPORTABLE_CHARS,        "\"{s}\" has a non-portable character");
pub const ONE_ITEM_DIRECTORIES_WARNING       = report(config.COMPTIME_ONE_ITEM_DIRECTORIES,     "\"{s}\" has one item");
pub const OWNERSHIPS_PERMISSIONS_WARNING     = report(config.COMPTIME_OWNERSHIPS_PERMISSIONS,   "\"{s}\" has permission 777");
pub const OWNERSHIPS_PERMISSIONS_GID_WARNING = report(config.COMPTIME_OWNERSHIPS_PERMISSIONS,   "\"{s}\" has invalid group ID \"{d}\"");
pub const OWNERSHIPS_PERMISSIONS_UID_WARNING = report(config.COMPTIME_OWNERSHIPS_PERMISSIONS,   "\"{s}\" has invalid user ID \"{d}\"");
pub const TEMPORARY_FILES_WARNING            = report(temp_on,                                  "\"{s}\" is a temporary file");
pub const UTF8_ENCODING_WARNING              = report(config.COMPTIME_UTF8_ENCODING,            "\"{s}\" is not encoded in UTF-8");
pub const WRONG_DATES_WARNING                = report(config.COMPTIME_WRONG_DATES,              "File \"{s}\" has a date in the future");

// Check messages
pub const COMPRESSED_FILES_CHECK             = report(config.COMPTIME_COMPRESSED_FILES,         "\"{s}\" has an uncommon compression method");
pub const DUPLICATE_CHARS_FILES_CHECK        = report(config.COMPTIME_DUPLICATE_CHARS_FILES,    "\"{s}\" has a duplicate character");
pub const DUPLICATE_CHARS_FILES_CHECK_EXT    = report(config.COMPTIME_DUPLICATE_CHARS_FILES,    "\"{s}\" has a duplicate extension");
pub const INTEGRITY_FILES_CHECK              = report(integrity_on,                             "\"{s}\" {s} hash created");
pub const NO_EXTENSION_CHECK                 = report(config.COMPTIME_NO_EXTENSION,             "Format of \"{s}\" could be \"{s}\"");

// Error messages
pub const END_OF_LINE_ERROR                  = console("Invalid line terminator in configuration");
pub const INTEGRITY_FILES_ERROR              = report(integrity_on,                             "\"{s}\" has a different {s} hash");
pub const INTEGRITY_FILES_ERROR_CHAR         = report(integrity_on,                             "\"{s}\" has an invalid character in its hash");
pub const LINKS_SHORTCUTS_ERROR              = report(links_on,                                 "\"{s}\" target was not found");
pub const MAGIC_NUMBERS_ERROR                = report(config.COMPTIME_MAGIC_NUMBERS,            "\"{s}\" has a wrong magic number");
pub const PARSE_FILES_ERROR                  = report(config.COMPTIME_PARSE_FILES,              "Can't parse \"{s}\"");

// Ok message
pub const INTEGRITY_FILES_OK                 = report(integrity_on, "\"{s}\" {s} verified");

// System messages
pub const OK_MESSAGE                         = console("OK");
pub const DISABLED_MESSAGE                   = console("DISABLED");
pub const QUIT_MESSAGE                       = console("Press Enter to quit");
pub const TOTAL_MESSAGE                      = console(" Total:");
pub const CHECK_MESSAGE                      = console(" CHECK  ");
pub const ERROR_MESSAGE                      = console(" ERROR  ");
pub const FOUND_MESSAGE                      = console(" FOUND  ");
pub const KEEPING_MESSAGE                    = console(" KEEPING ");
pub const OK_MESSAGE_FILE                    = console("   OK   ");

pub const REMOVING_MESSAGE                   = console("REMOVING ");
pub const WARNING_MESSAGE                    = console("WARNING ");

// System error messages
pub const ERROR_ACCESS_DENIED_PATH           = "\"{s}\": access denied";
pub const ERROR_ALLOC_MEM                    = "Failed to allocate memory for path \"{s}\": \"{}\"";
pub const ERROR_APPEND_PATH                  = "Failed to append path to list: \"{}\"";
pub const ERROR_COMMAND_NOT_FOUND            = "Command \"{s}\" not found";
pub const ERROR_CONFIG_FILE                  = "config.json already exists";
pub const ERROR_CONFIG_FILE_PARSE            = "Can't parse config.json";
pub const ERROR_EMPTY_PATH                   = "Input folder is empty in config.json";
pub const ERROR_FILE_BUSY                    = "\"{s}\" is busy";
pub const ERROR_HASH_FILE                    = "Failed to hash file \"{s}\": \"{}\"";
pub const ERROR_INPUT_DIRECTORY              = "Can't read input directory";
pub const ERROR_INSERT_HASHMAP               = "Failed to insert into hash map: \"{}\"";
pub const ERROR_PERMISSION_DENIED            = "\"{s}\": permission denied";
pub const ERROR_READING_FILE                 = "\"{s}\" is unreadable";
pub const ERROR_READ_ONLY_FS                 = "\"{s}\" is on a read-only filesystem";
pub const ERROR_STREAM_TOO_LONG              = "\"{s}\" is larger than the buffer";
pub const ERROR_UNEXPECTED_FILE              = "Unexpected error processing file \"{s}\"";

fn helpEntry(comptime c: Command) []const u8 {
    return "    --" ++ c.long ++ ", -" ++ c.short ++ ", " ++ c.long ++ ", /" ++ c.short ++ "\n" ++
        "        " ++ c.info ++ "\n" ++
        (if (c.cfg.len > 0) "        (create config.json to customize " ++ c.cfg ++ ")\n" else "") ++
        "\n";
}

fn gate(comptime on: bool, comptime text: []const u8) []const u8      { return if (on) text else "";                        }
fn console(comptime text: []const u8) []const u8                      { return gate(config.COMPTIME_STDOUT, text);          }
fn report(comptime check: bool, comptime text: []const u8) []const u8 { return gate(config.COMPTIME_STDOUT or check, text); }

fn header(comptime text: []const u8) []const u8 {
    if (text.len >= ALIGNED_SPACES) @compileError("header is wider than ALIGNED_SPACES: " ++ text);
    return console(text);
}

// Declarations are analysed lazily; this forces every string (and header-width guard) to be checked.
test "every string is valid" {
    std.testing.refAllDecls(@This());
}
