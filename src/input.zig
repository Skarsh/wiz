const std = @import("std");
const Allocator = std.mem.Allocator;

const Window = @import("windows.zig").Window;

pub const EventType = enum {
    Empty,
    WindowResized,
    WindowDestroyed,
    WindowDamaged,
    WindowVBlank,
    AppTerminated,
    KeyDown,
    KeyUp,
    MouseButtonDown,
    MouseButtonUp,
    MouseMotion,
};

pub const KeyEvent = struct {
    scancode: u32,
};

pub const MouseMotionEvent = struct {
    x: i16,
    y: i16,
};

pub const MouseButtonEvent = struct {
    x: i16,
    y: i16,
    button: MouseButton,
};

// TODO(Thomas) Many mouses has way more buttons than this,
// we need to support that aswell.
pub const MouseButton = enum(u8) {
    left = 1,
    middle = 2,
    right = 3,
    wheel_up = 4,
    wheel_down = 5,
    nav_backward = 6,
    nav_forward = 7,
    _,
};

pub const Event = union(EventType) {
    // TODO (Thomas): I don't know about these Window specific events.
    // Do they belong in here?
    Empty: void,
    WindowResized: *Window,
    WindowDestroyed: *Window,
    WindowDamaged: struct { window: *Window, x: u16, y: u16, w: u16, h: u16 },
    WindowVBlank: *Window,
    AppTerminated: void,
    KeyDown: KeyEvent,
    KeyUp: KeyEvent,
    MouseButtonDown: MouseButtonEvent,
    MouseButtonUp: MouseButtonEvent,
    MouseMotion: MouseMotionEvent,
};

// TODO (Thomas): What about thread safety for the EventQueue?
// Its fine when only the main thread is putting on events from the
// window proc.

/// Circular Event FIFO Queue
/// Head always holds the index of the oldest element
/// Tail always holds the index of the newest element
pub const EventQueue = struct {
    allocator: Allocator,
    queue: []Event,
    head: isize = -1,
    tail: isize = -1,

    pub fn init(allocator: Allocator, num_elements: usize) !EventQueue {
        const queue = try allocator.alloc(Event, num_elements);
        for (queue) |*event| {
            event.* = Event{ .Empty = undefined };
        }
        return EventQueue{ .allocator = allocator, .queue = queue };
    }

    pub fn deinit(self: EventQueue) void {
        self.allocator.free(self.queue);
    }

    /// Pushes a new event onto the queue. Will wrap around and
    /// overwrite older values if full.
    pub fn enqueue(self: *EventQueue, event: Event) void {
        // if the next position for tail is at the head, then we need to increment
        // bot head and tail, with modulo for handling wrapping.
        if (@mod(self.tail + 1, @as(isize, @intCast(self.queue.len))) == self.head) {
            self.tail = @mod(self.tail + 1, @as(isize, @intCast(self.queue.len)));
            self.queue[@intCast(self.tail)] = event;
            self.head = @mod(self.head + 1, @as(isize, @intCast(self.queue.len)));
        } else if (self.head == -1) {
            self.head = 0;
            self.tail = 0;
            self.queue[@intCast(self.tail)] = event;
        } else {
            self.tail = @mod(self.tail + 1, @as(isize, @intCast(self.queue.len)));
            self.queue[@intCast(self.tail)] = event;
        }
    }

    /// Polls the queue to see if there are new unprocessed elements to handle.
    /// When polled, returns the event at the rear
    pub fn poll(self: *EventQueue, event: *Event) bool {
        // Queue is empty
        if (self.head == -1) {
            return false;
        } else if (self.head == self.tail) {
            event.* = self.queue[@intCast(self.head)];
            self.head = -1;
            self.tail = -1;
            return true;
        } else {
            event.* = self.queue[@intCast(self.head)];
            self.head = @mod((self.head + 1), @as(isize, @intCast(self.queue.len)));
            return true;
        }
    }

    pub fn print(self: EventQueue) void {
        std.debug.print("queue: {any}\n", .{self.queue});
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Init test" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();
    try expectEqual(event_queue.queue.len, 10);
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);
}

test "EnqueueTest initial condition" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
    event_queue.enqueue(event);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event);
}

test "Poll initial condition" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 15 } };
    event_queue.enqueue(event);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event);

    var out_event: Event = Event{ .Empty = undefined };
    try expect(event_queue.poll(&out_event));
    try expectEqual(out_event, event);
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);
}

