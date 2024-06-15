const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @import("input.zig");
const EventQueue = input.EventQueue;

const wiz = @import("wiz.zig");

const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/keysymdef.h");
    @cInclude("X11/XKBlib.h");
});

pub const Window = struct {
    allocator: Allocator,
    window_data: *wiz.WindowData,
    //display: *c.Display,
    display: ?*anyopaque,
    //window_id: c.Window,
    window_id: c_ulong,
    width: i32,
    height: i32,
    name: []const u8,
    running: bool,
    capture_cursor: bool,
    raw_mouse_motion: bool,
    is_vsync: bool,
    event_queue: EventQueue,
    keycodes: [256]u16,
    scancodes: [@intFromEnum(input.Key.key_last)]u16,

    pub fn init(
        allocator: Allocator,
        window_data: *wiz.WindowData,
        width: i32,
        height: i32,
        window_format: wiz.WindowFormat,
        comptime name: []const u8,
    ) !*Window {
        var window = try allocator.create(Window);

        window.allocator = allocator;
        window.window_data = window_data;
        window.width = width;
        window.height = height;
        window.name = name;
        window.running = true;

        const event_queue_size: usize = 1000;
        window.event_queue = try EventQueue.init(allocator, event_queue_size);

        // TODO(Thomas): Is this necessary?

        _ = window_format;

        const display = c.XOpenDisplay(null);
        if (display == null) {
            std.log.err("Could not open display", .{});
            return error.CouldNotOpenDisplay;
        }

        window.display = display.?;

        const screen = c.DefaultScreenOfDisplay(display);
        const screen_id = c.DefaultScreen(display);

        // Open the window
        const x_window = c.XCreateSimpleWindow(
            display,
            c.RootWindowOfScreen(screen),
            0,
            0,
            320,
            200,
            1,
            c.BlackPixel(display, screen_id),
            c.WhitePixel(display, screen_id),
        );

        window.window_id = x_window;

        _ = c.XSelectInput(
            display,
            x_window,
            c.KeyPressMask | c.KeyReleaseMask | c.KeymapStateMask | c.PointerMotionMask | c.ButtonPressMask | c.ButtonReleaseMask | c.EnterWindowMask | c.LeaveWindowMask | c.ExposureMask,
        );

        // Name the window
        _ = c.XStoreName(display, x_window, @ptrCast(name));

        // Show the window
        _ = c.XClearWindow(display, x_window);
        _ = c.XMapRaised(display, x_window);

        return window;
    }

    pub fn deinit(self: Window) void {
        //self.allocator.destroy(self.event_queue);
        _ = c.XDestroyWindow(@ptrCast(self.display), self.window_id);
        _ = c.XCloseDisplay(@ptrCast(self.display));
    }

    pub fn makeModernOpenGLContext(self: *Window) !void {
        _ = self;
    }

    pub fn setVSync(self: *Window, value: bool) !void {
        _ = self;
        _ = value;
    }

    pub fn windowShouldClose(self: *Window, value: bool) void {
        self.running = !value;
    }

    pub fn toggleFullscreen(self: *Window) !void {
        _ = self;
    }

    pub fn setCaptureCursor(self: *Window, value: bool) !void {
        _ = self;
        _ = value;
    }

    pub fn enableRawMouseMotion(self: *Window) void {
        _ = self;
    }

    pub fn disableRawMouseMotion(self: *Window) void {
        _ = self;
    }

    pub fn swapBuffers(self: *Window) !void {
        _ = self;
    }

    pub fn processMessages(self: *Window) !void {
        _ = c.XPending(@ptrCast(self.display));
        while (c.QLength(self.display) != 0) {
            var x_event = std.mem.zeroes(c.XEvent);
            _ = c.XNextEvent(@ptrCast(self.display), &x_event);
            switch (x_event.type) {
                c.ButtonPress => {
                    const event: ?input.Event = switch (x_event.xbutton.button) {
                        1 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .left,
                                .x = @intCast(x_event.xbutton.x),
                                .y = @intCast(x_event.xbutton.y),
                            },
                        },
                        else => null,
                    };
                    if (event) |val| {
                        self.event_queue.enqueue(val);
                    }
                },

                c.KeyPress => {
                    const keysym = c.XKeycodeToKeysym(@ptrCast(self.display), @intCast(x_event.xkey.keycode), 0);
                    const key = translateX11KeyToWizKey(keysym);
                    if (key) |val| {
                        const event = input.Event{ .KeyDown = input.KeyEvent{ .scancode = @intFromEnum(val) } };
                        self.event_queue.enqueue(event);
                    }
                },
                else => {},
            }
        }

        _ = c.XFlush(@ptrCast(self.display));
    }

    pub fn createKeyTables(self: *Window) void {
        // TODO(Thomas): Add check for xkb availability

        const desc = c.XkbGetMap(@ptrCast(self.display), 0, c.XkbUseCoreKbd);
        c.XkbGetNames(@ptrCast(self.display), c.XkbKeyNamesMask | c.XkbKeyAliasesMask, desc);
    }
};

