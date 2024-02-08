const std = @import("std");
const win32 = std.os.windows;

const input = @import("input.zig");
pub const Event = input.Event;
pub const KeyEvent = input.KeyEvent;
pub const Scancode = input.Scancode;

const windows = @import("windows.zig");
pub const Window = windows.Window;
pub const WindowFormat = windows.WindowFormat;

pub const user32 = @import("user32.zig");
pub const opengl32 = @import("opengl32.zig");

pub const ns_per_sec = 1_000_000_000;
pub const ms_per_sec = 1000;

// TODO(Thomas): Move this into its own file, e.g. kernel32.zig
extern "kernel32" fn QueryPerformanceCounter(lpPerformanceCounter: *win32.LARGE_INTEGER) callconv(win32.WINAPI) win32.BOOL;
extern "kernel32" fn QueryPerformanceFrequency(lpFrequency: *win32.LARGE_INTEGER) callconv(win32.WINAPI) win32.BOOL;

// TODO(Thomas): Find a better home for this, but this file will do for now.
pub extern "winmm" fn timeBeginPeriod(uPeriod: win32.UINT) callconv(win32.WINAPI) win32.INT;

pub fn queryPerformanceCounter(performance_counter: *i64) !void {
    if (QueryPerformanceCounter(performance_counter) == 0) {
        switch (win32.kernel32.GetLastError()) {
            else => |err| return win32.unexpectedError(err),
        }
    }
}

pub fn queryPerformanceFrequency(performannce_frequency: *i64) !void {
    if (QueryPerformanceFrequency(performannce_frequency) == 0) {
        switch (win32.kernel32.GetLastError()) {
            else => |err| return win32.unexpectedError(err),
        }
    }
}

test {
    // TODO(Thomas): Would it be better to do this in a test in the
    // respective source file instead?
    std.testing.refAllDeclsRecursive(input);
    std.testing.refAllDeclsRecursive(windows);
    std.testing.refAllDeclsRecursive(opengl32);

    @setEvalBranchQuota(10_000);
    std.testing.refAllDeclsRecursive(user32);
}
