//! Creates the binary, runs in debug mode and unit tests
//!
//! Copyright © 2025-present Marcos Mazoti
//!
//! Commands available:
//!     zig build                         install the host build (zig-out/bin)
//!     zig build run -- folder           build and run, passing what follows `--`
//!     zig build test                    run the unit tests of every module
//!     zig build check                   compile only, nothing is installed (editor / CI)
//!     zig build all                     build every target into zig-out/<triple>/
//!
//! To deploy (needs `xz` in PATH):
//!     zig build deploy -p download
//!     zig build run -- -i download
//!     zig build run -- -drm download
//!     zig build run -- -edrm download
//!
//! `all` and `deploy` can be limited to some targets: a target is built when its
//! triple contains any of the given texts (repeat the option to give several):
//!     zig build deploy -p download -Dtarget-filter=linux-musl -Dtarget-filter=windows

const std = @import("std");

const Module   = std.Build.Module;
const Optimize = std.builtin.Optimize;
const Resolved = std.Build.ResolvedTarget;
const Step     = std.Build.Step;

/// Optimization mode of the `all` and `deploy` builds.
const release_optimize: Optimize = .small;

/// Every module of the program, created for one target and one optimization mode.
/// The executable and all the test binaries share these instances, so what the
/// tests compile is exactly what ships.
const Modules = struct {
    ahocorasick: *Module,
    config:      *Module,
    core:        *Module,
    data:        *Module,
    globals:     *Module,
    i18n:        *Module,
    icon:        *Module,
    main:        *Module,
    output:      *Module,
    print:       *Module,

    fn create(b: *std.Build, target: Resolved, optimize: Optimize) Modules {
        const ahocorasick: *Module = newModule(b, "src/ahocorasick.zig", target, optimize, &.{});
        const i18n:        *Module = newModule(b, "src/i18n.zig", target, optimize, &.{});

        const config:      *Module = newModule(b, "src/config.zig", target, optimize, &.{
            .{ .name = "i18n", .module = i18n },
        });

        const data: *Module = newModule(b, "src/data.zig", target, optimize, &.{
            .{ .name = "config" , .module = config },
        });

        const globals: *Module = newModule(b, "src/globals.zig", target, optimize, &.{
            .{ .name = "ahocorasick" , .module = ahocorasick },
            .{ .name = "config"      , .module = config      },
        });
        const print: *Module = newModule(b, "src/print.zig", target, optimize, &.{
            .{ .name = "config"  , .module = config  },
            .{ .name = "globals" , .module = globals },
            .{ .name = "i18n"    , .module = i18n    },
        });

        const output: *Module = newModule(b, "src/output.zig", target, optimize, &.{
            .{ .name = "config"      , .module = config      },
            .{ .name = "globals"     , .module = globals     },
            .{ .name = "i18n"        , .module = i18n        },
            .{ .name = "print"       , .module = print       },
        });

        const core: *Module = newModule(b, "src/modules/core.zig", target, optimize, &.{
            .{ .name = "ahocorasick" , .module = ahocorasick },
            .{ .name = "config"      , .module = config      },
            .{ .name = "data"        , .module = data        },
            .{ .name = "globals"     , .module = globals     },
            .{ .name = "i18n"        , .module = i18n        },
            .{ .name = "output"      , .module = output      },
            .{ .name = "print"       , .module = print       },
        });

        // Required to set an icon on Windows
        const icon: *Module = newModule(b, "src/empty.zig", target, optimize, &.{});
        icon.addWin32ResourceFile(.{ .file = b.path("resources/properties.rc") });

        const main: *Module = newModule(b, "src/main.zig", target, optimize, &.{
            .{ .name = "ahocorasick" , .module = ahocorasick },
            .{ .name = "icon"        , .module = icon        },
            .{ .name = "config"      , .module = config      },
            .{ .name = "core"        , .module = core        },
            .{ .name = "globals"     , .module = globals     },
            .{ .name = "i18n"        , .module = i18n        },
            .{ .name = "output"      , .module = output      },
            .{ .name = "print"       , .module = print       },
        });

        return .{
            .ahocorasick = ahocorasick,
            .config      = config,
            .core        = core,
            .data        = data,
            .globals     = globals,
            .i18n        = i18n,
            .icon        = icon,
            .main        = main,
            .output      = output,
            .print       = print,
        };
    }
};

fn newModule(b: *std.Build, path: []const u8, target: Resolved, optimize: Optimize, imports: []const Module.Import) *Module {
    return b.createModule(.{
        .root_source_file = b.path(path),
        .target           = target,
        .optimize         = optimize,
        .imports          = imports,
    });
}

