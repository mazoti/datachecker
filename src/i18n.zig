//! UTF-8 strings for english language
//!
//! Copyright © 2025-present Marcos Mazoti

/// Spacing constant for alignment - matches the largest string size in output
pub const ALIGNED_OK_SPACES: u32 = 49;

pub const HEADER = "\n🔬\x1b[38;5;255m DataChecker v2.2 by Marcos Mazoti" ++
    " - https://mazoti.github.io/datachecker\x1b[0m\n\n\n";

pub const HELP =
\\Usage:
\\        datachecker config (creates config.json file with default configuration)
\\
\\        datachecker <folder> or
\\        datachecker <folder> 2> results.txt (redirects outputs to text file)
\\
\\
;

pub const BYTES_TOTAL                      = "{d} byte\n";
pub const BYTES_TOTALS                     = "{d} bytes\n";

pub const CONFIG_MESSAGE                   = "\n\tLoading \"config.json\"...\n";
pub const CONFIG_MESSAGE_CREATE            = "\n\tCreating \"config.json\"...\n";
pub const CONFIG_MESSAGE_DEFAULT           = "\n\tLoading default configuration...\n";
pub const CONFIG_MESSAGE_WARNING           = "\"config.json\" could not be parsed, using default values\n";

pub const COMPRESSED_FILES_CHECK           = "\"{s}\" has an uncommon compression method";
pub const COMPRESSED_FILES_HEADER          = "\n\tLooking for compressed files...\n";
pub const COMPRESSED_FILES_WARNING         = "\"{s}\" compression could be improved";

pub const CONFIDENTIAL_FILES_HEADER        = "\n\tLooking for confidential files...\n";
pub const CONFIDENTIAL_FILES_WARNING       = "\"{s}\" has confidential data";

pub const DIR_FILE_NAME_SIZE_HEADER        = "\n\tLooking for large names...\n";
pub const DIR_FILE_NAME_SIZE_TOTAL         = "{d} file or directory\n";
pub const DIR_FILE_NAME_SIZE_TOTALS        = "{d} files or directories\n";
pub const DIR_FILE_NAME_SIZE_WARNING       = "\"{s}\" is larger than {d} characters";

pub const DUPLICATE_CHARS_FILES_CHECK      = "\"{s}\" has a duplicate character \"{c}\"";
pub const DUPLICATE_CHARS_FILES_HEADER     = "\n\tLooking for duplicate characters...\n";
pub const DUPLICATE_CHARS_FILES_TOTAL      = "{d} item with duplicate characters\n";
pub const DUPLICATE_CHARS_FILES_TOTALS     = "{d} items with duplicate characters\n";

pub const DUPLICATE_FILES_HEADER           = "\n\tLooking for duplicate files...\n";
pub const DUPLICATE_FILES_TOTAL            = "{d} byte wasted\n";
pub const DUPLICATE_FILES_TOTALS           = "{d} bytes wasted\n";

pub const FILES_TOTAL                      = "{d} file\n";
pub const FILES_TOTALS                     = "{d} files\n";

pub const LINKS_SHORTCUTS_HEADER           = "\n\tLooking for links and shortcuts...\n";
pub const LINKS_SHORTCUTS_TOTAL            = "{d} link/shortcut found\n";
pub const LINKS_SHORTCUTS_TOTALS           = "{d} links/shortcuts found\n";
pub const LINKS_SHORTCUTS_WARNING          = "\"{s}\" is not portable";
pub const LINKS_SHORTCUTS_ERROR            = "\"{s}\" target not found";

pub const EMPTY_DIRECTORIES_HEADER         = "\n\tLooking for empty directories...\n";
pub const EMPTY_DIRECTORIES_TOTAL          = "{d} empty directory\n";
pub const EMPTY_DIRECTORIES_TOTALS         = "{d} empty directories\n";
pub const EMPTY_DIRECTORIES_WARNING        = "\"{s}\" is empty";

pub const EMPTY_FILES_HEADER               = "\n\tLooking for empty files...\n";
pub const EMPTY_FILES_TOTAL                = "{d} empty file\n";
pub const EMPTY_FILES_TOTALS               = "{d} empty files\n";
pub const EMPTY_FILES_WARNING              = "\"{s}\" is empty";

pub const FULL_PATH_SIZE_HEADER            = "\n\tLooking for large paths...\n";
pub const FULL_PATH_SIZE_TOTAL             = "{d} path found\n";
pub const FULL_PATH_SIZE_TOTALS            = "{d} paths found\n";
pub const FULL_PATH_SIZE_WARNING           = "Path \"{s}\" is larger than {d} characters";

pub const INTEGRITY_FILES_HEADER           = "\n\tChecking files integrity...\n";
pub const INTEGRITY_FILES_TOTAL            = "{d} hash processed\n";
pub const INTEGRITY_FILES_TOTALS           = "{d} hashes processed\n";
pub const INTEGRITY_FILES_ERROR            = "\"{s}\" has a different {s} hash";
pub const INTEGRITY_FILES_OK               = "\"{s}\" {s} verified";
pub const INTEGRITY_FILES_CHECK            = "\"{s}\" {s} hash created";

