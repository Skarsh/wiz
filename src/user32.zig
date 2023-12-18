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

pub extern "user32" fn UnregisterClassA(lpClassName: [*:0]const u8, hInstance: HINSTANCE) callconv(WINAPI) BOOL;
pub fn unregisterClassA(lpClassName: [*:0]const u8, hInstance: HINSTANCE) !void {
    if (UnregisterClassA(lpClassName, hInstance) == 0) {
        switch (GetLastError()) {
            .CLASS_DOES_NOT_EXIST => return error.ClassDoesNotExist,
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub extern "user32" fn UnregisterClassW(lpClassName: [*:0]const u16, hInstance: HINSTANCE) callconv(WINAPI) BOOL;
pub var pfnUnregisterClassW: *const @TypeOf(UnregisterClassW) = undefined;
pub fn unregisterClassW(lpClassName: [*:0]const u16, hInstance: HINSTANCE) callconv(WINAPI) !void {
    const function = selectSymbol(UnregisterClassW, pfnUnregisterClassW, .win2k);
    if (function(lpClassName, hInstance) == 0) {
        switch (GetLastError()) {
            .CLASS_DOES_NOT_EXIST => return error.ClassDoesNotExist,
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub const WS_OVERLAPPED = 0x00000000;
pub const WS_POPUP = 0x80000000;
pub const WS_CHILD = 0x40000000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_CAPTION = WS_BORDER | WS_DLGFRAME;
pub const WS_BORDER = 0x00800000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_VSCROLL = 0x00200000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_GROUP = 0x00020000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_TILED = WS_OVERLAPPED;
pub const WS_ICONIC = WS_MINIMIZE;
pub const WS_SIZEBOX = WS_THICKFRAME;
pub const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
pub const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
pub const WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU;
pub const WS_CHILDWINDOW = WS_CHILD;

pub const WS_EX_DLGMODALFRAME = 0x00000001;
pub const WS_EX_NOPARENTNOTIFY = 0x00000004;
pub const WS_EX_TOPMOST = 0x00000008;
pub const WS_EX_ACCEPTFILES = 0x00000010;
pub const WS_EX_TRANSPARENT = 0x00000020;
pub const WS_EX_MDICHILD = 0x00000040;
pub const WS_EX_TOOLWINDOW = 0x00000080;
pub const WS_EX_WINDOWEDGE = 0x00000100;
pub const WS_EX_CLIENTEDGE = 0x00000200;
pub const WS_EX_CONTEXTHELP = 0x00000400;
pub const WS_EX_RIGHT = 0x00001000;
pub const WS_EX_LEFT = 0x00000000;
pub const WS_EX_RTLREADING = 0x00002000;
pub const WS_EX_LTRREADING = 0x00000000;
pub const WS_EX_LEFTSCROLLBAR = 0x00004000;
pub const WS_EX_RIGHTSCROLLBAR = 0x00000000;
pub const WS_EX_CONTROLPARENT = 0x00010000;
pub const WS_EX_STATICEDGE = 0x00020000;
pub const WS_EX_APPWINDOW = 0x00040000;
pub const WS_EX_LAYERED = 0x00080000;
pub const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;
pub const WS_EX_PALETTEWINDOW = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;

pub const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));

pub extern "user32" fn CreateWindowExA(
    dwExStyle: DWORD,
    lpClassName: [*:0]const u8,
    lpWindowName: [*:0]const u8,
    dwStyle: DWORD,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    hWindParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: ?LPVOID,
) callconv(WINAPI) ?HWND;
pub fn createWindowExA(
    dwExStyle: u32,
    lpClassName: [*:0]const u8,
    lpWindowName: [*:0]const u8,
    dwStyle: u32,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    hWindParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: ?*anyopaque,
) !HWND {
    const window = CreateWindowExA(
        dwExStyle,
        lpClassName,
        lpWindowName,
        dwStyle,
        x,
        y,
        nWidth,
        nHeight,
        hWindParent,
        hMenu,
        hInstance,
        lpParam,
    );
    if (window) |win| return win;

    switch (GetLastError()) {
        .CLASS_DOES_NOT_EXIST => return error.ClassDoesNotExist,
        .INVALID_PARAMETER => unreachable,
        else => |err| return windows.unexpectedError(err),
    }
}

pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: [*:0]const u16,
    lpWindowName: [*:0]const u16,
    dwStyle: DWORD,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    hWindParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: ?LPVOID,
) callconv(WINAPI) ?HWND;
pub var pfnCreateWindowExW: *const @TypeOf(CreateWindowExW) = undefined;
pub fn createWindowExW(
    dwExStyle: DWORD,
    lpClassName: [*:0]const u16,
    lpWindowName: [*:0]const u16,
    dwStyle: DWORD,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    hWindParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: ?*anyopaque,
) !HWND {
    const function = selectSymbol(CreateWindowExW, pfnCreateWindowExW, .win2k);
    const window = function(
        dwExStyle,
        lpClassName,
        lpWindowName,
        dwStyle,
        x,
        y,
        nWidth,
        nHeight,
        hWindParent,
        hMenu,
        hInstance,
        lpParam,
    );
    if (window) |win| return win;

    switch (GetLastError()) {
        .CLASS_DOES_NOT_EXIST => return error.ClassDoesNotExist,
        .INVALID_PARAMETER => unreachable,
        else => |err| return windows.unexpectedError(err),
    }
}

pub extern "user32" fn DestroyWindow(hWnd: HWND) callconv(WINAPI) BOOL;
pub fn destroyWindow(hWnd: HWND) !void {
    if (DestroyWindow(hWnd) == 0) {
        switch (GetLastError()) {
            .INVALID_WINDOW_HANDLE => unreachable,
            .INVALID_PARAMETER => unreachable,
            else => |err| return windows.unexpectedError(err),
        }
    }
}

// TODO (Thomas): Add wrapper function like the other ones
pub extern "user32" fn LoadCursorA(hInstance: HINSTANCE, lpCursorName: LPCSTR) callconv(WINAPI) HCURSOR;

// TODO (Thomas): Add wrapper function like the other ones
pub extern "user32" fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: LPCSTR) callconv(WINAPI) HCURSOR;
