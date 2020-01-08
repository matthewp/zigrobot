const std = @import("std");
const expectEqual = std.testing.expectEqual;

const robot = @import("robot.zig");
const State = robot.State;
const Transition = robot.Transition;
const createMachine = robot.createMachine;

test "Can do basic transitions" {
  const states = [_]State {
    robot.state("one", &[_]Transition {
      .{ .from = "next", .to = "two" }
    }),
    robot.state("two", &[_]Transition {})
  };

  const machine = createMachine(&states);
  var state = machine.initial;

  state = robot.send(machine, state, .{ .name = "next" });

  expectEqual(state.name, "two");
}