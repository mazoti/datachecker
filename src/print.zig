//! Functions to output data in stdout and stderr
//!
//! Copyright © 2025-present Marcos Mazoti

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");
const std     = @import("std");

// Prints spaces and a colored (or not) status
fn alignedCore(message: []const u8, comptime status_message: []const u8, comptime color_code: []const u8) !void {
    const fmt_str: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "\t\x1b[1A\x1b[2K{s}", .{message});
    try stdout(fmt_str);

    if (i18n.ALIGNED_SPACES > message.len) {
        for (0..(i18n.ALIGNED_SPACES - message.len)) |_| { _ = try stdout(" "); }

        if (config.COMPTIME_EMOJI_COLOR) {
            const status_str: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "\x1b[{s}m{s}\x1b[0m", .{color_code, status_message});
            return stdout(status_str);
        }
    }

    return stdout(status_message);
}

/// Prints message with aligned "DISABLED" status (moves cursor up and clears line)
pub fn alignedDisabled(comptime message: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    try header(message);

    return alignedCore(message, i18n.DISABLED_MESSAGE, "31");
}

/// Prints message with aligned "OK" status (moves cursor up and clears line)
pub fn alignedOk(message: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    return alignedCore(message, i18n.OK_MESSAGE, "32");
}

/// Prints message with a green "CHECK" on the left
pub fn check(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args)) return;
    if (try cleanPath2Strings(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args)) return;

    return core(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args);
}

/// Prints message with a green "CHECK" on the left (multi-thread)
pub fn check_mt(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    return core_mt(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args);
}

/// Core printing function with optional ANSI color codes
fn core(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    const fmt_str: []const u8 = try std.fmt.bufPrint(globals.buffer, fmt, args);

    // ANSI color format: ESC[<code>m <text> ESC[0m (reset)
    const data: []const u8 = if (config.COMPTIME_EMOJI_COLOR) try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{s}\x1b[0m{s}", .{ ansi_color, print_message, fmt_str }) else try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{s}", .{ print_message, fmt_str });

    return stderr(data);
}

/// Core printing function with optional ANSI color codes (multi-thread)
fn core_mt(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    var buf:  [config.COMPTIME_IO_BUFFER_SIZE / 4]u8 = undefined;
    var buf2: [config.COMPTIME_IO_BUFFER_SIZE / 4]u8 = undefined;

    const fmt_str: []const u8 = try std.fmt.bufPrint(&buf, fmt, args);

    // ANSI color format: ESC[<code>m <text> ESC[0m (reset)
    const data: []const u8 = if (config.COMPTIME_EMOJI_COLOR) try std.fmt.bufPrint(&buf2, "{s}{s}\x1b[0m{s}", .{ ansi_color, print_message, fmt_str }) else try std.fmt.bufPrint(&buf2, "{s}{s}", .{ print_message, fmt_str });

    return stderr(data);
}

/// Prints duplicate files grouped by size
pub fn duplicateFiles(duplicates: *const std.ArrayList(std.ArrayList([]u8)), remove_duplicate: bool) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    for (duplicates.items) |results_list| {
        const stat: std.Io.File.Stat = globals.file_stats.get(results_list.items[0]) orelse try std.Io.Dir.cwd().statFile(globals.init.io, results_list.items[0], .{});

        const plural: []const u8 = if (stat.size == 1) "byte:" else "bytes:";

        const data: []const u8 = if (config.COMPTIME_EMOJI_COLOR) try std.fmt.bufPrint(globals.buffer, "\n\t\t\x1b[33m{} {s}\x1b[0m\n", .{ stat.size, plural }) else try std.fmt.bufPrint(globals.buffer, "\n\t\t{} {s}\n", .{ stat.size, plural });

        try stderr(data);

        if (remove_duplicate) {
            // Does not remove first item
            try stderr(try std.fmt.bufPrint(globals.buffer, "\n\t\t\t{s}\n", .{results_list.items[0]}));

            if (config.COMPTIME_EMOJI_COLOR) {
                for (results_list.items[1..]) |result| {
                    var i: usize = 0;
                    for (result) |c| {
                        if (c == '\n' or c == '\r') continue;
                        globals.max_path_buffer[i] = c;
                        i += 1;
                    }

                    try stderr(try std.fmt.bufPrint(globals.buffer, "\n\t\t\t\x1b[31m{s}\x1b[0m{s}", .{i18n.REMOVING_MESSAGE, globals.max_path_buffer[0..i]}));
                }
            } else {
                for (results_list.items[1..]) |result| {

                    var i: usize = 0;
                    for (result) |c| {
                        if (c == '\n' or c == '\r') continue;
                        globals.max_path_buffer[i] = c;
                        i += 1;
                    }

                    try stderr(try std.fmt.bufPrint(globals.buffer, "\n\t\t\t{s}{s}", .{i18n.REMOVING_MESSAGE, globals.max_path_buffer[0..i]}));
                }
            }
        } else {
            for (results_list.items) |result| {
                var i: usize = 0;
                for (result) |c| {
                    if (c == '\n' or c == '\r') continue;
                    globals.max_path_buffer[i] = c;
                    i += 1;
                }

                try stderr(try std.fmt.bufPrint(globals.buffer, "\n\t\t\t{s}", .{globals.max_path_buffer[0..i]}));
            }
        }

        try stderr("\n");
    }
}

