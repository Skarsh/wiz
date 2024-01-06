const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const windows = std.os.windows;

const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const opengl32 = @import("opengl32.zig");
const input = @import("input.zig");
const Event = input.Event;
const EventQueue = input.EventQueue;
const MouseButton = input.MouseButton;
const MouseMotionEvent = input.MouseMotionEvent;
const MouseButtonEvent = input.MouseButtonEvent;
const KeyEvent = input.KeyEvent;

pub const WindowFormat = enum {
    windowed,
    fullscreen,
    borderless,
};

pub const WindowOptions = struct {
    x_pos: i32,
    y_pos: i32,
    width: i32,
    height: i32,
};

pub const windowPosCallbackType: *const fn (window: *Window, x_pos: i32, y_pos: i32) void = undefined;
pub const windowSizeCallbackType: *const fn (window: *Window, width: i32, height: i32) void = undefined;
pub const windowFramebufferSizeCallbackType: *const fn (window: *Window, width: i32, height: i32) void = undefined;
pub const mouseMoveCallbackType: *const fn (window: *Window, x_pos: i32, y_pos: i32) void = undefined;
pub const mouseButtonCallbackType: *const fn (window: *Window, x_pos: i32, y_pos: i32, button: MouseButton) void = undefined;

pub const WindowCallbacks = struct {
    window_pos: ?*const fn (window: *Window, x_pos: i32, y_pos: i32) void = null,
    window_resize: ?*const fn (window: *Window, width: i32, height: i32) void = null,
    window_framebuffer_resize: ?*const fn (window: *Window, width: i32, height: i32) void = null,
    mouse_move: ?*const fn (window: *Window, x_pos: i32, y_pos: i32) void = null,
    mouse_button: ?*const fn (window: *Window, x_pos: i32, y_pos: i32, button: MouseButton) void = null,
};

