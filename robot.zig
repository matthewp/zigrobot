const std = @import("std");

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

pub const Event = struct {
  name: []const u8
};

inline fn stringEquals(a: []const u8, b: []const u8) bool {
  return std.mem.eql(u8, a, b);
}

pub fn Machine(comptime T: type) type {
  return struct {
    fn defaultGuard(data: *T) bool {
      return true;
    }

    fn enterState(s: State) State {
      return s;
    }

    fn enterImmediate(s: State) State {
      std.debug.warn("We are in immediate\n", .{});
      return s;
    }

    pub const Transition = struct {
      from: []const u8,
      to: []const u8,
      guard_fn: fn (data: *T) bool = defaultGuard,
      is_immediate: bool = false
    };

    pub const State = struct {
      name: []const u8,
      transitions: []const Transition,
      immediates: []const Transition,
      enter: fn (s: State) State = enterState
    };

    const Self = @This();
    const ListOfTransitions = LinkedList(Transition);

    data: *T,
    initial: State,
    currentStates: []State,

    pub fn init(data: *T) Self {
      return Self{
        .initial = undefined,
        .currentStates = &[_]State{},
        .data = data,
      };
    }

    pub fn transition(self: *Self, from: []const u8, to: []const u8) Transition {
      return Transition{
        .from = from,
        .to = to
      };
    }

    pub fn immediate(self: *Self, to: []const u8) Transition {
      return Transition{
        .from = "",
        .to = to,
        .is_immediate = true
      };
    }

    pub fn guard(self: *Self, t: *Transition, comptime gfn: fn (data: *T) bool) void {
      t.guard_fn = gfn;
    }

    pub fn state(self: *Self, name: []const u8, transitions: []const Transition) State {
      var s = State{
        .name = name,
        .transitions = transitions
      };

      for (transitions) |t| {
        if(t.is_immediate) {
          std.debug.warn("Found an immediate transition\n", .{});
          s.enter = enterImmediate;
        }
      }

      return s;
    }

    pub fn states(self: *Self, ss: []State) void {
      var initial = ss[0];
      self.initial = initial.enter(self, initial);
      self.currentStates = ss;
    }

    fn transitionTo(self: *Self, current: State, candidates: ListOfTransitions, ev: Event) State {
      // Run guards
      var it = candidates.first;

      while (it) |node| : (it = node.next) {
        var t = node.data;

        var guard_passed = t.guard_fn(self.data);
        if(!guard_passed) {
          continue;
        }

        for (self.currentStates) |s| {
          if(stringEquals(s.name, t.to)) {
            return s.enter(s);
          }
        }
      }

      return current;
    }

    pub fn send(self: *Self, current: State, ev: Event) State {
      var transitions = current.transitions;
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

      return transitionTo(self, current, candidates, ev);
    }
  };
}