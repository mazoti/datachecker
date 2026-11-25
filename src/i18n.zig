//! UTF-8 strings for English language
//!
//! Copyright © 2025-present Marcos Mazoti

const config = @import("config");

/// Spacing constant for alignment - matches the largest header string size in output
pub const ALIGNED_SPACES: u32 = 52;

pub const HEADER_START = if (config.COMPTIME_STDOUT) "DataChecker v" else "";
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


pub const COMPTIME_COMPRESSED_FILES = if (config.COMPTIME_STDOUT)
    \\    --compressed, -c, compressed, /c
    \\        Search for optimization opportunities in lossless compressed files
    \\
    \\
    else "";

pub const COMPTIME_CONFIDENTIAL_FILES = if (config.COMPTIME_STDOUT)
    \\    --confidential, -conf, confidential, /conf
    \\        Search for confidential data in files
    \\        (create config.json to customize search patterns)
    \\
    \\
    else "";

pub const COMPTIME_DEBUG_INFO = if (config.COMPTIME_STDOUT)
    \\    --debuginfo, -di, debuginfo, /di
    \\        Search for binary files with debug information
    \\
    \\
    else "";

pub const COMPTIME_DIRECTORY_FILE_NAME_SIZE = if (config.COMPTIME_STDOUT)
    \\    --dirsize, -ds, dirsize, /ds
    \\        Search for directories or files with excessively long names
    \\        (create config.json to customize length threshold)
    \\
    \\
    else "";

pub const COMPTIME_DUPLICATE_CHARS_FILES = if (config.COMPTIME_STDOUT)
    \\    --dupchars, -dc, dupchars, /dc
    \\        Search for duplicate characters in file names
    \\
    \\
    else "";

pub const COMPTIME_DUPLICATE_FILES_PARALLEL = if (config.COMPTIME_STDOUT)
    \\    --duplicate_mt, -dmt, duplicate_mt, /dmt
    \\        Search for duplicate files using multithreading
    \\
    \\
    else "";

pub const COMPTIME_DUPLICATE_FILES = if (config.COMPTIME_STDOUT)
    \\    --duplicate, -d, duplicate, /d
    \\        Search for duplicate files
    \\
    \\
    else "";

pub const COMPTIME_EMPTY_FILES = if (config.COMPTIME_STDOUT)
    \\    --empty_files, -ef, empty_files, /ef
    \\        Search for empty files
    \\
    \\
    else "";

pub const COMPTIME_EMPTY_DIRECTORIES = if (config.COMPTIME_STDOUT)
    \\    --empty_dirs, -ed, empty_dirs, /ed
    \\        Search for empty directories
    \\
    \\
    else "";

pub const COMPTIME_END_OF_LINE = if (config.COMPTIME_STDOUT)
    \\    --end_of_line, -eol, end_of_line, /eol
    \\        Search for wrong line terminator in text files
    \\        (create config.json to customize terminator)
    \\
    \\
    else "";

pub const COMPTIME_FILES_NEWER_ATIME = if (config.COMPTIME_STDOUT)
    \\    --files_newer_atime, -fna, files_newer_atime, /fna
    \\        Search for files with newer access time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FILES_NEWER_CTIME = if (config.COMPTIME_STDOUT)
    \\    --files_newer_ctime, -fnc, files_newer_ctime, /fnc
    \\        Search for files with newer change time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FILES_NEWER_MTIME = if (config.COMPTIME_STDOUT)
    \\    --files_newer_mtime, -fnm, files_newer_mtime, /fnm
    \\        Search for files with newer modified time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FILES_OLDER_ATIME = if (config.COMPTIME_STDOUT)
    \\    --files_older_atime, -foa, files_older_atime, /foa
    \\        Search for files with older access time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FILES_OLDER_CTIME = if (config.COMPTIME_STDOUT)
    \\    --files_older_ctime, -foc, files_older_ctime, /foc
    \\        Search for files with older change time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FILES_OLDER_MTIME = if (config.COMPTIME_STDOUT)
    \\    --files_older_mtime, -fom, files_older_mtime, /fom
    \\        Search for files with older modified time
    \\        (create config.json to customize time)
    \\
    \\
    else "";

