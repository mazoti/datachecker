//! UTF-8 strings for english language
//!
//! Copyright © 2025-present Marcos Mazoti

/// Spacing constant for alignment - matches the largest header string size in output
pub const ALIGNED_OK_SPACES: u32 = 49;

pub const HEADER = "DataChecker v2.8 by Marcos Mazoti - https://mazoti.github.io/datachecker";

pub const USAGE =
    \\Usage:
    \\
    \\    datachecker <folder>
    \\              or
    \\    datachecker <command> <directory>
    \\              or
    \\    datachecker config
    \\        Creates config.json file with default configuration
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
    \\       Remove empty directories
    \\
    \\
;

pub const COMPTIME_EMPTY_DIRECTORIES =
    \\    --emptydirs, -e, -E, emptydirs, /E, EMPTYDIRS
    \\        Search for empty directories
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

pub const COMPTIME_PARSE_JSON_FILES =
    \\    --json, -j, -J, json, /J, JSON
    \\        Search for JSON files with syntax errors
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
    \\        Search for directories with excessive items
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

pub const COMPTIME_WRONG_DATES =
    \\    --wrong, -w, -W, wrong, /W, WRONG
    \\        Search for files with timestamps in the future
    \\
    \\
;

pub const BYTES_TOTAL                     = "{d} byte\n";
pub const BYTES_TOTALS                    = "{d} bytes\n";

pub const CONFIG_MESSAGE                  = "\n\tLoading config.json...\n";
pub const CONFIG_MESSAGE_CREATE           = "\n\tCreating config.json...\n";
pub const CONFIG_MESSAGE_DEFAULT          = "\n\tLoading default configuration...\n";
pub const CONFIG_MESSAGE_WARNING          = "\"config.json\" could not be parsed, using default values\n";

pub const COMPRESSED_FILES_CHECK          = "\"{s}\" has an uncommon compression method";
pub const COMPRESSED_FILES_HEADER         = "\n\tLooking for compressed files...\n";
pub const COMPRESSED_FILES_WARNING        = "\"{s}\" compression could be improved";

pub const CONFIDENTIAL_FILES_HEADER       = "\n\tLooking for confidential files...\n";
pub const CONFIDENTIAL_FILES_WARNING      = "\"{s}\" has confidential data";

pub const DIR_FILE_NAME_SIZE_HEADER       = "\n\tLooking for large names...\n";
pub const DIR_FILE_NAME_SIZE_TOTAL        = "{d} file or directory\n";
pub const DIR_FILE_NAME_SIZE_TOTALS       = "{d} files or directories\n";
pub const DIR_FILE_NAME_SIZE_WARNING      = "\"{s}\" is larger than {d} characters";

pub const DIRECTORIES_TOTAL               = "{d} directory\n";
pub const DIRECTORIES_TOTALS              = "{d} directories\n";

pub const DUPLICATE_CHARS_FILES_CHECK     = "\"{s}\" has a duplicate character \"{c}\"";
pub const DUPLICATE_CHARS_FILES_CHECK_EXT = "\"{s}\" has a duplicate extension \"{s}\"";
pub const DUPLICATE_CHARS_FILES_HEADER    = "\n\tLooking for duplicate characters...\n";
pub const DUPLICATE_CHARS_FILES_TOTAL     = "{d} item with duplicate characters\n";
pub const DUPLICATE_CHARS_FILES_TOTALS    = "{d} items with duplicate characters\n";

pub const DUPLICATE_FILES_HEADER          = "\n\tLooking for duplicate files...\n";

pub const DUPLICATE_REMOVE_FILES          = "Removing";

pub const FILES_NEWER_MTIME_HEADER        = "\n\tLooking for files with newer modified time...\n";
pub const FILES_OLDER_MTIME_HEADER        = "\n\tLooking for files with older modified time...\n";
pub const FILES_TIME_FOUND                = "\"{s}\"";

pub const FILES_TOTAL                     = "{d} file\n";
pub const FILES_TOTALS                    = "{d} files\n";

pub const LINKS_SHORTCUTS_HEADER          = "\n\tLooking for links and shortcuts...\n";
pub const LINKS_SHORTCUTS_TOTAL           = "{d} link/shortcut\n";
pub const LINKS_SHORTCUTS_TOTALS          = "{d} links/shortcuts\n";
pub const LINKS_SHORTCUTS_WARNING         = "\"{s}\" is not portable";
pub const LINKS_SHORTCUTS_ERROR           = "\"{s}\" target not found";

pub const EMPTY_DIRECTORIES_HEADER        = "\n\tLooking for empty directories...\n";
pub const EMPTY_DIRECTORIES_WARNING       = "\"{s}\" is empty";

pub const EMPTY_FILES_HEADER              = "\n\tLooking for empty files...\n";
pub const EMPTY_FILES_WARNING             = "\"{s}\" is empty";

pub const FULL_PATH_SIZE_HEADER           = "\n\tLooking for large paths...\n";
pub const FULL_PATH_SIZE_TOTAL            = "{d} path found\n";
pub const FULL_PATH_SIZE_TOTALS           = "{d} paths found\n";
pub const FULL_PATH_SIZE_WARNING          = "Path \"{s}\" is larger than {d} characters";

