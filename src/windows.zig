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
pub const windowFramebufferSizeCallbackType: *const fn (window: *Window, width: i32, height: i32) void = undefined;
pub const mouseMoveCallbackType: *const fn (window: *Window, x_pos: i32, y_pos: i32) void = undefined;

pub const WindowCallbacks = struct {
    window_pos: ?*const fn (window: *Window, x_pos: i32, y_pos: i32) void = null,
    window_resize: ?*const fn (window: *Window, width: i32, height: i32) void = null,
    window_framebuffer_resize: ?*const fn (window: *Window, width: i32, height: i32) void = null,
    mouse_move: ?*const fn (window: *Window, x_pos: i32, y_pos: i32) void = null,
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
    mouse_x: i32,
    mouse_y: i32,
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
        window.mouse_x = 0;
        window.mouse_y = 0;

        window.callbacks = WindowCallbacks{};

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

    pub fn windowShouldClose(self: *Window, value: bool) void {
        self.running = !value;
    }

    fn getWindowFromHwnd(hwnd: windows.HWND) ?*Window {
        const window_opt: ?*Window = @ptrFromInt(@as(usize, @intCast(user32.GetWindowLongPtrW(hwnd, user32.GWLP_USERDATA))));
        return window_opt;
    }

    inline fn getLParamDims(l_param: isize) [2]i16 {
        const dim: [2]i16 = @bitCast(@as(i32, @intCast(l_param)));
        return dim;
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
                const window_opt = getWindowFromHwnd(hwnd);

                if (window_opt) |win| {
                    std.debug.print("Setting running to false\n", .{});
                    win.windowShouldClose(true);
                }
                _ = user32.destroyWindow(hwnd) catch unreachable;
            },
            // TODO(Thomas): Need to deal with window handle etc here, due to the cases where there's multiple windows.
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
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    const dim = getLParamDims(l_param);
                    if (dim[0] != window.width or dim[1] != window.height) {
                        const width = dim[0];
                        const height = dim[1];

                        if (window.callbacks.window_resize) |cb| {
                            cb(window, width, height);
                        }
                        if (window.callbacks.window_framebuffer_resize) |cb| {
                            cb(window, width, height);
                        }
                    }
                }
            },
            user32.WM_MOVE => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    const pos = getLParamDims(l_param);
                    const x = pos[0];
                    const y = pos[1];
                    if (window.callbacks.window_pos) |cb| {
                        cb(window, x, y);
                    }
                }
            },
            user32.WM_PAINT => {
                // TODO (Thomas): Deal with software renderer here, for now we just returnd default window proc
                // so that message loop finishes.
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
            },

            user32.WM_MOUSEMOVE => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    const pos = getLParamDims(l_param);
                    const x = pos[0];
                    const y = pos[1];
                    if (window.callbacks.mouse_move) |cb| {
                        cb(window, x, y);
                    }
                }
            },
            user32.WM_LBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
            user32.WM_LBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
            user32.WM_RBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttondown
            user32.WM_RBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttonup
            user32.WM_MBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttondown
            user32.WM_MBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttonup
            => {
                //event.* = Event{ .MouseButtonUp = MouseButtonEvent{ .x = 0, .y = 0, .button = MouseButton.left } };

                // Should never be able to reach this until we move
                // the event handling code here from pollEvent();
                assert(false);
            },
            user32.WM_KEYDOWN, user32.WM_KEYUP => {
                //event.* = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };

                // Should never be able to reach this until we move
                // the event handling code here from pollEvent();
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

    pub fn setWindowFramebufferSizeCallback(self: *Window, cb_fun: @TypeOf(windowFramebufferSizeCallbackType)) void {
        self.callbacks.window_framebuffer_resize = cb_fun;
    }

    pub fn setMouseMoveCallback(self: *Window, cb_fun: @TypeOf(mouseMoveCallbackType)) void {
        self.callbacks.mouse_move = cb_fun;
    }

    // TODO (Thomas): What to do with the default callbacks? Are they really necessary?
    fn defaultWindowPosCallback(window: *Window, x_pos: i32, y_pos: i32) void {
        window.x_pos = x_pos;
        window.y_pos = y_pos;
    }

    fn defaultWindowSizeCallback(window: *Window, width: i32, height: i32) void {
        window.width = width;
        window.height = height;
    }

    fn defaultWindowFramebufferSizeCallback(window: *Window, width: i32, height: i32) void {
        _ = window;
        _ = width;
        _ = height;
    }

    fn defaultMoseMoveCallback(window: *Window, x_pos: i32, y_pos: i32) void {
        window.mouse_x = x_pos;
        window.mouse_y = y_pos;
    }
};
