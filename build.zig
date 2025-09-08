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

    const run_step = b.step("run", "Run the player example");
    run_step.dependOn(&run_cmd.step);
}
