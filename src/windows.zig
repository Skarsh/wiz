const std = @import("std");
const assert = std.debug.assert;
const windows = std.os.windows;

const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const user32 = @import("user32.zig");
const input = @import("input.zig");
const Event = input.Event;
const MouseButton = input.MouseButton;
const MouseMotionEvent = input.MouseMotionEvent;
const MouseButtonEvent = input.MouseButtonEvent;
const KeyEvent = input.KeyEvent;

pub const WindowOptions = struct {
    width: i32,
    height: i32,
};

pub const Window = struct {
    h_instance: windows.HINSTANCE,
    hwnd: windows.HWND,
    lp_class_name: [*:0]const u16,
    width: i32,
    height: i32,
    running: bool,

    pub fn init(options: WindowOptions) !Window {
        var h_instance: windows.HINSTANCE = undefined;
        if (windows.kernel32.GetModuleHandleW(null)) |hinst| {
            h_instance = @ptrCast(hinst);
        } else {
            std.log.err("Module handle is null. Cannot create window.\n", .{});
            unreachable;
        }

        var wc = user32.WNDCLASSEXW{
            .style = 0,
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = h_instance,
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
            h_instance,
            null,
        );

        return Window{
            .h_instance = h_instance,
            .hwnd = hwnd,
            .lp_class_name = wc.lpszClassName,
            .width = options.width,
            .height = options.height,
            .running = true,
        };
    }

    pub fn deinit(self: Window) !void {
        try user32.destroyWindow(self.hwnd);
        try user32.unregisterClassW(self.lp_class_name, self.h_instance);
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

            user32.WM_CREATE => {
                std.debug.print("window create\n", .{});
            },
            user32.WM_SIZE => {
                var window_rect = user32.RECT{ .top = 0, .left = 0, .right = 0, .bottom = 0 };
                user32.getWindowRect(window, &window_rect) catch unreachable;
                std.debug.print("window resize, window rect: {}\n", .{window_rect});
            },
            user32.WM_PAINT => {
                // TODO (Thomas): Deal with software renderer here, for now we just returnd default window proc
                // so that message loop finishes.
                result = user32.defWindowProcW(window, message, w_param, l_param);
            },
            user32.WM_MOUSEMOVE,
            user32.WM_LBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
            user32.WM_LBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
            user32.WM_RBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttondown
            user32.WM_RBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttonup
            user32.WM_MBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttondown
            user32.WM_MBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttonup
            user32.WM_KEYDOWN,
            user32.WM_KEYUP,
            => {
                assert(false);
            },

            else => {
                result = user32.defWindowProcW(window, message, w_param, l_param);
            },
        }

        return result;
    }

    pub fn pollEvent(self: *Window, event: *Event) !bool {
        _ = self;
        var msg = user32.MSG.default();
        const has_msg = try user32.peekMessageW(&msg, null, 0, 0, user32.PM_REMOVE);
        if (has_msg) {
            switch (msg.message) {
                // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mousemove
                user32.WM_MOUSEMOVE => {
                    event.* = Event{ .MouseMotion = MouseMotionEvent{ .x = 0, .y = 0 } };
                },
                user32.WM_LBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
                user32.WM_LBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
                user32.WM_RBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttondown
                user32.WM_RBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttonup
                user32.WM_MBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttondown
                user32.WM_MBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttonup
                => {
                    event.* = Event{ .MouseButtonUp = MouseButtonEvent{ .x = 0, .y = 0, .button = MouseButton.left } };
                },
                user32.WM_KEYDOWN, user32.WM_KEYUP => {
                    event.* = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
                },

                else => {
                    // TODO(Thomas): Deal with return values here
                    _ = user32.translateMessage(&msg);
                    _ = user32.dispatchMessageW(&msg);
                },
            }
        }
        return has_msg;
    }
};
