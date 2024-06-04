const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const win32 = std.os.windows;

const input = @import("input.zig");
pub const Event = input.Event;
pub const KeyEvent = input.KeyEvent;
pub const Scancode = input.Scancode;

const windows = @import("windows.zig");
const x11 = @import("x11.zig");

//pub const Window = windows.Window;
//pub const WindowFormat = windows.WindowFormat;
//
//pub const kernel32 = @import("kernel32.zig");
//pub const user32 = @import("user32.zig");
//pub const opengl32 = @import("opengl32.zig");

pub const ns_per_sec = 1_000_000_000;
pub const ms_per_sec = 1000;

pub const FrameTimes = struct {
    idx: usize,
    durations: []f32,

    pub fn new(allocator: Allocator, num_elements: usize) !FrameTimes {
        var durations = try allocator.alloc(f32, num_elements);

        for (0..durations.len) |i| {
            durations.ptr[i] = 0.0;
        }

        return FrameTimes{
            .idx = 0,
            .durations = durations,
        };
    }

    pub fn calculateMeanFrameTime(self: FrameTimes) f32 {
        var sum: f32 = 0.0;
        for (self.durations) |dur| {
            sum += dur;
        }

        const mean = sum / @as(f32, @floatFromInt(self.durations.len));
        return mean;
    }

    pub fn push(self: *FrameTimes, duration: f32) void {
        if (self.idx < self.durations.len) {
            self.durations.ptr[self.idx] = duration;
            self.idx += 1;
        } else {
            self.idx = 0;
            self.durations.ptr[self.idx] = duration;
            self.idx += 1;
        }
    }
};

pub const PlatformType = enum {
    X11,
    Windows,
};

pub const PlatformWindow = union(enum) {
    windows_window: *windows.Window,
    x11_window: *x11.Window,

    pub fn init(allocator: Allocator, width: i32, height: i32, comptime name: []const u8) !PlatformWindow {
        const window = switch (builtin.os.tag) {
            .windows => PlatformWindow{ .windows_window = try windows.Window.init(allocator, width, height, .windowed, name) },
            .linux => PlatformWindow{ .x11_window = try x11.Window.init(allocator, width, height, name) },
            else => @compileError("Unsupported OS"),
        };
        return window;
    }

    pub fn deinit(self: PlatformWindow) void {
        switch (self) {
            inline else => |case| case.deinit(),
        }
    }

    pub fn makeModernOpenGLContext(self: PlatformWindow) !void {
        switch (self) {
            inline else => |case| try case.makeModernOpenGLContext(),
        }
    }

    pub fn setVSync(self: PlatformWindow, value: bool) !void {
        switch (self) {
            inline else => |case| try case.setVSync(value),
        }
    }

    // TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn isRunning(self: PlatformWindow) bool {
        const running = switch (builtin.os.tag) {
            .windows => self.windows_window.running,
            .linux => self.x11_window.running,
            else => @compileError("Unsupported OS"),
        };

        return running;
    }

    pub fn processMessages() !void {
        switch (builtin.os.tag) {
            .windows => try windows.Window.processMessages(),
            .linux => try x11.Window.processMessages(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn pollEvent(self: PlatformWindow, event: *Event) bool {
        return switch (builtin.os.tag) {
            .windows => self.windows_window.event_queue.poll(event),
            .linux => self.windows_window.event_queue.poll(event),
            else => @compileError("Unsupported OS"),
        };
    }
};

//test {
//    // TODO(Thomas): Would it be better to do this in a test in the
//    // respective source file instead?
//    std.testing.refAllDeclsRecursive(input);
//    std.testing.refAllDeclsRecursive(windows);
//    std.testing.refAllDeclsRecursive(opengl32);
//
//    @setEvalBranchQuota(10_000);
//    std.testing.refAllDeclsRecursive(user32);
//}