// TODO(Thomas): Translating to scancodes for now, but this probably should
// be mapped to our own WizKey type or something similar.
// NOTE(Thomas): Not completed due to waiting to figure out how to solve this properly
pub fn translateX11KeyToWizKey(keysym: c.KeySym) ?input.Scancode {
    const result = switch (keysym) {
        c.XK_a => input.Scancode.Keyboard_A,
        c.XK_b => input.Scancode.Keyboard_B,
        c.XK_c => input.Scancode.Keyboard_C,
        c.XK_d => input.Scancode.Keyboard_D,
        c.XK_e => input.Scancode.Keyboard_E,
        c.XK_f => input.Scancode.Keyboard_F,
        c.XK_g => input.Scancode.Keyboard_G,
        c.XK_h => input.Scancode.Keyboard_H,
        c.XK_i => input.Scancode.Keyboard_I,
        c.XK_j => input.Scancode.Keyboard_J,
        c.XK_k => input.Scancode.Keyboard_K,
        c.XK_l => input.Scancode.Keyboard_L,
        c.XK_m => input.Scancode.Keyboard_M,
        c.XK_n => input.Scancode.Keyboard_N,
        c.XK_o => input.Scancode.Keyboard_O,
        c.XK_p => input.Scancode.Keyboard_P,
        c.XK_q => input.Scancode.Keyboard_Q,
        c.XK_r => input.Scancode.Keyboard_R,
        c.XK_s => input.Scancode.Keyboard_S,
        c.XK_t => input.Scancode.Keyboard_T,
        c.XK_u => input.Scancode.Keyboard_U,
        c.XK_v => input.Scancode.Keyboard_V,
        c.XK_w => input.Scancode.Keyboard_W,
        c.XK_x => input.Scancode.Keyboard_X,
        c.XK_y => input.Scancode.Keyboard_Y,
        c.XK_z => input.Scancode.Keyboard_Z,
        c.XK_1 => input.Scancode.Keyboard_1_And_Bang,
        c.XK_2 => input.Scancode.Keyboard_2_And_At,
        c.XK_3 => input.Scancode.Keyboard_3_And_Hash,
        c.XK_4 => input.Scancode.Keyboard_4_And_Dollar,
        c.XK_5 => input.Scancode.Keyboard_5_And_Percent,
        c.XK_6 => input.Scancode.Keyboard_6_And_Caret,
        c.XK_7 => input.Scancode.Keyboard_7_And_Ampersand,
        c.XK_8 => input.Scancode.Keyboard_8_And_Star,
        c.XK_9 => input.Scancode.Keyboard_9_And_Left_Bracket,
        c.XK_0 => input.Scancode.Keyboard_0_And_Right_Bracket,
        c.XK_Return => input.Scancode.Keyboard_Return_Enter,
        c.XK_Escape => input.Scancode.Keyboard_Escape,
        else => return null,
    };

    return result;
}