pub const COMPTIME_FULL_PATH_SIZE = if (config.COMPTIME_STDOUT)
    \\    --full_path_size, -fps, full_path_size, /fps
    \\        Search for excessively long absolute paths
    \\        (create config.json to customize path length threshold)
    \\
    \\
    else "";

pub const COMPTIME_INTEGRITY_FILES = if (config.COMPTIME_STDOUT)
    \\    --integrity, -i, integrity, /i
    \\        Create/verify file hashes
    \\
    \\
    else "";

pub const COMPTIME_INTEGRITY_FILES_PARALLEL = if (config.COMPTIME_STDOUT)
    \\    --integrity_mt, -imt, integrity_mt, /imt
    \\        Create/verify file hashes using multithreading
    \\
    \\
    else "";

pub const COMPTIME_LARGE_FILES = if (config.COMPTIME_STDOUT)
    \\    --large_files, -lf, large_files, /lf
    \\        Search for large files
    \\        (create config.json to customize size threshold)
    \\
    \\
    else "";

pub const COMPTIME_LAST_ACCESS_FILES = if (config.COMPTIME_STDOUT)
    \\    --last_access, -la, last_access, /la
    \\        Search for files not accessed recently
    \\        (create config.json to customize time period)
    \\
    \\
    else "";

pub const COMPTIME_LEGACY_FILES = if (config.COMPTIME_STDOUT)
    \\    --legacy_files, -lef, legacy_files, /lef
    \\        Search for files using outdated formats
    \\
    \\
    else "";

pub const COMPTIME_LINKS_SHORTCUTS = if (config.COMPTIME_STDOUT)
    \\    --links, -l, links, /l
    \\        Search for links and shortcuts
    \\
    \\
    else "";

pub const COMPTIME_MAGIC_NUMBERS = if (config.COMPTIME_STDOUT)
    \\    --magic_numbers, -mn, magic_numbers, /mn
    \\        Search for files with mismatched magic numbers
    \\
    \\
    else "";

pub const COMPTIME_MANY_ITEMS_DIRECTORIES = if (config.COMPTIME_STDOUT)
    \\    --many_items, -mi, many_items, /mi
    \\        Search for directories with an excessive number of items
    \\        (create config.json to customize item threshold)
    \\
    \\
    else "";

pub const COMPTIME_NONPORTABLE_CHARS = if (config.COMPTIME_STDOUT)
    \\    --nonportable_chars, -nc, nonportable_chars, /nc
    \\        Search for non-portable characters in absolute paths
    \\
    \\
    else "";

pub const COMPTIME_NO_EXTENSION = if (config.COMPTIME_STDOUT)
    \\    --no_extension, -ne, no_extension, /ne
    \\        Search for files without extensions and attempt to identify them
    \\
    \\
    else "";

pub const COMPTIME_ONE_ITEM_DIRECTORIES = if (config.COMPTIME_STDOUT)
    \\    --one_item_dir, -oid, one_item_dir, /oid
    \\        Search for directories containing only one item
    \\
    \\
    else "";

pub const COMPTIME_PARSE_FILES = if (config.COMPTIME_STDOUT)
    \\    --parse_files, -pf, parse_files, /pf
    \\        Parse files looking for errors
    \\
    \\
    else "";

pub const COMPTIME_TEMPORARY_FILES = if (config.COMPTIME_STDOUT)
    \\    --temp_files, -tf, temp_files, /tf
    \\        Search for temporary files
    \\
    \\
    else "";

