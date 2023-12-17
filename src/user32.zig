const std = @import("std");
const windows = std.os.windows;

// Types
pub const unexpectedError = windows.unexpectedError;
pub const HWND = windows.HWND;
pub const UINT = windows.UINT;
pub const HDC = windows.HDC;
pub const LONG = windows.LONG;
pub const LONG_PTR = windows.LONG_PTR;
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

// Messages
pub const WNDPROC = *const fn (hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;

pub const MSG = extern struct {
    hWnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};