pub const LARGE_FILES_HEADER               = "\n\tLooking for large files...\n";
pub const LARGE_FILES_TOTAL                = "{d} large file\n";
pub const LARGE_FILES_TOTALS               = "{d} large files\n";
pub const LARGE_FILES_WARNING              = "File \"{s}\" is larger than {d} bytes";

pub const LAST_ACCESS_HEADER               = "\n\tLooking for files accessed a long time ago...\n";
pub const LAST_ACCESS_WARNING              = "\"{s}\" last access was {d} ns ago";

pub const LEGACY_FILES_HEADER              = "\n\tLooking for legacy files...\n";
pub const LEGACY_FILES_TOTAL               = "{d} file found\n";
pub const LEGACY_FILES_TOTALS              = "{d} files found\n";
pub const LEGACY_FILES_WARNING             = "\"{s}\" has a legacy format \"{s}\"";

pub const MAGIC_NUMBERS_ERROR              = "\"{s}\" has a wrong magic number";
pub const MAGIC_NUMBERS_HEADER             = "\n\tLooking for files with wrong magic numbers...\n";

pub const MANY_ITEMS_DIRECTORIES_HEADER    = "\n\tLooking for many items directories...\n";
pub const MANY_ITEMS_DIRECTORIES_TOTAL     = "{d} directory with many items\n";
pub const MANY_ITEMS_DIRECTORIES_TOTALS    = "{d} directories with many items\n";
pub const MANY_ITEMS_DIRECTORIES_WARNING   = "\"{s}\" has more than {d} items";

pub const NO_EXTENSION_CHECK               = "Format of \"{s}\" could be \"{s}\"";
pub const NO_EXTENSION_HEADER              = "\n\tLooking for files with no extension...\n";
pub const NO_EXTENSION_WARNING             = "Format of \"{s}\" not found";

pub const ONE_ITEM_DIRECTORIES_HEADER      = "\n\tLooking for one item directories...\n";
pub const ONE_ITEM_DIRECTORIES_TOTAL       = "{d} directory with one item\n";
pub const ONE_ITEM_DIRECTORIES_TOTALS      = "{d} directories with one item\n";
pub const ONE_ITEM_DIRECTORIES_WARNING     = "\"{s}\" has one item";

pub const PARSE_JSON_FILES_ERROR           = "Can't parse \"{s}\"";
pub const PARSE_JSON_FILES_HEADER          = "\n\tLooking for errors in JSON files...\n";
pub const PARSE_JSON_FILES_TOTAL           = "{d} error found\n";
pub const PARSE_JSON_FILES_TOTALS          = "{d} errors found\n";

pub const TEMPORARY_FILES_HEADER           = "\n\tLooking for temporary files...\n";
pub const TEMPORARY_FILES_WARNING          = "\"{s}\" is a temporary file";

pub const UNPORTABLE_CHARS_WARNING         = "\"{s}\" has an unportable character";
pub const UNPORTABLE_CHARS_HEADER          = "\n\tLooking for unportable characters...\n";
pub const UNPORTABLE_CHARS_TOTAL           = "{d} item with unportable characters\n";
pub const UNPORTABLE_CHARS_TOTALS          = "{d} items with unportable characters\n";

pub const WRONG_DATES_HEADER               = "\n\tLooking for wrong date files...\n";
pub const WRONG_DATES_WARNING              = "File \"{s}\" has a date in the future";

/// System messages
pub const CHECK_MESSAGE                    = "\n\t\t CHECK  ";
pub const ERROR_MESSAGE                    = "\n\t\t ERROR  ";
pub const OK_MESSAGE                       = "OK";
pub const OK_MESSAGE_FILE                  = "\n\t\t   OK   ";
pub const QUIT_MESSAGE                     = "\n\nPress enter to quit";
pub const TOTAL_MESSAGE                    = "\n\n\t\t Total:\n\t\t\t";
pub const WARNING_MESSAGE                  = "\n\t\tWARNING ";

pub const ERROR_ACCESS_DENIED              = "Access denied: root or admin permission needed\n";
pub const ERROR_ALLOC_MEM                  = "Failed to allocate memory for path \"{s}\": {}\n";
pub const ERROR_APPEND_PATH                = "Failed to append path to list: \"{}\"\n";
pub const ERROR_CONFIG_FILE                = "\"config.json\" already exists";
pub const ERROR_HASH_FILE                  = "Failed to hash file \"{s}\": {}\n";
pub const ERROR_INPUT_DIRECTORY            = "Can't read input directory";
pub const ERROR_INSERT_HASHMAP             = "Failed to insert into hash map: \"{}\"\n";
pub const ERROR_READING_FILE               = "\"{s}\" is unreadable";
pub const ERROR_STREAM_TOO_LONG            = "\"{s}\" is bigger than buffer";
