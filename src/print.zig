//! Functions to output data in stdout and stderr
//!
//! Copyright © 2025-present Marcos Mazoti

const std     = @import("std");

const config  = @import("config");
const globals = @import("globals");
const i18n    = @import("i18n");

/// Prints message with aligned "OK" status (moves cursor up and clears line)
pub fn alignedOk(message: []const u8) !void {
    const fmt_str: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "\x1b[1A\x1b[2K{s}",
        .{message[1..message.len - 1]});
    try stdout(fmt_str);

    if (i18n.ALIGNED_OK_SPACES > message.len) {
        for (0..(i18n.ALIGNED_OK_SPACES - message.len)) |_| { _ = try stdout(" "); }

        if (globals.config_parsed.value.COLOR) {
            const ok_str: []const u8 = try std.fmt.bufPrint(&globals.max_path_buffer, "\x1b[32m{s}\x1b[0m",
                .{i18n.OK_MESSAGE});
            return stdout(ok_str);
        }
    }

    return stdout(i18n.OK_MESSAGE);
}

/// Prints message with a green "CHECK" on the left
pub fn check(comptime fmt: []const u8, args: anytype) !void {
    return core(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args);
}

/// Prints duplicate files grouped by size
pub fn duplicateFiles(duplicates: *const std.ArrayList(std.ArrayList([]u8))) !void {
    for (duplicates.items) |results_list| {
        const stat: std.Io.File.Stat = globals.file_stats.get(results_list.items[0])
            orelse try std.Io.Dir.cwd().statFile(globals.io, results_list.items[0], .{});

        const plural: []const u8 = if (stat.size > 1) "bytes:" else "byte:";

        const data: []const u8 = if (globals.config_parsed.value.COLOR) try std.fmt.bufPrint(globals.buffer,
            "\n\t\t\x1b[33m{} {s}\x1b[0m\n", .{stat.size, plural}) else
            try std.fmt.bufPrint(globals.buffer, "\n\t\t{} {s}\n", .{stat.size, plural});

        try stderr(data);

        for (results_list.items) |result| {
            try stderr(try std.fmt.bufPrint(globals.buffer, "\n\t\t\t{s}", .{result}));
        }

        try stderr("\n");
    }
}

/// Prints message with a red "ERROR" on the left
pub fn err(comptime fmt: []const u8, args: anytype) !void {
    return core(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args);
}

/// Prints error message at stderr and exits with error code 1
pub fn errorDirectory(directory_path: []const u8) noreturn {
    err("\n{s}", .{i18n.ERROR_INPUT_DIRECTORY}) catch {};

    const data: []const u8 = std.fmt.bufPrint(globals.buffer, " \"{s}\"\n\n", .{directory_path}) catch "";
    stderr(data) catch {};

    std.process.exit(1);
}

/// Prints message with a green "OK" on the left
pub fn ok(comptime fmt: []const u8, args: anytype) !void {
    return core(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args);
}

/// Prints results using singular or plural after total
pub fn results(total_items: u64, comptime header_message: []const u8, comptime message_total: []const u8,
comptime message_totals: []const u8) !void {
    return switch (total_items) {
        0    => alignedOk(header_message),
        1    => total(message_total,  .{total_items}),
        else => total(message_totals, .{total_items}),
    };
}

/// Redirects output to stdout
pub fn stdout(str: []const u8) !void {
    try globals.file_writer_stdout.interface.writeAll(str);
    return globals.file_writer_stdout.interface.flush();
}

/// Redirects output to stderr
pub fn stderr(str: []const u8) !void {
    try globals.file_writer_stderr.interface.writeAll(str);
    return globals.file_writer_stderr.interface.flush();
}

/// Prints message with a yellow "WARNING" on the left
pub fn warning(comptime fmt: []const u8, args: anytype) !void {
    return core(fmt, "\x1b[33m", i18n.WARNING_MESSAGE, args);
}

/// Core printing function with optional ANSI color codes
fn core(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8,
args: anytype) !void {
    const fmt_str: []const u8 = try std.fmt.bufPrint(globals.buffer, fmt, args);

    // ANSI color format: ESC[<code>m <text> ESC[0m (reset)
    const data: []const u8 = if (globals.config_parsed.value.COLOR) try std.fmt.bufPrint(&globals.max_path_buffer,
        "{s}{s}\x1b[0m{s}", .{ansi_color, print_message, fmt_str}) else
            try std.fmt.bufPrint(&globals.max_path_buffer, "{s}{s}", .{print_message, fmt_str});

    return stderr(data);
}

/// Prints a blue "Total" with tabs
fn total(comptime fmt: []const u8, args: anytype) !void {
    return core(fmt, "\x1b[36m", i18n.TOTAL_MESSAGE, args);
}

/// Prints message with a green "OK" on the left (multi-thread)
pub fn ok_mt(comptime fmt: []const u8, args: anytype) !void {
    return core_mt(fmt, "\x1b[32m", i18n.OK_MESSAGE_FILE, args);
}

/// Prints message with a red "ERROR" on the left (multi-thread)
pub fn err_mt(comptime fmt: []const u8, args: anytype) !void {
    return core_mt(fmt, "\x1b[31m", i18n.ERROR_MESSAGE, args);
}

/// Prints message with a green "CHECK" on the left (multi-thread)
pub fn check_mt(comptime fmt: []const u8, args: anytype) !void {
    return core_mt(fmt, "\x1b[32m", i18n.CHECK_MESSAGE, args);
}

/// Core printing function with optional ANSI color codes (multi-thread)
fn core_mt(comptime fmt: []const u8, comptime ansi_color: []const u8, comptime print_message: []const u8,
args: anytype) !void {
    const fmt_str: []const u8 = try std.fmt.allocPrint(globals.alloc.*, fmt, args);
    defer globals.alloc.free(fmt_str);

    // ANSI color format: ESC[<code>m <text> ESC[0m (reset)
    const data: []const u8 = if (globals.config_parsed.value.COLOR) try std.fmt.allocPrint(globals.alloc.*,
        "{s}{s}\x1b[0m{s}", .{ansi_color, print_message, fmt_str}) else
        try std.fmt.allocPrint(globals.alloc.*, "{s}{s}", .{print_message, fmt_str});

    defer globals.alloc.free(data);

    return stderr(data);
}
