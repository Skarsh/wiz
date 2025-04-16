const std = @import("std");
const Allocator = std.mem.Allocator;

//const Window = @import("windows.zig").Window;

const tracy = @import("tracy.zig");

pub const Key = enum(u32) {
    key_unspecified = 0,
    key_a = 4,
    key_b = 5,
    key_c = 6,
    key_d = 7,
    key_e = 8,
    key_f = 9,
    key_g = 10,
    key_h = 11,
    key_i = 12,
    key_j = 13,
    key_k = 14,
    key_l = 15,
    key_m = 16,
    key_n = 17,
    key_o = 18,
    key_p = 19,
    key_q = 20,
    key_r = 21,
    key_s = 22,
    key_t = 23,
    key_u = 24,
    key_v = 25,
    key_w = 26,
    key_x = 27,
    key_y = 28,
    key_z = 29,
    key_1 = 30,
    key_2 = 31,
    key_3 = 32,
    key_4 = 33,
    key_5 = 34,
    key_6 = 35,
    key_7 = 36,
    key_8 = 37,
    key_9 = 38,
    key_0 = 39,
    key_return = 40,
    key_escape = 41,
    key_backspace = 42,
    key_tab = 43,
    key_space = 44,
    key_minus = 45,
    key_equals = 46,
    key_left_bracket = 47,
    key_right_bracket = 48,
    key_backslash = 49,
    key_nonus_hash = 50,
    key_semicolon = 51,
    key_apostrophe = 52,
    key_grave = 53,
    key_comma = 54,
    key_period = 55,
    key_slash = 56,
    key_capslock = 57,
    key_f1 = 58,
    key_f2 = 59,
    key_f3 = 60,
    key_f4 = 61,
    key_f5 = 62,
    key_f6 = 63,
    key_f7 = 64,
    key_f8 = 65,
    key_f9 = 66,
    key_f10 = 67,
    key_f11 = 68,
    key_f12 = 69,
    key_printscreen = 70,
    key_scroll_lock = 71,
    key_pause = 72,
    key_insert = 73,
    key_home = 74,
    key_pageup = 75,
    key_delete = 76,
    key_end = 77,
    key_pagedown = 78,
    key_right = 79,
    key_left = 80,
    key_down = 81,
    key_up = 82,
    key_numlock_clear = 83,
    key_keypad_divide = 84,
    key_keypad_mulitply = 85,
    key_keypad_minus = 86,
    key_keypad_plus = 87,
    key_keypad_enter = 88,
    key_keypad_1 = 89,
    key_keypad_2 = 90,
    key_keypad_3 = 91,
    key_keypad_4 = 92,
    key_keypad_5 = 93,
    key_keypad_6 = 94,
    key_keypad_7 = 95,
    key_keypad_8 = 96,
    key_keypad_9 = 97,
    key_keypad_0 = 98,
    key_keypad_period = 99,
    key_keypad_nonus_backslash = 100,
    key_keypad_application = 101,
    key_keypad_power = 102,
    key_keypad_equals = 103,
    key_f13 = 104,
    key_f14 = 105,
    key_f15 = 106,
    key_f16 = 107,
    key_f17 = 108,
    key_f18 = 109,
    key_f19 = 110,
    key_f20 = 111,
    key_f21 = 112,
    key_f22 = 113,
    key_f23 = 114,
    key_f24 = 115,
    // TODO (Thomas) There are more keys here if one are supposed to follow
    // https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf (10 Keyboard/Keypad Page (0x07))
    // which e.g. SDL2 does. Not necessary for our case though for now
    //
    key_last = 116,
};

