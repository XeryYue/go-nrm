const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).

    const exe = b.addExecutable(.{
        .name = "grm",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_test = b.addTest(.{
        .root_source_file = b.path("src/mod.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exc_test = b.addRunArtifact(exe_test);

    const test_step = b.step("test", "Run exe test");

    test_step.dependOn(&run_exc_test.step);

    const zig_cli = b.dependency("zig-cli", .{});

    const ini_test = b.addTest(.{
        .root_source_file = b.path("ini/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_ini_test = b.addRunArtifact(ini_test);
    const test_ini_step = b.step("test-ini", "Run ini module test");
    test_ini_step.dependOn(&run_ini_test.step);

    const ini = b.addModule("ini", .{
        .root_source_file = b.path("ini/ini.zig"),
    });

    const commands = b.addModule("commands", .{
        .root_source_file = b.path("src/commands/mod.zig"),
    });

    commands.addImport("zig-cli", zig_cli.module("zig-cli"));

    exe.root_module.addImport("ini", ini);
    exe.root_module.addImport("commands", commands);
    exe.root_module.addImport("zig-cli", zig_cli.module("zig-cli"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
}