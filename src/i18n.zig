//! UTF-8 strings for English language
//!
//! Copyright © 2025-present Marcos Mazoti

/// Spacing constant for alignment - matches the largest header string size in output
pub const ALIGNED_SPACES: u32 = 52;

pub const HEADER = "DataChecker v3.0 by Marcos Mazoti - https://mazoti.github.io/datachecker";

pub const USAGE =
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
;

pub const COMPTIME_COMPRESSED_FILES =
    \\    --compressed, -c, -C, compressed, /C, COMPRESSED
    \\        Search for optimization opportunities in lossless compressed files
    \\
    \\
;

pub const COMPTIME_CONFIDENTIAL_FILES =
    \\    --conf, -cf, -CF, conf, /CF, CONF
    \\        Search for confidential data in files
    \\        (create config.json to customize search patterns)
    \\
    \\
;

pub const COMPTIME_DEBUG_INFO =
    \\    --debuginfo, -di, -DI, debuginfo, /DI, DEBUGINFO
    \\        Search for binary files with debug information
    \\
    \\
;

pub const COMPTIME_DIRECTORY_FILE_NAME_SIZE =
    \\    --dirsize, -ds, -DS, dirsize, /DS, DIRSIZE
    \\        Search for directories or files with excessively long names
    \\        (create config.json to customize length threshold)
    \\
    \\
;

pub const COMPTIME_DUPLICATE_CHARS_FILES =
    \\    --dupchars, -dc, -DC, dupchars, /DC, DUPCHARS
    \\        Search for duplicate characters in file names
    \\
    \\
;

pub const COMPTIME_DUPLICATE_FILES_PARALLEL =
    \\    --duplicate_mt, -dmt, -DMT, duplicate_mt, /DMT, DUPLICATE_MT
    \\        Search for duplicate files using multithreading
    \\
    \\
;

pub const COMPTIME_DUPLICATE_FILES_REMOVE =
    \\    --duplicate_rm, -drm, -DRM, duplicate_rm, /DRM, DUPLICATE_RM
    \\        Remove duplicate files
    \\
    \\
;

pub const COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE =
    \\    --duplicate_rmp, -drmp, -DRMP, duplicate_rmp, /DRMP, DUPLICATE_RMP
    \\        Remove duplicate files using multithreading
    \\
    \\
;

pub const COMPTIME_DUPLICATE_FILES =
    \\    --duplicate, -d, -D, duplicate, /D, DUPLICATE
    \\        Search for duplicate files
    \\
    \\
;

pub const COMPTIME_EMPTY_FILES_REMOVE =
    \\    --empty_rm, -efrm, -EFRM, empty_rm, /EFRM, EMPTY_RM
    \\        Remove empty files
    \\
    \\
;

pub const COMPTIME_EMPTY_FILES =
    \\    --empty, -ef, -EF, empty, /EF, EMPTY
    \\        Search for empty files
    \\
    \\
;

pub const COMPTIME_EMPTY_DIRECTORIES_REMOVE =
    \\    --emptydirs_rm, -erm, -ERM, emptydirs_rm, /ERM, EMPTYDIRS_RM
    \\        Remove empty directories
    \\
    \\
;

pub const COMPTIME_EMPTY_DIRECTORIES =
    \\    --emptydirs, -e, -E, emptydirs, /E, EMPTYDIRS
    \\        Search for empty directories
    \\
    \\
;

pub const COMPTIME_END_OF_LINE =
    \\    --endofline, -eol, -EOL, endofline, /EOL, ENDOFLINE
    \\        Search for wrong line terminator in text files
    \\        (create config.json to customize terminator)
    \\
    \\
;

pub const COMPTIME_FILES_NEWER_ATIME =
    \\    --fna, -fna, -FNA, fna, /FNA, FNA
    \\        Search for files with newer access time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FILES_NEWER_CTIME =
    \\    --fnc, -fnc, -FNC, fnc, /FNC, FNC
    \\        Search for files with newer change time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FILES_NEWER_MTIME =
    \\    --fnm, -fnm, -FNM, fnm, /FNM, FNM
    \\        Search for files with newer modified time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FILES_OLDER_ATIME =
    \\    --foa, -foa, -FOA, foa, /FOA, FOA
    \\        Search for files with older access time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FILES_OLDER_CTIME =
    \\    --foc, -foc, -FOC, foc, /FOC, FOC
    \\        Search for files with older change time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FILES_OLDER_MTIME =
    \\    --fom, -fom, -FOM, fom, /FOM, FOM
    \\        Search for files with older modified time
    \\        (create config.json to customize time)
    \\
    \\
