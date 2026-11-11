//! This module implements a multi-strategy pattern matching system to identify
//! temporary, cache or obsolete format files.
//!
//! Copyright © 2025-present Marcos Mazoti

const ahocorasick     = @import("ahocorasick");
const builtin         = @import("builtin");
const core            = @import("core.zig");
const data            = @import("data.zig");
const globals         = @import("globals");
const i18n            = @import("i18n");
const print           = @import("print");
const std             = @import("std");

fn checkTempFiles(args: anytype, remove_file: bool) !void {
    // Extract and normalize extension for case-insensitive matching
    const filename: []const u8 = std.fs.path.basename(args[0]);

    if (core.getExtensionLowercase(args[0])) |lowercase| {
        // Checks if the file extension is in the temporary extensions map
        if (data.TEMPORARY_EXTENSIONS.has(lowercase)) {
            args[1].* += args[2].size;
            return warnRemoveFile(args[0], remove_file);
        }
    }

    // Checks if the full filename matches exactly
    if (data.FULL_NAME.has(filename)) {
        args[1].* += args[2].size;
        return warnRemoveFile(args[0], remove_file);
    }

    // Checks if filename matches start/end patterns
    for (data.START_END) |pattern| {
        if ((pattern.start.len > 0 and !std.mem.startsWith(u8, filename, pattern.start)) or
            (pattern.end.len   > 0 and !std.mem.endsWith(  u8, filename, pattern.end))) continue;

        args[1].* += args[2].size;
        return warnRemoveFile(args[0], remove_file);
    }

    // Checks if the path contains any of the known temporary patterns
    if (args[3].contains(args[0])) {
        args[1].* += args[2].size;
        return warnRemoveFile(args[0], remove_file);
    }
}

/// Scans a directory tree for legacy file formats
pub fn debugInfo(args: anytype) !bool {
    var input_file: std.Io.File = std.Io.Dir.cwd().openFile(globals.init.io, args[0],
        .{.mode = .read_only, .lock = .shared}) catch |err| {
            core.debugPrintError(err);
            globals.exit_error.store(true, .monotonic);
            return false;
        };
    defer input_file.close(globals.init.io);

    var file_reader: std.Io.File.Reader = input_file.reader(globals.init.io, globals.buffer[0..4]);

    const chunk_tmp: ?[]const u8 = core.readExactChunk(&file_reader, 4, args[0], args[1]) catch |err| {
        core.debugPrintError(err);
        globals.exit_error.store(true, .monotonic);
        return false;
    };

    const chunk = chunk_tmp orelse return false;

    // ELF executable
    if (std.mem.eql(u8, chunk[0..4], "\x7F\x45\x4C\x46")) {
        var elf_file = try std.debug.ElfFile.load(globals.init.arena.allocator(), globals.init.io, input_file, &.{}, &std.debug.ElfFile.DebugInfoSearchPaths.none);
        defer elf_file.deinit(globals.init.arena.allocator());

        if (elf_file.dwarf != null or elf_file.symtab != null) {
            args[1].* += 1;
            globals.exit_warning.store(true, .monotonic);
            try print.warning(i18n.DEBUG_INFO_WARNING, .{args[0]});
        }
        return false;
    }

    // PE executable
    if (std.mem.eql(u8, chunk[0..2], "MZ")) {
        // Small .exe files makes the system panic
        if (args[2].size < 4096) return false;

        try file_reader.seekTo(0);

        const file_contents = try file_reader.interface.allocRemaining(globals.init.arena.allocator(), std.Io.Limit.limited64(globals.memory_limit));
        defer globals.init.arena.allocator().free(file_contents);

        var coff = try std.coff.Coff.init(file_contents, false);

        const pdb_path = coff.getPdbPath() catch blk: { break :blk null; };

        var has_embedded_dwarf = false;
        inline for (.{ ".debug_info", ".debug_line", ".debug_abbrev", ".debug_str" }) |name| {
            if (coff.getSectionByName(name) != null) {
                has_embedded_dwarf = true;
                break;
           }
        }

        const symtab = coff.getSymtab();
        const has_symtab = symtab != null and symtab.?.len() > 0;

        if (pdb_path != null or has_embedded_dwarf or has_symtab) {
            args[1].* += 1;
            globals.exit_warning.store(true, .monotonic);
            try print.warning(i18n.DEBUG_INFO_WARNING, .{args[0]});
        }
        return false;
    }

    // Mach-O executable
    if (std.mem.eql(u8, chunk[0..4], "\xFE\xED\xFA\xCE") or std.mem.eql(u8, chunk[0..4], "\xCE\xFA\xED\xFE") or
        std.mem.eql(u8, chunk[0..4], "\xFE\xED\xFA\xCF") or std.mem.eql(u8, chunk[0..4], "\xCF\xFA\xED\xFE") or
        std.mem.eql(u8, chunk[0..4], "\xCA\xFE\xBA\xBE") or std.mem.eql(u8, chunk[0..4], "\xBE\xBA\xFE\xCA") or
        std.mem.eql(u8, chunk[0..4], "\xCA\xFE\xBA\xBF") or std.mem.eql(u8, chunk[0..4], "\xBF\xBA\xFE\xCA")) {

            for ([_]std.Target.Cpu.Arch{ .x86_64, .aarch64 }) |arch| {
                var macho_file = std.debug.MachOFile.load(globals.init.arena.allocator(), globals.init.io, args[0], arch) catch continue;
                defer macho_file.deinit(globals.init.arena.allocator());

                for (macho_file.symbols) |sym| {
                    _ = macho_file.getDwarfForAddress(globals.init.arena.allocator(), globals.init.io, sym.addr) catch continue;

                    args[1].* += 1;
                    globals.exit_warning.store(true, .monotonic);
                    try print.warning(i18n.DEBUG_INFO_WARNING, .{args[0]});
                    return false;
                }
            }
    }
    return false;
}