test "Poll two elements" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event1: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    event_queue.enqueue(event1);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event1);

    const event2 = Event{ .KeyDown = KeyEvent{ .scancode = 2 } };
    event_queue.enqueue(event2);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 1);
    try expectEqual(event_queue.queue[1], event2);

    var out_event: Event = Event{ .Empty = undefined };
    try expect(event_queue.poll(&out_event));
    try expectEqual(out_event, event1);
    try expectEqual(event_queue.head, 1);
    try expectEqual(event_queue.tail, 1);

    out_event = Event{ .Empty = undefined };
    try expect(event_queue.poll(&out_event));
    try expectEqual(out_event, event2);
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);
}

test "Poll before enqueue" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const expected_event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    var out_event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    try expect(!event_queue.poll(&out_event));
    try expectEqual(expected_event, out_event);
}

test "Wrap around tail" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 3;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event1: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    event_queue.enqueue(event1);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event1);

    const event2: Event = Event{ .KeyDown = KeyEvent{ .scancode = 2 } };
    event_queue.enqueue(event2);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 1);
    try expectEqual(event_queue.queue[1], event2);

    const event3: Event = Event{ .KeyDown = KeyEvent{ .scancode = 3 } };
    event_queue.enqueue(event3);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 2);
    try expectEqual(event_queue.queue[2], event3);

    const event4: Event = Event{ .KeyDown = KeyEvent{ .scancode = 4 } };
    event_queue.enqueue(event4);
    try expectEqual(event_queue.head, 1);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event4);
}

test "Wrap around head synthetic" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 3;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    event_queue.head = 2;
    event_queue.tail = 1;
    const event1: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    event_queue.enqueue(event1);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 2);
    try expectEqual(event_queue.queue[2], event1);
}

test "Wrap around head with enqueue" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 3;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event1: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    event_queue.enqueue(event1);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event1);

    const event2: Event = Event{ .KeyDown = KeyEvent{ .scancode = 2 } };
    event_queue.enqueue(event2);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 1);
    try expectEqual(event_queue.queue[1], event2);

    const event3: Event = Event{ .KeyDown = KeyEvent{ .scancode = 3 } };
    event_queue.enqueue(event3);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 2);
    try expectEqual(event_queue.queue[2], event3);

    // Wrapping around here
    const event4: Event = Event{ .KeyDown = KeyEvent{ .scancode = 4 } };
    event_queue.enqueue(event4);
    try expectEqual(event_queue.head, 1);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event4);

    const event5: Event = Event{ .KeyDown = KeyEvent{ .scancode = 5 } };
    event_queue.enqueue(event5);
    try expectEqual(event_queue.head, 2);
    try expectEqual(event_queue.tail, 1);
    try expectEqual(event_queue.queue[1], event5);

    const event6: Event = Event{ .KeyDown = KeyEvent{ .scancode = 6 } };
    event_queue.enqueue(event6);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 2);
    try expectEqual(event_queue.queue[2], event6);
}

test "Wrap around tail and unwrap with poll" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 3;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event1: Event = Event{ .KeyDown = KeyEvent{ .scancode = 1 } };
    event_queue.enqueue(event1);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event1);

    const event2: Event = Event{ .KeyDown = KeyEvent{ .scancode = 2 } };
    event_queue.enqueue(event2);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 1);
    try expectEqual(event_queue.queue[1], event2);

    const event3: Event = Event{ .KeyDown = KeyEvent{ .scancode = 3 } };
    event_queue.enqueue(event3);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 2);
    try expectEqual(event_queue.queue[2], event3);

    // Wrapping around here
    const event4: Event = Event{ .KeyDown = KeyEvent{ .scancode = 4 } };
    event_queue.enqueue(event4);
    try expectEqual(event_queue.head, 1);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event4);

    var out_event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
    try expect(event_queue.poll(&out_event));
    try expectEqual(event_queue.head, 2);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(out_event, event2);

    try expect(event_queue.poll(&out_event));
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(out_event, event3);

    try expect(event_queue.poll(&out_event));
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);
    try expectEqual(out_event, event4);

    const event5: Event = Event{ .KeyDown = KeyEvent{ .scancode = 5 } };
    event_queue.enqueue(event5);
    try expectEqual(event_queue.head, 0);
    try expectEqual(event_queue.tail, 0);
    try expectEqual(event_queue.queue[0], event5);
}
