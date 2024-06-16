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
pub fn translateX11KeyToWizKey(keysym: c.KeySym) ?input.Key {
    const result = switch (keysym) {
        c.XK_a => input.Key.key_a,
        c.XK_b => input.Key.key_b,
        c.XK_c => input.Key.key_c,
        c.XK_d => input.Key.key_d,
        c.XK_e => input.Key.key_e,
        c.XK_f => input.Key.key_f,
        c.XK_g => input.Key.key_g,
        c.XK_h => input.Key.key_h,
        c.XK_i => input.Key.key_i,
        c.XK_j => input.Key.key_j,
        c.XK_k => input.Key.key_k,
        c.XK_l => input.Key.key_l,
        c.XK_m => input.Key.key_m,
        c.XK_n => input.Key.key_n,
        c.XK_o => input.Key.key_o,
        c.XK_p => input.Key.key_p,
        c.XK_q => input.Key.key_q,
        c.XK_r => input.Key.key_r,
        c.XK_s => input.Key.key_s,
        c.XK_t => input.Key.key_t,
        c.XK_u => input.Key.key_u,
        c.XK_v => input.Key.key_v,
        c.XK_w => input.Key.key_w,
        c.XK_x => input.Key.key_x,
        c.XK_y => input.Key.key_y,
        c.XK_z => input.Key.key_z,
        c.XK_1 => input.Key.key_1,
        c.XK_2 => input.Key.key_2,
        c.XK_3 => input.Key.key_3,
        c.XK_4 => input.Key.key_4,
        c.XK_5 => input.Key.key_5,
        c.XK_6 => input.Key.key_6,
        c.XK_7 => input.Key.key_7,
        c.XK_8 => input.Key.key_8,
        c.XK_9 => input.Key.key_9,
        c.XK_0 => input.Key.key_0,
        c.XK_Return => input.Key.key_return,
        c.XK_Escape => input.Key.key_escape,
        else => return null,
    };

    return result;
}