pub const COMPTIME_UTF8_ENCODING = if (config.COMPTIME_STDOUT)
    \\    --utf8, -u, utf8, /u
    \\        Search for non-UTF8 encoded text files
    \\
    \\
    else "";

pub const COMPTIME_WRONG_DATES = if (config.COMPTIME_STDOUT)
    \\    --wrong_dates, -wd, wrong_dates, /wd
    \\        Search for files with timestamps in the future
    \\
    \\
    else "";

pub const COMPTIME_DUPLICATE_FILES_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --duplicate_rm, -drm, duplicate_rm, /drm
    \\        Remove duplicate files
    \\
    \\
    else "";

pub const COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --duplicate_rmt, -drmt, duplicate_rmt, /drmt
    \\        Remove duplicate files using multithreading
    \\
    \\
    else "";

pub const COMPTIME_EMPTY_FILES_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --empty_rm, -efrm, empty_rm, /efrm
    \\        Remove empty files
    \\
    \\
    else "";

pub const COMPTIME_EMPTY_DIRECTORIES_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --empty_dirs_rm, -edrm, empty_dirs_rm, /edrm
    \\        Remove empty directories
    \\
    \\
    else "";

pub const COMPTIME_LINKS_SHORTCUTS_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --links_rm, -lrm, links_rm, /lrm
    \\        Remove links and shortcuts
    \\
    \\
    else "";

pub const COMPTIME_TEMPORARY_FILES_REMOVE = if (config.COMPTIME_STDOUT)
    \\    --temp_rm, -trm, temp_rm, /trm
    \\        Remove temporary files
    \\
    \\
    else "";

