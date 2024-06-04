const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @import("input.zig");
const EventQueue = input.EventQueue;

pub const Window = struct {
    width: i32,
    height: i32,
    name: []const u8,
    running: bool,
    event_queue: EventQueue,

    pub fn init(allocator: Allocator, width: i32, height: i32, comptime name: []const u8) !*Window {
        var window = try allocator.create(Window);

        window.width = width;
        window.height = height;
        window.name = name;
        window.running = true;

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
};
