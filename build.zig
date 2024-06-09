const std = @import("std");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const Compile = Build.Step.Compile;

pub fn build(
    b: *std.Build,
) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "wiz",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/root.zig" } },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const exe_options = b.addOptions();

    const enable_tracy = b.option(bool, "enable_tracy", "Whether tracy should be enabled.") orelse false;
    exe_options.addOption(bool, "enable_tracy", enable_tracy);
    exe_options.addOption(
        bool,
        "enable_tracy_allocation",
        b.option(
            bool,
            "enable_tracy_allocation",
            "Enable using TracyAllocator to monitor allocations.",
        ) orelse enable_tracy,
    );
    exe_options.addOption(
        bool,
        "enable_tracy_callstack",
        b.option(
            bool,
            "enable_tracy_callstack",
            "Enable callstack graphs.",
        ) orelse enable_tracy,
    );
    exe_options.addOption(
        bool,
        "enable_tracy_gpu",
        b.option(bool, "enable_tracy_gpu", "Enable GPU zones") orelse enable_tracy,
    );

    makeExe(b, target, optimize, exe_options, enable_tracy);
    makeOpenglExampleExe(b, target, optimize, exe_options, enable_tracy);
    runTests(b, optimize, target);
}

fn buildTracy(b: *std.Build, exe: *Compile, target: ResolvedTarget) void {
    const client_cpp = "src/tracy/public/TracyClient.cpp";

    // On mingw, we need to opt into windows 7+ to get some features required by tracy.
    const tracy_c_flags: []const []const u8 = if (target.result.isMinGW())
        &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined", "-D_WIN32_WINNT=0x601" }
    else
        &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" };

    exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "src/tracy" } });
    exe.addCSourceFile(.{
        .file = .{ .src_path = .{ .owner = b, .sub_path = client_cpp } },
        .flags = tracy_c_flags,
    });
    exe.linkLibCpp();
    exe.linkLibC();

    if (target.result.os.tag == .windows) {
        exe.linkSystemLibrary("dbghelp");
        exe.linkSystemLibrary("ws2_32");
    }
}

fn buildExe(b: *Build, exe: *Compile, target: ResolvedTarget, enable_tracy: bool) void {
    if (enable_tracy) {
        buildTracy(b, exe, target);
    }

    if (target.result.os.tag == .windows) {
        exe.linkSystemLibrary("opengl32");
    }

    if (target.result.os.tag == .linux) {
        exe.linkLibC();
        exe.linkSystemLibrary("X11");
    }

    b.installArtifact(exe);
}

fn runExe(b: *std.Build, exe: *Compile, name: []const u8, description: []const u8) void {
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(name, description);
    run_step.dependOn(&run_cmd.step);
}

fn makeExe(
    b: *std.Build,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    options: *std.Build.Step.Options,
    enable_tracy: bool,
) void {
    const exe = b.addExecutable(.{
        .name = "wiz",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/main.zig" } },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("build_options", options.createModule());

    buildExe(b, exe, target, enable_tracy);
    runExe(b, exe, "run", "Run the App");
}

fn buildOpenglExample(
    b: *Build,
    exe: *Compile,
    target: ResolvedTarget,
    build_options_module: *std.Build.Module,
    enable_tracy: bool,
) void {
    const wiz_module = b.addModule("wiz", .{
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/wiz.zig" } },
    });

    wiz_module.addImport("build_options", build_options_module);

    exe.root_module.addImport("wiz", wiz_module);
    if (target.result.os.tag == .linux) {
        exe.linkLibC();
        exe.linkSystemLibrary("X11");
    }

    if (enable_tracy) {
        buildTracy(b, exe, target);
    }

    b.installArtifact(exe);

    const opengl_run_cmd = b.addRunArtifact(exe);
    opengl_run_cmd.step.dependOn(b.getInstallStep());
}

fn makeOpenglExampleExe(
    b: *std.Build,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    options: *std.Build.Step.Options,
    enable_tracy: bool,
) void {
    const exe = b.addExecutable(.{
        .name = "opengl-example",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "examples/opengl.zig" } },
        .target = target,
        .optimize = optimize,
    });
    buildOpenglExample(b, exe, target, options.createModule(), enable_tracy);
    runExe(b, exe, "run-opengl-example", "Run the OpenGL example");
}

fn runTests(b: *std.Build, optimize: std.builtin.OptimizeMode, target: ResolvedTarget) void {
    const root_tests = b.addTest(.{
        .name = "root_tests",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/root.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const input_tests = b.addTest(.{
        .name = "input_tests",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/input.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const windows_tests = b.addTest(.{
        .name = "windows_tests",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/windows.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const exe_tests = b.addTest(.{
        .name = "exe_tests",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/main.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const wiz_module_tests = b.addTest(.{
        .name = "wiz_module_tests",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/wiz.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const run_root_tests = b.addRunArtifact(root_tests);
    const run_lib_input_tests = b.addRunArtifact(input_tests);
    const run_lib_windows_tests = b.addRunArtifact(windows_tests);
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const run_wiz_module_tests = b.addRunArtifact(wiz_module_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_root_tests.step);
    test_step.dependOn(&run_lib_input_tests.step);
    test_step.dependOn(&run_lib_windows_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_wiz_module_tests.step);
}