pub const HELP = if (config.COMPTIME_STDOUT) USAGE
    ++ (if (config.COMPTIME_COMPRESSED_FILES)                COMPTIME_COMPRESSED_FILES                else "")
    ++ (if (config.COMPTIME_CONFIDENTIAL_FILES)              COMPTIME_CONFIDENTIAL_FILES              else "")
    ++ (if (config.COMPTIME_DEBUG_INFO)                      COMPTIME_DEBUG_INFO                      else "")
    ++ (if (config.COMPTIME_DIRECTORY_FILE_NAME_SIZE)        COMPTIME_DIRECTORY_FILE_NAME_SIZE        else "")
    ++ (if (config.COMPTIME_DUPLICATE_CHARS_FILES)           COMPTIME_DUPLICATE_CHARS_FILES           else "")
    ++ (if (config.COMPTIME_DUPLICATE_FILES_PARALLEL)        COMPTIME_DUPLICATE_FILES_PARALLEL        else "")
    ++ (if (config.COMPTIME_DUPLICATE_FILES_REMOVE)          COMPTIME_DUPLICATE_FILES_REMOVE          else "")
    ++ (if (config.COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE) COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE else "")
    ++ (if (config.COMPTIME_DUPLICATE_FILES)                 COMPTIME_DUPLICATE_FILES                 else "")
    ++ (if (config.COMPTIME_EMPTY_FILES_REMOVE)              COMPTIME_EMPTY_FILES_REMOVE              else "")
    ++ (if (config.COMPTIME_EMPTY_FILES)                     COMPTIME_EMPTY_FILES                     else "")
    ++ (if (config.COMPTIME_EMPTY_DIRECTORIES_REMOVE)        COMPTIME_EMPTY_DIRECTORIES_REMOVE        else "")
    ++ (if (config.COMPTIME_EMPTY_DIRECTORIES)               COMPTIME_EMPTY_DIRECTORIES               else "")
    ++ (if (config.COMPTIME_END_OF_LINE)                     COMPTIME_END_OF_LINE                     else "")
    ++ (if (config.COMPTIME_FILES_NEWER_ATIME)               COMPTIME_FILES_NEWER_ATIME               else "")
    ++ (if (config.COMPTIME_FILES_NEWER_CTIME)               COMPTIME_FILES_NEWER_CTIME               else "")
    ++ (if (config.COMPTIME_FILES_NEWER_MTIME)               COMPTIME_FILES_NEWER_MTIME               else "")
    ++ (if (config.COMPTIME_FILES_OLDER_ATIME)               COMPTIME_FILES_OLDER_ATIME               else "")
    ++ (if (config.COMPTIME_FILES_OLDER_CTIME)               COMPTIME_FILES_OLDER_CTIME               else "")
    ++ (if (config.COMPTIME_FILES_OLDER_MTIME)               COMPTIME_FILES_OLDER_MTIME               else "")
    ++ (if (config.COMPTIME_FULL_PATH_SIZE)                  COMPTIME_FULL_PATH_SIZE                  else "")
    ++ (if (config.COMPTIME_INTEGRITY_FILES_PARALLEL)        COMPTIME_INTEGRITY_FILES_PARALLEL        else "")
    ++ (if (config.COMPTIME_INTEGRITY_FILES)                 COMPTIME_INTEGRITY_FILES                 else "")
    ++ (if (config.COMPTIME_LARGE_FILES)                     COMPTIME_LARGE_FILES                     else "")
    ++ (if (config.COMPTIME_LAST_ACCESS_FILES)               COMPTIME_LAST_ACCESS_FILES               else "")
    ++ (if (config.COMPTIME_LEGACY_FILES)                    COMPTIME_LEGACY_FILES                    else "")
    ++ (if (config.COMPTIME_LINKS_SHORTCUTS_REMOVE)          COMPTIME_LINKS_SHORTCUTS_REMOVE          else "")
    ++ (if (config.COMPTIME_LINKS_SHORTCUTS)                 COMPTIME_LINKS_SHORTCUTS                 else "")
    ++ (if (config.COMPTIME_MAGIC_NUMBERS)                   COMPTIME_MAGIC_NUMBERS                   else "")
    ++ (if (config.COMPTIME_MANY_ITEMS_DIRECTORIES)          COMPTIME_MANY_ITEMS_DIRECTORIES          else "")
    ++ (if (config.COMPTIME_NO_EXTENSION)                    COMPTIME_NO_EXTENSION                    else "")
    ++ (if (config.COMPTIME_NONPORTABLE_CHARS)               COMPTIME_NONPORTABLE_CHARS               else "")
    ++ (if (config.COMPTIME_ONE_ITEM_DIRECTORIES)            COMPTIME_ONE_ITEM_DIRECTORIES            else "")
    ++ (if (config.COMPTIME_PARSE_FILES)                     COMPTIME_PARSE_FILES                     else "")
    ++ (if (config.COMPTIME_TEMPORARY_FILES_REMOVE)          COMPTIME_TEMPORARY_FILES_REMOVE          else "")
    ++ (if (config.COMPTIME_TEMPORARY_FILES)                 COMPTIME_TEMPORARY_FILES                 else "")
    ++ (if (config.COMPTIME_UTF8_ENCODING)                   COMPTIME_UTF8_ENCODING                   else "")
    ++ (if (config.COMPTIME_WRONG_DATES)                     COMPTIME_WRONG_DATES                     else "")
    else "";

pub const CONFIG_MESSAGE_CREATE            = if (config.COMPTIME_STDOUT) "Creating config.json..."         else "";

// Summary messages
pub const BYTES_TOTAL                      = if (config.COMPTIME_STDOUT) "byte"                            else "";
pub const BYTES_TOTALS                     = if (config.COMPTIME_STDOUT) "bytes"                           else "";

pub const DIRECTORIES_TOTAL                = if (config.COMPTIME_STDOUT) "directory"                       else "";
pub const DIRECTORIES_TOTALS               = if (config.COMPTIME_STDOUT) "directories"                     else "";

pub const FILES_TOTAL                      = if (config.COMPTIME_STDOUT) "file"                            else "";
pub const FILES_TOTALS                     = if (config.COMPTIME_STDOUT) "files"                           else "";

