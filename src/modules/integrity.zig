//! Validates file integrity by calculating hash and comparing with file hash code
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

const HashFunctions = struct {
    single:   *const fn ([]const u8, *u64) anyerror!bool,
    parallel: *const fn ([]const u8, *u64) void,

    fn init(comptime name: []const u8, comptime HashType: type) HashFunctions {
        return .{
            .single   = makeHashFunction(  name, HashType),
            .parallel = makeHashFunctionMt(name, HashType),
        };
    }
};

fn makeHashFunction(comptime name: []const u8, comptime HashType: type) *const fn ([]const u8, *u64) anyerror!bool {
    return &struct {
        fn hash(f: []const u8, t: *u64) anyerror!bool {
            return hashSingleCore(f, t, name, HashType);
        }
    }.hash;
}

fn makeHashFunctionMt(comptime name: []const u8, comptime HashType: type) *const fn ([]const u8, *u64) void {
    return &struct {
        fn hash(f: []const u8, t: *u64) void {
            return hashParallelCore(f, t, name, HashType);
        }
    }.hash;
}

fn H(comptime ext: []const u8, comptime name: []const u8, comptime T: type) struct { []const u8, HashFunctions } {
    return .{ ext, HashFunctions.init(name, T) };
}

const hash_functions_map = std.StaticStringMap(HashFunctions).initComptime(.{
    H(".ascon256",    "ASCON256",    std.crypto.hash.ascon.AsconHash256),
    H(".blake2b128",  "BLAKE2B128",  std.crypto.hash.blake2.Blake2b128),
    H(".blake2b160",  "BLAKE2B160",  std.crypto.hash.blake2.Blake2b160),
    H(".blake2b256",  "BLAKE2B256",  std.crypto.hash.blake2.Blake2b256),
    H(".blake2b384",  "BLAKE2B384",  std.crypto.hash.blake2.Blake2b384),
    H(".blake2b512",  "BLAKE2B512",  std.crypto.hash.blake2.Blake2b512),
    H(".blake2s128",  "BLAKE2S128",  std.crypto.hash.blake2.Blake2s128),
    H(".blake2s160",  "BLAKE2S160",  std.crypto.hash.blake2.Blake2s160),
    H(".blake2s224",  "BLAKE2S224",  std.crypto.hash.blake2.Blake2s224),
    H(".blake2s256",  "BLAKE2S256",  std.crypto.hash.blake2.Blake2s256),
    H(".blake3",      "BLAKE3",      std.crypto.hash.Blake3),
    H(".md5",         "MD5",         std.crypto.hash.Md5),
    H(".sha1",        "SHA1",        std.crypto.hash.Sha1),
    H(".sha224",      "SHA224",      std.crypto.hash.sha2.Sha224),
    H(".sha256",      "SHA256",      std.crypto.hash.sha2.Sha256),
    H(".sha256t192",  "SHA256T192",  std.crypto.hash.sha2.Sha256T192),
    H(".sha384",      "SHA384",      std.crypto.hash.sha2.Sha384),
    H(".sha512",      "SHA512",      std.crypto.hash.sha2.Sha512),
    H(".sha512_224",  "SHA512_224",  std.crypto.hash.sha2.Sha512_224),
    H(".sha512t224",  "SHA512T224",  std.crypto.hash.sha2.Sha512T224),
    H(".sha512_256",  "SHA512_256",  std.crypto.hash.sha2.Sha512_256),
    H(".sha512t256",  "SHA512T256",  std.crypto.hash.sha2.Sha512T256),
    H(".sha3_224",    "SHA3_224",    std.crypto.hash.sha3.Sha3_224),
    H(".sha3_256",    "SHA3_256",    std.crypto.hash.sha3.Sha3_256),
    H(".sha3_384",    "SHA3_384",    std.crypto.hash.sha3.Sha3_384),
    H(".sha3_512",    "SHA3_512",    std.crypto.hash.sha3.Sha3_512),
});

pub fn checkIntegrity(total_items: *u64) !void {
    return if (globals.config_parsed.value.INTEGRITY_FILES_PARALLEL) checkParallel(total_items)
        else checkSingle(total_items);
}

fn checkParallel(total_items: *u64) !void {
    const max_jobs_limit: std.Io.Limit = std.Io.Limit.limited64(globals.config_parsed.value.MAX_JOBS);

    var parallel_threaded: std.Io.Threaded = std.Io.Threaded.init(globals.alloc.*, .{.async_limit = max_jobs_limit,
        .concurrent_limit = max_jobs_limit, .environ = std.process.Environ.empty });
    defer parallel_threaded.deinit();

    const io: std.Io = parallel_threaded.io();

    globals.group = std.Io.Group.init;
    defer globals.group.cancel(io);

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.alloc.*);
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        if (file_iterator.using_cache) {
            const extension: []const u8 = std.fs.path.extension(entry.path);
            if (extension.len == 0) continue;

            if (hash_functions_map.get(extension)) |func| {
                try globals.semaphore.wait(io);
                globals.group.async(io, hashParallel, .{entry.path, total_items, false, func.parallel});
            }
        } else {
            if (core.getExtensionLowercase(entry.path)) |lowercase| {
                if (hash_functions_map.get(lowercase)) |func| {
                    const entry_path: []const u8 = try globals.alloc.*.dupe(u8, entry.path);
                    try globals.semaphore.wait(io);
                    globals.group.async(io, hashParallel, .{entry_path, total_items, true, func.parallel});
                }
            }
        }
    }

    try globals.group.await(io);
}

fn checkSingle(total_items: *u64) !void {
    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.alloc.*);
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        _ = try hashSingle(entry.path, total_items);
    }
}