/// Scans a directory tree for legacy file formats
pub fn legacyFiles(args: anytype) !bool {
    const lowercase   = core.getExtensionLowercase(args[0])          orelse return false;
    const description = data.LEGACY_EXTENSIONS_DESCRIPTION.get(lowercase) orelse return false;

    globals.exit_warning.store(true, .monotonic);
    try print.warning(i18n.LEGACY_FILES_WARNING, .{ args[0], description });
    args[1].* += 1;
    return true;
}

/// Scans a directory tree for temporary files
pub fn temporaryFiles(total_items: *u64) !bool {
    // Initializes Aho-Corasick trie
    var ac = try ahocorasick.AhoCorasick.init(globals.init.arena.allocator(), &data.CONTAINS);
    defer ac.deinit();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.init.arena.allocator());
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        try checkTempFiles(.{entry.path, total_items, &entry.stat, &ac}, false);
    }

    return false;
}

/// Scans a directory tree and removes temporary files
pub fn temporaryRemoveFiles(total_items: *u64) !bool {
    // Initializes Aho-Corasick trie
    var ac = try ahocorasick.AhoCorasick.init(globals.init.arena.allocator(), &data.CONTAINS);
    defer ac.deinit();

    var file_iterator: core.FileIterator = try core.FileIterator.init(globals.init.arena.allocator());
    defer file_iterator.deinit();

    while (try file_iterator.next(total_items)) |entry| {
        try checkTempFiles(.{entry.path, total_items, &entry.stat, &ac}, true);
    }

    return false;
}

fn warnRemoveFile(filepath: []const u8, remove_file: bool) !void {
    if (!remove_file) {
        globals.exit_warning.store(true, .monotonic);
        return print.warning(i18n.TEMPORARY_FILES_WARNING, .{filepath});
    }

    globals.clear_cache.store(true, .monotonic);

    try std.Io.Dir.deleteFileAbsolute(globals.init.io, filepath);
    return print.removing("\"{s}\"", .{filepath});
}
