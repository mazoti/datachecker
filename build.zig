//! Creates the binary, runs in debug mode and runs unit tests
const std = @import("std");

fn createExecutableForTarget(
    b: *std.Build,
    resolved_target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const ahocorasick_mod = b.addModule("ahocorasick", .{
        .root_source_file = b.path("src/ahocorasick.zig"),
        .target = resolved_target
    });

    const config_mod = b.addModule("config", .{
        .root_source_file = b.path("src/config.zig"),
        .target = resolved_target
    });

    const globals_mod = b.addModule("globals", .{
        .root_source_file = b.path("src/globals.zig"),
        .target = resolved_target,
        .imports = &.{
            .{ .name = "config", .module = config_mod }
    }});

    const i18n_mod = b.addModule("i18n", .{
        .root_source_file = b.path("src/i18n.zig"),
        .target = resolved_target
    });

    // Required to set an icon on Windows
    const icon_mod = b.addModule("icon", .{
        .root_source_file = b.path("src/empty.zig"),
        .target = resolved_target
    });

    const print_mod = b.addModule("print", .{
        .root_source_file = b.path("src/print.zig"),
        .target = resolved_target,
        .imports = &.{
            .{ .name = "globals", .module = globals_mod },
            .{ .name = "i18n",    .module = i18n_mod    },
    }});

    const core_mod = b.addModule("core", .{
        .root_source_file = b.path("src/modules/core.zig"),
        .target = resolved_target,
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
            .target = resolved_target,
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

    if (resolved_target.result.os.tag == .windows) {
        icon_mod.addWin32ResourceFile(.{ .file = b.path("resources/properties.rc") });
    }

    return exe;
}

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = createExecutableForTarget(b, target, optimize);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd  = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| { run_cmd.addArgs(args); }

    const test_step = b.step("test", "Run tests");

    // Create test modules with default target
    const ahocorasick_mod = b.addModule("ahocorasick", .{
        .root_source_file = b.path("src/ahocorasick.zig"),
        .target = target
    });

    const config_mod = b.addModule("config", .{
        .root_source_file = b.path("src/config.zig"),
        .target = target
    });

    const ahocorasick_tests     = b.addTest(.{ .root_module = ahocorasick_mod });
    const config_tests          = b.addTest(.{ .root_module = config_mod      });
    const exe_tests             = b.addTest(.{ .root_module = exe.root_module });
    const run_ahocorasick_tests = b.addRunArtifact(ahocorasick_tests);
    const run_config_tests      = b.addRunArtifact(config_tests);
    const run_exe_tests         = b.addRunArtifact(exe_tests);

    test_step.dependOn(&run_ahocorasick_tests.step);
    test_step.dependOn(&run_config_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // Windows cross-compilation targets
    const windows_step = b.step("windows", "Build for all Windows targets");

    const windows_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64  , .os_tag = .windows, .abi = .gnu  },
        .{ .cpu_arch = .x86_64  , .os_tag = .windows, .abi = .msvc },
        .{ .cpu_arch = .x86     , .os_tag = .windows, .abi = .gnu  },
        .{ .cpu_arch = .x86     , .os_tag = .windows, .abi = .msvc },
        .{ .cpu_arch = .aarch64 , .os_tag = .windows, .abi = .gnu  },
        .{ .cpu_arch = .aarch64 , .os_tag = .windows, .abi = .msvc },
    };

    for (windows_targets) |win_target| {
        const resolved_target = b.resolveTargetQuery(win_target);
        const win_exe = createExecutableForTarget(b, resolved_target, .ReleaseFast);

        const target_name = std.fmt.allocPrint(
            b.allocator,
            "windows-{s}-{s}",
            .{ @tagName(win_target.cpu_arch.?), @tagName(win_target.abi.?) }
        ) catch @panic("OOM");

        const target_output = b.addInstallArtifact(win_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = target_name,
                },
            },
        });

        windows_step.dependOn(&target_output.step);
    }

    // Linux cross-compilation targets
    const linux_step = b.step("linux", "Build for all Linux targets");

    const linux_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64  , .os_tag = .linux, .abi = .gnu        },
        .{ .cpu_arch = .x86_64  , .os_tag = .linux, .abi = .musl       },
        .{ .cpu_arch = .x86     , .os_tag = .linux, .abi = .gnu        },
        .{ .cpu_arch = .x86     , .os_tag = .linux, .abi = .musl       },
        .{ .cpu_arch = .aarch64 , .os_tag = .linux, .abi = .gnu        },
        .{ .cpu_arch = .aarch64 , .os_tag = .linux, .abi = .musl       },
        .{ .cpu_arch = .arm     , .os_tag = .linux, .abi = .gnueabihf  },
        .{ .cpu_arch = .arm     , .os_tag = .linux, .abi = .musleabihf },
        .{ .cpu_arch = .riscv64 , .os_tag = .linux, .abi = .gnu        },
        .{ .cpu_arch = .riscv64 , .os_tag = .linux, .abi = .musl       },
    };

    for (linux_targets) |linux_target| {
        const resolved_target = b.resolveTargetQuery(linux_target);
        const linux_exe = createExecutableForTarget(b, resolved_target, .ReleaseFast);

        const target_name = std.fmt.allocPrint(
            b.allocator,
            "linux-{s}-{s}",
            .{ @tagName(linux_target.cpu_arch.?), @tagName(linux_target.abi.?) }
        ) catch @panic("OOM");

        const target_output = b.addInstallArtifact(linux_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = target_name,
                },
            },
        });

        linux_step.dependOn(&target_output.step);
    }

    // FreeBSD cross-compilation targets
    const freebsd_step = b.step("freebsd", "Build for all FreeBSD targets");

    const freebsd_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64  , .os_tag = .freebsd },
        .{ .cpu_arch = .x86     , .os_tag = .freebsd },
        .{ .cpu_arch = .aarch64 , .os_tag = .freebsd },
        .{ .cpu_arch = .arm     , .os_tag = .freebsd },
        .{ .cpu_arch = .riscv64 , .os_tag = .freebsd },
    };

    for (freebsd_targets) |freebsd_target| {
        const resolved_target = b.resolveTargetQuery(freebsd_target);
        const freebsd_exe = createExecutableForTarget(b, resolved_target, .ReleaseFast);

        const target_name = std.fmt.allocPrint(
            b.allocator,
            "freebsd-{s}",
            .{ @tagName(freebsd_target.cpu_arch.?) }
        ) catch @panic("OOM");

        const target_output = b.addInstallArtifact(freebsd_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = target_name,
                },
            },
        });

        freebsd_step.dependOn(&target_output.step);
    }

    // NetBSD cross-compilation targets
    const netbsd_step = b.step("netbsd", "Build for all NetBSD targets");

    const netbsd_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64  , .os_tag = .netbsd },
        .{ .cpu_arch = .x86     , .os_tag = .netbsd },
        .{ .cpu_arch = .aarch64 , .os_tag = .netbsd },
        .{ .cpu_arch = .arm     , .os_tag = .netbsd },
    };

    for (netbsd_targets) |netbsd_target| {
        const resolved_target = b.resolveTargetQuery(netbsd_target);
        const netbsd_exe = createExecutableForTarget(b, resolved_target, .ReleaseFast);

        const target_name = std.fmt.allocPrint(
            b.allocator,
            "netbsd-{s}",
            .{ @tagName(netbsd_target.cpu_arch.?) }
        ) catch @panic("OOM");

        const target_output = b.addInstallArtifact(netbsd_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = target_name,
                },
            },
        });

        netbsd_step.dependOn(&target_output.step);
    }
}
