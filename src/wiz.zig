const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const win32 = std.os.windows;

const input = @import("input.zig");
pub const Event = input.Event;
pub const KeyEvent = input.KeyEvent;
pub const Scancode = input.Scancode;
pub const MouseButton = input.MouseButton;

pub const opengl = @import("opengl.zig");

const windows = @import("windows.zig");
const x11 = @import("x11.zig");

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

pub fn queryPerformanceCounter(performance_counter: *i64) !void {
    switch (builtin.os.tag) {
        .windows => {
            const kernel32 = @import("kernel32.zig");
            try kernel32.queryPerformanceCounter(performance_counter);
        },
        .linux => {},
        else => @compileError("Unsupported OS"),
    }
}

pub fn queryPerformanceFrequency(performance_frequency: *i64) !void {
    switch (builtin.os.tag) {
        .windows => {
            const kernel32 = @import("kernel32.zig");
            try kernel32.queryPerformanceFrequency(performance_frequency);
        },
        .linux => {},
        else => @compileError("Unsupported OS"),
    }
}

pub const PlatformType = enum {
    X11,
    Windows,
};

pub const WindowType = union(enum) {
    windows_window: *windows.Window,
    x11_window: *x11.Window,
};

pub const WindowFormat = enum {
    windowed,
    fullscreen,
    borderless,
};

pub const windowPosCallbackType: *const fn (window: *WindowData, x_pos: i32, y_pos: i32) void = undefined;
pub const windowSizeCallbackType: *const fn (window: *WindowData, width: i32, height: i32) void = undefined;
pub const windowFramebufferSizeCallbackType: *const fn (window: *WindowData, width: i32, height: i32) void = undefined;
pub const mouseMoveCallbackType: *const fn (window: *WindowData, x_pos: i32, y_pos: i32) void = undefined;
pub const mouseButtonCallbackType: *const fn (window: *WindowData, x_pos: i32, y_pos: i32, button: MouseButton) void = undefined;

// TODO (Thomas): What to do with the default callbacks? Are they really necessary?
fn defaultWindowPosCallback(window_data: *WindowData, x_pos: i32, y_pos: i32) void {
    _ = window_data;
    _ = x_pos;
    _ = y_pos;
}

fn defaultWindowSizeCallback(window_data: *WindowData, width: i32, height: i32) void {
    window_data.width = width;
    window_data.height = height;
}

fn defaultWindowFramebufferSizeCallback(window_data: *WindowData, width: i32, height: i32) void {
    _ = window_data;
    _ = width;
    _ = height;
}

fn defaultMouseMoveCallback(window_data: *WindowData, x_pos: i32, y_pos: i32) void {
    window_data.last_mouse_x = x_pos;
    window_data.last_mouse_y = y_pos;
}

fn defaultMouseButtonCallback(window_data: *WindowData, x_pos: i32, y_pos: i32, button: MouseButton) void {
    _ = window_data;
    _ = x_pos;
    _ = y_pos;
    _ = button;
}

pub const WindowCallbacks = struct {
    window_pos: ?*const fn (window: *WindowData, x_pos: i32, y_pos: i32) void = null,
    window_resize: ?*const fn (window_data: *WindowData, width: i32, height: i32) void = null,
    window_framebuffer_resize: ?*const fn (window: *WindowData, width: i32, height: i32) void = null,
    mouse_move: ?*const fn (window: *WindowData, x_pos: i32, y_pos: i32) void = null,
    mouse_button: ?*const fn (window: *WindowData, x_pos: i32, y_pos: i32, button: MouseButton) void = null,
};

pub const WindowData = struct {
    width: i32,
    height: i32,
    last_mouse_x: i32,
    last_mouse_y: i32,
    callbacks: WindowCallbacks,
};

