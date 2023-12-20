const std = @import("std");
const windows = std.os.windows;
const user32 = @import("user32.zig");

const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

pub const WindowOptions = struct {
    width: i32,
    height: i32,
};

pub const Window = struct {
    hwnd: ?windows.HWND,
    width: i32,
    height: i32,

    pub fn init(options: WindowOptions) !Window {
        return Window{ .hwnd = null, .width = options.width, .height = options.height };
    }

    fn windowProc(hwnd: windows.HWND, uMsg: c_uint, wParam: usize, lParam: isize) callconv(windows.WINAPI) windows.LRESULT {
        _ = hwnd;
        _ = uMsg;
        _ = wParam;
        _ = lParam;
        return 0;
    }
};