pub const DIR_FILE_NAME_SIZE_TOTAL         = if (config.COMPTIME_STDOUT) "file or directory"               else "";
pub const DIR_FILE_NAME_SIZE_TOTALS        = if (config.COMPTIME_STDOUT) "files or directories"            else "";

pub const DUPLICATE_CHARS_FILES_TOTAL      = if (config.COMPTIME_STDOUT) "item with duplicate characters"  else "";
pub const DUPLICATE_CHARS_FILES_TOTALS     = if (config.COMPTIME_STDOUT) "items with duplicate characters" else "";

pub const LINKS_SHORTCUTS_TOTAL            = if (config.COMPTIME_STDOUT) "link/shortcut" else "";
pub const LINKS_SHORTCUTS_TOTALS           = if (config.COMPTIME_STDOUT) "links/shortcuts" else "";

pub const FULL_PATH_SIZE_TOTAL             = if (config.COMPTIME_STDOUT) "path found" else "";
pub const FULL_PATH_SIZE_TOTALS            = if (config.COMPTIME_STDOUT) "paths found" else "";

pub const INTEGRITY_FILES_TOTAL            = if (config.COMPTIME_STDOUT) "hash processed" else "";
pub const INTEGRITY_FILES_TOTALS           = if (config.COMPTIME_STDOUT) "hashes processed" else "";

pub const NONPORTABLE_CHARS_TOTAL          = if (config.COMPTIME_STDOUT) "item with non-portable characters"  else "";
pub const NONPORTABLE_CHARS_TOTALS         = if (config.COMPTIME_STDOUT) "items with non-portable characters" else "";

pub const PARSE_FILES_TOTAL                = if (config.COMPTIME_STDOUT) "error found"                        else "";
pub const PARSE_FILES_TOTALS               = if (config.COMPTIME_STDOUT) "errors found"                       else "";