pub const PlatformWindow = struct {
    allocator: Allocator,
    window_data: *WindowData,
    window_type: WindowType,

    pub fn init(allocator: Allocator, width: i32, height: i32, window_format: WindowFormat, comptime name: []const u8) !PlatformWindow {
        var window_data = try allocator.create(WindowData);
        window_data.width = width;
        window_data.height = height;
        window_data.callbacks = WindowCallbacks{};

        var window = switch (builtin.os.tag) {
            .windows => PlatformWindow{
                .allocator = allocator,
                .window_data = window_data,
                .window_type = .{ .windows_window = try windows.Window.init(allocator, window_data, window_format, name) },
            },

            .linux => PlatformWindow{
                .allocator = allocator,
                .window_data = window_data,
                .window_type = .{ .x11_window = try x11.Window.init(allocator, window_data, width, height, window_format, name) },
            },

            else => @compileError("Unsupported OS"),
        };

        window.window_data.callbacks.window_framebuffer_resize = defaultWindowFramebufferSizeCallback;

        return window;
    }

    pub fn deinit(self: PlatformWindow) void {
        //switch (self) {
        //    inline else => |case| case.deinit(),
        //}

        switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.deinit(),
            .linux => self.window_type.x11_window.deinit(),
            else => @compileError("Unsupported OS"),
        }

        self.allocator.destroy(self.window_data);
    }

    pub fn makeModernOpenGLContext(self: PlatformWindow) !void {
        //switch (self) {
        //    inline else => |case| try case.makeModernOpenGLContext(),
        //}

        try switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.makeModernOpenGLContext(),
            .linux => self.window_type.x11_window.makeModernOpenGLContext(),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn setVSync(self: PlatformWindow, value: bool) !void {
        //switch (self) {
        //    inline else => |case| try case.setVSync(value),
        //}

        try switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.setVSync(value),
            .linux => self.window_type.x11_window.setVSync(value),
            else => @compileError("Unsupported OS"),
        };
    }

    //// TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn isVSync(self: PlatformWindow) bool {
        const is_vsync = switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.is_vsync,
            .linux => self.window_type.x11_window.is_vsync,
            else => @compileError("Unsupported OS"),
        };

        return is_vsync;
    }

    //// TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn isRunning(self: PlatformWindow) bool {
        const running = switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.running,
            .linux => self.window_type.x11_window.running,
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
            .windows => self.window_type.windows_window.event_queue.poll(event),
            .linux => self.window_type.x11_window.event_queue.poll(event),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn windowShouldClose(self: PlatformWindow, value: bool) void {
        switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.windowShouldClose(value),
            .linux => self.window_type.x11_window.windowShouldClose(value),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn toggleFullscreen(self: PlatformWindow) !void {
        try switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.toggleFullscreen(),
            .linux => self.window_type.x11_window.toggleFullscreen(),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn setCaptureCursor(self: PlatformWindow, value: bool) !void {
        try switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.setCaptureCursor(value),
            .linux => self.window_type.x11_window.setCaptureCursor(value),
            else => @compileError("Unsupported OS"),
        };
    }

    // TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn getCaptureCursor(self: PlatformWindow) bool {
        const capture_cursor = switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.capture_cursor,
            .linux => self.window_type.x11_window.capture_cursor,
            else => @compileError("Unsupported OS"),
        };

        return capture_cursor;
    }

    // TODO(Thomas): We should do this differently but it's the least intrusive way now
    pub fn getRawMouseMotion(self: PlatformWindow) bool {
        const raw_mouse_motion = switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.raw_mouse_motion,
            .linux => self.window_type.x11_window.raw_mouse_motion,
            else => @compileError("Unsupported OS"),
        };

        return raw_mouse_motion;
    }

    pub fn enableRawMouseMotion(self: PlatformWindow) void {
        switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.enableRawMouseMotion(),
            .linux => self.window_type.x11_window.enableRawMouseMotion(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn disableRawMouseMotion(self: PlatformWindow) void {
        switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.disableRawMouseMotion(),
            .linux => self.window_type.x11_window.disableRawMouseMotion(),
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn swapBuffers(self: PlatformWindow) !void {
        try switch (builtin.os.tag) {
            .windows => self.window_type.windows_window.swapBuffers(),
            .linux => self.window_type.x11_window.swapBuffers(),
            else => @compileError("Unsupported OS"),
        };
    }

    pub fn setWindowPosCallback(self: *PlatformWindow, cb_fun: @TypeOf(windowPosCallbackType)) void {
        self.window_data.callbacks.window_pos = cb_fun;
    }

    pub fn setWindowSizeCallback(self: *PlatformWindow, cb_fun: @TypeOf(windowSizeCallbackType)) void {
        self.window_data.callbacks.window_resize = cb_fun;
    }

    pub fn setWindowFramebufferSizeCallback(self: *PlatformWindow, cb_fun: @TypeOf(windowFramebufferSizeCallbackType)) void {
        self.window_data.callbacks.window_framebuffer_resize = cb_fun;
    }

    pub fn setMouseMoveCallback(self: *PlatformWindow, cb_fun: @TypeOf(mouseMoveCallbackType)) void {
        self.window_data.callbacks.mouse_move = cb_fun;
    }

    pub fn setMouseButtonCallback(self: *PlatformWindow, cb_fun: @TypeOf(mouseButtonCallbackType)) void {
        self.window_data.callbacks.mouse_button = cb_fun;
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
