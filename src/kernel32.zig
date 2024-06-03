const std = @import("std");
const windows = std.os.windows;

pub extern "kernel32" fn MulDiv(nNumber: windows.INT, nNumerator: windows.INT, nDenominator: windows.INT) callconv(windows.WINAPI) windows.INT;
pub extern "kernel32" fn QueryPerformanceCounter(lpPerformanceCounter: *windows.LARGE_INTEGER) callconv(windows.WINAPI) windows.BOOL;
pub extern "kernel32" fn QueryPerformanceFrequency(lpFrequency: *windows.LARGE_INTEGER) callconv(windows.WINAPI) windows.BOOL;

const GetLastError = windows.kernel32.GetLastError;
const unexpectedError = windows.unexpectedError;

pub fn queryPerformanceCounter(performance_counter: *i64) !void {
    if (QueryPerformanceCounter(performance_counter) == 0) {
        switch (GetLastError()) {
            else => |err| return unexpectedError(err),
        }
    }
}

pub fn queryPerformanceFrequency(performannce_frequency: *i64) !void {
    if (QueryPerformanceFrequency(performannce_frequency) == 0) {
        switch (GetLastError()) {
            else => |err| return unexpectedError(err),
        }
    }
}
