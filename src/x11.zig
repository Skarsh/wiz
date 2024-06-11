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
                        const event = input.Event{ .KeyDown = input.KeyEvent{ .scancode = ev.xkey.keycode } };
                        self.event_queue.enqueue(event);
                    }
                },
                c.KeyRelease => {
                    len = c.XLookupString(&ev.xkey, &str, 25, &keysym, null);
                    if (len > 0) {
                        std.debug.print("Key released: {s} - {} - {}\n", .{ str, len, keysym });
                        const event = input.Event{ .KeyUp = input.KeyEvent{ .scancode = ev.xkey.keycode } };
                        self.event_queue.enqueue(event);
                    }
                },
                c.ButtonPress => {
                    switch (ev.xbutton.button) {
                        1 => {
                            std.debug.print("Left mouse button down\n", .{});
                        },
                        2 => {
                            std.debug.print("Middle mouse button down\n", .{});
                        },
                        3 => {
                            std.debug.print("Right mouse button down\n", .{});
                        },
                        4 => {
                            std.debug.print("Mouse scroll up\n", .{});
                        },
                        5 => {
                            std.debug.print("Mouse scroll down\n", .{});
                        },
                        else => {},
                    }
                },
                c.ButtonRelease => {
                    switch (ev.xbutton.button) {
                        1 => {
                            std.debug.print("Left mouse button up\n", .{});
                        },
                        2 => {
                            std.debug.print("Middle mouse button up\n", .{});
                        },
                        3 => {
                            std.debug.print("Right mouse button up\n", .{});
                        },
                        else => {},
                    }
                },
                c.MotionNotify => {
                    x = ev.xmotion.x;
                    y = ev.xmotion.y;
                    std.debug.print("Mouse X: {}, Y: {}\n", .{ x, y });
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