/// Prints message with a red "ERROR" on the left
pub fn err(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args)) return;
    if (try cleanPath2Strings(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args)) return;

    return core(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args);
}

/// Prints message with a red "ERROR" on the left (multi-thread)
pub fn err_mt(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args)) return;
    if (try cleanPath2Strings(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args)) return;

    return core_mt(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args);
}

/// Prints error message at stderr
pub fn errorDirectory(directory_path: []const u8) !void {
    if (config.COMPTIME_STDOUT_STDERR) {
        try stderr("\n");
        try err("{s}", .{i18n.ERROR_INPUT_DIRECTORY});

        const data: []const u8 = try std.fmt.bufPrint(globals.buffer, " \"{s}\"\n\n", .{directory_path});
        try stderr(data);
    }
}

///
pub fn found(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    return core(fmt, "\x1b[34m", i18n.FOUND_MESSAGE, args);
}

/// Prints message, increase items count and returns parameter value
pub fn messageSumReturn(return_value: bool, total_items: *u64, comptime process_fn: anytype, comptime fmt: []const u8, args: anytype) !bool {
    try process_fn(fmt , args);
    total_items.* += 1;
    return return_value;
}

/// Prints message with a green "OK" on the left
pub fn ok(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath2Strings(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args)) return;
    return core(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args);
}

/// Prints message with a green "OK" on the left (multi-thread)
pub fn ok_mt(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath2Strings(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args)) return;
    return core_mt(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args);
}

/// Prints message with a red "REMOVING" on the left
pub fn removing(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    return core(fmt, "\x1b[31m", i18n.REMOVING_MESSAGE, args);
}

/// Prints results using singular or plural after total
pub fn results(total_items: u64, comptime header_message: []const u8, comptime message_total: []const u8, comptime message_totals: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    return switch (total_items) {
        0    => alignedOk(header_message),
        1    => total(message_total,  .{total_items}),
        else => total(message_totals, .{total_items}),
    };
}

/// Redirects output to stdout
pub fn stdout(str: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    try globals.file_writer_stdout.interface.writeAll(str);
    return globals.file_writer_stdout.interface.flush();
}

/// Redirects output to stderr
pub fn stderr(str: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    try    globals.file_writer_stderr.interface.writeAll(str);
    return globals.file_writer_stderr.interface.flush();
}

/// Prints a blue "Total" with tabs
fn total(comptime result_type: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    try stdout("\n\n\t\t");
    if (config.COMPTIME_EMOJI_COLOR)  try stdout("\x1b[36m");
    try stdout(i18n.TOTAL_MESSAGE);
    if (config.COMPTIME_EMOJI_COLOR)  try stdout("\x1b[0m");

    try stdout("\n\t\t\t");
    const fmt_str: []const u8 = try std.fmt.bufPrint(globals.buffer, "{d} {s}", .{args[0], result_type});
    try stderr(fmt_str);
    return stderr("\n");
}

/// Prints message with a yellow "WARNING" on the left
pub fn warning(comptime fmt: []const u8, args: anytype) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    if (try cleanPath(fmt, "\x1b[33m", i18n.WARNING_MESSAGE, args)) return;
    if (try cleanPath2Strings(fmt, "\x1b[33m", i18n.WARNING_MESSAGE, args)) return;
    if (try cleanPathStringU64(fmt, "\x1b[33m", i18n.WARNING_MESSAGE, args)) return;

    return core(fmt, "\x1b[33m", i18n.WARNING_MESSAGE, args);
}

/// Prints the header to stdout
pub fn header(str: []const u8) !void {
    if (!config.COMPTIME_STDOUT_STDERR) return;

    try globals.file_writer_stdout.interface.writeAll("\n\t");
    try globals.file_writer_stdout.interface.writeAll(str);
    try globals.file_writer_stdout.interface.writeAll("\n");

    return globals.file_writer_stdout.interface.flush();
}

fn cleanPath(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8, args: anytype) !bool {
    if (args.len == 1 and @TypeOf(args[0]) == []const u8) {
       // Index of the last EOL character (0 if there is none; then nothing is dropped).
       var i: usize = 0;
       for (args[0]) |c| {
           if (c == '\n' or c == '\r') continue;
           globals.buffer[i] = c;
           i += 1;
       }

       try stderr("\n\t\t");

       try core_mt(fmt, ansi_color, print_message, .{globals.buffer[0..i]});
       return true;
    }

    return false;
}


fn cleanPath2Strings(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8, args: anytype) !bool {
    if (args.len == 2 and @TypeOf(args[0]) == []const u8 and @TypeOf(args[1]) == []const u8) {

        var i: usize = 0;
        for (args[0]) |c| {
            if (c == '\n' or c == '\r') continue;
            globals.buffer[i] = c;
            i += 1;
        }

        try stderr("\n\t\t");

        try core_mt(fmt, ansi_color, print_message, .{globals.buffer[0..i], args[1]});
        return true;
    }

    return false;
}

fn cleanPathStringU64(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8, args: anytype) !bool {
    if (args.len == 2 and @TypeOf(args[0]) == []const u8 and @TypeOf(args[1]) == u64) {
        var i: usize = 0;
        for (args[0]) |c| {
            if (c == '\n' or c == '\r') continue;
            globals.buffer[i] = c;
            i += 1;
        }

        try stderr("\n\t\t");

        try core_mt(fmt, ansi_color, print_message, .{globals.buffer[0..i], args[1]});
        return true;
    }

    return false;
}