// Header messages
pub const CONFIG_MESSAGE_HEADER            = if (config.COMPTIME_STDOUT) "Loading config.json..."                              else "";
pub const CONFIG_MESSAGE_HEADER_DEFAULT    = if (config.COMPTIME_STDOUT) "Loading default configuration..."                    else "";
pub const COMPRESSED_FILES_HEADER          = if (config.COMPTIME_STDOUT) "Looking for compressed files..."                     else "";
pub const CONFIDENTIAL_FILES_HEADER        = if (config.COMPTIME_STDOUT) "Looking for confidential files..."                   else "";
pub const DEBUG_INFO_HEADER                = if (config.COMPTIME_STDOUT) "Looking for debug info in binary files..."           else "";
pub const DIR_FILE_NAME_SIZE_HEADER        = if (config.COMPTIME_STDOUT) "Looking for long names..."                           else "";
pub const DUPLICATE_CHARS_FILES_HEADER     = if (config.COMPTIME_STDOUT) "Looking for duplicate characters..."                 else "";
pub const DUPLICATE_FILES_HEADER           = if (config.COMPTIME_STDOUT) "Looking for duplicate files..."                      else "";
pub const FILES_NEWER_ATIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with newer access time..."         else "";
pub const FILES_NEWER_CTIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with newer change time..."         else "";
pub const FILES_NEWER_MTIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with newer modified time..."       else "";
pub const FILES_OLDER_ATIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with older access time..."         else "";
pub const FILES_OLDER_CTIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with older change time..."         else "";
pub const FILES_OLDER_MTIME_HEADER         = if (config.COMPTIME_STDOUT) "Looking for files with older modified time..."       else "";
pub const LINKS_SHORTCUTS_HEADER           = if (config.COMPTIME_STDOUT) "Looking for links and shortcuts..."                  else "";
pub const EMPTY_DIRECTORIES_HEADER         = if (config.COMPTIME_STDOUT) "Looking for empty directories..."                    else "";
pub const EMPTY_FILES_HEADER               = if (config.COMPTIME_STDOUT) "Looking for empty files..."                          else "";
pub const END_OF_LINE_HEADER               = if (config.COMPTIME_STDOUT) "Looking for wrong line terminators in text files..." else "";
pub const INTEGRITY_FILES_HEADER           = if (config.COMPTIME_STDOUT) "Checking file integrity..."                          else "";
pub const FULL_PATH_SIZE_HEADER            = if (config.COMPTIME_STDOUT) "Looking for long paths..."                           else "";
pub const JSON_OUTPUT_HEADER               = if (config.COMPTIME_STDOUT) "Writing results in JSON output..."                   else "";
pub const LARGE_FILES_HEADER               = if (config.COMPTIME_STDOUT) "Looking for large files..."                          else "";
pub const LAST_ACCESS_HEADER               = if (config.COMPTIME_STDOUT) "Looking for files accessed a long time ago..."       else "";
pub const LEGACY_FILES_HEADER              = if (config.COMPTIME_STDOUT) "Looking for legacy files..."                         else "";
pub const MAGIC_NUMBERS_HEADER             = if (config.COMPTIME_STDOUT) "Looking for files with wrong magic numbers..."       else "";
pub const MANY_ITEMS_DIRECTORIES_HEADER    = if (config.COMPTIME_STDOUT) "Looking for directories with many items..."          else "";
pub const NO_EXTENSION_HEADER              = if (config.COMPTIME_STDOUT) "Looking for files with no extension..."              else "";
pub const NONPORTABLE_CHARS_HEADER         = if (config.COMPTIME_STDOUT) "Looking for non-portable characters..."              else "";
pub const ONE_ITEM_DIRECTORIES_HEADER      = if (config.COMPTIME_STDOUT) "Looking for directories with one item..."            else "";
pub const PARSE_FILES_HEADER               = if (config.COMPTIME_STDOUT) "Looking for errors while parsing files..."           else "";
pub const TEMPORARY_FILES_HEADER           = if (config.COMPTIME_STDOUT) "Looking for temporary files..."                      else "";
pub const UTF8_ENCODING_HEADER             = if (config.COMPTIME_STDOUT) "Looking for text files not encoded in UTF-8..."      else "";
pub const WRONG_DATES_HEADER               = if (config.COMPTIME_STDOUT) "Looking for files with wrong dates..."               else "";

