const std = @import("std");

pub const Transition = struct {
  from: []const u8,
  to: []const u8
};

pub const State = struct {
  name: []const u8,
  transitions: []const Transition
};

pub const Machine = struct {
  initial: State,
  states: []const State
};

pub const Event = struct {
  name: []const u8
};

pub fn transition(from: []const u8, to: []const u8) Transition {
  return Transition{
    .from = from,
    .to = to
  };
}

pub fn state(name: []const u8, transitions: []const Transition) State {
  return State{
    .name = name,
    .transitions = transitions
  };
}

pub fn createMachine(states: []const State) Machine {
  const initial = states[0];

  return Machine{
    .initial = initial,
    .states = states
  };
}

fn transitionTo(machine: Machine, current: State, t: Transition, ev: Event) State {
  // TODO run guards

  for (machine.states) |s| {
    if(std.mem.eql(u8, s.name, t.to)) {
      return s;
    }
  }

  return current;
}

pub fn send(machine: Machine, current: State, ev: Event) State {
  const transitions = current.transitions;
  var new_state = current;

  for (transitions) |t| {
    if(std.mem.eql(u8, t.from, ev.name)) {
      return transitionTo(machine, current, t, ev);
    }
  }
  
  return new_state;
}