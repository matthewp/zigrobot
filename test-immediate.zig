const std = @import("std");
const expectEqual = std.testing.expectEqual;

const robot = @import("robot.zig");

test "An immediate moves to the next state" {
  const Data = struct {};

  const MyMachine = robot.Machine(Data);

  var machine = MyMachine.init(&Data{});

  var states = &[_]MyMachine.State {
    machine.state("one", &[_]MyMachine.Transition {
      machine.immediate("two")
    }),
    machine.state("two", &[_]MyMachine.Transition {})
  };

  machine.states(states);

  var state = machine.initial;
  expectEqual(state.name, "one");
}