;

pub const COMPTIME_FULL_PATH_SIZE =
    \\    --fullpathsize, -f, -F, fullpathsize, /F, FULLPATHSIZE
    \\        Search for excessively long absolute paths
    \\        (create config.json to customize path length threshold)
    \\
    \\
;

pub const COMPTIME_INTEGRITY_FILES_PARALLEL =
    \\    --integrity_mt, -imt, -IMT, integrity_mt, /IMT, INTEGRITY_MT
    \\        Create/verify file hashes using multithreading
    \\
    \\
;

pub const COMPTIME_INTEGRITY_FILES =
    \\    --integrity, -i, -I, integrity, /I, INTEGRITY
    \\        Create/verify file hashes
    \\
    \\
;

pub const COMPTIME_LARGE_FILES =
    \\    --large, -lf, -LF, large, /LF, LARGE
    \\        Search for large files
    \\        (create config.json to customize size threshold)
    \\
    \\
;

pub const COMPTIME_LAST_ACCESS_FILES =
    \\    --last, -l, -L, last, /L, LAST
    \\        Search for files not accessed recently
    \\        (create config.json to customize time period)
    \\
    \\
;

pub const COMPTIME_LEGACY_FILES =
    \\    --legacy, -legacy, /LEGACY, legacy, LEGACY
    \\        Search for files using outdated formats
    \\
    \\
;

pub const COMPTIME_LINKS_SHORTCUTS_REMOVE =
    \\    --links_rm, -lsrm, -LSRM, links_rm, /LSRM, LINKS_RM
    \\        Remove links and shortcuts
    \\
    \\
;

pub const COMPTIME_LINKS_SHORTCUTS =
    \\    --links, -ls, -LS, links, /LS, LINKS
    \\        Search for links and shortcuts
    \\
    \\
;

pub const COMPTIME_MAGIC_NUMBERS =
    \\    --magic, -m, -M, magic, /M, MAGIC
    \\        Search for files with mismatched magic numbers
    \\
    \\
;

pub const COMPTIME_MANY_ITEMS_DIRECTORY =
    \\    --manyitems, -mi, -MI, manyitems, /MI, MANYITEMS
    \\        Search for directories with an excessive number of items
    \\        (create config.json to customize item threshold)
    \\
    \\
;

pub const COMPTIME_NO_EXTENSION =
    \\    --noext, -n, -N, noext, /N, NOEXT
    \\        Search for files without extensions and attempt to identify them
    \\
    \\
;

pub const COMPTIME_ONE_ITEM_DIRECTORY =
    \\    --oneitem, -o, -O, oneitem, /O, ONEITEM
    \\        Search for directories containing only one item
    \\
    \\
;

pub const COMPTIME_PARSE_FILES =
    \\    --parse, -p, -P, parse, /P, PARSE
    \\        Parse files looking for errors
    \\
    \\
;

pub const COMPTIME_TEMPORARY_FILES_REMOVE =
    \\    --temp_rm, -tfrm, -TFRM, temp_rm, /TFRM, TEMP_RM
    \\        Remove temporary files
    \\
    \\
;

pub const COMPTIME_TEMPORARY_FILES =
    \\    --temp, -tf, -TF, temp, /TF, TEMP
    \\        Search for temporary files
    \\
    \\
;

pub const COMPTIME_UNPORTABLE_CHARS =
    \\    --uchars, -u, -U, uchars, /U, UCHARS
    \\        Search for non-portable characters in absolute paths
    \\
    \\
;

pub const COMPTIME_UTF8_ENCODING =
    \\    --utf8, -utf8, -UTF8, utf8, /UTF8, UTF8
    \\        Search for non-UTF8 encoded text files
    \\
    \\
;

pub const COMPTIME_WRONG_DATES =
    \\    --wrong, -w, -W, wrong, /W, WRONG
    \\        Search for files with timestamps in the future
    \\
    \\
;

pub const CONFIG_MESSAGE_CREATE           = "Creating config.json...";

// Summary messages
pub const BYTES_TOTAL                     = "byte";
pub const BYTES_TOTALS                    = "bytes";

pub const DIRECTORIES_TOTAL               = "directory";
pub const DIRECTORIES_TOTALS              = "directories";

pub const FILES_TOTAL                     = "file";
pub const FILES_TOTALS                    = "files";

