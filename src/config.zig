//! Compile time features and JSON configuration values
//!
//! Copyright © 2025-present Marcos Mazoti

const std  = @import("std");

/// Version in the banner and JSON output
pub const COMPTIME_VERSION:                     []const u8 = "0.3.1";

/// Configuration file, looked up in the current working directory
pub const COMPTIME_CONFIG_FILE_NAME:            []const u8 = "config.json";

/// Compile-time flags to determine which features are compiled into the binary
pub const COMPTIME_IO_BUFFER_SIZE:                   usize = 16384;
pub const COMPTIME_IGNORE_PATH_PATTERNS:              bool = true;
pub const COMPTIME_STDOUT:                            bool = true;
    pub const COMPTIME_EMOJI_COLOR:                   bool = true;

// -----------------------------------------------------------------------------
// Compile-time feature flags.
//
// Setting a flag to `false` removes the feature from the binary: its help text
// (see `HELP`) and its result storage (see `Output`) disappear with it.
// -----------------------------------------------------------------------------

pub const COMPTIME_COMPRESSED_FILES:                  bool = true;
pub const COMPTIME_CONFIDENTIAL_FILES:                bool = true;
pub const COMPTIME_DEBUG_INFO:                        bool = true;
pub const COMPTIME_DIRECTORY_FILE_NAME_SIZE:          bool = true;
pub const COMPTIME_DUPLICATE_CHARS_FILES:             bool = true;
pub const COMPTIME_DUPLICATE_FILES:                   bool = true;
pub const COMPTIME_DUPLICATE_FILES_PARALLEL:          bool = true;
pub const COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE:   bool = true;
pub const COMPTIME_DUPLICATE_FILES_REMOVE:            bool = true;
pub const COMPTIME_EMPTY_FILES:                       bool = true;
pub const COMPTIME_EMPTY_FILES_REMOVE:                bool = true;
pub const COMPTIME_END_OF_LINE:                       bool = true;
pub const COMPTIME_EMPTY_DIRECTORIES:                 bool = true;
pub const COMPTIME_EMPTY_DIRECTORIES_REMOVE:          bool = true;
pub const COMPTIME_FILES_NEWER_ATIME:                 bool = true;
pub const COMPTIME_FILES_NEWER_CTIME:                 bool = true;
pub const COMPTIME_FILES_NEWER_MTIME:                 bool = true;
pub const COMPTIME_FILES_OLDER_ATIME:                 bool = true;
pub const COMPTIME_FILES_OLDER_CTIME:                 bool = true;
pub const COMPTIME_FILES_OLDER_MTIME:                 bool = true;
pub const COMPTIME_FULL_PATH_SIZE:                    bool = true;
pub const COMPTIME_INTEGRITY_FILES_PARALLEL:          bool = true;
pub const COMPTIME_INTEGRITY_FILES:                   bool = true;
pub const COMPTIME_JSON_OUTPUT:                       bool = true;
    pub const COMPTIME_JSON_OUTPUT_COMPRESSED:        bool = true;
pub const COMPTIME_LARGE_FILES:                       bool = true;
pub const COMPTIME_LAST_ACCESS_FILES:                 bool = true;
pub const COMPTIME_LEGACY_FILES:                      bool = true;
pub const COMPTIME_LINKS_SHORTCUTS:                   bool = true;
pub const COMPTIME_LINKS_SHORTCUTS_REMOVE:            bool = true;
pub const COMPTIME_MAGIC_NUMBERS:                     bool = true;
pub const COMPTIME_MANY_ITEMS_DIRECTORIES:            bool = true;
pub const COMPTIME_NO_EXTENSION:                      bool = true;
pub const COMPTIME_NONPORTABLE_CHARS:                 bool = true;
pub const COMPTIME_ONE_ITEM_DIRECTORIES:              bool = true;
pub const COMPTIME_OWNERSHIPS_PERMISSIONS:            bool = false;
pub const COMPTIME_PARSE_FILES:                       bool = true;
pub const COMPTIME_TEMPORARY_FILES:                   bool = true;
pub const COMPTIME_TEMPORARY_FILES_REMOVE:            bool = true;
pub const COMPTIME_UTF8_ENCODING:                     bool = true;
pub const COMPTIME_WRONG_DATES:                       bool = true;

