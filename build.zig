//! Creates the binary, runs in debug mode and runs unit tests

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ahocorasick_mod = b.addModule("ahocorasick", .{
        .root_source_file = b.path("src/ahocorasick.zig"),
        .target = target
    });

    const config_mod = b.addModule("config", .{
        .root_source_file = b.path("src/config.zig"),
        .target = target
    });

    const globals_mod = b.addModule("globals", .{
        .root_source_file = b.path("src/globals.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "config", .module = config_mod }
    }});

    const i18n_mod = b.addModule("i18n", .{
        .root_source_file = b.path("src/i18n.zig"),
        .target = target
    });

    // Required to set an icon on Windows
    const icon_mod = b.addModule("icon", .{
        .root_source_file = b.path("src/empty.zig"),
        .target = target
    });

    const print_mod = b.addModule("print", .{
        .root_source_file = b.path("src/print.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "globals", .module = globals_mod },
            .{ .name = "i18n",    .module = i18n_mod    },
    }});

    const core_mod = b.addModule("core", .{
        .root_source_file = b.path("src/modules/core.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "ahocorasick" , .module = ahocorasick_mod },
            .{ .name = "config"      , .module = config_mod      },
            .{ .name = "globals"     , .module = globals_mod     },
            .{ .name = "i18n"        , .module = i18n_mod        },
            .{ .name = "print"       , .module = print_mod       },
    }});

    const exe = b.addExecutable(.{
        .name = "datachecker",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ahocorasick" , .module = ahocorasick_mod },
                .{ .name = "icon"        , .module = icon_mod        },
                .{ .name = "config"      , .module = config_mod      },
                .{ .name = "core"        , .module = core_mod        },
                .{ .name = "globals"     , .module = globals_mod     },
                .{ .name = "i18n"        , .module = i18n_mod        },
                .{ .name = "print"       , .module = print_mod       },
    }})});

    if (target.result.os.tag == .windows) {
        icon_mod.addWin32ResourceFile(.{ .file = b.path("resources/properties.rc") });
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd  = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| { run_cmd.addArgs(args); }

    const test_step = b.step("test", "Run tests");

    const ahocorasick_tests     = b.addTest(.{ .root_module = ahocorasick_mod });
    const config_tests          = b.addTest(.{ .root_module = config_mod      });
    const exe_tests             = b.addTest(.{ .root_module = exe.root_module });

    const run_ahocorasick_tests = b.addRunArtifact(ahocorasick_tests);
    const run_config_tests      = b.addRunArtifact(config_tests);
    const run_exe_tests         = b.addRunArtifact(exe_tests);

    test_step.dependOn(&run_ahocorasick_tests.step);
    test_step.dependOn(&run_config_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