pub const DIR_FILE_NAME_SIZE_TOTAL        = "file or directory";
pub const DIR_FILE_NAME_SIZE_TOTALS       = "files or directories";

pub const DUPLICATE_CHARS_FILES_TOTAL     = "item with duplicate characters";
pub const DUPLICATE_CHARS_FILES_TOTALS    = "items with duplicate characters";

pub const LINKS_SHORTCUTS_TOTAL           = "link/shortcut";
pub const LINKS_SHORTCUTS_TOTALS          = "links/shortcuts";

pub const FULL_PATH_SIZE_TOTAL            = "path found";
pub const FULL_PATH_SIZE_TOTALS           = "paths found";

pub const INTEGRITY_FILES_TOTAL           = "hash processed";
pub const INTEGRITY_FILES_TOTALS          = "hashes processed";

pub const PARSE_FILES_TOTAL               = "error found";
pub const PARSE_FILES_TOTALS              = "errors found";

pub const UNPORTABLE_CHARS_TOTAL          = "item with non-portable characters";
pub const UNPORTABLE_CHARS_TOTALS         = "items with non-portable characters";

// Header messages
pub const CONFIG_MESSAGE_HEADER           = "Loading config.json...";
pub const CONFIG_MESSAGE_HEADER_DEFAULT   = "Loading default configuration...";
pub const COMPRESSED_FILES_HEADER         = "Looking for compressed files...";
pub const CONFIDENTIAL_FILES_HEADER       = "Looking for confidential files...";
pub const DEBUG_INFO_HEADER               = "Looking for debug info in binary files...";
pub const DIR_FILE_NAME_SIZE_HEADER       = "Looking for long names...";
pub const DUPLICATE_CHARS_FILES_HEADER    = "Looking for duplicate characters...";
pub const DUPLICATE_FILES_HEADER          = "Looking for duplicate files...";
pub const FILES_NEWER_ATIME_HEADER        = "Looking for files with newer access time...";
pub const FILES_NEWER_CTIME_HEADER        = "Looking for files with newer change time...";
pub const FILES_NEWER_MTIME_HEADER        = "Looking for files with newer modified time...";
pub const FILES_OLDER_ATIME_HEADER        = "Looking for files with older access time...";
pub const FILES_OLDER_CTIME_HEADER        = "Looking for files with older change time...";
pub const FILES_OLDER_MTIME_HEADER        = "Looking for files with older modified time...";
pub const LINKS_SHORTCUTS_HEADER          = "Looking for links and shortcuts...";
pub const EMPTY_DIRECTORIES_HEADER        = "Looking for empty directories...";
pub const EMPTY_FILES_HEADER              = "Looking for empty files...";
pub const END_OF_LINE_HEADER              = "Looking for wrong line terminators in text files...";
pub const INTEGRITY_FILES_HEADER          = "Checking file integrity...";
pub const FULL_PATH_SIZE_HEADER           = "Looking for long paths...";
pub const LARGE_FILES_HEADER              = "Looking for large files...";
pub const LAST_ACCESS_HEADER              = "Looking for files accessed a long time ago...";
pub const LEGACY_FILES_HEADER             = "Looking for legacy files...";
pub const MAGIC_NUMBERS_HEADER            = "Looking for files with wrong magic numbers...";
pub const MANY_ITEMS_DIRECTORIES_HEADER   = "Looking for directories with many items...";
pub const NO_EXTENSION_HEADER             = "Looking for files with no extension...";
pub const ONE_ITEM_DIRECTORIES_HEADER     = "Looking for directories with one item...";
pub const PARSE_FILES_HEADER              = "Looking for errors while parsing files...";
pub const TEMPORARY_FILES_HEADER          = "Looking for temporary files...";
pub const UNPORTABLE_CHARS_HEADER         = "Looking for non-portable characters...";
pub const UTF8_ENCODING_HEADER            = "Looking for text files not encoded in UTF-8...";
pub const WRONG_DATES_HEADER              = "Looking for files with wrong dates...";