fn hashSingle(absolute_path: []const u8, total_items: *u64) !bool {
    if (core.getExtensionLowercase(absolute_path)) |lowercase| {
        if (hash_functions_map.get(lowercase)) |func| { _ = try func.single(absolute_path, total_items); }
    }

    return false;
}

fn hashParallel(absolute_path: []const u8, total_items: *u64, defer_clean: bool, func: *const fn ([]const u8, *u64)
void) void {
    defer {
        globals.semaphore.post(globals.io);
        if (defer_clean) globals.alloc.*.free(absolute_path);
    }

    _ = func(absolute_path, total_items);
}

fn hashSingleCore(hash_file_path: []const u8, total_items: *u64, extension: []const u8, algorithm: type) anyerror!bool {
    const hex_size: usize = algorithm.digest_length * 2;

    var hash_code: [hex_size]u8 = undefined;
    var calc_hash: [algorithm.digest_length]u8 = undefined;
    var hash_code_bytes_buffer: [algorithm.digest_length]u8 = undefined;

    const hash_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, hash_file_path, .{.mode = .read_write});
    defer hash_file.close(globals.io);

    var file_reader: std.Io.File.Reader = hash_file.reader(globals.io, hash_code[0..hex_size]);
    const chunk: []u8 = file_reader.interface.take(hex_size) catch |err| blk: switch (err) {
        error.EndOfStream => break :blk "",
        else => return err,
    };

    // removes the .cipher_extension
    const input_file: []const u8 = hash_file_path[0..(hash_file_path.len - extension.len - 1)];
    core.hashFile(algorithm, input_file, &calc_hash) catch |err| {
        if (err == error.FileNotFound) return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE,
            .{input_file});
        return err;
    };

    if (chunk.len == 0) {
        var file_writer: std.Io.File.Writer = hash_file.writer(globals.io, &globals.io_buffer);
        try file_writer.interface.writeAll(&std.fmt.bytesToHex(calc_hash, .lower));
        try file_writer.interface.flush();

        return core.messageSum(print.check, total_items, 1, i18n.INTEGRITY_FILES_CHECK, .{input_file, extension});
    }

    if (chunk.len != hex_size) return core.messageSum(print.err, total_items, 1, i18n.ERROR_READING_FILE,
        .{hash_file_path});

    const hash_code_bytes: []u8 = try std.fmt.hexToBytes(&hash_code_bytes_buffer, &hash_code);

    if(std.mem.eql(u8, &calc_hash, hash_code_bytes)) {
        return core.messageSum(print.ok, total_items, 1, i18n.INTEGRITY_FILES_OK, .{input_file, extension});
    }

    return core.messageSum(print.err, total_items, 1, i18n.INTEGRITY_FILES_ERROR, .{input_file, extension});
}

fn hashParallelCore(hash_file_path: []const u8, total_items: *u64, extension: []const u8, algorithm: type) void {
    const hex_size: usize = algorithm.digest_length * 2;

    var hash_code: [hex_size]u8 = undefined;
    var calc_hash: [algorithm.digest_length]u8 = undefined;
    var hash_code_bytes_buffer: [algorithm.digest_length]u8 = undefined;

    const hash_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.io, hash_file_path, .{.mode = .read_write})
        catch |err| {
            return core.debugPrintError(err);
        };
    defer hash_file.close(globals.io);

    var file_reader: std.Io.File.Reader = hash_file.reader(globals.io, hash_code[0..hex_size]);
    const chunk: []u8 = file_reader.interface.take(hex_size) catch |err| blk: switch (err) {
        error.EndOfStream => break :blk "",
        else => return core.debugPrintError(err),
    };

    // removes the .cipher_extension
    const input_file: []const u8 = hash_file_path[0..(hash_file_path.len - extension.len - 1)];
    core.hashFile(algorithm, input_file, &calc_hash) catch |err| {
        if (err == error.FileNotFound) return messageSumMutex(print.err_mt, total_items, 1, i18n.ERROR_READING_FILE,
            .{input_file});

        return core.debugPrintError(err);
    };

    if (chunk.len == 0) {
        var file_writer: std.Io.File.Writer = hash_file.writer(globals.io, &globals.io_buffer);
        file_writer.interface.writeAll(&std.fmt.bytesToHex(calc_hash, .lower)) catch |err| {
            return core.debugPrintError(err);
        };
        file_writer.interface.flush() catch |err| {
            return core.debugPrintError(err);
        };

        return messageSumMutex(print.check_mt, total_items, 1, i18n.INTEGRITY_FILES_CHECK, .{input_file, extension});
    }

    if (chunk.len != hex_size) return messageSumMutex(print.err_mt, total_items, 1, i18n.ERROR_READING_FILE,
        .{hash_file_path});

    const hash_code_bytes: []u8 = std.fmt.hexToBytes(&hash_code_bytes_buffer, &hash_code) catch |err| {
        return core.debugPrintError(err);
    };

    if(std.mem.eql(u8, &calc_hash, hash_code_bytes)) return messageSumMutex(print.ok_mt, total_items, 1,
        i18n.INTEGRITY_FILES_OK, .{input_file, extension});

    messageSumMutex(print.err_mt, total_items, 1, i18n.INTEGRITY_FILES_ERROR, .{input_file, extension});
}

/// Helper to print message and accumulate totals with mutex
pub fn messageSumMutex(
    print_function: *const fn (comptime []const u8, anytype) anyerror!void,
    total_items:    *u64,
    sum_value:      u64,
    comptime fmt:   []const u8,
    args:           anytype
) void {
    globals.mutex.lock(globals.io) catch |err| { return core.debugPrintError(err); };
    defer globals.mutex.unlock(globals.io);
        total_items.* += sum_value;
        print_function(fmt, args) catch |err| {
            return core.debugPrintError(err);
        };
}
