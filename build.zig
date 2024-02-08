const std = @import("std");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const Compile = Build.Step.Compile;

fn buildOpengl(b: *Build, opengl_exe: *Compile, target: ResolvedTarget, build_options_module: *std.Build.Module, enable_tracy: bool) void {
    const wiz_module = b.addModule("wiz", .{
        .root_source_file = .{ .path = "src/wiz.zig" },
    });

    wiz_module.addImport("build_options", build_options_module);

    opengl_exe.root_module.addImport("wiz", wiz_module);

    if (enable_tracy) {
        const client_cpp = "src/tracy/public/TracyClient.cpp";

        // On mingw, we need to opt into windows 7+ to get some features required by tracy.
        const tracy_c_flags: []const []const u8 = if (target.result.isMinGW())
            &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined", "-D_WIN32_WINNT=0x601" }
        else
            &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" };

        opengl_exe.addIncludePath(.{ .path = "src/tracy" });
        opengl_exe.addCSourceFile(.{
            .file = .{ .path = client_cpp },
            .flags = tracy_c_flags,
        });
        opengl_exe.linkLibCpp();
        opengl_exe.linkLibC();

        if (target.result.os.tag == .windows) {
            opengl_exe.linkSystemLibrary("dbghelp");
            opengl_exe.linkSystemLibrary("ws2_32");
        }
    }

    b.installArtifact(opengl_exe);

    const opengl_run_cmd = b.addRunArtifact(opengl_exe);
    opengl_run_cmd.step.dependOn(b.getInstallStep());
}

pub fn build(
    b: *std.Build,
) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "wiz",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "wiz",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const exe_options = b.addOptions();

    const enable_tracy = b.option(bool, "enable_tracy", "Whether tracy should be enabled.") orelse false;
    exe_options.addOption(bool, "enable_tracy", enable_tracy);
    exe_options.addOption(bool, "enable_tracy_allocation", b.option(
        bool,
        "enable_tracy_allocation",
        "Enable using TracyAllocator to monitor allocations.",
    ) orelse enable_tracy);
    exe_options.addOption(bool, "enable_tracy_callstack", b.option(bool, "enable_tracy_callstack", "Enable callstack graphs.") orelse enable_tracy);
    exe_options.addOption(bool, "enable_tracy_gpu", b.option(bool, "enable_tracy_gpu", "Enable GPU zones") orelse enable_tracy);
    exe.root_module.addImport("build_options", exe_options.createModule());

    if (enable_tracy) {
        const client_cpp = "src/tracy/public/TracyClient.cpp";

        // On mingw, we need to opt into windows 7+ to get some features required by tracy.
        const tracy_c_flags: []const []const u8 = if (target.result.isMinGW())
            &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined", "-D_WIN32_WINNT=0x601" }
        else
            &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" };

        exe.addIncludePath(.{ .path = "src/tracy" });
        exe.addCSourceFile(.{
            .file = .{ .path = client_cpp },
            .flags = tracy_c_flags,
        });
        exe.linkLibCpp();
        exe.linkLibC();

        if (target.result.os.tag == .windows) {
            exe.linkSystemLibrary("dbghelp");
            exe.linkSystemLibrary("ws2_32");
        }
    }

    exe.linkSystemLibrary("opengl32");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const opengl_example_exe = b.addExecutable(.{
        .name = "opengl-example",
        .root_source_file = .{ .path = "examples/opengl.zig" },
        .target = target,
        .optimize = optimize,
    });
    buildOpengl(b, opengl_example_exe, target, exe_options.createModule(), enable_tracy);

    const opengl_example_run_cmd = b.addRunArtifact(opengl_example_exe);
    opengl_example_run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        opengl_example_run_cmd.addArgs(args);
    }

    const opengl_example_run_step = b.step("run-opengl-example", "Run the OpenGL example");
    opengl_example_run_step.dependOn(&opengl_example_run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const lib_input_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/input.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_input_unit_tests = b.addRunArtifact(lib_input_unit_tests);
    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const wiz_module_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/wiz.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_wiz_module_unit_tests = b.addRunArtifact(wiz_module_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_lib_input_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_wiz_module_unit_tests.step);
}
