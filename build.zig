const std = @import("std");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;

fn buildOpengl(b: *Build, target: ResolvedTarget, optimize_mode: std.builtin.OptimizeMode) void {
    const opengl = b.addExecutable(.{
        .name = "opengl-example",
        .root_source_file = .{ .path = "examples/opengl.zig" },
        .target = target,
        .optimize = optimize_mode,
    });

    const wiz_module = b.addModule("wiz", .{
        .root_source_file = .{ .path = "src/wiz.zig" },
    });

    opengl.root_module.addImport("wiz", wiz_module);

    b.installArtifact(opengl);

    const opengl_run_cmd = b.addRunArtifact(opengl);
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

    buildOpengl(b, target, optimize);

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