// Warning messages
pub const COMPRESSED_FILES_WARNING         = if (config.COMPTIME_STDOUT or config.COMPTIME_COMPRESSED_FILES)         "\"{s}\" compression could be improved"         else "";
pub const CONFIDENTIAL_FILES_WARNING       = if (config.COMPTIME_STDOUT or config.COMPTIME_CONFIDENTIAL_FILES)       "\"{s}\" has confidential data"                 else "";
pub const DEBUG_INFO_WARNING               = if (config.COMPTIME_STDOUT or config.COMPTIME_DEBUG_INFO)               "\"{s}\" has debug/symbol information"          else "";
pub const DIRECTORY_FILE_NAME_SIZE_WARNING = if (config.COMPTIME_STDOUT or config.COMPTIME_DIRECTORY_FILE_NAME_SIZE) "\"{s}\" is longer than {d} characters"         else "";
pub const EMPTY_WARNING                    = if (config.COMPTIME_STDOUT or config.COMPTIME_EMPTY_FILES or config.COMPTIME_EMPTY_DIRECTORIES) "\"{s}\" is empty"                  else "";
pub const END_OF_LINE_WARNING              = if (config.COMPTIME_STDOUT or config.COMPTIME_END_OF_LINE)              "\"{s}\" has an invalid end-of-line terminator" else "";
pub const FULL_PATH_SIZE_WARNING           = if (config.COMPTIME_STDOUT or config.COMPTIME_FULL_PATH_SIZE)           "Path \"{s}\" is longer than {d} characters"    else "";
pub const LINKS_SHORTCUTS_WARNING          = if (config.COMPTIME_STDOUT or config.COMPTIME_LINKS_SHORTCUTS)          "\"{s}\" is not portable"                       else "";
pub const LARGE_FILES_WARNING              = if (config.COMPTIME_STDOUT or config.COMPTIME_LARGE_FILES)              "File \"{s}\" is larger than {d} bytes"         else "";
pub const LAST_ACCESS_FILES_WARNING        = if (config.COMPTIME_STDOUT or config.COMPTIME_LAST_ACCESS_FILES)        "\"{s}\" last access was {d} ns ago"            else "";
pub const LEGACY_FILES_WARNING             = if (config.COMPTIME_STDOUT or config.COMPTIME_LEGACY_FILES)             "\"{s}\" has a legacy format \"{s}\""           else "";
pub const MANY_ITEMS_DIRECTORIES_WARNING   = if (config.COMPTIME_STDOUT or config.COMPTIME_MANY_ITEMS_DIRECTORIES)   "\"{s}\" has more than {d} items"               else "";
pub const NO_EXTENSION_WARNING             = if (config.COMPTIME_STDOUT or config.COMPTIME_NO_EXTENSION)             "Format of \"{s}\" was not found"               else "";
pub const NONPORTABLE_CHARS_WARNING        = if (config.COMPTIME_STDOUT or config.COMPTIME_NONPORTABLE_CHARS)        "\"{s}\" has a non-portable character"          else "";
pub const ONE_ITEM_DIRECTORIES_WARNING     = if (config.COMPTIME_STDOUT or config.COMPTIME_ONE_ITEM_DIRECTORIES)     "\"{s}\" has one item"                          else "";
pub const TEMPORARY_FILES_WARNING          = if (config.COMPTIME_STDOUT or config.COMPTIME_TEMPORARY_FILES)          "\"{s}\" is a temporary file"                   else "";
pub const UTF8_ENCODING_WARNING            = if (config.COMPTIME_STDOUT or config.COMPTIME_UTF8_ENCODING)            "\"{s}\" is not encoded in UTF-8"               else "";
pub const WRONG_DATES_WARNING              = if (config.COMPTIME_STDOUT or config.COMPTIME_WRONG_DATES)              "File \"{s}\" has a date in the future"         else "";

// Check messages
pub const COMPRESSED_FILES_CHECK          = if (config.COMPTIME_STDOUT or config.COMPTIME_COMPRESSED_FILES)          "\"{s}\" has an uncommon compression method"    else "";
pub const DUPLICATE_CHARS_FILES_CHECK     = if (config.COMPTIME_STDOUT or config.COMPTIME_DUPLICATE_CHARS_FILES)     "\"{s}\" has a duplicate character"             else "";
pub const DUPLICATE_CHARS_FILES_CHECK_EXT = if (config.COMPTIME_STDOUT or config.COMPTIME_DUPLICATE_CHARS_FILES)     "\"{s}\" has a duplicate extension"             else "";
pub const INTEGRITY_FILES_CHECK           = if (config.COMPTIME_STDOUT or config.COMPTIME_INTEGRITY_FILES)           "\"{s}\" {s} hash created"                      else "";
pub const NO_EXTENSION_CHECK              = if (config.COMPTIME_STDOUT or config.COMPTIME_NO_EXTENSION)              "Format of \"{s}\" could be \"{s}\""            else "";

