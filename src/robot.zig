const std = @import("std");
const Allocator = std.mem.Allocator;

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

    fn enterState(self: *Self, s: State) State {
      return s;
    }

    fn enterImmediate(self: *Self, s: State) State {
      return transitionTo(self, s, s.immediates);
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
      immediates: *ListOfTransitions,
      enter: fn (self: *Self, s: State) State = enterState
    };

    const Self = @This();
    const ListOfTransitions = std.SinglyLinkedList(Transition);

    data: *T,
    initial: State,
    currentStates: []State,
    allocator: *Allocator,

    pub fn init(data: *T, allocator: *Allocator) Self {
      return Self{
        .initial = undefined,
        .currentStates = &[_]State{},
        .data = data,
        .allocator = allocator
      };
    }

    pub fn deinit(self: Self) void {
      // Destroy immediates
      for (self.currentStates) |s| {
        var immediates = s.immediates;
        var it = immediates.first;
        while (it) |node| {
          var n = node.next;
          immediates.destroyNode(node, self.allocator);
          it = n;
        }

        self.allocator.destroy(immediates);
      }
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

    pub fn state(self: *Self, name: []const u8, transitions: []const Transition) !State {
      var immediates = try self.allocator.create(ListOfTransitions);
      immediates.first = null;

      var last: *ListOfTransitions.Node = undefined;
      var first = false;
      for (transitions) |t| {
        if(t.is_immediate) {
          var node = try immediates.createNode(t, self.allocator);

          if(first) {
            immediates.insertAfter(last, node);
          } else {
            immediates.prepend(node);
            first = true;
            last = node;
          }
        }
      }

      var s = State{
        .name = name,
        .transitions = transitions,
        .immediates = immediates
      };

      if(first) {
        s.enter = enterImmediate;
      }

      return s;
    }

    pub fn states(self: *Self, ss: []State) void {
      self.currentStates = ss;
      var initial = ss[0];
      self.initial = initial.enter(self, initial);
    }

    fn initState(s: *State, allocator: *Allocator) !void {

    }

    fn transitionTo(self: *Self, current: State, candidates: *ListOfTransitions) State {
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
            return s.enter(self, s);
          }
        }
      }

      return current;
    }

    pub fn send(self: *Self, current: State, ev: Event) !State {
      var transitions = current.transitions;
      var new_state = current;
      var allocator = self.allocator;

      var candidates = ListOfTransitions.init();

      var last: *ListOfTransitions.Node = undefined;
      var first = false;
      for (transitions) |t| {
        if(stringEquals(t.from, ev.name)) {
          var node = try candidates.createNode(t, allocator);

          if(first) {
            candidates.insertAfter(last, node);
          } else {
            candidates.prepend(node);
            first = true;
            last = node;
          }
        }
      }

      defer {
        var it = candidates.first;
        while (it) |node| {
          var n = node.next;
          candidates.destroyNode(node, allocator);
          it = n;
        }
      }

      return transitionTo(self, current, &candidates);
    }
  };
}