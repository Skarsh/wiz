const std = @import("std");
const windows = std.os.windows;
const kernel32 = windows.kernel32;
const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const input = @import("input.zig");
const Event = input.Event;
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const Window = @import("windows.zig").Window;
const WindowOptions = @import("windows.zig").WindowOptions;

const WINAPI = windows.WINAPI;

const STD_HANDLE = enum(windows.UINT) {
    INPUT_HANDLE = 4294967286,
    OUTPUT_HANDLE = 4294967285,
    ERROR_HANDLE = 4294967284,
};

var global_running = true;

extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(windows.WINAPI) ?windows.HGLRC;
extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
extern "opengl32" fn wglDeleteContext(hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
extern "opengl32" fn wglGetProcAddress(fn_name: windows.LPCSTR) callconv(windows.WINAPI) ?windows.PVOID;
extern "opengl32" fn glGetString(name: u32) callconv(.C) [*:0]u8;

pub export fn WindowProc(
    hWnd: windows.HWND,
    message: windows.UINT,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(windows.WINAPI) windows.LRESULT {
    switch (message) {
        user32.WM_CREATE => {
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

            const our_window_handle_to_device_context = user32.GetDC(hWnd);

            const let_windows_choose_pixel_format = gdi32.ChoosePixelFormat(
                our_window_handle_to_device_context.?,
                &pfd,
            );

            // TODO: handle return value
            _ = gdi32.SetPixelFormat(
                our_window_handle_to_device_context.?,
                let_windows_choose_pixel_format,
                &pfd,
            );

            const our_opengl_rendering_context = wglCreateContext(
                our_window_handle_to_device_context.?,
            );

            // TODO: handle return value
            _ = wglMakeCurrent(
                our_window_handle_to_device_context.?,
                our_opengl_rendering_context.?,
            );

            // TOOD (Thomas): What is this magic number?
            const gl_version = glGetString(7938);
            std.debug.print("OpenGL Version: {s}\n", .{gl_version});

            // TODO: handle return value
            _ = user32.messageBoxA(null, gl_version, "OPENGL VERSION", 0) catch unreachable;

            // TODO: handle return value
            _ = wglDeleteContext(our_opengl_rendering_context.?);
            user32.PostQuitMessage(0);
        },
        else => {
            return user32.DefWindowProcW(hWnd, message, wParam, lParam);
        },
    }
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const win_opts = WindowOptions{
        .x_pos = 0,
        .y_pos = 0,
        .min_x = 0,
        .min_y = 0,
        .max_x = 2560,
        .max_y = 1440,
        .width = 640,
        .height = 480,
    };
    var win = try Window.init(allocator, win_opts);
    win.setWindowSizeCallback(windowSizeCallback);
    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    while (win.running) {
        try Window.processMessages();
        while (win.event_queue.poll(&event)) {
            std.debug.print("Event: {}\n", .{event});
        }
        // Equals 1ms sleep, just so CPU don't blow up
        std.time.sleep(1_000_000);
    }

    std.debug.print("Exiting app\n", .{});
}

pub fn windowSizeCallback(window: *Window, width: i32, height: i32) void {
    window.width = width;
    window.height = height;
    std.debug.print("WindowSizeCallback!\n", .{});
    std.debug.print("window.width: {}, new width: {}, new height: {}\n ", .{ window.width, width, height });
}
