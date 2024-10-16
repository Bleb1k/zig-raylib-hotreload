const std = @import("std");

pub const Options = struct {
    hot_reload: bool = false,
    game_only: bool = false,
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const defaults = Options{};
    const options = Options{
        .hot_reload = b.option(bool, "hot-reload", "Compile with hot reload") orelse defaults.hot_reload,
        .game_only = b.option(bool, "game-only", "Only build the game shared library") orelse defaults.game_only,
    };

    const lib_args = .{
        .name = "game",
        .root_source_file = b.path("src/game.zig"),
        .target = target,
        .optimize = optimize,
    };
    const lib = if (options.hot_reload) b.addSharedLibrary(lib_args) else b.addStaticLibrary(lib_args);

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
        .shared = options.hot_reload,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    lib.linkLibrary(raylib_artifact);
    lib.root_module.addImport("raylib", raylib);
    lib.root_module.addImport("raygui", raygui);

    b.installArtifact(lib);

    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/game.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    if (!options.game_only) {
        const exe = b.addExecutable(.{
            .name = "exeFile",
            .root_source_file = b.path(if (options.hot_reload) "src/mainHR.zig" else "src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path(if (options.hot_reload) "src/mainHR.zig" else "src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
