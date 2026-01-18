//! Validates file integrity by calculating hash and comparing with file hash code
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");
const builtin = @import("builtin");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const print   = @import("print");

const core    = @import("core.zig");

const HashFunctions = struct {
    single:    *const fn ([]const u8, *u64) anyerror!bool,
    parallel:  *const fn ([]const u8, *u64) void,
};

const hash_functions_map = std.StaticStringMap(HashFunctions).initComptime(.{
    .{ ".ascon256"   , HashFunctions{ .single = ascon256   , .parallel = ascon256_mt   }},
    .{ ".blake2b128" , HashFunctions{ .single = blake2b128 , .parallel = blake2b128_mt }},
    .{ ".blake2b160" , HashFunctions{ .single = blake2b160 , .parallel = blake2b160_mt }},
    .{ ".blake2b256" , HashFunctions{ .single = blake2b256 , .parallel = blake2b256_mt }},
    .{ ".blake2b384" , HashFunctions{ .single = blake2b384 , .parallel = blake2b384_mt }},
    .{ ".blake2b512" , HashFunctions{ .single = blake2b512 , .parallel = blake2b512_mt }},
    .{ ".blake2s128" , HashFunctions{ .single = blake2s128 , .parallel = blake2s128_mt }},
    .{ ".blake2s160" , HashFunctions{ .single = blake2s160 , .parallel = blake2s160_mt }},
    .{ ".blake2s224" , HashFunctions{ .single = blake2s224 , .parallel = blake2s224_mt }},
    .{ ".blake2s256" , HashFunctions{ .single = blake2s256 , .parallel = blake2s256_mt }},
    .{ ".blake3"     , HashFunctions{ .single = blake3     , .parallel = blake3_mt     }},
    .{ ".md5"        , HashFunctions{ .single = md5        , .parallel = md5_mt        }},
    .{ ".sha1"       , HashFunctions{ .single = sha1       , .parallel = sha1_mt       }},
    .{ ".sha224"     , HashFunctions{ .single = sha224     , .parallel = sha224_mt     }},
    .{ ".sha256"     , HashFunctions{ .single = sha256     , .parallel = sha256_mt     }},
    .{ ".sha256t192" , HashFunctions{ .single = sha256t192 , .parallel = sha256t192_mt }},
    .{ ".sha384"     , HashFunctions{ .single = sha384     , .parallel = sha384_mt     }},
    .{ ".sha512"     , HashFunctions{ .single = sha512     , .parallel = sha512_mt     }},
    .{ ".sha512_224" , HashFunctions{ .single = sha512_224 , .parallel = sha512_224_mt }},
    .{ ".sha512t224" , HashFunctions{ .single = sha512t224 , .parallel = sha512t224_mt }},
    .{ ".sha512_256" , HashFunctions{ .single = sha512_256 , .parallel = sha512_256_mt }},
    .{ ".sha512t256" , HashFunctions{ .single = sha512t256 , .parallel = sha512t256_mt }},
    .{ ".sha3_224"   , HashFunctions{ .single = sha3_224   , .parallel = sha3_224_mt   }},
    .{ ".sha3_256"   , HashFunctions{ .single = sha3_256   , .parallel = sha3_256_mt   }},
    .{ ".sha3_384"   , HashFunctions{ .single = sha3_384   , .parallel = sha3_384_mt   }},
    .{ ".sha3_512"   , HashFunctions{ .single = sha3_512   , .parallel = sha3_512_mt   }},
});

const cipher = std.crypto.hash;

