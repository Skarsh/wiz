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

//pub fn queryPerformanceCounter(performance_counter: *i64) !void {
//    if (kernel32.QueryPerformanceCounter(performance_counter) == 0) {
//        switch (win32.kernel32.GetLastError()) {
//            else => |err| return win32.unexpectedError(err),
//        }
//    }
//}
//
//pub fn queryPerformanceFrequency(performannce_frequency: *i64) !void {
//    if (kernel32.QueryPerformanceFrequency(performannce_frequency) == 0) {
//        switch (win32.kernel32.GetLastError()) {
//            else => |err| return win32.unexpectedError(err),
//        }
//    }
//}

pub const PlatformType = enum {
    X11,
    Windows,
};

pub const PlatformWindow = union {
    windows_window: windows.Window,
    x11_window: x11.Window,
};

//pub const PlatformsEnabled = struct {
//    x11: bool = if (builtin.os.tag == .linux) true else false,
//    windows: bool = if (builtin.os.tag == .windows) true else false,
//};

pub fn createWindow(
    allocator: Allocator,
    width: i32,
    height: i32,
    name: []const u8,
    comptime platform_type: PlatformType,
) !PlatformWindow {
    switch (platform_type) {
        .Windows => {
            std.debug.print("Platform: Windows\n", .{});
            const window = try windows.Window.init(allocator, width, height, .windowed, name);
            return PlatformWindow{ .windows_window = window };
        },
        .X11 => {
            std.debug.print("Platform: X11\n", .{});
            const window = x11.Window{};
            return PlatformWindow{ .x11_window = window };
        },
    }
}

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
