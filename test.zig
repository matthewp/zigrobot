const std = @import("std");
const expectEqual = std.testing.expectEqual;

const robot = @import("robot.zig");
const State = robot.State;
const Transition = robot.Transition;
const createMachine = robot.createMachine;
const addGuard = robot.addGuard;

test "Can do basic transitions" {
  const states = [_]State {
    robot.state("one", &[_]Transition {
      robot.transition("next", "two")
    }),
    robot.state("two", &[_]Transition {})
  };

  const machine = createMachine(&states);
  var state = machine.initial;

  state = robot.send(machine, state, .{ .name = "next" });

  expectEqual(state.name, "two");
}

fn returnFalse() bool {
  return false;
}

test "A guard can prevent a transition" {
  var transition = robot.transition("next", "two");
  addGuard(&transition, returnFalse);

  const states = [_] State {
    robot.state("one", &[_]Transition {
      transition
    }),
    robot.state("two", &[_]Transition {})
  };

  const machine = createMachine(&states);
  var state = machine.initial;

  state = robot.send(machine, state, .{ .name = "next" });

  expectEqual(state.name, "one");
}