// NOTE(Thomas): These scancodes are from https://learn.microsoft.com/nb-no/windows/win32/inputdev/about-keyboard-input
pub const Scancode = enum(u32) {
    Keyboard_A = 0x001E,
    Keyboard_B = 0x0030,
    Keyboard_C = 0x002E,
    Keyboard_D = 0x0020,
    Keyboard_E = 0x0012,
    Keyboard_F = 0x0021,
    Keyboard_G = 0x0022,
    Keyboard_H = 0x0023,
    Keyboard_I = 0x0017,
    Keyboard_J = 0x0024,
    Keyboard_K = 0x0025,
    Keyboard_L = 0x0026,
    Keyboard_M = 0x0032,
    Keyboard_N = 0x0031,
    Keyboard_O = 0x0018,
    Keyboard_P = 0x0019,
    Keyboard_Q = 0x0010,
    Keyboard_R = 0x0013,
    Keyboard_S = 0x001F,
    Keyboard_T = 0x0014,
    Keyboard_U = 0x0016,
    Keyboard_V = 0x002F,
    Keyboard_W = 0x0011,
    Keyboard_X = 0x002D,
    Keyboard_Y = 0x0015,
    Keyboard_Z = 0x002C,
    Keyboard_1_And_Bang = 0x0002,
    Keyboard_2_And_At = 0x0003,
    Keyboard_3_And_Hash = 0x0004,
    Keyboard_4_And_Dollar = 0x0005,
    Keyboard_5_And_Percent = 0x0006,
    Keyboard_6_And_Caret = 0x0007,
    Keyboard_7_And_Ampersand = 0x0008,
    Keyboard_8_And_Star = 0x0009,
    Keyboard_9_And_Left_Bracket = 0x000A,
    Keyboard_0_And_Right_Bracket = 0x000B,
    Keyboard_Return_Enter = 0x001C,
    Keyboard_Escape = 0x0001,
    Keyboard_Delete = 0x000E,
    Keyboard_Tab = 0x000F,
    Keyboard_Spacebar = 0x0039,
    Keyboard_Dash_And_Underscore = 0x000C,
    Keyboard_Equals_And_Plus = 0x000D,
    Keyboard_Left_Brace = 0x001A,
    Keyboard_Right_Brace = 0x001B,
    Keyboard_Pipe_And_Slash_And_Non_US = 0x002B,
    Keyboard_Semicolon_And_Colon = 0x0027,
    Keyboard_Apostrophe_And_Double_Questionmark = 0x0028,
    Keyboard_Grave_Accent_And_Tilde = 0x0029,
    Keyboard_Comma = 0x0033,
    Keyboard_period = 0x0034,
    Keyboard_QuestionMark = 0x0035,
    Keyboard_CapsLock = 0x003A,
    Keyboard_F1 = 0x003B,
    Keyboard_F2 = 0x003C,
    Keyboard_F3 = 0x003D,
    Keyboard_F4 = 0x003E,
    Keyboard_F5 = 0x003F,
    Keyboard_F6 = 0x0040,
    Keyboard_F7 = 0x0041,
    Keyboard_F8 = 0x0042,
    Keyboard_F9 = 0x0043,
    Keyboard_F10 = 0x0044,
    Keyboard_F11 = 0x0057,
    Keyboard_F12 = 0x0058,
    // NOTE(Thommas): Refer to MSDN on the PrintScreen case
    Keyboard_PrintScreen = 0xE037,
    Keyboard_Scroll_Lock = 0x0046,
    // NOTE(Thommas): Refer to MSDN on the Pause case
    Keyboard_Pause = 0xE11D45,
    Keyboard_Insert = 0xE052,
    Keyboard_Home = 0xE047,
    Keyboard_PageUp = 0xE049,
    Keyboard_Delete_Forward = 0xE053,
    Keyboard_End = 0xE04F,
    Keyboard_PageDown = 0xE051,
    Keyboard_RightArrow = 0xE04D,
    Keyboard_LeftArrow = 0xE04B,
    Keyboard_DownArrow = 0xE050,
    Keyboard_UpArrow = 0xE048,

    // TODO(Thomas): Fill in the rest here
};

pub const EventType = enum {
    Empty,
    //WindowResized,
    //WindowDestroyed,
    //WindowDamaged,
    //WindowVBlank,
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
    x_rel: i16,
    y_rel: i16,
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
    //WindowResized: *Window,
    //WindowDestroyed: *Window,
    //WindowDamaged: struct { window: *Window, x: u16, y: u16, w: u16, h: u16 },
    //WindowVBlank: *Window,
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
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        // if the next position for tail is at the head, then we need to increment
        // both head and tail, with modulo for handling wrapping.
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
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        // Queue is empty
        if (self.head == -1) {
            return false;
        } else if (self.head == self.tail and self.head >= 0 and self.tail >= 0) {
            event.* = self.queue[@intCast(self.head)];
            self.head = -1;
            self.tail = -1;
            return true;
        } else {
            if (self.head >= 0) {
                event.* = self.queue[@intCast(self.head)];
                self.head = @mod((self.head + 1), @as(isize, @intCast(self.queue.len)));
                return true;
            } else {
                return false;
            }
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

test "Poll Empty Queue" {
    const allocator = std.testing.allocator;
    const num_elements: usize = 10;
    var event_queue = try EventQueue.init(allocator, num_elements);
    defer event_queue.deinit();

    var event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
    try expectEqual(event_queue.queue.len, 10);
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);

    try expectEqual(event_queue.poll(&event), false);

    try expectEqual(event_queue.queue.len, 10);
    try expectEqual(event_queue.head, -1);
    try expectEqual(event_queue.tail, -1);
}

test "Enqueue empty queue" {
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

test "Poll one element" {
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
