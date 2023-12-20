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
        const hInstance: windows.HINSTANCE = @ptrCast(windows.kernel32.GetModuleHandleW(null));

        var wc = user32.WNDCLASSEXW{
            .style = 0,
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = hInstance,
            .hIcon = null,
            .hCursor = null,
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = u8to16le("Test Window"),
            .hIconSm = null,
        };

        _ = try user32.registerClassExW(&wc);

        const hwnd = try user32.createWindowExW(
            0,
            wc.lpszClassName,
            u8to16le("Wiz"),
            user32.WS_OVERLAPPEDWINDOW | user32.WS_VISIBLE,
            0,
            0,
            options.width,
            options.height,
            null,
            null,
            hInstance,
            null,
        );

        return Window{ .hwnd = hwnd, .width = options.width, .height = options.height };
    }

    fn windowProc(
        window: windows.HWND,
        message: windows.UINT,
        w_param: windows.WPARAM,
        l_param: windows.LPARAM,
    ) callconv(windows.WINAPI) windows.LRESULT {
        var result: windows.LRESULT = 0;

        switch (message) {
            user32.WM_CLOSE => {
                std.debug.print("closing\n", .{});
                _ = user32.destroyWindow(window) catch unreachable;
            },
            user32.WM_DESTROY => {
                std.debug.print("destroying window\n", .{});
            },
            else => {
                result = user32.defWindowProcW(window, message, w_param, l_param);
            },
        }

        return result;
    }
};