/// Configuration structure that holds runtime-configurable parameters
pub const Config = struct {
    INPUT_FOLDER:                 []const u8   = ".",
    OUTPUT_FILE:                  []const u8   = "",
        OUTPUT_FILE_COMPRESSED:   bool         = true,
    BUFFER_SIZE:                  usize        = 65536,
    ENABLE_CACHE:                 bool         = true,
    ENTER_TO_QUIT:                bool         = false,
    MAX_JOBS:                     usize        = 0, // Uses maximum number of threads

    // Runtime toggles for each check type (can be overridden by config.json)
    COMPRESSED_FILES:             bool         = true,
    CONFIDENTIAL_FILES:           bool         = true,
        PATTERNS:                 [][]const u8 = &[_][]const u8{},
        PATTERN_BASE64_BYTES:     [][]const u8 = &[_][]const u8{},
    DEBUG_INFO:                   bool         = true,
    DIRECTORY_FILE_NAME_SIZE:     bool         = true,
        MAX_DIR_FILE_NAME_SIZE:   u32          = 200,
    DUPLICATE_CHARS_FILES:        bool         = true,
    DUPLICATE_FILES_PARALLEL:     bool         = true,
    DUPLICATE_FILES:              bool         = false,
    EMPTY_FILES:                  bool         = true,
    EMPTY_DIRECTORIES:            bool         = true,
    END_OF_LINE:                  bool         = true,
        EOL_CHARS:                []const u8   = "\n",
    FILES_NEWER_ATIME:            bool         = true,
    FILES_NEWER_CTIME:            bool         = true,
    FILES_NEWER_MTIME:            bool         = true,
    FILES_OLDER_ATIME:            bool         = true,
    FILES_OLDER_CTIME:            bool         = true,
    FILES_OLDER_MTIME:            bool         = true,
        FILE_TIME:                u64          = 0,
    FULL_PATH_SIZE:               bool         = true, // Checks for deeply nested paths
        MAX_FULL_PATH_SIZE:       u32          = 1024,
    IGNORE_PATH_PATTERNS:         bool         = true,
        IGNORE_PATTERNS:          [][]const u8 = &[_][]const u8{},
    INTEGRITY_FILES_PARALLEL:     bool         = true,
    INTEGRITY_FILES:              bool         = false,
    LARGE_FILES:                  bool         = true,
        LARGE_FILE_SIZE:          u64          = 107374182400, // 100 GiB
    LAST_ACCESS_FILES:            bool         = true,
        LAST_ACCESS_TIME:         u64          = 31536000000000000, // ~1 year in nanoseconds
    LEGACY_FILES:                 bool         = true,
    LINKS_SHORTCUTS:              bool         = true,
    MAGIC_NUMBERS:                bool         = true, // Validates file signatures
    MANY_ITEMS_DIRECTORIES:       bool         = true,
        MAX_ITEMS_DIRECTORIES:    u32          = 10000,
    NO_EXTENSION:                 bool         = true,
    NONPORTABLE_CHARS:            bool         = true,
    ONE_ITEM_DIRECTORIES:         bool         = true, // Detects unnecessary directory nesting
    OWNERSHIPS_PERMISSIONS:       bool         = true,
    PARSE_FILES:                  bool         = true,
    TEMPORARY_FILES:              bool         = true, // Looks for for .tmp, .temp, ~ and .swp
    UTF8_ENCODING:                bool         = true,
    WRONG_DATES:                  bool         = true,
};