pub const INTEGRITY_FILES_HEADER          = "\n\tChecking files integrity...\n";
pub const INTEGRITY_FILES_TOTAL           = "{d} hash processed\n";
pub const INTEGRITY_FILES_TOTALS          = "{d} hashes processed\n";
pub const INTEGRITY_FILES_ERROR           = "\"{s}\" has a different {s} hash";
pub const INTEGRITY_FILES_ERROR_CHAR      = "\"{s}\" has a invalid character in hash";
pub const INTEGRITY_FILES_OK              = "\"{s}\" {s} verified";
pub const INTEGRITY_FILES_CHECK           = "\"{s}\" {s} hash created";

pub const LARGE_FILES_HEADER              = "\n\tLooking for large files...\n";
pub const LARGE_FILES_WARNING             = "File \"{s}\" is larger than {d} bytes";

pub const LAST_ACCESS_HEADER              = "\n\tLooking for files accessed a long time ago...\n";
pub const LAST_ACCESS_WARNING             = "\"{s}\" last access was {d} ns ago";

pub const LEGACY_FILES_HEADER             = "\n\tLooking for legacy files...\n";
pub const LEGACY_FILES_WARNING            = "\"{s}\" has a legacy format \"{s}\"";

pub const MAGIC_NUMBERS_ERROR             = "\"{s}\" has a wrong magic number";
pub const MAGIC_NUMBERS_HEADER            = "\n\tLooking for files with wrong magic numbers...\n";

pub const MANY_ITEMS_DIRECTORIES_HEADER   = "\n\tLooking for many items directories...\n";
pub const MANY_ITEMS_DIRECTORIES_WARNING  = "\"{s}\" has more than {d} items";

pub const NO_EXTENSION_CHECK              = "Format of \"{s}\" could be \"{s}\"";
pub const NO_EXTENSION_HEADER             = "\n\tLooking for files with no extension...\n";
pub const NO_EXTENSION_WARNING            = "Format of \"{s}\" not found";

pub const ONE_ITEM_DIRECTORIES_HEADER     = "\n\tLooking for one item directories...\n";
pub const ONE_ITEM_DIRECTORIES_WARNING    = "\"{s}\" has one item";

pub const PARSE_JSON_FILES_ERROR          = "Can't parse \"{s}\"";
pub const PARSE_JSON_FILES_HEADER         = "\n\tLooking for errors in JSON files...\n";
pub const PARSE_JSON_FILES_TOTAL          = "{d} error found\n";
pub const PARSE_JSON_FILES_TOTALS         = "{d} errors found\n";

pub const TEMPORARY_FILES_HEADER          = "\n\tLooking for temporary files...\n";
pub const TEMPORARY_FILES_WARNING         = "\"{s}\" is a temporary file";

pub const UNPORTABLE_CHARS_WARNING        = "\"{s}\" has an unportable character";
pub const UNPORTABLE_CHARS_HEADER         = "\n\tLooking for unportable characters...\n";
pub const UNPORTABLE_CHARS_TOTAL          = "{d} item with unportable characters\n";
pub const UNPORTABLE_CHARS_TOTALS         = "{d} items with unportable characters\n";

pub const WRONG_DATES_HEADER              = "\n\tLooking for wrong date files...\n";
pub const WRONG_DATES_WARNING             = "File \"{s}\" has a date in the future";

/// System messages
pub const CHECK_MESSAGE                   = "\n\t\t CHECK  ";
pub const ERROR_MESSAGE                   = "\n\t\t ERROR  ";
pub const FOUND_MESSAGE                   = "\n\t\t FOUND  ";
pub const OK_MESSAGE                      = "OK";
pub const OK_MESSAGE_FILE                 = "\n\t\t   OK   ";
pub const QUIT_MESSAGE                    = "\n\nPress enter to quit";
pub const REMOVING_MESSAGE                = "\n\t\tREMOVING ";
pub const TOTAL_MESSAGE                   = "\n\n\t\t Total:\n\t\t\t";
pub const WARNING_MESSAGE                 = "\n\t\tWARNING ";

pub const ERROR_ACCESS_DENIED_PATH        = "\"{s}\": access denied";
pub const ERROR_ALLOC_MEM                 = "Failed to allocate memory for path \"{s}\": {}\n";
pub const ERROR_APPEND_PATH               = "Failed to append path to list: \"{}\"\n";
pub const ERROR_COMMAND_NOT_FOUND         = "Command \"{s}\" not found\n";
pub const ERROR_CONFIG_FILE               = "\n\tERROR: config.json already exists\n\n";
pub const ERROR_CONFIG_FILE_PARSE         = "\t\tFailed to parse config.json\n\n\n";
pub const ERROR_FILE_BUSY                 = "\"{s}\" is busy";
pub const ERROR_HASH_FILE                 = "Failed to hash file \"{s}\": {}\n";
pub const ERROR_INPUT_DIRECTORY           = "Can't read input directory";
pub const ERROR_INSERT_HASHMAP            = "Failed to insert into hash map: \"{}\"\n";
pub const ERROR_READING_FILE              = "\"{s}\" is unreadable";
pub const ERROR_STREAM_TOO_LONG           = "\"{s}\" is bigger than buffer";
