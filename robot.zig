const std = @import("std");

fn defaultGuard() bool {
  return true;
}

pub const Transition = struct {
  from: []const u8,
  to: []const u8,
  guard_fn: fn () bool = defaultGuard,
};

pub const State = struct {
  name: []const u8,
  transitions: []const Transition
};

pub const Machine = struct {
  initial: State,
  states: []const State,
  data: void,
};

pub const Event = struct {
  name: []const u8
};

fn LinkedList(comptime T: type) type {
  return struct {
    pub const Node = struct {
      prev: ?*Node,
      next: ?*Node,
      data: T,
    };

    first: ?*Node,
    last:  ?*Node,
    len:   usize,
  };
}

const ListOfTransitions = LinkedList(Transition);

pub fn transition(from: []const u8, to: []const u8) Transition {
  return Transition{
    .from = from,
    .to = to
  };
}

pub fn addGuard(t: *Transition, comptime gfn: fn () bool) void {
  t.guard_fn = gfn;
}

pub fn state(name: []const u8, transitions: []const Transition) State {
  return State{
    .name = name,
    .transitions = transitions
  };
}

pub fn createMachine(states: []const State) Machine {
  const initial = states[0];

  const mytype = struct {};
  var thing = mytype{};

  return Machine{
    .initial = initial,
    .states = states,
    .data = thing
  };
}

fn transitionTo(machine: Machine, current: State, candidates: ListOfTransitions, ev: Event) State {
  // Run guards
  var it = candidates.first;

  while (it) |node| : (it = node.next) {
    var t = node.data;

    

    var guard_passed = t.guard_fn();
    if(!guard_passed) {
      continue;
    }

    for (machine.states) |s| {
      if(std.mem.eql(u8, s.name, t.to)) {
        return s;
      }
    }
  }

  return current;
}

pub fn send(machine: Machine, current: State, ev: Event) State {
  const transitions = current.transitions;
  var new_state = current;

  var candidates = ListOfTransitions{
    .first = null,
    .last = null,
    .len = 0
  };

  var i: usize = 0;
  var node: ListOfTransitions.Node = undefined;
  for (transitions) |t| {
    if(std.mem.eql(u8, t.from, ev.name)) {
      i += 1;
      var last = node;
      node = ListOfTransitions.Node{
        .prev = &last,
        .next = null,
        .data = t
      };

      candidates.last = &node;
      candidates.len = i;
      if(candidates.first == null) {
        candidates.first = &node;
      }
    }
  }

  return transitionTo(machine, current, candidates, ev);
}