fn ascon256  (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "ASCON256",   cipher.ascon.AsconHash256); }
fn blake2b128(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2B128", cipher.blake2.Blake2b128);  }
fn blake2b160(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2B160", cipher.blake2.Blake2b160);  }
fn blake2b256(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2B256", cipher.blake2.Blake2b256);  }
fn blake2b384(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2B384", cipher.blake2.Blake2b384);  }
fn blake2b512(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2B512", cipher.blake2.Blake2b512);  }
fn blake2s128(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2S128", cipher.blake2.Blake2s128);  }
fn blake2s160(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2S160", cipher.blake2.Blake2s160);  }
fn blake2s224(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2S224", cipher.blake2.Blake2s224);  }
fn blake2s256(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE2S256", cipher.blake2.Blake2s256);  }
fn blake3    (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "BLAKE3",     cipher.Blake3);             }
fn md5       (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "MD5",        cipher.Md5);                }
fn sha1      (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA1",       cipher.Sha1);               }
fn sha224    (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA224",     cipher.sha2.Sha224);        }
fn sha256    (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA256",     cipher.sha2.Sha256);        }
fn sha256t192(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA256T192", cipher.sha2.Sha256T192);    }
fn sha384    (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA384",     cipher.sha2.Sha384);        }
fn sha512    (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA512",     cipher.sha2.Sha512);        }
fn sha512_224(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA512_224", cipher.sha2.Sha512_224);    }
fn sha512t224(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA512T224", cipher.sha2.Sha512T224);    }
fn sha512_256(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA512_256", cipher.sha2.Sha512_256);    }
fn sha512t256(f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA512T256", cipher.sha2.Sha512T256);    }
fn sha3_224  (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA3_224",   cipher.sha3.Sha3_224);      }
fn sha3_256  (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA3_256",   cipher.sha3.Sha3_256);      }
fn sha3_384  (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA3_384",   cipher.sha3.Sha3_384);      }
fn sha3_512  (f: []const u8, t: *u64) anyerror!bool { return hashSingleCore(f, t, "SHA3_512",   cipher.sha3.Sha3_512);      }

fn ascon256_mt  (f: []const u8, t: *u64) void { hashParallelCore(f, t, "ASCON256",   cipher.ascon.AsconHash256); }
fn blake2b128_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2B128", cipher.blake2.Blake2b128);  }
fn blake2b160_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2B160", cipher.blake2.Blake2b160);  }
fn blake2b256_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2B256", cipher.blake2.Blake2b256);  }
fn blake2b384_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2B384", cipher.blake2.Blake2b384);  }
fn blake2b512_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2B512", cipher.blake2.Blake2b512);  }
fn blake2s128_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2S128", cipher.blake2.Blake2s128);  }
fn blake2s160_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2S160", cipher.blake2.Blake2s160);  }
fn blake2s224_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2S224", cipher.blake2.Blake2s224);  }
fn blake2s256_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE2S256", cipher.blake2.Blake2s256);  }
fn blake3_mt    (f: []const u8, t: *u64) void { hashParallelCore(f, t, "BLAKE3",     cipher.Blake3);             }
fn md5_mt       (f: []const u8, t: *u64) void { hashParallelCore(f, t, "MD5",        cipher.Md5);                }
fn sha1_mt      (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA1",       cipher.Sha1);               }
fn sha224_mt    (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA224",     cipher.sha2.Sha224);        }
fn sha256_mt    (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA256",     cipher.sha2.Sha256);        }
fn sha256t192_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA256T192", cipher.sha2.Sha256T192);    }
fn sha384_mt    (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA384",     cipher.sha2.Sha384);        }
fn sha512_mt    (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA512",     cipher.sha2.Sha512);        }
fn sha512_224_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA512_224", cipher.sha2.Sha512_224);    }
fn sha512t224_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA512T224", cipher.sha2.Sha512T224);    }
fn sha512_256_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA512_256", cipher.sha2.Sha512_256);    }
fn sha512t256_mt(f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA512T256", cipher.sha2.Sha512T256);    }
fn sha3_224_mt  (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA3_224",   cipher.sha3.Sha3_224);      }
fn sha3_256_mt  (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA3_256",   cipher.sha3.Sha3_256);      }
fn sha3_384_mt  (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA3_384",   cipher.sha3.Sha3_384);      }
fn sha3_512_mt  (f: []const u8, t: *u64) void { hashParallelCore(f, t, "SHA3_512",   cipher.sha3.Sha3_512);      }

pub fn checkIntegrity(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    return if (globals.config_parsed.value.INTEGRITY_FILES_PARALLEL) checkParallel(total_items, walker)
        else checkSingle(total_items, walker);
}

fn checkParallel(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    const max_jobs_limit: std.Io.Limit = std.Io.Limit.limited64(globals.config_parsed.value.MAX_JOBS);

    var parallel_threaded: std.Io.Threaded = std.Io.Threaded.init(globals.alloc.*, .{.async_limit = max_jobs_limit,
        .concurrent_limit = max_jobs_limit, .environ = std.process.Environ.empty });
    defer parallel_threaded.deinit();

    const io: std.Io = parallel_threaded.io();

    globals.group = std.Io.Group.init;
    defer globals.group.cancel(io);

    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.keyIterator();

        while (iterator.next()) |entry| {
            // skips directories
            const cached_stat: std.Io.File.Stat = globals.file_stats.get(entry.*) orelse continue;

            if (cached_stat.kind == std.Io.File.Kind.file) {

                // Extract extension and normalize to lowercase for case-insensitive matching
                const extension: []const u8 = std.fs.path.extension(entry.*);
                if (extension.len == 0) continue;

                // Bounds check before lowercasing
                if (extension.len > globals.buffer.len) continue;

                //const lowercase: []const u8 = std.ascii.lowerString(globals.buffer[0..extension.len], extension);

                if (hash_functions_map.get(extension)) |func| {
                    globals.semaphore.wait();
                    globals.group.async(io, hashParallel, .{entry.*, total_items, false, func.parallel});
                }
            }
        }

        return globals.group.await(io);
    }

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file and entry.kind != .directory) continue;

        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
            .{globals.absolute_input_path, std.fs.path.sep, entry.path});

        // Add the file and directory to cache
        _ = try core.fetchAdd(absolute_path);
        if (entry.kind != .file) continue;

        // Extract extension and normalize to lowercase for case-insensitive matching
        const extension: []const u8 = std.fs.path.extension(absolute_path);
        if (extension.len == 0) continue;

        // Bounds check before lowercasing
        if (extension.len > globals.buffer.len) continue;

        const lowercase: []const u8 = std.ascii.lowerString(globals.buffer[0..extension.len], extension);

        if (hash_functions_map.get(lowercase)) |func| {
            const entry_path: []const u8 = try globals.alloc.*.dupe(u8, absolute_path);
            globals.semaphore.wait();
            globals.group.async(io, hashParallel, .{entry_path, total_items, true, func.parallel});
        }
    }

    try globals.group.await(io);
}

fn checkSingle(total_items: *u64, walker: *std.Io.Dir.Walker) !void {
    // First check if there are cached file statistics
    if (globals.file_stats.count() > 0) {
        var iterator = globals.file_stats.keyIterator();

        while (iterator.next()) |entry| {
            // skips directories
            const cached_stat: std.Io.File.Stat = globals.file_stats.get(entry.*) orelse continue;
            if (cached_stat.kind == std.Io.File.Kind.file) _ = try hashSingle(entry.*, total_items);
        }
        return;
    }

    while (try walker.next(globals.io)) |entry| {
        if (entry.kind != .file and entry.kind != .directory) continue;

        const absolute_path: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{c}{s}",
            .{globals.absolute_input_path, std.fs.path.sep, entry.path});

        // Add the file or directory to cache
        _ = try core.fetchAdd(absolute_path);

        if (entry.kind == .file) _ = try hashSingle(absolute_path, total_items);
    }
}

fn hashSingle(absolute_path: []const u8, total_items: *u64) !bool {
    // Extract extension and normalize to lowercase for case-insensitive matching
    const extension: []const u8 = std.fs.path.extension(absolute_path);
    if (extension.len == 0) return false;

    // Bounds check before lowercasing
    if (extension.len > globals.buffer.len) return false;

    const lowercase: []const u8 = std.ascii.lowerString(globals.buffer[0..extension.len], extension);

    if (hash_functions_map.get(lowercase)) |func| { _ = try func.single(absolute_path, total_items); }

    return false;
}

fn hashParallel(absolute_path: []const u8, total_items: *u64, defer_clean: bool, func: *const fn ([]const u8, *u64)
void) void {
    defer {
        globals.semaphore.post();
        if (defer_clean) globals.alloc.*.free(absolute_path);
    }

    _ = func(absolute_path, total_items);
}

fn hashSingleCore(file_hash: []const u8, total_items: *u64, extension: []const u8, algorithm: type) anyerror!bool {
    const hex_size: usize = algorithm.digest_length * 2;
    var hash_code: [hex_size]u8 = undefined;
    var calc_hash: [algorithm.digest_length]u8 = undefined;
    var hash_code_bytes_buffer: [algorithm.digest_length]u8 = undefined;

    const hash_file: std.Io.File = try std.Io.Dir.cwd().openFile(globals.io, file_hash, .{.mode = .read_write});
    defer hash_file.close(globals.io);

    var file_reader: std.Io.File.Reader = hash_file.reader(globals.io, hash_code[0..hex_size]);
    const chunk: []u8 = file_reader.interface.take(hex_size) catch |err| blk: switch (err) {
        error.EndOfStream => break :blk "",
        else => return err,
    };

    // removes the .cipher_extension
    const input_file: []const u8 = file_hash[0..(file_hash.len - extension.len - 1)];
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
        .{file_hash});

    const hash_code_bytes: []u8 = try std.fmt.hexToBytes(&hash_code_bytes_buffer, &hash_code);

    if(std.mem.eql(u8, &calc_hash, hash_code_bytes)) {
        return core.messageSum(print.ok, total_items, 1, i18n.INTEGRITY_FILES_OK, .{input_file, extension});
    }

    return core.messageSum(print.err, total_items, 1, i18n.INTEGRITY_FILES_ERROR, .{input_file, extension});
}

fn hashParallelCore(file_hash: []const u8, total_items: *u64, extension: []const u8, algorithm: type) void {
    const hex_size: usize = algorithm.digest_length * 2;

    var hash_code: [hex_size]u8 = undefined;
    var calc_hash: [algorithm.digest_length]u8 = undefined;
    var hash_code_bytes_buffer: [algorithm.digest_length]u8 = undefined;

    const hash_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.io, file_hash, .{.mode = .read_write})
        catch |err| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return;
        };
    defer hash_file.close(globals.io);

    var file_reader: std.Io.File.Reader = hash_file.reader(globals.io, hash_code[0..hex_size]);
    const chunk: []u8 = file_reader.interface.take(hex_size) catch |err| blk: switch (err) {
        error.EndOfStream => break :blk "",
        else => {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return;
        }
    };

    // removes the .cipher_extension
    const input_file: []const u8 = file_hash[0..(file_hash.len - extension.len - 1)];
    core.hashFile(algorithm, input_file, &calc_hash) catch |err| {
        if (err == error.FileNotFound) return messageSumMutex(print.err_mt, total_items, 1, i18n.ERROR_READING_FILE,
            .{input_file});

        if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
        return;
    };

    if (chunk.len == 0) {
        var file_writer: std.Io.File.Writer = hash_file.writer(globals.io, &globals.io_buffer);
        file_writer.interface.writeAll(&std.fmt.bytesToHex(calc_hash, .lower)) catch |err| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return;
        };
        file_writer.interface.flush() catch |err| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
            return;
        };

        return messageSumMutex(print.check_mt, total_items, 1, i18n.INTEGRITY_FILES_CHECK, .{input_file, extension});
    }

    if (chunk.len != hex_size) return messageSumMutex(print.err_mt, total_items, 1, i18n.ERROR_READING_FILE,
        .{file_hash});

    const hash_code_bytes: []u8 = std.fmt.hexToBytes(&hash_code_bytes_buffer, &hash_code) catch |err| {
        if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
        return;
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
    globals.mutex.lock();
    defer globals.mutex.unlock();
        total_items.* += sum_value;
        print_function(fmt, args) catch |err| {
            if (builtin.mode == .Debug) std.debug.print("{s}:{d} => {any}\n", .{ @src().file, @src().line, err });
        };
}
