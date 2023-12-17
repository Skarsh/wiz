const std = @import("std");
const windows = std.os.windows;
const WINAPI = windows.WINAPI;
const winh = @import("winh.zig").winh;

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
extern "kernel32" fn GetModuleHandle(lp_moudle_name: ?windows.LPCSTR) callconv(WINAPI) windows.HMODULE;

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
            std.debug.print("closing");
        },
    }
}

pub export fn wWinMain(
    h_instance: ?windows.HINSTANCE,
    h_prev_instance: ?windows.HINSTANCE,
    lp_cmd_line: ?windows.LPWSTR,
    n_show_cmd: windows.INT,
) callconv(WINAPI) windows.INT {
    _ = h_instance;
    _ = h_prev_instance;
    _ = lp_cmd_line;
    _ = n_show_cmd;

    _ = MessageBoxA(null, "Zig is pretty great", "Wow much exposure", 4);
    _ = AllocConsole();

    var written: windows.UINT = 0;
    const h_console = GetStdHandle(STD_HANDLE.OUTPUT_HANDLE);

    const hello = "hello";
    _ = WriteConsoleA(h_console, hello, hello.len, &written, null);

    return 0;
}