pub const DEFAULT_JSON_CONFIG: []const u8 =
    \\{
    \\    "INPUT_FOLDER":                    ".",
    \\    "OUTPUT_FILE":                     "",
    \\        "OUTPUT_FILE_COMPRESSED":      false,
    \\    "BUFFER_SIZE":                     65536,
    \\    "ENABLE_CACHE":                    true,
    \\    "ENTER_TO_QUIT":                   false,
    \\    "MAX_JOBS":                        0,
    \\    "COMPRESSED_FILES":                true,
    \\    "CONFIDENTIAL_FILES":              true,
    \\        "PATTERNS":                    [
    \\            "access code",                         "Access code",                         "Access Code",                       "ACCESS CODE",
    \\            "account number",                      "Account number",                      "Account Number",                    "ACCOUNT NUMBER",
    \\            "api key",                             "API Key",                             "API key",                           "API KEY",
    \\            "attorney eyes only",                  "Attorney eyes only",                  "ATTORNEY EYES ONLY",
    \\            "attorney-client",                     "ATTORNEY-CLIENT",
    \\            "authentication",                      "Authentication",                      "AUTHENTICATION",
    \\            "bank account",                        "Bank Account",                        "BANK ACCOUNT",
    \\            "burn after reading",                  "Burn after reading",                  "BURN AFTER READING",
    \\            "card number",                         "Card number",                         "Card Number",                       "CARD NUMBER",
    \\            "classified",                          "Classified",                          "CLASSIFIED",
    \\            "clearance level",                     "Clearance level",                     "Clearance Level",                   "CLEARANCE LEVEL",
    \\            "compensation",                        "Compensation",                        "COMPENSATION",
    \\            "confidential",                        "Confidential",                        "CONFIDENTIAL",
    \\            "contract terms",                      "Contract terms",                      "Contract Terms",                    "CONTRACT TERMS",
    \\            "controlled unclassified information", "Controlled Unclassified Information", "CUI",
    \\            "credentials",                         "Credentials",                         "CREDENTIALS",
    \\            "credit card",                         "Credit card",                         "Credit Card",                       "CREDIT CARD",
    \\            "customer list",                       "Customer List",                       "CUSTOMER LIST",
    \\            "card verification value",             "Card Verification Value",             "CARD VERIFICATION VALUE",           "CVV",
    \\            "date of birth",                       "Date of Birth",                       "DATE OF BIRTH",                     "DOB",
    \\            "delete this email",                   "Delete this email",                   "DELETE THIS EMAIL",
    \\            "deposition",                          "Deposition",                          "DEPOSITION",
    \\            "destroy after",                       "Destroy After",                       "DESTROY AFTER",
    \\            "do not distribute",                   "Do not distribute",                   "DO NOT DISTRIBUTE",                 "DND",
    \\            "don't forward",                       "Don't forward",                       "DON'T FORWARD",
    \\            "driver's license",                    "Driver's license",                    "Driver's License",                  "DRIVER'S LICENSE",
    \\            "employer identification number",      "Employer Identification Number",      "EMPLOYER IDENTIFICATION NUMBER",    "EIN",
    \\            "encryption key",                      "Encryption Key",                      "ENCRYPTION KEY",
    \\            "for internal use only",               "For internal use only",               "FOR INTERNAL USE ONLY",
    \\            "for official use only",               "For Official Use Only",               "FOR OFFICIAL USE ONLY",             "FOUO",
    \\            "health record",                       "Health record",                       "Health Record",                     "HEALTH RECORD",
    \\            "home address",                        "Home address",                        "Home Address",                      "HOME ADDRESS",
    \\            "international bank account number",   "International Bank Account Number",   "INTERNATIONAL BANK ACCOUNT NUMBER", "IBAN",
    \\            "insider trading",                     "Insider trading",                     "Insider Trading",                   "INSIDER TRADING",
    \\            "internal only",                       "Internal only",                       "Internal Only",                     "INTERNAL ONLY",
    \\            "keep this quiet",                     "Keep this quiet",                     "Keep This Quiet",                   "KEEP THIS QUIET",
    \\            "legal hold",                          "Legal hold",                          "Legal Hold",                        "LEGAL HOLD",
    \\            "loan application",                    "Loan application",                    "Loan Application",                  "LOAN APPLICATION",
    \\            "material non-public",                 "Material non-public",                 "MATERIAL NON-PUBLIC",               "MNPI",
    \\            "medical record",                      "Medical record",                      "Medical Record",                    "MEDICAL RECORD",
    \\            "medical history",                     "Medical history",                     "Medical History",                   "MEDICAL HISTORY",
    \\            "motion in limine",                    "Motion in limine",                    "Motion In Limine",                  "MOTION IN LIMINE",
    \\            "national ID",                         "National ID",                         "NATIONAL ID",
    \\            "non-disclosure",                      "Non-disclosure",                      "NON-DISCLOSURE",                    "NDA",
    \\            "not for distribution",                "Not for distribution",                "Not For Distribution",              "NOT FOR DISTRIBUTION",
    \\            "off the record",                      "Off the record",                      "Off The Record",                    "OFF THE RECORD",
    \\            "passphrase",                          "Passphrase",                          "PASSPHRASE",
    \\            "password",                            "Password",                            "PASSWORD",
    \\            "patent pending",                      "Patent pending",                      "Patent Pending",                    "PATENT PENDING",
    \\            "patient ID",                          "Patient ID",                          "PATIENT ID",
    \\            "personal email",                      "Personal email",                      "Personal Email",                    "PERSONAL EMAIL",
    \\            "phone number",                        "Phone number",                        "Phone Number",                      "PHONE NUMBER",
    \\            "personal identification number",      "Personal Identification Number",      "PERSONAL IDENTIFICATION NUMBER",    "PIN",
    \\            "private key",                         "Private key",                         "Private Key",                       "PRIVATE KEY",
    \\            "private repository",                  "Private repository",                  "Private Repository",                "PRIVATE REPOSITORY",
    \\            "protected health information",        "Protected health information",        "Protected Health Information",      "PROTECTED HEALTH INFORMATION",
    \\            "routing number",                      "Routing number",                      "Routing Number",                    "ROUTING NUMBER",
    \\            "secret key",                          "Secret key",                          "Secret Key",                        "SECRET KEY",
    \\            "SSH key",                             "SSH Key",                             "SSH KEY",
    \\            "social security number",              "Social Security Number",              "SOCIAL SECURITY NUMBER",            "SSN",
    \\            "swift",                               "SWIFT",
    \\            "tax ID",                              "Tax ID",                              "TAX ID",
    \\            "top secret",                          "Top secret",                          "Top Secret",                        "TOP SECRET",
    \\            "trade secret",                        "Trade secret",                        "Trade Secret",                      "TRADE SECRET",
    \\            "under seal",                          "Under seal",                          "Under Seal",                        "UNDER SEAL"
    \\                                       ],
    \\        "PATTERN_BASE64_BYTES":        [
    \\            "LS0tLS1CRUdJTiBEU0EgUFJJVkFURSBLRVktLS0tLQ==",
    \\            "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0t",
    \\            "LS0tLS1CRUdJTiBFTkNSWVBURUQgUFJJVkFURSBLRVktLS0tLQ==",
    \\            "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0=",
    \\            "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t",
    \\            "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ=="
    \\                                       ],
    \\    "DEBUG_INFO":                      true,
    \\    "DIRECTORY_FILE_NAME_SIZE":        true,
    \\        "MAX_DIR_FILE_NAME_SIZE":      200,
    \\    "DUPLICATE_CHARS_FILES":           true,
    \\    "DUPLICATE_FILES_PARALLEL":        true,
    \\    "DUPLICATE_FILES":                 false,
    \\    "EMPTY_FILES":                     true,
    \\    "EMPTY_DIRECTORIES":               true,
    \\    "END_OF_LINE":                     true,
    \\        "EOL_CHARS":                   "\n",
    \\    "FILES_NEWER_ATIME":               true,
    \\    "FILES_NEWER_CTIME":               true,
    \\    "FILES_NEWER_MTIME":               true,
    \\    "FILES_OLDER_ATIME":               true,
    \\    "FILES_OLDER_CTIME":               true,
    \\    "FILES_OLDER_MTIME":               true,
    \\        "FILE_TIME":                   0,
    \\    "FULL_PATH_SIZE":                  true,
    \\        "MAX_FULL_PATH_SIZE":          1024,
    \\    "IGNORE_PATH_PATTERNS":            true,
    \\        "IGNORE_PATTERNS":             [".git", ".zig-cache", ".gitignore", "zig-out", ".svn", ".hg", "__pycache__", "node_modules" ],
    \\    "INTEGRITY_FILES_PARALLEL":        true,
    \\    "INTEGRITY_FILES":                 false,
    \\    "LARGE_FILES":                     true,
    \\        "LARGE_FILE_SIZE":             107374182400,
    \\    "LAST_ACCESS_FILES":               true,
    \\        "LAST_ACCESS_TIME":            31536000000000000,
    \\    "LEGACY_FILES":                    true,
    \\    "LINKS_SHORTCUTS":                 true,
    \\    "MAGIC_NUMBERS":                   true,
    \\    "MANY_ITEMS_DIRECTORIES":          true,
    \\        "MAX_ITEMS_DIRECTORIES":       10000,
    \\    "NO_EXTENSION":                    true,
    \\    "NONPORTABLE_CHARS":               true,
    \\    "ONE_ITEM_DIRECTORIES":            true,
    \\    "OWNERSHIPS_PERMISSIONS":          true,
    \\    "PARSE_FILES":                     true,
    \\    "TEMPORARY_FILES":                 true,
    \\    "UTF8_ENCODING":                   true,
    \\    "WRONG_DATES":                     true
    \\}
    \\
