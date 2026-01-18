//! Compile time features and JSON configuration values
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");
const builtin = @import("builtin");

const i18n    = @import("i18n");

/// Compile-time feature flags to determine which checks are compiled into the binary
pub const IO_BUFFER_SIZE:                   usize = 16384;

pub const COMPTIME_DUPLICATE_FILES:          bool = true;
pub const COMPTIME_LINKS_SHORTCUTS:          bool = true;
pub const COMPTIME_INTEGRITY_FILES:          bool = true;
pub const COMPTIME_TEMPORARY_FILES:          bool = true;
pub const COMPTIME_CONFIDENTIAL_FILES:       bool = true;

pub const COMPTIME_COMPRESSED_FILES:         bool = true;
pub const COMPTIME_DUPLICATE_CHARS_FILES:    bool = true;
pub const COMPTIME_EMPTY_FILES:              bool = true;
pub const COMPTIME_LARGE_FILES:              bool = true;
pub const COMPTIME_LAST_ACCESS_FILES:        bool = true;
pub const COMPTIME_LEGACY_FILES:             bool = true;
pub const COMPTIME_MAGIC_NUMBERS:            bool = true;
pub const COMPTIME_NO_EXTENSION:             bool = true;
pub const COMPTIME_PARSE_JSON_FILES:         bool = true;
pub const COMPTIME_WRONG_DATES:              bool = true;

pub const COMPTIME_EMPTY_DIRECTORIES:        bool = true;
pub const COMPTIME_MANY_ITEMS_DIRECTORY:     bool = true;
pub const COMPTIME_ONE_ITEM_DIRECTORY:       bool = true;

pub const COMPTIME_DIRECTORY_FILE_NAME_SIZE: bool = true;
pub const COMPTIME_FULL_PATH_SIZE:           bool = true;
pub const COMPTIME_UNPORTABLE_CHARS:         bool = true;

/// Configuration structure that holds runtime-configurable parameters
pub const Config = struct {
    INPUT_FOLDER:                      []const u8 = "",
    BUFFER_SIZE:                            usize = 65536,
    COLOR:                                   bool = true,
    ENABLE_CACHE:                            bool = true,
    ENTER_TO_QUIT:                           bool = false,
    MAX_JOBS:                               usize = 0,                 // Uses maximum number of threads

    // Runtime toggles for each check type (can be overridden by config.json)
    DUPLICATE_FILES:                         bool = true,
        DUPLICATE_FILES_PARALLEL:            bool = true,
    LINKS_SHORTCUTS:                         bool = true,
    INTEGRITY_FILES:                         bool = true,
        INTEGRITY_FILES_PARALLEL:            bool = true,
    TEMPORARY_FILES:                         bool = true,              // Looks for for .tmp, .temp, ~ and .swp
    CONFIDENTIAL_FILES:                      bool = true,
        PATTERNS:                    [][]const u8 = &[_][]const u8{},
        PATTERN_BASE64_BYTES:        [][]const u8 = &[_][]const u8{},

    COMPRESSED_FILES:                        bool = true,
    DUPLICATE_CHARS_FILES:                   bool = true,
    EMPTY_FILES:                             bool = true,
    LARGE_FILES:                             bool = true,
        LARGE_FILE_SIZE:                      u64 = 107374182400,      // 100 GB
    LAST_ACCESS_FILES:                       bool = true,
        LAST_ACCESS_TIME:                     u64 = 31536000000000000, // ~1 year in nanoseconds
    LEGACY_FILES:                            bool = true,
    MAGIC_NUMBERS:                           bool = true,              // Validates file signatures
    NO_EXTENSION:                            bool = true,
    PARSE_JSON_FILES:                        bool = true,
    WRONG_DATES:                             bool = true,

    EMPTY_DIRECTORIES:                       bool = true,
    FULL_PATH_SIZE:                          bool = true,              // Checks for deeply nested paths
        MAX_FULL_PATH_SIZE:                   u32 = 1024,
    MANY_ITEMS_DIRECTORY:                    bool = true,
        MAX_ITEMS_DIRECTORY:                  u32 = 10000,
    ONE_ITEM_DIRECTORY:                      bool = true,              // Detects unnecessary directory nesting

    DIRECTORY_FILE_NAME_SIZE:                bool = true,
    MAX_DIR_FILE_NAME_SIZE:                   u32 = 200,
    UNPORTABLE_CHARS:                        bool = true,
};

