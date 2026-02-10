//! Compress the binary files, renames, moves to download folder
//! and creates an empty file for hash calculation
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var current_directory: []u8 = undefined;
    const arena: std.mem.Allocator = init.arena.allocator();

    current_directory = try std.process.currentPathAlloc(init.io, arena);
    defer arena.free(current_directory);

    const input_folder: []u8 = try std.fmt.allocPrint(arena, "{s}{c}zig-out{c}", .{current_directory, std.fs.path.sep, std.fs.path.sep});
    defer arena.free(input_folder);

    var input_dir = try std.Io.Dir.openDirAbsolute(init.io, input_folder, .{ .iterate = true });
    var walker: std.Io.Dir.Walker = try input_dir.walk(arena);
    defer walker.deinit();

    var dir_name: []const u8 = undefined;

    var buffer:             [2048]u8 = undefined;
    var buffer_output:      [2048]u8 = undefined;
    var buffer_output_last: [2048]u8 = undefined;
    var buffer_hash_file:   [2048]u8 = undefined;

    while (try walker.next(init.io)) |entry| {
        if (entry.kind == .directory) {
            dir_name = entry.path;
            continue;
        }

        if (entry.kind == .file) {
            const extension: []const u8 = std.fs.path.extension(entry.path);
            if (std.mem.eql(u8, extension, ".pdb")) continue;

            const input_bin: []const u8 = try std.fmt.bufPrint(&buffer, "zig-out{c}{s}",
                .{std.fs.path.sep, entry.path});

            var child = try std.process.spawn(init.io, .{.argv = &[_][]const u8{ "xz", "-z", "-9", "-e", input_bin}});
            _ = try child.wait(init.io);

            // Moves compressed files to download folder
            const old_dir_tmp: []const u8 = try std.fmt.bufPrint(&buffer, "{s}{s}{c}", .{input_folder, dir_name, std.fs.path.sep});
            const old_dir = try std.Io.Dir.openDirAbsolute(init.io, old_dir_tmp, .{ .iterate = true });
            const old_sub_path: []const u8 = try std.fmt.bufPrint(&buffer, "{s}.xz", .{entry.path[dir_name.len + 1..]});

            const new_dir_tmp: []const u8 = try std.fmt.bufPrint(&buffer_output, "{s}{c}download{c}", .{current_directory, std.fs.path.sep, std.fs.path.sep});
            const new_dir = try std.Io.Dir.openDirAbsolute(init.io, new_dir_tmp, .{ .iterate = true });

            const new_sub_path: []const u8 = if (std.mem.endsWith(u8, entry.path, ".exe"))
                try std.fmt.bufPrint(&buffer_output_last, "{s}datachecker-{s}.exe.xz", .{new_dir_tmp, dir_name})
            else
                try std.fmt.bufPrint(&buffer_output_last, "{s}datachecker-{s}.xz", .{new_dir_tmp, dir_name});

            try std.Io.Dir.rename(old_dir, old_sub_path, new_dir, new_sub_path, init.io);

            // Creates empty file for hash later
            const empty_hash: []const u8 = try std.fmt.bufPrint(&buffer_hash_file, "{s}.sha3_256", .{new_sub_path});
            const empty_hash_file: std.Io.File = try std.Io.Dir.cwd().createFile(init.io, empty_hash, .{});
            empty_hash_file.close(init.io);

            std.debug.print("Moving {s}...\nCreating {s}...\n", .{new_sub_path, empty_hash});
        }
    }
}
