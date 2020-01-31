const std = @import("std");
const expectEqual = std.testing.expectEqual;
const allocator = std.heap.page_allocator;

const robot = @import("robot.zig");

test "Can do basic transitions" {
  const Data = struct {};

  const MyMachine = robot.Machine(Data);

  var machine = MyMachine.init(&Data{}, allocator);

  var states = &[_]MyMachine.State {
    try machine.state("one", &[_]MyMachine.Transition {
      machine.transition("next", "two")
    }),
    try machine.state("two", &[_]MyMachine.Transition {})
  };

  machine.states(states);

  var state = machine.initial;

  state = try machine.send(state, .{ .name = "next" });

  expectEqual(state.name, "two");
}

test "A guard can prevent a transition" {
  const Data = struct {};
  const MyMachine = robot.Machine(Data);
  var machine = MyMachine.init(&Data{}, allocator);
  var transition = machine.transition("next", "two");

  const return_false = struct {
    fn returnFalse(d: *Data) bool {
      return false;
    }
  }.returnFalse;
  machine.guard(&transition, return_false);

  const states = &[_]MyMachine.State {
    try machine.state("one", &[_]MyMachine.Transition {
      transition
    }),
    try machine.state("two", &[_]MyMachine.Transition {})
  };

  machine.states(states);
  var state = machine.initial;

  state = try machine.send(state, .{ .name = "next" });

  expectEqual(state.name, "one");
}

test "A guard can conditionally prevent a transition" {
  const Data = struct {
    pass: bool = false
  };

  const MyMachine = robot.Machine(Data);
  var data = Data{};
  var machine = MyMachine.init(&data, allocator);

  var transition = machine.transition("next", "two");
  const my_guard = struct {
    fn myGuard(d: *Data) bool {
      return d.pass;
    }
  }.myGuard;
  machine.guard(&transition, my_guard);

  const states = &[_] MyMachine.State {
    try machine.state("one", &[_]MyMachine.Transition {
      transition
    }),
    try machine.state("two", &[_]MyMachine.Transition {})
  };

  machine.states(states);
  var state = machine.initial;

  state = try machine.send(state, .{ .name = "next" });
  expectEqual(state.name, "one");

  data.pass = true;
  state = try machine.send(state, .{ .name = "next" });
  expectEqual(state.name, "two");
}