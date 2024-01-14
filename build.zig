const std = @import("std");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const Compile = Build.Step.Compile;

fn buildOpengl(b: *Build, opengl_exe: *Compile) void {
    const wiz_module = b.addModule("wiz", .{
        .root_source_file = .{ .path = "src/wiz.zig" },
    });

    opengl_exe.root_module.addImport("wiz", wiz_module);

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
    buildOpengl(b, opengl_example_exe);

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

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_lib_input_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
