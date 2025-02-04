const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Module

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Dependencies

    const sdl_dep = b.dependency("sdl", .{ .target = target, .optimize = optimize });
    const sdl_lib = sdl_dep.artifact("SDL3");
    exe_mod.linkLibrary(sdl_lib);

    // Exexcutable

    const exe = b.addExecutable(.{
        .name = "ntdash",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // Run

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Pass arguments to the executable
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Runs the program");
    run_step.dependOn(&run_cmd.step);

    b.default_step = run_step;

    // Tests

    const @"test" = b.addTest(.{ .root_module = exe_mod });
    const test_cmd = b.addRunArtifact(@"test");

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_cmd.step);
}
