const std = @import("std");
const windows = std.os.windows;
const winh = @import("winh.zig").winh;
const user32 = @import("user32.zig");
const WINAPI = user32.WINAPI;

extern "kernel32" fn GetLastError() callconv(WINAPI) windows.DWORD;

extern "user32" fn MessageBoxA(
    h_wnd: ?windows.HANDLE,
    lp_text: ?windows.LPCSTR,
    lp_caption: ?windows.LPCSTR,
    u_type: windows.UINT,
) callconv(WINAPI) windows.INT;

extern "kernel32" fn AllocConsole() callconv(WINAPI) windows.BOOL;

extern "kernel32" fn WriteConsoleA(
    h_console_output: ?windows.HANDLE,
    lp_buffer: [*c]const u8,
    n_number_of_chars_to_write: windows.UINT,
    lp_number_of_chars_to_written: ?*windows.UINT,
    lp_reserved: ?*anyopaque,
) callconv(WINAPI) windows.BOOL;

const STD_HANDLE = enum(windows.UINT) {
    INPUT_HANDLE = 4294967286,
    OUTPUT_HANDLE = 4294967285,
    ERROR_HANDLE = 4294967284,
};

extern "kernel32" fn GetStdHandle(n_std_handle: STD_HANDLE) callconv(WINAPI) windows.HANDLE;
extern "kernel32" fn GetModuleHandleW(lp_moudle_name: ?windows.LPCSTR) callconv(WINAPI) windows.HMODULE;
extern "user32" fn RegisterClassW(wnd_class_w: winh.LPWNDCLASSW) callconv(WINAPI) winh.ATOM;

var global_running = true;

fn win32MainWindowCallback(
    window: windows.HWND,
    message: windows.UINT,
    w_param: windows.WPARAM,
    l_param: windows.LPARAM,
) callconv(WINAPI) windows.LRESULT {
    _ = window;
    _ = w_param;
    _ = l_param;

    const result: windows.LRESULT = 0;
    _ = result;

    switch (message) {
        winh.WM_CLOSE => {
            std.debug.print("closing", .{});
        },
        else => {},
    }

    return 0;
}

pub fn main() !void {
    const instance = GetModuleHandleW(null);
    _ = instance;

    var window_class = winh.WNDCLASSW{};
    window_class.style = winh.CS_HREDRAW | winh.CS_VREDRAW | winh.CS_OWNDC;
    //window_class.lpfnWndProc = win32MainWindowCallback;
    window_class.lpfnWndProc = winh.DefWindowProcW;
    //window_class.hInstance = instance;
}
