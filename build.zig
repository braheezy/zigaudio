const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const simd = b.option(bool, "simd", "Enable SIMD code paths") orelse false;

    // Create AAC decoder static library
    const faad2_dep = b.dependency(
        "faad2",
        .{ .target = target, .optimize = optimize },
    );
    const aac_lib = faad2_dep.artifact("faad2");

    // Create zigaudio library module
    const lib_mod = b.addModule("zigaudio", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.linkLibrary(aac_lib);
    const options = b.addOptions();
    options.addOption(bool, "simd", simd);
    lib_mod.addOptions("build_options", options);

    // Test target
    const test_exe = b.addTest(.{
        .name = "test",
        .root_module = lib_mod,
    });
    const test_run = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_run.step);

    // Build examples (only when explicitly requested)
    buildExamples(b, lib_mod, target, optimize);
}

fn buildExamples(
    b: *std.Build,
    lib_mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    // Player example
    {
        const zoto_dep = b.dependency("zoto", .{ .target = target, .optimize = optimize });
        const zoto_mod = zoto_dep.module("zoto");

        const player_mod = b.createModule(.{
            .root_source_file = b.path("examples/player/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zigaudio", .module = lib_mod }},
        });
        player_mod.addImport("zoto", zoto_mod);

        const player_exe = b.addExecutable(.{
            .name = "player",
            .root_module = player_mod,
        });

        const install_player = b.addInstallArtifact(player_exe, .{});
        const player_step = b.step("player", "Build the player example");
        player_step.dependOn(&install_player.step);

        const run_cmd = b.addRunArtifact(player_exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run the player example");
        run_step.dependOn(&run_cmd.step);
    }

    // Bench example
    {
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

        const install_bench = b.addInstallArtifact(bench_exe, .{});
        const bench_step = b.step("bench", "Build and install the bench example");
        bench_step.dependOn(&install_bench.step);

        const bench_run = b.addRunArtifact(bench_exe);
        if (b.args) |args| bench_run.addArgs(args);
        const bench_run_step = b.step("run-bench", "Run the bench example");
        bench_run_step.dependOn(&bench_run.step);
    }

    // Convert example
    {
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

        const install_convert = b.addInstallArtifact(convert_exe, .{});
        const convert_step = b.step("convert", "Build and install the convert example");
        convert_step.dependOn(&install_convert.step);
    }
}
