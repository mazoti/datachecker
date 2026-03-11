//! Creates the binary, runs in debug mode and unit tests
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

fn createExecutableForTarget(
    b: *std.Build,
    resolved_target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {

    const ahocorasick_mod = b.addModule("ahocorasick" , .{ .root_source_file = b.path("src/ahocorasick.zig") , .target = resolved_target });
    const config_mod      = b.addModule("config"      , .{ .root_source_file = b.path("src/config.zig")      , .target = resolved_target });
    const globals_mod     = b.addModule("globals"     , .{ .root_source_file = b.path("src/globals.zig")     , .target = resolved_target, .imports = &.{.{ .name = "config", .module = config_mod }} });
    const i18n_mod        = b.addModule("i18n"        , .{ .root_source_file = b.path("src/i18n.zig")        , .target = resolved_target });

    // Required to set an icon on Windows
    const icon_mod = b.addModule("icon", .{ .root_source_file = b.path("src/empty.zig"), .target = resolved_target });

    const print_mod = b.addModule("print", .{ .root_source_file = b.path("src/print.zig"), .target = resolved_target, .imports = &.{
        .{ .name = "config"  , .module = config_mod  },
        .{ .name = "globals" , .module = globals_mod },
        .{ .name = "i18n"    , .module = i18n_mod    },
    } });

    const core_mod = b.addModule("core", .{ .root_source_file = b.path("src/modules/core.zig"), .target = resolved_target, .imports = &.{
        .{ .name = "ahocorasick" , .module = ahocorasick_mod },
        .{ .name = "config"      , .module = config_mod      },
        .{ .name = "globals"     , .module = globals_mod     },
        .{ .name = "i18n"        , .module = i18n_mod        },
        .{ .name = "print"       , .module = print_mod       },
    } });

    const exe = b.addExecutable(.{ .name = "datachecker", .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = resolved_target, .optimize = optimize, .imports = &.{
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
    const ahocorasick_mod = b.addModule("ahocorasick" , .{ .root_source_file = b.path("src/ahocorasick.zig") , .target = target });
    const config_mod      = b.addModule("config"      , .{ .root_source_file = b.path("src/config.zig")      , .target = target });

    const ahocorasick_tests = b.addTest(.{ .root_module = ahocorasick_mod });
    const config_tests      = b.addTest(.{ .root_module = config_mod      });
    const exe_tests         = b.addTest(.{ .root_module = exe.root_module });

    const run_ahocorasick_tests = b.addRunArtifact(ahocorasick_tests);
    const run_config_tests      = b.addRunArtifact(config_tests);
    const run_exe_tests         = b.addRunArtifact(exe_tests);

    test_step.dependOn(&run_ahocorasick_tests.step);
    test_step.dependOn(&run_config_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // -------------------------------------------------------------------------
    // all: every target Zig can cross-compile to
    // -------------------------------------------------------------------------
    const build_all_step = b.step("all", "Build for every target Zig supports");

    // All targets are expressed as { query, output_folder_name } pairs so the
    // deploy helper's allocPrint format strings are bypassed and each triple
    // gets a stable, unique directory under zig-out/.
    const all_targets = [_]std.Target.Query{
        // ── FreeBSD ──────────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .freebsd                         },
        .{ .cpu_arch = .x86         , .os_tag = .freebsd                         },
        .{ .cpu_arch = .aarch64     , .os_tag = .freebsd                         },
        .{ .cpu_arch = .arm         , .os_tag = .freebsd                         },
        .{ .cpu_arch = .riscv64     , .os_tag = .freebsd                         },
        .{ .cpu_arch = .powerpc64   , .os_tag = .freebsd                         },
        .{ .cpu_arch = .mips        , .os_tag = .freebsd                         },
        // ── NetBSD ───────────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .netbsd                          },
        .{ .cpu_arch = .x86         , .os_tag = .netbsd                          },
        .{ .cpu_arch = .aarch64     , .os_tag = .netbsd                          },
        .{ .cpu_arch = .arm         , .os_tag = .netbsd                          },
        .{ .cpu_arch = .sparc64     , .os_tag = .netbsd                          },
        .{ .cpu_arch = .powerpc     , .os_tag = .netbsd                          },
        .{ .cpu_arch = .mips        , .os_tag = .netbsd                          },
        // ── OpenBSD ──────────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .openbsd                         },
        .{ .cpu_arch = .x86         , .os_tag = .openbsd                         },
        .{ .cpu_arch = .aarch64     , .os_tag = .openbsd                         },
        .{ .cpu_arch = .arm         , .os_tag = .openbsd                         },
        .{ .cpu_arch = .riscv64     , .os_tag = .openbsd                         },
        .{ .cpu_arch = .mips64el    , .os_tag = .openbsd                         },
        .{ .cpu_arch = .powerpc64   , .os_tag = .openbsd                         },
        .{ .cpu_arch = .sparc64     , .os_tag = .openbsd                         },
        // ── DragonFlyBSD ─────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .dragonfly                       },
        // ── Solaris / illumos ─────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .illumos                         },
        // ── macOS ─────────────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .macos                           },
        .{ .cpu_arch = .aarch64     , .os_tag = .macos                           },
        // ── iOS ───────────────────────────────────────────────────────────────
        .{ .cpu_arch = .aarch64     , .os_tag = .ios                             },
        .{ .cpu_arch = .x86_64      , .os_tag = .ios    , .abi = .simulator      },
        .{ .cpu_arch = .aarch64     , .os_tag = .ios    , .abi = .simulator      },
        // ── tvOS ──────────────────────────────────────────────────────────────
        .{ .cpu_arch = .aarch64     , .os_tag = .tvos                            },
        .{ .cpu_arch = .x86_64      , .os_tag = .tvos   , .abi = .simulator      },
        .{ .cpu_arch = .aarch64     , .os_tag = .tvos   , .abi = .simulator      },
        // ── watchOS ───────────────────────────────────────────────────────────
        .{ .cpu_arch = .arm         , .os_tag = .watchos                         },
        .{ .cpu_arch = .x86_64      , .os_tag = .watchos, .abi = .simulator      },
        .{ .cpu_arch = .aarch64     , .os_tag = .watchos, .abi = .simulator      },
        // ── visionOS ──────────────────────────────────────────────────────────
        .{ .cpu_arch = .aarch64     , .os_tag = .visionos                        },
        .{ .cpu_arch = .aarch64     , .os_tag = .visionos, .abi = .simulator     },
        // ── Windows ───────────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .windows, .abi = .gnu            },
        .{ .cpu_arch = .x86_64      , .os_tag = .windows, .abi = .msvc           },
        .{ .cpu_arch = .x86         , .os_tag = .windows, .abi = .gnu            },
        .{ .cpu_arch = .x86         , .os_tag = .windows, .abi = .msvc           },
        .{ .cpu_arch = .aarch64     , .os_tag = .windows, .abi = .gnu            },
        .{ .cpu_arch = .aarch64     , .os_tag = .windows, .abi = .msvc           },
        .{ .cpu_arch = .thumb       , .os_tag = .windows, .abi = .gnu            },
        // ── Linux / glibc ─────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .x86         , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .aarch64     , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .aarch64_be  , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .gnueabi          },
        .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .gnueabihf        },
        .{ .cpu_arch = .armeb       , .os_tag = .linux, .abi = .gnueabi          },
        .{ .cpu_arch = .armeb       , .os_tag = .linux, .abi = .gnueabihf        },
        .{ .cpu_arch = .thumb       , .os_tag = .linux, .abi = .gnueabi          },
        .{ .cpu_arch = .thumb       , .os_tag = .linux, .abi = .gnueabihf        },
        .{ .cpu_arch = .mips        , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .mipsel      , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .mips64      , .os_tag = .linux, .abi = .gnuabi64         },
        .{ .cpu_arch = .mips64el    , .os_tag = .linux, .abi = .gnuabi64         },
        .{ .cpu_arch = .powerpc     , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .powerpc64   , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .powerpc64le , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .riscv32     , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .riscv64     , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .sparc       , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .sparc64     , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .s390x       , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .loongarch64 , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .csky        , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .m68k        , .os_tag = .linux, .abi = .gnu              },
        .{ .cpu_arch = .hexagon     , .os_tag = .linux, .abi = .gnu              },
        // ── Linux / musl ──────────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .x86         , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .aarch64     , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .aarch64_be  , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .musleabi         },
        .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .musleabihf       },
        .{ .cpu_arch = .armeb       , .os_tag = .linux, .abi = .musleabi         },
        .{ .cpu_arch = .armeb       , .os_tag = .linux, .abi = .musleabihf       },
        .{ .cpu_arch = .thumb       , .os_tag = .linux, .abi = .musleabi         },
        .{ .cpu_arch = .thumb       , .os_tag = .linux, .abi = .musleabihf       },
        .{ .cpu_arch = .mips        , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .mipsel      , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .mips64      , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .mips64el    , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .powerpc     , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .powerpc64   , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .powerpc64le , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .riscv32     , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .riscv64     , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .sparc64     , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .s390x       , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .loongarch64 , .os_tag = .linux, .abi = .musl             },
        .{ .cpu_arch = .m68k        , .os_tag = .linux, .abi = .musl             },
        // ── Linux / Android ───────────────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .linux, .abi = .android          },
        .{ .cpu_arch = .x86         , .os_tag = .linux, .abi = .android          },
        .{ .cpu_arch = .aarch64     , .os_tag = .linux, .abi = .android          },
        .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .android          },
        // ── WASI ──────────────────────────────────────────────────────────────
        .{ .cpu_arch = .wasm32      , .os_tag = .wasi                            },
        // ── WebAssembly / freestanding ────────────────────────────────────────
        .{ .cpu_arch = .wasm32      , .os_tag = .freestanding                    },
        .{ .cpu_arch = .wasm64      , .os_tag = .freestanding                    },
        // ── Freestanding (bare-metal) ─────────────────────────────────────────
        .{ .cpu_arch = .x86_64      , .os_tag = .freestanding                    },
        .{ .cpu_arch = .x86         , .os_tag = .freestanding                    },
        .{ .cpu_arch = .aarch64     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .aarch64_be  , .os_tag = .freestanding                    },
        .{ .cpu_arch = .arm         , .os_tag = .freestanding                    },
        .{ .cpu_arch = .armeb       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .thumb       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .mips        , .os_tag = .freestanding                    },
        .{ .cpu_arch = .mipsel      , .os_tag = .freestanding                    },
        .{ .cpu_arch = .mips64      , .os_tag = .freestanding                    },
        .{ .cpu_arch = .mips64el    , .os_tag = .freestanding                    },
        .{ .cpu_arch = .powerpc     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .powerpc64   , .os_tag = .freestanding                    },
        .{ .cpu_arch = .powerpc64le , .os_tag = .freestanding                    },
        .{ .cpu_arch = .riscv32     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .riscv64     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .sparc       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .sparc64     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .s390x       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .loongarch64 , .os_tag = .freestanding                    },
        .{ .cpu_arch = .m68k        , .os_tag = .freestanding                    },
        .{ .cpu_arch = .avr         , .os_tag = .freestanding                    },
        .{ .cpu_arch = .bpfel       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .bpfeb       , .os_tag = .freestanding                    },
        .{ .cpu_arch = .nvptx64     , .os_tag = .cuda                            },
        .{ .cpu_arch = .spirv32     , .os_tag = .opencl                          },
        .{ .cpu_arch = .spirv64     , .os_tag = .opencl                          },
        .{ .cpu_arch = .hexagon     , .os_tag = .freestanding                    },
        .{ .cpu_arch = .ve          , .os_tag = .freestanding                    },
    };

    deployAllTargets(&all_targets, b, build_all_step);
}

/// Deploy using zigTriple as the output folder name, works for any query.
fn deployAllTargets(targets: []const std.Target.Query, b: *std.Build, step: *std.Build.Step) void {
    for (targets) |query| {
        const resolved_target = b.resolveTargetQuery(query);
        const binary_build    = createExecutableForTarget(b, resolved_target, .ReleaseFast);

        const triple = query.zigTriple(b.allocator) catch @panic("OOM");

        const target_output = b.addInstallArtifact(binary_build, .{
            .dest_dir = .{ .override = .{ .custom = triple } },
        });

        step.dependOn(&target_output.step);
    }
}
