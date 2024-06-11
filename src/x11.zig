const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @import("input.zig");
const EventQueue = input.EventQueue;

const wiz = @import("wiz.zig");

const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/keysymdef.h");
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

    pub fn processMessages(self: *Window) !void {
        var ev = c.XEvent{ .type = 0 };

        var attribs = c.XWindowAttributes{};
        _ = c.XGetWindowAttributes(@ptrCast(self.display), self.window_id, &attribs);

        var str = [_]u8{0} ** 25;
        var keysym: c_ulong = 0;
        var len: c_int = 0;
        //var running = true;
        var x: i32 = 0;
        var y: i32 = 0;

        const event_mask =
            c.KeyPressMask | c.KeyReleaseMask | c.KeymapStateMask | c.PointerMotionMask | c.ButtonPressMask | c.ButtonReleaseMask | c.EnterWindowMask | c.LeaveWindowMask | c.ExposureMask;

        while (c.XCheckWindowEvent(@ptrCast(self.display), self.window_id, event_mask, &ev) != 0) {
            _ = c.XNextEvent(@ptrCast(self.display), &ev);
            switch (ev.type) {
                c.KeymapNotify => {
                    _ = c.XRefreshKeyboardMapping(&ev.xmapping);
                },
                c.KeyPress => {
                    _ = c.XLookupString(&ev.xkey, &str, 25, &keysym, null);
                    if (len > 0) {
                        std.debug.print("Key pressed: {s} - {} - {}\n", .{ str, len, keysym });
                        // TODO(Thomas): Deal with null value properly
                        const scancode = @intFromEnum(translateX11KeyToWizKey(keysym).?);
                        const event = input.Event{ .KeyDown = input.KeyEvent{ .scancode = scancode } };
                        self.event_queue.enqueue(event);
                    }
                },
                c.KeyRelease => {
                    len = c.XLookupString(&ev.xkey, &str, 25, &keysym, null);
                    if (len > 0) {
                        std.debug.print("Key released: {s} - {} - {}\n", .{ str, len, keysym });

                        // TODO(Thomas): Deal with null value properly
                        const scancode = @intFromEnum(translateX11KeyToWizKey(keysym).?);
                        const event = input.Event{ .KeyUp = input.KeyEvent{ .scancode = scancode } };
                        self.event_queue.enqueue(event);
                    }
                },
                c.ButtonPress => {
                    // TODO(Thomas): Verify the button mappings, there's probably a better
                    // way to retrieve these values from Xlib or similar instead of just hardcoding.
                    const event: ?input.Event = switch (ev.xbutton.button) {
                        1 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .left,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        2 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .middle,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },

                        3 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .right,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },

                        4 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .wheel_up,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        5 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .wheel_down,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        6 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .nav_backward,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        7 => input.Event{
                            .MouseButtonDown = input.MouseButtonEvent{
                                .button = .nav_forward,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        else => null,
                    };
                    // NOTE(Thomas): We only put events on the queue if they matches the set of legal buttons
                    if (event) |val| {
                        self.event_queue.enqueue(val);
                    }
                },
                c.ButtonRelease => {
                    // TODO(Thomas): Verify the button mappings, there's probably a better
                    // way to retrieve these values from Xlib or similar instead of just hardcoding.
                    const event: ?input.Event = switch (ev.xbutton.button) {
                        1 => input.Event{
                            .MouseButtonUp = input.MouseButtonEvent{
                                .button = .left,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        2 => input.Event{
                            .MouseButtonUp = input.MouseButtonEvent{
                                .button = .middle,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },

                        3 => input.Event{
                            .MouseButtonUp = input.MouseButtonEvent{
                                .button = .right,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },

                        6 => input.Event{
                            .MouseButtonUp = input.MouseButtonEvent{
                                .button = .nav_backward,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        7 => input.Event{
                            .MouseButtonUp = input.MouseButtonEvent{
                                .button = .nav_forward,
                                .x = @intCast(ev.xbutton.x),
                                .y = @intCast(ev.xbutton.y),
                            },
                        },
                        else => null,
                    };
                    // NOTE(Thomas): We only put events on the queue if they matches the set of legal buttons
                    if (event) |val| {
                        self.event_queue.enqueue(val);
                    }
                },
                c.MotionNotify => {
                    x = ev.xmotion.x;
                    y = ev.xmotion.y;
                    // TODO(Thomas): Think about making MouseMotion fields be i32 instead of i16 to avoid intCast. That would have no impact on
                    // windows side since it would be casting up to a bigger size.
                    const event = input.Event{ .MouseMotion = input.MouseMotionEvent{ .x = @intCast(x), .y = @intCast(y), .x_rel = 0, .y_rel = 0 } };
                    self.event_queue.enqueue(event);
                },
                c.EnterNotify => {
                    std.debug.print("Mouse enter\n", .{});
                },
                c.LeaveNotify => {
                    std.debug.print("Mouse leave\n", .{});
                },
                c.Expose => {
                    std.debug.print("Expose event fired", .{});
                    _ = c.XGetWindowAttributes(@ptrCast(self.display), self.window_id, &attribs);
                    std.debug.print("\tWindow width: {}, height: {}\n", .{ attribs.width, attribs.height });
                },
                else => {},
            }
        }
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
