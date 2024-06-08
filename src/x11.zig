const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @import("input.zig");
const EventQueue = input.EventQueue;

const wiz = @import("wiz.zig");

//const c = @cImport({
//    @cInclude("X11/X.h");
//    @cInclude("X11/Xlib.h");
//    @cInclude("GL/gl.h");
//    @cInclude("GL/glx.h");
//});
//
//pub fn main() !void {
//    const display = c.XOpenDisplay(0);
//    const root_window = c.DefaultRootWindow(display);
//    _ = c.DefaultScreen(display);
//    const window = c.XCreateWindow(display, root_window, 0, 0, 1280, 720, 0, 0, 0, 0, 0, 0);
//    _ = c.XMapWindow(display, window);
//    _ = c.XFlush(display);
//
//    while (true) {}
//}

pub const Window = struct {
    allocator: Allocator,
    window_data: *wiz.WindowData,
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

        _ = window_format;

        return window;
    }

    pub fn deinit(self: Window) void {
        _ = self;
    }

    pub fn makeModernOpenGLContext(self: *Window) !void {
        _ = self;
    }

    pub fn setVSync(self: *Window, value: bool) !void {
        _ = self;
        _ = value;
    }

    pub fn processMessages() !void {}

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
