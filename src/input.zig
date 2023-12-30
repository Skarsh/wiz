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

/// Circular Event FIFO Queue
/// Front always holds the index of the oldest element
/// Rear always holds the index of the newest element
pub const EventQueue = struct {
    allocator: Allocator,
    queue: []Event,
    front: isize = -1,
    rear: isize = -1,

    pub fn init(allocator: Allocator, num_elements: usize) !EventQueue {
        const queue = try allocator.alloc(Event, num_elements);
        for (queue) |*event| {
            event.* = Event{ .Empty = undefined };
        }
        return EventQueue{ .allocator = allocator, .queue = queue, .front = -1, .rear = -1 };
    }

    pub fn deinit(self: EventQueue) void {
        self.allocator.free(self.queue);
    }

    pub fn enqueue(self: *EventQueue, event: Event) void {
        // Initial case
        if (self.front == -1 and self.rear == -1) {
            self.front = 0;
            self.rear += 1;
            self.queue[@intCast(self.rear)] = event;
        }

        // Other cases to handle:
        // 1. front < rear, just increase rear by 1, deal with potential wrap
        // 2. front > rear + 1, just increase rear by 1 and set element
        // 3. rear + 1 == front, increate front by 1 (deal with wrap), increase rear by 1 and set element,

        if (self.front < self.rear) {
            // We need to check if front is 0 here
            if (self.rear == self.queue.len) {
                if (self.front == 0) {
                    self.rear = 0;
                    self.queue[@intCast(self.rear)] = event;
                    self.front += 1;
                } else {
                    self.rear = 0;
                    self.queue[@intCast(self.rear)] = event;
                }
            } else {
                self.rear += 1;
                self.queue[@intCast(self.rear)] = event;
            }
        } else if (self.front > self.rear + 1) {
            self.rear += 1;
            self.queue[@intCast(self.rear)] = event;
        } else if (self.rear + 1 == self.front) {
            if (self.front == self.queue.len) {
                self.rear += 1;
                self.queue[@intCast(self.rear)] = event;
                self.front = 0;
            } else {
                self.rear += 1;
                self.queue[@intCast(self.rear)] = event;
                self.front += 1;
            }
        }
    }

    pub fn dequeue(self: *EventQueue) ?Event {
        _ = self;
    }

    /// Polls the queue to see if there are new unprocessed elements to handle.
    /// When polled, returns the event at the rear
    pub fn poll(self: *EventQueue, event: *Event) bool {
        // Cases to handle:
        // 1. Simplest case, rear > front
        // 2. Rear has wrapped, so rear < front
        // 3. There is only one element left, meaning rear == front

        if (self.rear == -1) {
            return false;
        }

        event.* = self.queue[@intCast(self.rear)];
        if (self.rear > self.front) {
            self.rear -= 1;
            return true;
        } else if (self.rear < self.front) {
            // Check if at 0, if so need to wrap around backward
            if (self.rear == 0) {
                self.rear = @as(isize, @intCast(self.queue.len)) - 1;
                return true;
            } else {
                self.rear -= 1;
                return true;
            }
        } else if (self.rear == self.front) {
            self.front = -1;
            self.rear = -1;
            return true;
        }

        return false;
    }

    pub fn print(self: EventQueue) void {
        std.debug.print("queue: {any}\n", .{self.queue});
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// TODO (Thomas): Test for whether all has the right initialized Event value?
test "Init test" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();
    try expectEqual(event_queue.queue.len, 10);
}

test "EnqueueTest initial condition" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
    event_queue.enqueue(event);
    try expectEqual(event_queue.front, 0);
    try expectEqual(event_queue.rear, 0);
    try expectEqual(event_queue.queue[0], event);
}

test "Poll initial condition" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    const event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 15 } };
    event_queue.enqueue(event);
    try expectEqual(event_queue.front, 0);
    try expectEqual(event_queue.rear, 0);
    try expectEqual(event_queue.queue[0], event);

    var out_event: Event = Event{ .Empty = undefined };
    try expect(event_queue.poll(&out_event));
    try expectEqual(out_event, event);
    try expectEqual(event_queue.front, -1);
    try expectEqual(event_queue.rear, -1);
}