pub const Window = struct {
    allocator: Allocator,
    h_instance: windows.HINSTANCE,
    hwnd: ?windows.HWND,
    hglrc: ?windows.HGLRC,
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
    event_queue: EventQueue,

    pub fn init(allocator: Allocator, options: WindowOptions, format: WindowFormat, comptime name: []const u8) !*Window {
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
            // TODO (Thomas): Add some postfix for the classname?
            .lpszClassName = u8to16le(name),
            .hIconSm = null,
        };

        _ = try user32.registerClassExW(&wc);

        var window = try allocator.create(Window);
        window.allocator = allocator;
        window.h_instance = h_instance;
        window.hglrc = null;
        window.lp_class_name = wc.lpszClassName;
        window.x_pos = options.x_pos;
        window.y_pos = options.y_pos;
        window.width = options.width;
        window.height = options.height;
        window.running = true;
        window.mouse_x = 0;
        window.mouse_y = 0;

        window.callbacks = WindowCallbacks{};

        // TODO (Thomas): Make event queue size configureable?
        window.event_queue = try EventQueue.init(allocator, 1000);

        const hwnd = try user32.createWindowExW(
            0,
            wc.lpszClassName,
            u8to16le(name),
            user32.WS_OVERLAPPEDWINDOW | user32.WS_VISIBLE,
            0,
            0,
            window.width,
            window.height,
            null,
            null,
            h_instance,
            window,
        );

        window.hwnd = hwnd;

        const monitor_handle = try user32.monitorFromWindow(hwnd, 0);
        var monitor_info = user32.MONITORINFO{
            .rcWork = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
            .rcMonitor = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
            .dwFlags = 0,
        };
        try user32.getMonitorInfoW(monitor_handle, &monitor_info);

        window.min_x = monitor_info.rcMonitor.left;
        window.min_y = monitor_info.rcMonitor.top;
        window.max_x = monitor_info.rcMonitor.right;
        window.max_y = monitor_info.rcMonitor.bottom;

        switch (format) {
            .windowed => {},
            .fullscreen => {

                // TODO(Thomas): This sets it to fullscreen, but "forgets" everything else, e.g.
                // windows is not cleared to pink from OpenGL etc.
                _ = try user32.setWindowLongPtrW(hwnd, user32.GWL_STYLE, user32.WS_POPUP);

                try user32.setWindowPos(
                    hwnd,
                    null,
                    window.min_x,
                    window.min_y,
                    window.max_x - window.min_x,
                    window.max_y - window.min_y,
                    user32.SWP_NOZORDER | user32.SWP_NOACTIVATE | user32.SWP_FRAMECHANGED,
                );

                window.width = window.max_x - window.min_x;
                window.height = window.max_y - window.min_y;
            },
            .borderless => {},
        }

        return window;
    }

    pub fn makeOpenGLContext(self: *Window) !void {
        var pfd = gdi32.PIXELFORMATDESCRIPTOR{
            .nSize = @sizeOf(gdi32.PIXELFORMATDESCRIPTOR),
            .nVersion = 1,
            .dwFlags = gdi32.PFD_DRAW_TO_WINDOW | gdi32.PFD_SUPPORT_OPENGL | gdi32.PFD_DOUBLEBUFFER,
            .iPixelType = gdi32.PFD_TYPE_RGBA,
            .cColorBits = 32,
            .cRedBits = 0,
            .cRedShift = 0,
            .cGreenBits = 0,
            .cGreenShift = 0,
            .cBlueBits = 0,
            .cBlueShift = 0,
            .cAlphaBits = 0,
            .cAlphaShift = 0,
            .cAccumBits = 0,
            .cAccumRedBits = 0,
            .cAccumGreenBits = 0,
            .cAccumBlueBits = 0,
            .cAccumAlphaBits = 0,
            .cDepthBits = 24, // Number of bits for the depthbuffer
            .cStencilBits = 8, // Number of bits for the stencilbuffer
            .cAuxBuffers = 0, // Number of Aux buffers in the framebuffer
            .iLayerType = 0, // NOTE: This is PFD_MAIN_PLANE in the Khronos example https://www.khronos.org/opengl/wiki/Creating_an_OpenGL_Context_(WGL), but this is suppposed to not be needed anymore?
            .bReserved = 0,
            .dwLayerMask = 0,
            .dwVisibleMask = 0,
            .dwDamageMask = 0,
        };

        // TODO (Thomas): Deal with optionals
        const hdc = try user32.getDC(self.hwnd);
        defer _ = user32.releaseDC(self.hwnd, hdc);

        const let_windows_choose_pixel_format = gdi32.ChoosePixelFormat(
            hdc,
            &pfd,
        );

        // TODO: handle return value
        _ = gdi32.SetPixelFormat(
            hdc,
            let_windows_choose_pixel_format,
            &pfd,
        );

        const our_opengl_rendering_context = opengl32.wglCreateContext(
            hdc,
        );

        self.hglrc = our_opengl_rendering_context;

        // TODO: handle return value
        _ = opengl32.wglMakeCurrent(
            hdc,
            our_opengl_rendering_context.?,
        );
    }

    pub fn deinit(self: Window) !void {
        try user32.destroyWindow(self.hwnd);
        try user32.unregisterClassW(self.lp_class_name, self.h_instance);

        // TODO: handle return value
        if (self.hglrc) |hglrc| {
            _ = opengl32.wglDeleteContext(hglrc);
        }
    }

    pub fn swapBuffers(self: *Window) !void {
        // TODO (Thomas): What to do with boolean value here? Return it to the caller?
        if (self.hwnd) |hwnd| {
            const hdc = try user32.getDC(hwnd);
            _ = gdi32.SwapBuffers(hdc);
        }
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
                const window_opt = getWindowFromHwnd(hwnd);

                if (window_opt) |win| {
                    win.windowShouldClose(true);
                }
                _ = user32.destroyWindow(hwnd) catch unreachable;
            },
            // TODO(Thomas): Need to deal with window handle etc here, due to the cases where there's multiple windows.
            // In general do the different types of cleanups necessary here
            user32.WM_DESTROY => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    window.hwnd = null;
                }
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
                    } else {
                        const event: Event = Event{ .MouseMotion = MouseMotionEvent{ .x = x, .y = y } };
                        window.event_queue.enqueue(event);
                    }
                }
            },
            // TODO (Thomas): Add mouse scroll etc.
            user32.WM_LBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
            user32.WM_LBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
            user32.WM_RBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttondown
            user32.WM_RBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-rbuttonup
            user32.WM_MBUTTONDOWN, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttondown
            user32.WM_MBUTTONUP, // https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-mbuttonup
            => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    const pos = getLParamDims(l_param);
                    const x = pos[0];
                    const y = pos[1];

                    if (window.callbacks.mouse_button) |cb| {
                        // TODO (Thomas): Need to know wheter it was button up or down in callback
                        cb(window, x, y, MouseButton.middle);
                    } else {
                        const button_event = MouseButtonEvent{
                            .x = x,
                            .y = y,
                            .button = switch (message) {
                                user32.WM_LBUTTONDOWN, user32.WM_LBUTTONUP => .left,
                                user32.WM_MBUTTONDOWN, user32.WM_MBUTTONUP => .middle,
                                user32.WM_RBUTTONDOWN, user32.WM_RBUTTONUP => .right,
                                else => unreachable,
                            },
                        };
                        const event: Event =
                            if ((message == user32.WM_LBUTTONDOWN) or (message == user32.WM_MBUTTONDOWN) or (message == user32.WM_RBUTTONDOWN))
                            Event{ .MouseButtonDown = button_event }
                        else
                            Event{ .MouseButtonUp = button_event };

                        window.event_queue.enqueue(event);
                    }
                }
            },
            user32.WM_KEYDOWN, user32.WM_KEYUP => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    // TODO (Thomas): Is this correct????
                    const key_event = KeyEvent{
                        .scancode = @as(u8, @truncate(@as(u32, @intCast((l_param >> 16))))),
                    };
                    const event = if (message == user32.WM_KEYDOWN) Event{ .KeyDown = key_event } else Event{ .KeyUp = key_event };
                    window.event_queue.enqueue(event);
                }
            },

            else => {
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
            },
        }

        return result;
    }

    pub fn processMessages() !void {
        var msg = user32.MSG.default();
        while (try user32.peekMessageW(&msg, null, 0, 0, user32.PM_REMOVE)) {
            switch (msg.message) {
                else => {
                    _ = user32.translateMessage(&msg);
                    _ = user32.dispatchMessageW(&msg);
                },
            }
        }
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
