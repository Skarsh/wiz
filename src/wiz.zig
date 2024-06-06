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
        //switch (self) {
        //    inline else => |case| case.deinit(),
        //}

        switch (builtin.os.tag) {
            .windows => self.windows_window.deinit(),
            .linux => self.x11_window.deinit(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn makeModernOpenGLContext(self: PlatformWindow) !void {
        //switch (self) {
        //    inline else => |case| try case.makeModernOpenGLContext(),
        //}

        try switch (builtin.os.tag) {
            .windows => self.windows_window.makeModernOpenGLContext(),
            .linux => self.x11_window.makeModernOpenGLContext(),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn setVSync(self: PlatformWindow, value: bool) !void {
        //switch (self) {
        //    inline else => |case| try case.setVSync(value),
        //}

        try switch (builtin.os.tag) {
            .windows => self.windows_window.setVSync(value),
            .linux => self.x11_window.setVSync(value),
            else => @compileError("Unsupported OS"),
        };
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
            .linux => self.x11_window.event_queue.poll(event),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn windowShouldClose(self: PlatformWindow, value: bool) void {
        switch (builtin.os.tag) {
            .windows => self.windows_window.windowShouldClose(value),
            .linux => self.x11_window.windowShouldClose(value),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn toggleFullscreen(self: PlatformWindow) !void {
        try switch (builtin.os.tag) {
            .windows => self.windows_window.toggleFullscreen(),
            .linux => self.x11_window.toggleFullscreen(),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn setCaptureCursor(self: PlatformWindow, value: bool) !void {
        try switch (builtin.os.tag) {
            .windows => self.windows_window.setCaptureCursor(value),
            .linux => self.x11_window.setCaptureCursor(value),
            else => @compileError("Unsupported OS"),
        };
    }

    // TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn getCaptureCursor(self: PlatformWindow) bool {
        const capture_cursor = switch (builtin.os.tag) {
            .windows => self.windows_window.capture_cursor,
            .linux => self.x11_window.capture_cursor,
            else => @compileError("Unsupported OS"),
        };

        return capture_cursor;
    }

    // TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn getRawMouseMotion(self: PlatformWindow) bool {
        const raw_mouse_motion = switch (builtin.os.tag) {
            .windows => self.windows_window.raw_mouse_motion,
            .linux => self.x11_window.raw_mouse_motion,
            else => @compileError("Unsupported OS"),
        };

        return raw_mouse_motion;
    }

    pub fn enableRawMouseMotion(self: PlatformWindow) void {
        switch (builtin.os.tag) {
            .windows => self.windows_window.enableRawMouseMotion(),
            .linux => self.x11_window.enableRawMouseMotion(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn disableRawMouseMotion(self: PlatformWindow) void {
        switch (builtin.os.tag) {
            .windows => self.windows_window.disableRawMouseMotion(),
            .linux => self.x11_window.disableRawMouseMotion(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn swapBuffers(self: PlatformWindow) !void {
        try switch (builtin.os.tag) {
            .windows => self.windows_window.swapBuffers(),
            .linux => self.x11_window.swapBuffers(),
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
