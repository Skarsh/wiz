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

const tracy = @import("tracy.zig");

pub const default_window_width: i32 = 640;
pub const default_window_height: i32 = 480;

pub const WindowFormat = enum {
    windowed,
    fullscreen,
    borderless,
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
    hdc: ?windows.HDC,
    lp_class_name: [*:0]const u16,
    x_pos: i32,
    y_pos: i32,
    width: i32,
    height: i32,
    running: bool,
    mouse_x: i16,
    mouse_y: i16,
    wp_prev: user32.WINDOWPLACEMENT,
    capture_cursor: bool,
    is_vsync: bool,
    is_fullscreen: bool,
    self: *Window = undefined,
    callbacks: WindowCallbacks,
    event_queue: EventQueue,

    pub fn init(allocator: Allocator, width: i32, height: i32, format: WindowFormat, comptime name: []const u8) !*Window {
        var h_instance: windows.HINSTANCE = undefined;
        if (windows.kernel32.GetModuleHandleW(null)) |hinst| {
            h_instance = @ptrCast(hinst);
        } else {
            std.log.err("Module handle is null. Cannot create window.\n", .{});
            unreachable;
        }

        // NOTE(Thomas): This mimics what the MAKEINTRESOURCE win32 macro does.
        // TODO(Thomas): This only works for the 2-byte aligned IDC/IDI constants.
        const arrow: [*:0]const u16 = @ptrFromInt(user32.IDC_ARROW);

        // NOTE(Thomas) Use null for the hInstance here, this makes windows figure out which hInstance is the correct one.
        // When passing our own this becomes wrong.
        const cursor = try user32.loadCursorW(null, arrow);

        var wc = user32.WNDCLASSEXW{
            .style = 0,
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = h_instance,
            .hIcon = null,
            .hCursor = cursor,
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
        window.hdc = null;
        window.lp_class_name = wc.lpszClassName;
        window.width = width;
        window.height = height;

        window.running = true;
        window.x_pos = 0;
        window.y_pos = 0;
        window.mouse_x = 0;
        window.mouse_y = 0;
        window.wp_prev = user32.WINDOWPLACEMENT{
            .flags = 0,
            .showCmd = 0,
            .ptMinPosition = user32.POINT{ .x = 0, .y = 0 },
            .ptMaxPosition = user32.POINT{ .x = 0, .y = 0 },
            .rcNormalPosition = user32.RECT{ .top = 0, .left = 0, .right = 0, .bottom = 0 },
            .rcDevice = user32.RECT{ .top = 0, .left = 0, .right = 0, .bottom = 0 },
        };
        window.capture_cursor = false;
        window.is_vsync = false;
        window.is_fullscreen = false;

        window.callbacks = WindowCallbacks{};
        window.callbacks.window_resize = defaultWindowSizeCallback;

        // TODO (Thomas): Make event queue size configureable?
        const event_queue_size: usize = 1000;
        window.event_queue = try EventQueue.init(allocator, event_queue_size);

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

        const dwStyle = try user32.getWindowLongW(window.hwnd.?, user32.GWL_STYLE);
        switch (format) {
            .windowed => {
                _ = try user32.setWindowLongPtrW(window.hwnd.?, user32.GWL_STYLE, dwStyle | @as(i32, user32.WS_OVERLAPPEDWINDOW));

                // TODO (Thomas): This panics here, don't know why. Doesn't seem to be necessary on startup?
                //try user32.setWindowPlacement(window.hwnd, &window.wp_prev);

                try user32.setWindowPos(
                    window.hwnd.?,
                    null,
                    0,
                    0,
                    0,
                    0,
                    user32.SWP_NOMOVE | user32.SWP_NOSIZE | user32.SWP_NOZORDER |
                        user32.SWP_NOOWNERZORDER | user32.SWP_FRAMECHANGED,
                );
            },
            .fullscreen => {
                // https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
                if ((dwStyle & @as(i32, user32.WS_OVERLAPPEDWINDOW)) != 0) {
                    if (user32.GetWindowPlacement(window.hwnd.?, &window.wp_prev) != 0 and user32.GetMonitorInfoW(monitor_handle, &monitor_info) != 0) {
                        try user32.getMonitorInfoW(monitor_handle, &monitor_info);

                        const min_x = monitor_info.rcMonitor.left;
                        const min_y = monitor_info.rcMonitor.top;
                        const max_x = monitor_info.rcMonitor.right;
                        const max_y = monitor_info.rcMonitor.bottom;

                        _ = try user32.setWindowLongPtrW(window.hwnd.?, user32.GWL_STYLE, dwStyle & ~@as(i32, user32.WS_OVERLAPPEDWINDOW));

                        try user32.setWindowPos(
                            window.hwnd.?,
                            null,
                            min_x,
                            min_y,
                            max_x - min_x,
                            max_y - min_y,
                            user32.SWP_NOOWNERZORDER | user32.SWP_FRAMECHANGED,
                        );

                        window.width = max_x - min_x;
                        window.height = max_y - min_y;
                    }
                    window.is_fullscreen = true;
                }
            },
            .borderless => {},
        }

        // NOTE(Thomas): Not really sure why this is needed here, it's already set for the windowclass, but that does not seem to help
        // TODO(Thomas): use wrappers here instead
        _ = user32.SetCursor(cursor);

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

        const hdc = try user32.getDC(self.hwnd);
        self.hdc = hdc;

        const format = try gdi32.choosePixelFormat(hdc, &pfd);

        // TODO(Thomas): What about the nBytes field here, using @sizeOf the type.
        // TODO(Thomas): Deal with return value here, look at https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-describepixelformat
        _ = try gdi32.describePixelFormat(hdc, format, @sizeOf(gdi32.PIXELFORMATDESCRIPTOR), &pfd);

        try gdi32.setPixelFormat(hdc, format, &pfd);

        const rendering_context = opengl32.wglCreateContext(
            hdc,
        );

        // TODO(Thomas): This will make it crash, are there a more graceful way to deal with this?
        if (rendering_context) |rc| {
            self.hglrc = rc;

            const result = opengl32.wglMakeCurrent(
                hdc,
                rc,
            );

            assert(result != 0);
        } else {
            assert(false);
        }
    }

    // TODO(Thomas): Think about splitting out the loading of OpenGL functions to its own function here
    pub fn makeModernOpenGLContext(self: *Window) !void {
        // NOTE(Thomas):
        // This one is a bit more involved than the plain makeOpenGLContext function
        // Modern OpenGLContext creation requires loading OpenGL extension functions, which
        // itself requires to have a OpenGL context created. Due to this the current way to do it
        // is the following:
        // 1. Make legacy OpenGL context
        // 2. LoadOpenGLFunctions
        // 3. Make modern OpenGL context
        try self.makeOpenGLContext();
        opengl32.loadOpenGLFunctions();

        {

            // Set pixel format for OpenGl context
            const attrib = [_]i32{
                opengl32.WGL_DRAW_TO_WINDOW_ARB, opengl32.GL_TRUE,
                opengl32.WGL_SUPPORT_OPENGL_ARB, opengl32.GL_TRUE,
                opengl32.WGL_DOUBLE_BUFFER_ARB,  opengl32.GL_TRUE,
                opengl32.WGL_PIXEL_TYPE_ARB,     opengl32.WGL_TYPE_RGBA_ARB,
                opengl32.WGL_COLOR_BITS_ARB,     32,
                opengl32.WGL_DEPTH_BITS_ARB,     24,
                opengl32.WGL_STENCIL_BITS_ARB,   8,
                // uncomment for sRGB framebuffer, from WGL_ARB_framebuffer_sRGB extension
                // https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_framebuffer_sRGB.txt
                //WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB, GL_TRUE,

                // uncomment for multisampeld framebuffer, from WGL_ARB_multisample extension
                // https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_multisample.txt
                //WGL_SAMPLE_BUFFERS_ARB, 1,
                //WGL_SAMPLES_ARB,        4, // 4x MSAA

                0,
            };

            var format: i32 = 0;
            var num_formats: u32 = 0;

            if (self.hdc) |hdc| {
                const result = opengl32.wglChoosePixelFormatARB(hdc, &attrib, null, 1, &format, &num_formats);
                std.debug.assert(result == 1 and num_formats != 0);

                const pfd = gdi32.PIXELFORMATDESCRIPTOR.default();
                _ = try gdi32.describePixelFormat(hdc, format, pfd.nSize, &pfd);

                _ = try gdi32.setPixelFormat(hdc, format, &pfd);
            }
        }

        // crate modern OpenGL context
        {
            var attrib = [_]i32{
                opengl32.WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
                opengl32.WGL_CONTEXT_MINOR_VERSION_ARB, 5,
                opengl32.WGL_CONTEXT_PROFILE_MASK_ARB,  opengl32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
                // TODO (Thomas): Would like to do something similar to this
                //#ifndef NDEBUG
                //            // ask for debug context for non "Release" builds
                //            // this is so we can enable debug callback
                //            WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_DEBUG_BIT_ARB,
                //#endif
                0,
            };

            if (self.hdc) |hdc| {
                const rc_opt = opengl32.wglCreateContextAttribsARB(hdc, null, &attrib);
                if (rc_opt) |rc| {
                    const ok = opengl32.wglMakeCurrent(hdc, rc);
                    std.debug.assert(ok == 1);
                }
            }
        }
    }

    pub fn deinit(self: Window) !void {
        try user32.destroyWindow(self.hwnd);
        try user32.unregisterClassW(self.lp_class_name, self.h_instance);

        // TODO: handle return value
        if (self.hglrc) |hglrc| {
            _ = opengl32.wglDeleteContext(hglrc);
        }

        if (self.hdc) |hdc| {
            _ = user32.releaseDC(self.hwnd, hdc);
        }
    }

    pub fn swapBuffers(self: *Window) !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        if (self.hdc) |hdc| {
            _ = gdi32.SwapBuffers(hdc);
        }
    }

    pub fn windowShouldClose(self: *Window, value: bool) void {
        self.running = !value;
    }

    fn getWindowFromHwnd(hwnd: windows.HWND) ?*Window {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        const window_opt: ?*Window = @ptrFromInt(@as(usize, @intCast(user32.GetWindowLongPtrW(hwnd, user32.GWLP_USERDATA))));
        return window_opt;
    }

    inline fn getLParamDims(l_param: isize) [2]i16 {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        const x = @as(i16, @truncate(l_param & 0xFFFF));
        const y = @as(i16, @truncate((l_param >> 16) & 0xFFFF));
        return [2]i16{ x, y };
    }

    fn windowProc(
        hwnd: windows.HWND,
        message: windows.UINT,
        w_param: windows.WPARAM,
        l_param: windows.LPARAM,
    ) callconv(windows.WINAPI) windows.LRESULT {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        var result: windows.LRESULT = 0;

        switch (message) {
            user32.WM_CLOSE => {
                const window_opt = getWindowFromHwnd(hwnd);

                if (window_opt) |win| {
                    win.windowShouldClose(true);
                }
                //TODO (Thomas): Better error handling here.
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
                const create_info_opt: ?*user32.CREATESTRUCTW = @ptrFromInt(@as(usize, @intCast(l_param)));
                if (create_info_opt) |create_info| {
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
                    window.x_pos = x;
                    window.y_pos = y;
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
                    // NOTE: x and y here are in "window" space, not in "screen" space
                    const x = pos[0];
                    const y = pos[1];

                    // Cursor position in "client" space
                    var cursor_client_point = user32.POINT{ .x = x, .y = y };

                    // TODO (Thomas): Use wrapper here instead (when its made)
                    user32.screenToClient(hwnd, &cursor_client_point) catch unreachable;

                    if (window.callbacks.mouse_move) |cb| {
                        cb(window, x, y);
                    } else {
                        var x_rel: i16 = 0;
                        var y_rel: i16 = 0;
                        if (window.capture_cursor) {

                            // Center in "window" space
                            const window_center_x: i32 = window.x_pos + @divFloor(window.width, 2);
                            const window_center_y: i32 = window.y_pos + @divFloor(window.height, 2);

                            var client_center_point = user32.POINT{ .x = window_center_x, .y = window_center_y };

                            user32.screenToClient(hwnd, &client_center_point) catch unreachable;

                            // x and y delta in "client" space
                            x_rel = @as(i16, @intCast(cursor_client_point.x)) - @as(i16, @intCast(client_center_point.x));
                            y_rel = @as(i16, @intCast(cursor_client_point.y)) - @as(i16, @intCast(client_center_point.y));

                            // This is the center of the window in "screen" space.
                            var screen_window_center_point = user32.POINT{ .x = client_center_point.x, .y = client_center_point.y };
                            user32.clientToScreen(hwnd, &screen_window_center_point) catch unreachable;

                            _ = user32.setCursorPos(screen_window_center_point.x, screen_window_center_point.y) catch unreachable;
                        } else {
                            // x and y delta in "window" space
                            x_rel = window.mouse_x - x;
                            y_rel = window.mouse_y - y;
                        }

                        // TODO(Thomas): Think about "window" vs "client space" here
                        // x and y here is always given in "window" space as it is now.
                        const event: Event = Event{ .MouseMotion = MouseMotionEvent{ .x = x, .y = y, .x_rel = x_rel, .y_rel = y_rel } };
                        window.event_queue.enqueue(event);
                    }
                }
            },
            // TODO (Thomas): Add mouse scroll etc.
            user32.WM_LBUTTONDOWN,
            user32.WM_LBUTTONUP,
            user32.WM_RBUTTONDOWN,
            user32.WM_RBUTTONUP,
            user32.WM_MBUTTONDOWN,
            user32.WM_MBUTTONUP,
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
            // TODO (Thomas): What about WM_SYSKEYDOWN/WM_SYSKEYUP
            user32.WM_KEYDOWN, user32.WM_KEYUP => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    const key_event = KeyEvent{
                        .scancode = @as(u8, @truncate(@as(u32, @intCast((l_param >> 16))))),
                    };
                    const event = if (message == user32.WM_KEYDOWN) Event{ .KeyDown = key_event } else Event{ .KeyUp = key_event };
                    window.event_queue.enqueue(event);
                }
            },
            user32.WM_SETCURSOR => {
                const window_opt = getWindowFromHwnd(hwnd);
                if (window_opt) |window| {
                    if (window.capture_cursor) {
                        // NOTE(Thomas): This is needed to ensure that mouse stays hidden
                        // when re-entering and so on.
                        // TODO(Thomas): Use wrapper setCursor instead
                        _ = user32.SetCursor(null);
                    }
                }
            },
            // TODO(Thomas): Deal with this for cursor capture and so no, currently we don't do anything here at all.
            // This will probably be a problem in a drag an drop scenario.
            // https://www.codeproject.com/Tips/127813/Using-SetCapture-and-ReleaseCapture-correctly-usua
            user32.WM_CAPTURECHANGED => {
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
            },

            else => {
                result = user32.defWindowProcW(hwnd, message, w_param, l_param);
            },
        }

        return result;
    }

    // https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
    pub fn toggleFullscreen(self: *Window) !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        const dwStyle = try user32.getWindowLongW(self.hwnd.?, user32.GWL_STYLE);

        // Toggling to fullscreen
        if ((dwStyle & @as(i32, user32.WS_OVERLAPPEDWINDOW)) != 0) {
            const monitor_handle = try user32.monitorFromWindow(self.hwnd, 0);
            var monitor_info = user32.MONITORINFO{
                .rcWork = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
                .rcMonitor = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
                .dwFlags = 0,
            };

            // TODO(Thomas): Use wrapper calls here instead, this seems to be the same as the wrapper calls passing without errors
            if (user32.GetWindowPlacement(self.hwnd.?, &self.wp_prev) != 0 and user32.GetMonitorInfoW(monitor_handle, &monitor_info) != 0) {
                try user32.getMonitorInfoW(monitor_handle, &monitor_info);

                const min_x = monitor_info.rcMonitor.left;
                const min_y = monitor_info.rcMonitor.top;
                const max_x = monitor_info.rcMonitor.right;
                const max_y = monitor_info.rcMonitor.bottom;

                _ = try user32.setWindowLongPtrW(self.hwnd.?, user32.GWL_STYLE, dwStyle & ~@as(i32, user32.WS_OVERLAPPEDWINDOW));

                try user32.setWindowPos(
                    self.hwnd.?,
                    null,
                    min_x,
                    min_y,
                    max_x - min_x,
                    max_y - min_y,
                    user32.SWP_NOOWNERZORDER | user32.SWP_FRAMECHANGED,
                );

                self.width = max_x - min_x;
                self.height = max_y - min_y;
                if (self.capture_cursor) {
                    var client_rect = user32.RECT{ .top = 0, .right = 0, .bottom = 0, .left = 0 };
                    try user32.getClientRect(self.hwnd, &client_rect);
                    try user32.clipCursor(&client_rect);

                    try self.setCursorPos(@divFloor(self.width, 2), @divFloor(self.height, 2));
                }
            }
            self.is_fullscreen = true;
        } else {
            // Toggling off fullscreen, going to windowed.
            _ = try user32.setWindowLongPtrW(self.hwnd.?, user32.GWL_STYLE, dwStyle | @as(i32, user32.WS_OVERLAPPEDWINDOW));
            try user32.setWindowPlacement(self.hwnd, &self.wp_prev);
            try user32.setWindowPos(
                self.hwnd.?,
                null,
                0,
                0,
                0,
                0,
                user32.SWP_NOMOVE | user32.SWP_NOSIZE | user32.SWP_NOZORDER |
                    user32.SWP_NOOWNERZORDER | user32.SWP_FRAMECHANGED,
            );

            if (self.capture_cursor) {
                const window_center_x: i32 = self.x_pos + @divFloor(self.width, 2);
                const window_center_y: i32 = self.y_pos + @divFloor(self.height, 2);
                var client_center_point = user32.POINT{ .x = window_center_x, .y = window_center_y };

                try user32.clientToScreen(self.hwnd, &client_center_point);

                var client_rect = user32.RECT{ .top = 0, .right = 0, .bottom = 0, .left = 0 };
                user32.getClientRect(self.hwnd, &client_rect) catch unreachable;

                // TODO(Thomas): Do this in a bit more obvious way than @ptrCast to get the
                // two first fields?
                try user32.clientToScreen(self.hwnd, @ptrCast(&client_rect.left));
                try user32.clientToScreen(self.hwnd, @ptrCast(&client_rect.right));
                try user32.clipCursor(&client_rect);

                try self.setCursorPos(client_center_point.x, client_center_point.y);
            }

            self.is_fullscreen = false;
        }
    }

    pub fn setCursorPos(self: *Window, x: i32, y: i32) !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        _ = self;
        try user32.setCursorPos(x, y);
    }

    pub fn setCaptureCursor(self: *Window, value: bool) !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        self.capture_cursor = value;
        if (value) {
            // TODO(Thomas): Use wrapper setCursor
            _ = user32.SetCursor(null);
            // TODO(Thomas): Use wrapper
            _ = user32.SetCapture(self.hwnd);
            var client_rect = user32.RECT{ .top = 0, .right = 0, .bottom = 0, .left = 0 };
            user32.getClientRect(self.hwnd, &client_rect) catch unreachable;
            // TODO(Thomas): Do this in a bit more obvious way than @ptrCast to get the
            // two first fields?
            try user32.clientToScreen(self.hwnd, @ptrCast(&client_rect.left));
            try user32.clientToScreen(self.hwnd, @ptrCast(&client_rect.right));
            user32.clipCursor(&client_rect) catch unreachable;
        } else {
            // TODO(Thomas): use stored cursor icon/type/styling instead of hardcoded as IDC_ARROW
            const arrow: [*:0]const u16 = @ptrFromInt(user32.IDC_ARROW);
            const cursor = try user32.loadCursorW(null, arrow);
            // TODO(Thomas): use wrappers here instead
            _ = user32.SetCursor(cursor);
            _ = user32.ReleaseCapture();
            user32.clipCursor(null) catch unreachable;
        }
    }

    // TODO(Thomas): This function needs more error checking, also
    // there's still something that does not make complete sense when setting this.
    // The value reported back from the function does not seem to change, but the frame durations
    // matches with what VSync being set or not.
    pub fn setVSync(self: *Window, value: bool) !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        // TODO(Thomas): Check if we have the wgl_ext_swap_control extension
        // TODO(Thomas): Probably not use ARB but ETX here??
        //const extensions = opengl32.wglGetExtensionsStringARB(win.hdc);

        const swap_interval = opengl32.wglGetSwapIntervalEXT();
        if (swap_interval == 1 and value) {
            std.log.warn("VSync already set to 1\n", .{});
            return;
        } else if (swap_interval == 0 and !value) {
            std.log.warn("VSync already set to 0\n", .{});
            return;
        }

        if (value) {
            const result = opengl32.wglSwapIntervalEXT(1);
            if (result == opengl32.GL_FALSE) {
                // TODO(Thomas): Do deeper error checking here to get more detailed error message.
                return error.UnableToSetVsync;
            }
        } else {
            const result = opengl32.wglSwapIntervalEXT(0);
            if (result == opengl32.GL_FALSE) {
                // TODO(Thomas): Do deeper error checking here to get more detailed error message.
                return error.UnableToSetVsync;
            }
        }
        self.is_vsync = value;
    }

    pub fn processMessages() !void {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
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
        _ = window;
        _ = x_pos;
        _ = y_pos;
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