;

pub fn deinit(config_file: *[]const u8, config_parsed: *std.json.Parsed(Config), alloc: std.mem.Allocator, must_clean: bool) void {
    config_parsed.*.deinit();
    if (must_clean) alloc.free(config_file.*);
}

pub const Status = enum { CHECK, ERROR, FOUND, OK, REMOVED, WARNING };

pub const DuplicateResult = struct {
    file_size_bytes:  u64,
    files_duplicated: std.ArrayList([]u8),
};

pub const FileResult = struct {
    status:  Status,
    message: []const u8,
};

pub const Output = struct {
    version: []const u8,

    compressed_files:              if (COMPTIME_COMPRESSED_FILES)             std.ArrayList(FileResult) else void,
    confidential_files:            if (COMPTIME_CONFIDENTIAL_FILES)           std.ArrayList(FileResult) else void,
    debug_information:             if (COMPTIME_DEBUG_INFO)                   std.ArrayList(FileResult) else void,
    directory_file_name_size:      if (COMPTIME_DIRECTORY_FILE_NAME_SIZE)     std.ArrayList(FileResult) else void,
    duplicate_chars_files:         if (COMPTIME_DUPLICATE_CHARS_FILES)        std.ArrayList(FileResult) else void,
    duplicate_files:               if (COMPTIME_DUPLICATE_FILES or COMPTIME_DUPLICATE_FILES_PARALLEL)   std.ArrayList(DuplicateResult) else void,
    duplicate_files_remove:        if (COMPTIME_DUPLICATE_FILES_REMOVE or COMPTIME_DUPLICATE_FILES_PARALLEL_REMOVE) std.ArrayList(FileResult)      else void,
    empty_files:                   if (COMPTIME_EMPTY_FILES)                  std.ArrayList(FileResult) else void,
    empty_files_remove:            if (COMPTIME_EMPTY_FILES_REMOVE)           std.ArrayList(FileResult) else void,
    end_of_line:                   if (COMPTIME_END_OF_LINE)                  std.ArrayList(FileResult) else void,
    empty_directories:             if (COMPTIME_EMPTY_DIRECTORIES)            std.ArrayList(FileResult) else void,
    empty_directories_remove:      if (COMPTIME_EMPTY_DIRECTORIES_REMOVE)     std.ArrayList(FileResult) else void,
    files_newer_atime:             if (COMPTIME_FILES_NEWER_ATIME)            std.ArrayList(FileResult) else void,
    files_newer_ctime:             if (COMPTIME_FILES_NEWER_CTIME)            std.ArrayList(FileResult) else void,
    files_newer_mtime:             if (COMPTIME_FILES_NEWER_MTIME)            std.ArrayList(FileResult) else void,
    files_older_atime:             if (COMPTIME_FILES_OLDER_ATIME)            std.ArrayList(FileResult) else void,
    files_older_ctime:             if (COMPTIME_FILES_OLDER_CTIME)            std.ArrayList(FileResult) else void,
    files_older_mtime:             if (COMPTIME_FILES_OLDER_MTIME)            std.ArrayList(FileResult) else void,
    full_path_size:                if (COMPTIME_FULL_PATH_SIZE)               std.ArrayList(FileResult) else void,
    integrity_files:               if (COMPTIME_INTEGRITY_FILES_PARALLEL or COMPTIME_INTEGRITY_FILES) std.ArrayList(FileResult) else void,
    large_files:                   if (COMPTIME_LARGE_FILES)                  std.ArrayList(FileResult) else void,
    last_access_files:             if (COMPTIME_LAST_ACCESS_FILES)            std.ArrayList(FileResult) else void,
    legacy_files:                  if (COMPTIME_LEGACY_FILES)                 std.ArrayList(FileResult) else void,
    links_shortcuts:               if (COMPTIME_LINKS_SHORTCUTS)              std.ArrayList(FileResult) else void,
    links_shortcuts_remove:        if (COMPTIME_LINKS_SHORTCUTS_REMOVE)       std.ArrayList(FileResult) else void,
    magic_numbers:                 if (COMPTIME_MAGIC_NUMBERS)                std.ArrayList(FileResult) else void,
    many_items_directories:        if (COMPTIME_MANY_ITEMS_DIRECTORIES)       std.ArrayList(FileResult) else void,
    no_extension:                  if (COMPTIME_NO_EXTENSION)                 std.ArrayList(FileResult) else void,
    nonportable_chars:             if (COMPTIME_NONPORTABLE_CHARS)            std.ArrayList(FileResult) else void,
    one_item_directories:          if (COMPTIME_ONE_ITEM_DIRECTORIES)         std.ArrayList(FileResult) else void,
    ownerships_permissions:        if (COMPTIME_OWNERSHIPS_PERMISSIONS)       std.ArrayList(FileResult) else void,
    parse_files:                   if (COMPTIME_PARSE_FILES)                  std.ArrayList(FileResult) else void,
    temporary_files:               if (COMPTIME_TEMPORARY_FILES)              std.ArrayList(FileResult) else void,
    temporary_files_remove:        if (COMPTIME_TEMPORARY_FILES_REMOVE)       std.ArrayList(FileResult) else void,
    utf8_encoding:                 if (COMPTIME_UTF8_ENCODING)                std.ArrayList(FileResult) else void,
    wrong_dates:                   if (COMPTIME_WRONG_DATES)                  std.ArrayList(FileResult) else void,
};

comptime {
    if (COMPTIME_EMOJI_COLOR and !COMPTIME_STDOUT)                 @compileError("COMPTIME_EMOJI_COLOR requires COMPTIME_STDOUT to be true");
    if (COMPTIME_JSON_OUTPUT and !COMPTIME_JSON_OUTPUT_COMPRESSED) @compileError("COMPTIME_JSON_OUTPUT requires COMPTIME_JSON_OUTPUT_COMPRESSED to be true");
    if (COMPTIME_IO_BUFFER_SIZE < 16384)                           @compileError("COMPTIME_IO_BUFFER_SIZE must be at least 16384");
}
