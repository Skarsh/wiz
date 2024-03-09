const std = @import("std");
const windows = std.os.windows;

pub extern "kernel32" fn MulDiv(nNumber: windows.INT, nNumerator: windows.INT, nDenominator: windows.INT) callconv(windows.WINAPI) windows.INT;
pub extern "kernel32" fn QueryPerformanceCounter(lpPerformanceCounter: *windows.LARGE_INTEGER) callconv(windows.WINAPI) windows.BOOL;
pub extern "kernel32" fn QueryPerformanceFrequency(lpFrequency: *windows.LARGE_INTEGER) callconv(windows.WINAPI) windows.BOOL;