fn addDatachecker(b: *std.Build, modules: Modules) *Step.Compile {
    return b.addExecutable(.{ .name = "datachecker", .root_module = modules.main });
}

pub fn build(b: *std.Build) void {
    const target:   Resolved  = b.standardTargetOptions(.{});
    const optimize: Optimize  = b.standardOptimizeOption(.{});

    const modules: Modules    = Modules.create(b, target, optimize);

    const exe: *Step.Compile  = addDatachecker(b, modules);
    b.installArtifact(exe);

    const run_step: *Step     = b.step("run", "Run the app");
    const run_cmd:  *Step.Run = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    // Compiles without installing anything: meant for editors (ZLS build-on-save) and CI.
    const check_step: *Step = b.step("check", "Compile the app without installing it");
    check_step.dependOn(&addDatachecker(b, modules).step);

    // Zig only collects `test` blocks from the root module of a compilation, so each
    // module needs its own test binary or its tests are silently skipped.
    const unit_tests = [_]struct { name: []const u8, module: *Module }{
        .{ .name = "ahocorasick" , .module = modules.ahocorasick },
        .{ .name = "config"      , .module = modules.config      },
        .{ .name = "core"        , .module = modules.core        },
        .{ .name = "datachecker" , .module = modules.main        },
        .{ .name = "globals"     , .module = modules.globals     },
        .{ .name = "i18n"        , .module = modules.i18n        },
        .{ .name = "print"       , .module = modules.print       },
    };

    const test_step: *Step = b.step("test", "Run tests");
    for (unit_tests) |unit| {
        const compile:  *Step.Compile = b.addTest(.{ .name = unit.name, .root_module = unit.module });
        const run_unit: *Step.Run     = b.addRunArtifact(compile);
        test_step.dependOn(&run_unit.step);
    }

    // -------------------------------------------------------------------------
    // all: every target of `all_targets`
    // -------------------------------------------------------------------------
    const build_all_step: *Step = b.step("all", "Build every target of the table");
    const deploy_step:    *Step = b.step("deploy", "Build and xz-compress releases for every target");

    const target_filter: []const []const u8 = b.option(
        []const []const u8,
        "target-filter",
        "Only build the targets whose triple contains this text, e.g. -Dtarget-filter=linux-musl (repeatable)",
    ) orelse &.{};

    deployAllTargets(b, &all_targets, target_filter, build_all_step, deploy_step);
}

/// Build every target, keep raw artifacts under `all`, and xz-compress them under `deploy`.
fn deployAllTargets(
    b: *std.Build,
    targets: []const std.Target.Query,
    filters: []const []const u8,
    build_all_step: *Step,
    deploy_step: *Step,
) void {
    // Located when the step runs (not while configuring), so a missing `xz` is one
    // clear error instead of one failure per target.
    const xz_exe: std.Build.LazyPath = b.findProgramLazy(.{ .names = &.{"xz"} });

    // This empty placeholder is installed next to every compressed release.
    const empty_sha3_sidecar: std.Build.LazyPath = b.addWriteFiles().add("datachecker.xz.sha3_256", "");

    var selected: usize = 0;
    for (targets) |query| {
        // The triple names the output folder: zig-out/<triple>/ and download/<triple>/.
        const triple: []const u8 = query.zigTriple(b.allocator) catch @panic("OOM");
        if (!matchesAny(triple, filters)) continue;
        selected += 1;

        const resolved_target: Resolved = b.resolveTargetQuery(query);
        const binary_build: *Step.Compile = addDatachecker(b, Modules.create(b, resolved_target, release_optimize));

        // Keep the uncompressed builds available through `zig build all`.
        const target_output: *Step.InstallArtifact = b.addInstallArtifact(binary_build, .{
            .dest_dir = .{ .override = .{ .custom = triple } },
        });
        build_all_step.dependOn(&target_output.step);

        // Compress the emitted binary on the build host. Writing to stdout
        // avoids storing the original executable name in the XZ stream.
        const xz_cmd: *Step.Run = Step.Run.create(b, b.fmt("xz {s}", .{triple}));
        xz_cmd.addFileArg(xz_exe);
        xz_cmd.addArgs(&.{ "-9", "-c" });
        xz_cmd.addFileArg(binary_build.getEmittedBin());
        const xz_output: std.Build.LazyPath = xz_cmd.captureStdOut(.{
            .basename = b.fmt("datachecker-{s}.xz", .{triple}),
        });

        // `-p download` installs these at ./download/<triple>/.
        const install_xz: *Step.InstallFile = b.addInstallFileWithDir(
            xz_output,
            .prefix,
            b.fmt("{s}/datachecker.xz", .{triple}),
        );
        deploy_step.dependOn(&install_xz.step);

        // Install the empty SHA3-256 sidecar placeholder next to the archive, and only
        // once the archive is installed: a target that fails to build or to compress must
        // not leave behind a folder that holds nothing but the sidecar.
        const install_sha3_sidecar: *Step.InstallFile = b.addInstallFileWithDir(
            empty_sha3_sidecar,
            .prefix,
            b.fmt("{s}/datachecker.xz.sha3_256", .{triple}),
        );
        install_sha3_sidecar.step.dependOn(&install_xz.step);
        deploy_step.dependOn(&install_sha3_sidecar.step);
    }

    // A typo in -Dtarget-filter must not look like a successful (empty) build.
    if (selected == 0) {
        const no_match: *Step.Fail = Step.Fail.create(b, "-Dtarget-filter does not match any known target");
        build_all_step.dependOn(&no_match.step);
        deploy_step.dependOn(&no_match.step);
    }
}

