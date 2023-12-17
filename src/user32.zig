const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;

// Types
pub const GetLastError = windows.kernel32.GetLastError;
pub const SetLastError = windows.kernel32.SetLastError;
pub const unexpectedError = windows.unexpectedError;
pub const HWND = windows.HWND;
pub const UINT = windows.UINT;
pub const HDC = windows.HDC;
pub const LONG = windows.LONG;
pub const LONG_PTR = windows.LONG_PTR;
pub const LPCSTR = windows.LPCSTR;
pub const WINAPI = windows.WINAPI;
pub const RECT = windows.RECT;
pub const DWORD = windows.DWORD;
pub const BOOL = windows.BOOL;
pub const TRUE = windows.TRUE;
pub const HMENU = windows.HMENU;
pub const HINSTANCE = windows.HINSTANCE;
pub const LPVOID = windows.LPVOID;
pub const ATOM = windows.ATOM;
pub const WPARAM = windows.WPARAM;
pub const LRESULT = windows.LRESULT;
pub const HICON = windows.HICON;
pub const LPARAM = windows.LPARAM;
pub const POINT = windows.POINT;
pub const HCURSOR = windows.HCURSOR;
pub const HBRUSH = windows.HBRUSH;

inline fn selectSymbol(comptime function_static: anytype, function_dynamic: *const @TypeOf(function_static), comptime os: std.Target.Os.WindowsVersion) *const @TypeOf(function_static) {
    const sym_ok = comptime builtin.os.isAtLeast(.windows, os);
    if (sym_ok == true) return function_static;
    if (sym_ok == null) return function_dynamic;
    if (sym_ok == false) @compileError("Target OS range does not support function, at least " ++ @tagName(os) ++ " is required");
}

//==== Messages ==== //
pub const WNDPROC = *const fn (
    hwnd: HWND,
    uMsg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT;

pub const MSG = extern struct {
    hWnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};

// ==== Windows ==== //
pub const CS_VREDRAW = 0x0001;
pub const CS_HREDRAW = 0x0002;
pub const CS_DBLCKS = 0x0008;
pub const CS_OWNDC = 0x0020;
pub const CS_CLASSDC = 0x0040;
pub const CS_PARENTDC = 0x0080;
pub const CS_NOCLOSE = 0x0200;
pub const CS_SAVEBITS = 0x0800;
pub const CS_BYTEALIGNCLIENT = 0x1000;
pub const CS_BYTEALIGNWINDOW = 0x2000;
pub const CS_GLOBALCLASS = 0x4000;

pub const WNDCLASSEXA = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXA),
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?[*:0]const u8,
    lpszClassName: [*:0]const u8,
    hIconSm: ?HICON,
};

pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXW),
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
    hIconSm: ?HICON,
};

pub extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(WINAPI) ATOM;
pub fn registerClassExA(window_class: *const WNDCLASSEXA) !ATOM {
    const atom = RegisterClassExA(window_class);
    if (atom != 0) return atom;
    switch (GetLastError()) {
        .CLASS_ALREADY_EXISTS => return error.AlreadyExists,
        .INVALID_PARAMETER => unreachable,
        else => |err| return windows.unexpectedError(err),
    }
}

pub extern "user32" fn RegisterClassExW(*const WNDCLASSEXW) callconv(WINAPI) ATOM;
pub var pfnRegisterClassExW: *const @TypeOf(RegisterClassExW) = undefined;
pub fn registerClassExW(window_class: *const WNDCLASSEXW) !ATOM {
    const function = selectSymbol(RegisterClassExW, pfnRegisterClassExW, .win2k);
    const atom = function(window_class);
    if (atom != 0) return atom;
    switch (GetLastError()) {
        .CLASS_ALREADY_EXISTS => return error.AlreadyExists,
        .CALL_NOT_IMPLEMENTED => unreachable,
        .INVALID_PARAMETER => unreachable,
        else => |err| return windows.unexpectedError(err),
    }
}

pub extern "user32" fn LoadCursorA(
    hInstance: HINSTANCE,
    lpCursorName: LPCSTR,
) callconv(WINAPI) HCURSOR;

pub extern "user32" fn LoadCursorW(
    hInstance: HINSTANCE,
    lpCursorName: LPCSTR,
) callconv(WINAPI) HCURSOR;
