const std = @import("std");
const Allocator = std.mem.Allocator;
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
    x_pos: i32,
    y_pos: i32,
    min_x: i32,
    min_y: i32,
    max_x: i32,
    max_y: i32,
    width: i32,
    height: i32,
};

pub const windowPosCallbackType: *const fn (window: *Window, x_pos: i32, y_pos: i32) void = undefined;
pub const windowSizeCallbackType: *const fn (window: *Window, width: i32, height: i32) void = undefined;

pub const WindowCallbacks = struct {
    window_pos: *const fn (window: *Window, x_pos: i32, y_pos: i32) void = undefined,
    window_resize: *const fn (window: *Window, width: i32, height: i32) void = undefined,
};

pub const Window = struct {
    h_instance: windows.HINSTANCE,
    hwnd: ?windows.HWND,
    lp_class_name: [*:0]const u16,
    x_pos: i32,
    y_pos: i32,
    min_x: i32,
    min_y: i32,
    max_x: i32,
    max_y: i32,
    width: i32,
    height: i32,
    running: bool,
    self: *Window = undefined,
    callbacks: WindowCallbacks,

    pub fn init(allocator: Allocator, options: WindowOptions) !*Window {
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

        var window = try allocator.create(Window);

        window.h_instance = h_instance;
        window.hwnd = null;
        window.lp_class_name = wc.lpszClassName;
        window.x_pos = options.x_pos;
        window.y_pos = options.y_pos;
        window.min_x = options.min_x;
        window.min_y = options.min_y;
        window.max_x = options.max_x;
        window.max_y = options.max_y;
        window.width = options.width;
        window.height = options.height;
        window.running = true;

        const callbacks = WindowCallbacks{ .window_resize = defaultWindowSizeCallback };
        window.callbacks = callbacks;

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
            window,
        );

        window.hwnd = hwnd;

        return window;
    }

    pub fn deinit(self: Window) !void {
        try user32.destroyWindow(self.hwnd);
        try user32.unregisterClassW(self.lp_class_name, self.h_instance);
    }

    fn get_window_from_hwnd(hwnd: windows.HWND) ?*Window {
        const window_opt: ?*Window = @ptrFromInt(@as(usize, @intCast(user32.GetWindowLongPtrW(hwnd, user32.GWLP_USERDATA))));
        return window_opt;
    }

    fn windowProc(
        hwnd: windows.HWND,
        message: windows.UINT,
        w_param: windows.WPARAM,
        l_param: windows.LPARAM,
    ) callconv(windows.WINAPI) windows.LRESULT {
        var result: windows.LRESULT = 0;

        switch (message) {
            user32.WM_CLOSE => {
                std.debug.print("closing\n", .{});
                const window_opt = get_window_from_hwnd(hwnd);

                // TODO (Thomas) Is this the right ordering, and is this also the right place to set the running variable?
                if (window_opt) |win| {
                    std.debug.print("Setting running to false\n", .{});
                    win.running = false;
                }
                _ = user32.destroyWindow(hwnd) catch unreachable;
            },
            user32.WM_DESTROY => {
                std.debug.print("destroying window\n", .{});
            },

            user32.WM_CREATE => {
                std.debug.print("window create\n", .{});
                const create_info_opt: ?*user32.CREATESTRUCTW = @ptrFromInt(@as(usize, @intCast(l_param)));
                if (create_info_opt) |create_info| {
                    std.debug.print("create_info: {}\n", .{create_info});
                    const window_ptr: *const Window = @ptrCast(@alignCast(create_info.lpCreateParams));
                    std.debug.print("window.width: {}\n", .{window_ptr.width});
                    _ = user32.SetWindowLongPtrW(hwnd, user32.GWLP_USERDATA, @intCast(@intFromPtr(create_info.lpCreateParams)));
                }
            },
            user32.WM_SIZE => {
                // NOTE (Thomas): This only deals with the size of the window, should also set the rect of what is actually drawable.
                const window_opt = get_window_from_hwnd(hwnd);
                if (window_opt) |win| {
                    const dim: [2]u16 = @bitCast(@as(u32, @intCast(l_param)));
                    if (dim[0] != win.width or dim[1] != win.height) {
                        const width = dim[0];
                        const height = dim[1];

                        win.callbacks.window_resize(win, width, height);
                    }
                }
            },
            user32.WM_MOVE => {
                const window_opt = get_window_from_hwnd(hwnd);
                if (window_opt) |window| {
                    _ = window;
                    // TODO (Thomas): if this is within min and max values.
                    // const xPos = @as(i16, @intCast(l_param & 0xFFFF)); // Get lower 16 bits for x position
                    // const yPos = @as(i16, @intCast((l_param >> 16) & 0xFFFF)); // Get higher 16 bits for y position
                    //if ((xPos >= window.min_x and xPos < window.max_x) and (yPos >= window.min_y and yPos < window.max_y)) {
                    //    window.x_pos = xPos;
                    //    window.y_pos = yPos;
                    //    std.debug.print("window x_pos: {}, y_pos: {}\n", .{ window.x_pos, window.y_pos });
                    // }
                }
            },
            user32.WM_PAINT => {
                // TODO (Thomas): Deal with software renderer here, for now we just returnd default window proc
                // so that message loop finishes.
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
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
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
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

    pub fn setWindowPosCallback(self: *Window, cb_fun: @TypeOf(windowPosCallbackType)) void {
        self.callbacks.window_pos = cb_fun;
    }

    pub fn setWindowSizeCallback(self: *Window, cb_fun: @TypeOf(windowSizeCallbackType)) void {
        self.callbacks.window_resize = cb_fun;
    }

    // TODO (Thomas): Probably setting
    pub fn defaultWindowPosCallback(window: *Window, x_pos: i32, y_pos: i32) void {
        _ = window;
        _ = x_pos;
        _ = y_pos;
    }

    pub fn defaultWindowSizeCallback(window: *Window, width: i32, height: i32) void {
        window.width = width;
        window.height = height;
    }
};
