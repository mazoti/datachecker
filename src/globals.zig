//! Variables used all to times are moved here to avoid redeclaration
//!
//! Copyright © 2025-present Marcos Mazoti

const ahocorasick = @import("ahocorasick");
const std         = @import("std");
const config      = @import("config");

/// Defines the hash map type
pub const FileStatMap: type = std.StringHashMap(std.Io.File.Stat);


/// The full path string of the processed input directory
pub var absolute_input_path: []const u8 = undefined;

/// Address of the allocator used
pub var alloc: *const std.mem.Allocator = undefined;

/// The buffer with size specified by user
pub var buffer: []u8 = undefined;

// Prevents bugs with odd sizes of buffer
pub var buffer_size:  usize = undefined;
pub var buffer_total: usize = undefined;

/// Default configurations or parsed from JSON
pub var config_parsed: std.json.Parsed(config.Config) = undefined;
pub var config_file:   []const u8                     = undefined;

/// Global hash map instance for caching directory items count
pub var dir_count: std.StringHashMap(usize) = undefined;

/// System exit code: 0 (no problems), 1 (errors)
pub var exit_code: u8 = 0;

/// Terminal I/O operations
pub var file_writer_stdout:           std.Io.File.Writer = undefined;
pub var file_writer_stderr:           std.Io.File.Writer = undefined;
pub var file_writer_stdout_interface: std.Io.Writer      = undefined;
pub var file_writer_stderr_interface: std.Io.Writer      = undefined;

/// Global hash map instance for caching file stats
pub var file_stats: FileStatMap = undefined;

/// AC trie with patterns used to ignore paths
pub var ignore_path_patterns: ahocorasick.AhoCorasick = undefined;

/// The processed input directory
pub var input_directory: std.Io.Dir = undefined;

/// IO used to read and write data to files and stdout/stderr
pub var io: std.Io = undefined;

/// The buffer with size specified by config.zig
pub var io_buffer: [config.COMPTIME_IO_BUFFER_SIZE]u8 = undefined;

/// Thread-local buffer for storing file paths
pub var max_path_buffer: [std.fs.max_path_bytes]u8 = undefined;

/// Memory max usage
pub var memory_limit: usize = undefined;

/// Parallel synchronization
pub var mutex:     std.Io.Mutex     = std.Io.Mutex{.state = std.atomic.Value(std.Io.Mutex.State).init(.unlocked)};
pub var semaphore: std.Io.Semaphore = undefined;
pub var group:     std.Io.Group     = undefined;

/// Nanoseconds since 1970
pub var now_stat: std.Io.File.Stat = undefined;
