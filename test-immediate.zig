const std = @import("std");
const expectEqual = std.testing.expectEqual;
const allocator = std.heap.page_allocator;

const robot = @import("robot.zig");

test "An immediate moves to the next state" {
  const Data = struct {};

  const MyMachine = robot.Machine(Data);

  var machine = MyMachine.init(&Data{}, allocator);

  var states = &[_]MyMachine.State {
    try machine.state("one", &[_]MyMachine.Transition {
      machine.immediate("two")
    }),
    try machine.state("two", &[_]MyMachine.Transition {})
  };

  machine.states(states);

  var state = machine.initial;
  expectEqual(state.name, "two");
}