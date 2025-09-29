const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("examples/player/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zigaudio", .module = lib_mod }},
    });
    // Always add zoto module for playback
    const zoto_dep = b.dependency("zoto", .{ .target = target, .optimize = optimize });
    const zoto_mod = zoto_dep.module("zoto");
    exe_mod.addImport("zoto", zoto_mod);

    const exe = b.addExecutable(.{
        .name = "player",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const build_player_step = b.step("player", "Build the player example");
    build_player_step.dependOn(&exe.step);

    const run_step = b.step("run", "Run the player example");
    run_step.dependOn(&run_cmd.step);

    // Bench binary
    const bench_mod = b.createModule(.{
        .root_source_file = b.path("examples/bench/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zigaudio", .module = lib_mod }},
    });
    const bench_exe = b.addExecutable(.{
        .name = "bench",
        .root_module = bench_mod,
    });
    b.installArtifact(bench_exe);
    const bench_run = b.addRunArtifact(bench_exe);
    if (b.args) |args| bench_run.addArgs(args);
    const bench_step = b.step("bench", "Run the bench example");
    bench_step.dependOn(&bench_run.step);

    // Bench file binary
    const bench_file_mod = b.createModule(.{
        .root_source_file = b.path("examples/bench_file/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zigaudio", .module = lib_mod }},
    });
    const bench_file_exe = b.addExecutable(.{
        .name = "bench_file",
        .root_module = bench_file_mod,
    });
    b.installArtifact(bench_file_exe);

    // Convert example
    const convert_mod = b.createModule(.{
        .root_source_file = b.path("examples/convert/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zigaudio", .module = lib_mod }},
    });
    const convert_exe = b.addExecutable(.{
        .name = "convert",
        .root_module = convert_mod,
    });
    b.installArtifact(convert_exe);

    // Test target
    const test_exe = b.addTest(.{
        .name = "test",
        .root_module = lib_mod,
    });
    const test_run = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_run.step);
}
