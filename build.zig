const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zigrobot", "src/robot.zig");
    lib.setBuildMode(mode);
    lib.install();

    const test_step = b.step("test", "Run library tests");
    var all_tests = [_]*LibExeObjStep{
      b.addTest("src/test.zig"),
      b.addTest("src/test-immediate.zig")
    };

    for (all_tests) |t| {
      t.setBuildMode(mode);
      test_step.dependOn(&t.step);
    }
}