// Error messages
pub const END_OF_LINE_ERROR               = if (config.COMPTIME_STDOUT)                                              "Invalid line terminator in configuration"      else "";
pub const INTEGRITY_FILES_ERROR           = if (config.COMPTIME_STDOUT or config.COMPTIME_INTEGRITY_FILES)           "\"{s}\" has a different {s} hash"              else "";
pub const INTEGRITY_FILES_ERROR_CHAR      = if (config.COMPTIME_STDOUT or config.COMPTIME_INTEGRITY_FILES)           "\"{s}\" has an invalid character in its hash"  else "";
pub const LINKS_SHORTCUTS_ERROR           = if (config.COMPTIME_STDOUT or config.COMPTIME_LINKS_SHORTCUTS)           "\"{s}\" target was not found"                  else "";
pub const MAGIC_NUMBERS_ERROR             = if (config.COMPTIME_STDOUT or config.COMPTIME_MAGIC_NUMBERS)             "\"{s}\" has a wrong magic number"              else "";
pub const PARSE_FILES_ERROR               = if (config.COMPTIME_STDOUT or config.COMPTIME_PARSE_FILES)               "Can't parse \"{s}\""                           else "";

// Ok message
pub const INTEGRITY_FILES_OK              = if (config.COMPTIME_STDOUT or config.COMPTIME_INTEGRITY_FILES)           "\"{s}\" {s} verified"                          else "";

// System messages
pub const OK_MESSAGE                      = if (config.COMPTIME_STDOUT)  "OK"                                                                                        else "";
pub const DISABLED_MESSAGE                = if (config.COMPTIME_STDOUT) "DISABLED"                                                                                   else "";
pub const QUIT_MESSAGE                    = if (config.COMPTIME_STDOUT) "Press Enter to quit"                                                                        else "";
pub const TOTAL_MESSAGE                   = if (config.COMPTIME_STDOUT) " Total:"                                                                                    else "";
pub const CHECK_MESSAGE                   = if (config.COMPTIME_STDOUT) " CHECK  "                                                                                   else "";
pub const ERROR_MESSAGE                   = if (config.COMPTIME_STDOUT) " ERROR  "                                                                                   else "";
pub const FOUND_MESSAGE                   = if (config.COMPTIME_STDOUT) " FOUND  "                                                                                   else "";
pub const KEEPING_MESSAGE                 = if (config.COMPTIME_STDOUT) " KEEPING "                                                                                  else "";
pub const OK_MESSAGE_FILE                 = if (config.COMPTIME_STDOUT) "   OK   "                                                                                   else "";
pub const REMOVING_MESSAGE                = if (config.COMPTIME_STDOUT) "REMOVING "                                                                                  else "";
pub const WARNING_MESSAGE                 = if (config.COMPTIME_STDOUT) "WARNING "                                                                                   else "";

// System error messages
pub const ERROR_ACCESS_DENIED_PATH        = "\"{s}\": access denied";
pub const ERROR_ALLOC_MEM                 = "Failed to allocate memory for path \"{s}\": \"{}\"";
pub const ERROR_APPEND_PATH               = "Failed to append path to list: \"{}\"";
pub const ERROR_COMMAND_NOT_FOUND         = "Command \"{s}\" not found";
pub const ERROR_CONFIG_FILE               = "config.json already exists";
pub const ERROR_CONFIG_FILE_PARSE         = "Can't parse config.json";
pub const ERROR_EMPTY_PATH                = "Input folder is empty in config.json";
pub const ERROR_FILE_BUSY                 = "\"{s}\" is busy";
pub const ERROR_HASH_FILE                 = "Failed to hash file \"{s}\": \"{}\"";
pub const ERROR_INPUT_DIRECTORY           = "Can't read input directory";
pub const ERROR_INSERT_HASHMAP            = "Failed to insert into hash map: \"{}\"";
pub const ERROR_PERMISSION_DENIED         = "\"{s}\": permission denied";
pub const ERROR_READING_FILE              = "\"{s}\" is unreadable";
pub const ERROR_READ_ONLY_FS              = "\"{s}\" is on a read-only filesystem";
pub const ERROR_STREAM_TOO_LONG           = "\"{s}\" is larger than the buffer";
pub const ERROR_UNEXPECTED_FILE           = "Unexpected error processing file \"{s}\"";