/// True when `filters` is empty or when `triple` contains at least one of them.
fn matchesAny(triple: []const u8, filters: []const []const u8) bool {
    if (filters.len == 0) return true;
    for (filters) |filter| {
        if (std.mem.find(u8, triple, filter) != null) return true;
    }
    return false;
}

/// Left out on purpose (worth re-checking when Zig is upgraded):
///   - no OS to scan folders on: every *-freestanding row, spirv32/spirv64-opencl, nvptx64-cuda
///   - no libc in Zig: x86_64-illumos, x86_64-dragonfly, mips-freebsd
///   - Apple device builds that do not build or link: aarch64-ios, aarch64-tvos,
///     aarch64-visionos, arm-watchos (their *-simulator variants are kept)
///   - no linker or backend support: sparc-linux-gnu, sparc64-netbsd, m68k-linux-gnu,
///     m68k-linux-musl, csky-linux-gnu, hexagon-linux-gnu
const all_targets = [_]std.Target.Query{
    // ── FreeBSD ──────────────────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .freebsd                         },
    .{ .cpu_arch = .x86         , .os_tag = .freebsd                         },
    .{ .cpu_arch = .aarch64     , .os_tag = .freebsd                         },
    .{ .cpu_arch = .arm         , .os_tag = .freebsd                         },
    .{ .cpu_arch = .riscv64     , .os_tag = .freebsd                         },
    .{ .cpu_arch = .powerpc64   , .os_tag = .freebsd                         },
    // ── NetBSD ───────────────────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .netbsd                          },
    .{ .cpu_arch = .x86         , .os_tag = .netbsd                          },
    .{ .cpu_arch = .aarch64     , .os_tag = .netbsd                          },
    .{ .cpu_arch = .arm         , .os_tag = .netbsd                          },
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
    // ── macOS ─────────────────────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .macos                           },
    .{ .cpu_arch = .aarch64     , .os_tag = .macos                           },
    // ── iOS (simulator only) ──────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .ios    , .abi = .simulator      },
    .{ .cpu_arch = .aarch64     , .os_tag = .ios    , .abi = .simulator      },
    // ── tvOS (simulator only) ─────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .tvos   , .abi = .simulator      },
    .{ .cpu_arch = .aarch64     , .os_tag = .tvos   , .abi = .simulator      },
    // ── watchOS (simulator only) ──────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .watchos, .abi = .simulator      },
    .{ .cpu_arch = .aarch64     , .os_tag = .watchos, .abi = .simulator      },
    // ── visionOS (simulator only) ─────────────────────────────────────────
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
    .{ .cpu_arch = .sparc64     , .os_tag = .linux, .abi = .gnu              },
    .{ .cpu_arch = .s390x       , .os_tag = .linux, .abi = .gnu              },
    .{ .cpu_arch = .loongarch64 , .os_tag = .linux, .abi = .gnu              },
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
    // ── Linux / Android ───────────────────────────────────────────────────
    .{ .cpu_arch = .x86_64      , .os_tag = .linux, .abi = .android          },
    .{ .cpu_arch = .x86         , .os_tag = .linux, .abi = .android          },
    .{ .cpu_arch = .aarch64     , .os_tag = .linux, .abi = .android          },
    .{ .cpu_arch = .arm         , .os_tag = .linux, .abi = .android          },
    // ── WASI ──────────────────────────────────────────────────────────────
    .{ .cpu_arch = .wasm32      , .os_tag = .wasi                            },
};