pub const DEFAULT_JSON_CONFIG: []const u8 =
    \\{
    \\    "INPUT_FOLDER":                 ".",
    \\    "BUFFER_SIZE":                  65536,
    \\    "COLOR":                        true,
    \\    "ENABLE_CACHE":                 true,
    \\    "ENTER_TO_QUIT":                false,
    \\    "MAX_JOBS":                     0,
    \\
    \\    "DUPLICATE_FILES":              true,
    \\        "DUPLICATE_FILES_PARALLEL": true,
    \\    "LINKS_SHORTCUTS":              true,
    \\    "INTEGRITY_FILES":              true,
    \\        "INTEGRITY_FILES_PARALLEL": true,
    \\    "TEMPORARY_FILES":              true,
    \\    "CONFIDENTIAL_FILES":           true,
    \\        "PATTERNS":                 [
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
    \\            "date of birth",                       "Date of Birth",                       "DATA OF BIRTH",                     "DOB",
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
    \\                                    ],
    \\        "PATTERN_BASE64_BYTES":     [
    \\            "LS0tLS1CRUdJTiBEU0EgUFJJVkFURSBLRVktLS0tLQ==",
    \\            "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0t",
    \\            "LS0tLS1CRUdJTiBFTkNSWVBURUQgUFJJVkFURSBLRVktLS0tLQ==",
    \\            "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0=",
    \\            "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t",
    \\            "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ=="
    \\                                    ],
    \\
    \\    "COMPRESSED_FILES":             true,
    \\    "DUPLICATE_CHARS_FILES":        true,
    \\    "EMPTY_FILES":                  true,
    \\    "LARGE_FILES":                  true,
    \\        "LARGE_FILE_SIZE":          107374182400,
    \\    "LAST_ACCESS_FILES":            true,
    \\        "LAST_ACCESS_TIME":         31536000000000000,
    \\    "LEGACY_FILES":                 true,
    \\    "MAGIC_NUMBERS":                true,
    \\    "NO_EXTENSION":                 true,
    \\    "PARSE_JSON_FILES":             true,
    \\    "WRONG_DATES":                  true,
    \\
    \\    "EMPTY_DIRECTORIES":            true,
    \\    "MANY_ITEMS_DIRECTORY":         true,
    \\        "MAX_ITEMS_DIRECTORY":      10000,
    \\    "ONE_ITEM_DIRECTORY":           true,
    \\
    \\    "DIRECTORY_FILE_NAME_SIZE":     true,
    \\        "MAX_DIR_FILE_NAME_SIZE":   200,
    \\    "FULL_PATH_SIZE":               true,
    \\    "MAX_FULL_PATH_SIZE":           1024,
    \\    "UNPORTABLE_CHARS":             true
    \\}
    \\
;

/// Attempts to load configuration from a local "config.json" file in the current working directory
pub fn loadLocal(config_file: *[]const u8, config_parsed: *std.json.Parsed(Config), io: *std.Io,
alloc: *const std.mem.Allocator) bool {
    config_file.* = std.Io.Dir.cwd().readFileAlloc(io.*, "config.json", alloc.*,
        std.Io.Limit.limited(IO_BUFFER_SIZE)) catch |err| blk: {
            if (builtin.mode == .Debug) std.debug.print("Failed to read config.json: {any}\n", .{err});
            break :blk "";
        };

    // Parses JSON with enum support, on error sets default values
    const result: bool = (config_file.*.len > 0);
    const data: []const u8 = if (result) config_file.* else DEFAULT_JSON_CONFIG;

    config_parsed.* = parseJSON(data, alloc, config_file) catch {
        std.debug.panic("\n\n\nPANIC: DEFAULT_JSON_CONFIG IS INVALID AND THIS SHOULD NEVER HAPPEN\n\n\n", .{});
    };

    return result;
}

pub fn deinit(config_file: *[]const u8, config_parsed: *std.json.Parsed(Config), alloc: *const std.mem.Allocator)
void {
    config_parsed.*.deinit();
    if (config_file.*.len > 0) alloc.*.free(config_file.*);
}

fn parseJSON(data: []const u8, alloc: *const std.mem.Allocator, config_file: *[]const u8) !std.json.Parsed(Config) {
    return std.json.parseFromSlice(Config, alloc.*, data, .{}) catch |err| {
        if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });

        // Invalid config.json
        alloc.*.free(config_file.*);
        config_file.* = "";

        return std.json.parseFromSlice(Config, alloc.*, DEFAULT_JSON_CONFIG, .{});
    };
}

test "No config file" {
    var gpa: std.heap.DebugAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = &gpa.allocator();

    var tmp = std.Io.Threaded.init_single_threaded;
    var io = tmp.io();

    var config_parsed: std.json.Parsed(Config) = undefined;
    var config_file:   []const u8              = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer deinit(&config_file, &config_parsed, alloc);

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
    try file_writer.interface.writeAll(DEFAULT_JSON_CONFIG);
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(Config) = undefined;
    var config_file:   []const u8              = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer deinit(&config_file, &config_parsed, alloc);

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
    try file_writer.interface.writeAll(DEFAULT_JSON_CONFIG[1..]);
    try file_writer.interface.flush();

    var config_parsed: std.json.Parsed(Config) = undefined;
    var config_file:   []const u8              = "empty";

    const result: bool = loadLocal(&config_file, &config_parsed, &io, alloc);
    defer deinit(&config_file, &config_parsed, alloc);

    try std.testing.expect(result);
}
