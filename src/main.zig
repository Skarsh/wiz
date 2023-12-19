const std = @import("std");
const windows = std.os.windows;
const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const WINAPI = windows.WINAPI;

extern "user32" fn MessageBoxA(
    h_wnd: ?windows.HANDLE,
    lp_text: ?windows.LPCSTR,
    lp_caption: ?windows.LPCSTR,
    u_type: windows.UINT,
) callconv(WINAPI) windows.INT;

extern "kernel32" fn AllocConsole() callconv(WINAPI) windows.BOOL;

extern "kernel32" fn WriteConsoleA(
    h_console_output: ?windows.HANDLE,
    lp_buffer: [*c]const u8,
    n_number_of_chars_to_write: windows.UINT,
    lp_number_of_chars_to_written: ?*windows.UINT,
    lp_reserved: ?*anyopaque,
) callconv(WINAPI) windows.BOOL;

const STD_HANDLE = enum(windows.UINT) {
    INPUT_HANDLE = 4294967286,
    OUTPUT_HANDLE = 4294967285,
    ERROR_HANDLE = 4294967284,
};

extern "kernel32" fn GetStdHandle(n_std_handle: STD_HANDLE) callconv(WINAPI) windows.HANDLE;
extern "kernel32" fn GetModuleHandleA(lp_module_name: ?windows.LPCSTR) callconv(WINAPI) windows.HMODULE;
extern "kernel32" fn GetModuleHandleW(lp_moudle_name: ?windows.LPCSTR) callconv(WINAPI) windows.HMODULE;

var global_running = true;

extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(windows.WINAPI) ?windows.HGLRC;
extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
extern "opengl32" fn wglDeleteContext(hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
extern "opengl32" fn wglGetProcAccress(fn_name: windows.LPCSTR) callconv(windows.WINAPI) ?windows.PVOID;
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

            const let_windows_choose_pixel_format = gdi32.ChoosePixelFormat(our_window_handle_to_device_context.?, &pfd);

            // TODO: handle return value
            _ = gdi32.SetPixelFormat(our_window_handle_to_device_context.?, let_windows_choose_pixel_format, &pfd);

            const our_opengl_rendering_context = wglCreateContext(our_window_handle_to_device_context.?);

            // TODO: handle return value
            _ = wglMakeCurrent(our_window_handle_to_device_context.?, our_opengl_rendering_context.?);

            // TOOD (Thomas): What is this magic number?
            const gl_version = glGetString(7938);
            std.debug.print("OpenGL Version: {s}\n", .{gl_version});

            // TODO: handle return value
            _ = MessageBoxA(null, gl_version, "OPENGL VERSION", 0);

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

fn win32MainWindowCallback(
    window: windows.HWND,
    message: windows.UINT,
    w_param: windows.WPARAM,
    l_param: windows.LPARAM,
) callconv(WINAPI) windows.LRESULT {
    var result: windows.LRESULT = 0;

    switch (message) {
        user32.WM_CLOSE => {
            std.debug.print("closing\n", .{});
            global_running = false;
        },
        user32.WM_DESTROY => {
            std.debug.print("destroying window\n", .{});
            global_running = false;
        },
        else => {
            result = user32.defWindowProcW(window, message, w_param, l_param);
        },
    }

    return result;
}

fn win32ProcessPendingMessages() !void {
    var msg = user32.MSG.default();
    while (try user32.peekMessageW(&msg, null, 0, 0, user32.PM_REMOVE)) {
        switch (msg.message) {
            user32.WM_QUIT => {
                global_running = false;
                break;
            },
            else => {
                // TODO(Thomas): Deal with return values here
                _ = user32.translateMessage(&msg);
                _ = user32.dispatchMessageW(&msg);
            },
        }
    }
}

pub fn main() !void {
    const hInstance: windows.HMODULE = @ptrCast(GetModuleHandleA(null));

    var wc = user32.WNDCLASSEXW{
        .style = 0,
        //.lpfnWndProc = WindowProc,
        .lpfnWndProc = win32MainWindowCallback,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = @ptrCast(hInstance),
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
        user32.WS_OVERLAPPED | user32.WS_VISIBLE,
        0,
        0,
        640,
        480,
        null,
        null,
        @ptrCast(hInstance),
        null,
    );

    const hdc = try user32.getDC(hwnd);
    _ = hdc;

    while (global_running) {
        try win32ProcessPendingMessages();
    }
}