// Warning messages
pub const COMPRESSED_FILES_WARNING        = "\"{s}\" compression could be improved";
pub const CONFIDENTIAL_FILES_WARNING      = "\"{s}\" has confidential data";
pub const DEBUG_INFO_WARNING              = "\"{s}\" has debug/symbol information";
pub const DIR_FILE_NAME_SIZE_WARNING      = "\"{s}\" is longer than {d} characters";
pub const EMPTY_WARNING                   = "\"{s}\" is empty";
pub const END_OF_LINE_WARNING             = "\"{s}\" has an invalid end-of-line terminator";
pub const FULL_PATH_SIZE_WARNING          = "Path \"{s}\" is longer than {d} characters";
pub const LINKS_SHORTCUTS_WARNING         = "\"{s}\" is not portable";
pub const LARGE_FILES_WARNING             = "File \"{s}\" is larger than {d} bytes";
pub const LAST_ACCESS_WARNING             = "\"{s}\" last access was {d} ns ago";
pub const LEGACY_FILES_WARNING            = "\"{s}\" has a legacy format \"{s}\"";
pub const MANY_ITEMS_DIRECTORIES_WARNING  = "\"{s}\" has more than {d} items";
pub const NO_EXTENSION_WARNING            = "Format of \"{s}\" was not found";
pub const ONE_ITEM_DIRECTORIES_WARNING    = "\"{s}\" has one item";
pub const TEMPORARY_FILES_WARNING         = "\"{s}\" is a temporary file";
pub const UNPORTABLE_CHARS_WARNING        = "\"{s}\" has an non-portable character";
pub const UTF8_ENCODING_WARNING           = "\"{s}\" is not encoded in UTF-8";
pub const WRONG_DATES_WARNING             = "File \"{s}\" has a date in the future";

// Check messages
pub const COMPRESSED_FILES_CHECK          = "\"{s}\" has an uncommon compression method";
pub const DUPLICATE_CHARS_FILES_CHECK     = "\"{s}\" has a duplicate character";
pub const DUPLICATE_CHARS_FILES_CHECK_EXT = "\"{s}\" has a duplicate extension";
pub const INTEGRITY_FILES_CHECK           = "\"{s}\" {s} hash created";
pub const NO_EXTENSION_CHECK              = "Format of \"{s}\" could be \"{s}\"";

/// Error messages
pub const LINKS_SHORTCUTS_ERROR           = "\"{s}\" target was not found";
pub const END_OF_LINE_ERROR               = "Invalid line terminator in configuration";
pub const INTEGRITY_FILES_ERROR           = "\"{s}\" has a different {s} hash";
pub const INTEGRITY_FILES_ERROR_CHAR      = "\"{s}\" has an invalid character in its hash";
pub const MAGIC_NUMBERS_ERROR             = "\"{s}\" has a wrong magic number";
pub const PARSE_FILES_ERROR               = "Can't parse \"{s}\"";

pub const INTEGRITY_FILES_OK              = "\"{s}\" {s} verified";

/// System messages
pub const OK_MESSAGE                      = "OK";
pub const DISABLED_MESSAGE                = "DISABLED";
pub const QUIT_MESSAGE                    = "Press Enter to quit";
pub const TOTAL_MESSAGE                   = " Total:";

pub const CHECK_MESSAGE                   = " CHECK  ";
pub const ERROR_MESSAGE                   = " ERROR  ";
pub const FOUND_MESSAGE                   = " FOUND  ";
pub const OK_MESSAGE_FILE                 = "   OK   ";
pub const REMOVING_MESSAGE                = "REMOVING ";
pub const WARNING_MESSAGE                 = "WARNING ";

/// System error messages
pub const ERROR_ACCESS_DENIED_PATH        = "\"{s}\": access denied";
pub const ERROR_ALLOC_MEM                 = "Failed to allocate memory for path \"{s}\": {}";
pub const ERROR_APPEND_PATH               = "Failed to append path to list: \"{}\"";
pub const ERROR_COMMAND_NOT_FOUND         = "Command \"{s}\" not found";
pub const ERROR_CONFIG_FILE               = "config.json already exists";
pub const ERROR_CONFIG_FILE_PARSE         = "Can't parse config.json";
pub const ERROR_EMPTY_PATH                = "Input folder is empty in config.json";
pub const ERROR_FILE_BUSY                 = "\"{s}\" is busy";
pub const ERROR_HASH_FILE                 = "Failed to hash file \"{s}\": {}";
pub const ERROR_INPUT_DIRECTORY           = "Can't read input directory";
pub const ERROR_INSERT_HASHMAP            = "Failed to insert into hash map: \"{}\"";
pub const ERROR_READING_FILE              = "\"{s}\" is unreadable";
pub const ERROR_READ_ONLY_FS              = "\"{s}\" is on a read-only filesystem";
pub const ERROR_STREAM_TOO_LONG           = "\"{s}\" is larger than the buffer";
pub const ERROR_UNEXPECTED_FILE           = "Unexpected error processing file \"{s}\"";
