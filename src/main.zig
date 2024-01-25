const std = @import("std");
const Timer = std.time.Timer;
const windows = std.os.windows;
const kernel32 = windows.kernel32;
const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const opengl32 = @import("opengl32.zig");
const input = @import("input.zig");
const wiz = @import("wiz.zig");
const tracy = @import("tracy.zig");
const build_options = @import("build_options");
const Event = input.Event;
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const Window = @import("windows.zig").Window;
const WindowOptions = @import("windows.zig").WindowOptions;
const WindowFormat = @import("windows.zig").WindowFormat;
const enable_tracy = build_options.enable_tracy;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const window_width = 640;
    const window_height = 480;
    var win = try Window.init(allocator, window_width, window_height, WindowFormat.fullscreen, "win1");

    try win.makeOpenGLContext();

    opengl32.loadOpenGLFunctions();

    {

        // Set pixel format for OpenGl context
        const attrib = [_]i32{
            opengl32.WGL_DRAW_TO_WINDOW_ARB, opengl32.GL_TRUE,
            opengl32.WGL_SUPPORT_OPENGL_ARB, opengl32.GL_TRUE,
            opengl32.WGL_DOUBLE_BUFFER_ARB,  opengl32.GL_TRUE,
            opengl32.WGL_PIXEL_TYPE_ARB,     opengl32.WGL_TYPE_RGBA_ARB,
            // TODO(Thomas): Why isn't this 32???
            opengl32.WGL_COLOR_BITS_ARB,     24,
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
        std.debug.print("attrib: {any}\n", .{attrib});

        var format: i32 = 0;
        var num_formats: u32 = 0;

        if (win.hdc) |hdc| {
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

        if (win.hdc) |hdc| {
            const rc_opt = opengl32.wglCreateContextAttribsARB(hdc, null, &attrib);
            const ok = opengl32.wglMakeCurrent(hdc, rc_opt.?);
            std.debug.assert(ok == 1);
        }
    }

    const extensions = opengl32.wglGetExtensionsStringARB(win.hdc);
    std.debug.print("extensions: {s}\n", .{extensions.?});

    const swap_interval = opengl32.wglGetSwapIntervalEXT();
    std.debug.print("swap interval before setting it: {}\n", .{swap_interval});

    const result = opengl32.wglSwapIntervalEXT(0);
    if (result == 0) {
        std.debug.print("setting wglSwapIntevalEXT failed\n", .{});
    }
    std.debug.print("swap interval after setting it: {}\n", .{swap_interval});

    win.setWindowSizeCallback(windowSizeCallback);
    win.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    //const win2 = try Window.init(allocator, win_opts, "win2");
    //win2.setWindowSizeCallback(windowSizeCallback);

    //var perf_counter: i64 = 0;
    //var perf_freq: i64 = 0;
    var frame_count: usize = 0;
    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    var timer = try Timer.start();
    //var last: u64 = 0;
    while (win.running) {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();
        frame_count += 1;
        const delta_time = timer.lap();
        timer.reset();
        //try wiz.queryPerformanceCounter(&perf_counter);
        //try wiz.queryPerformanceFrequency(&perf_freq);
        try Window.processMessages();

        //last = now;
        if (@mod(frame_count, 60) == 0) {
            std.debug.print("delta_time: {d}ms\n", .{delta_time / std.time.ns_per_ms});
        }

        while (win.event_queue.poll(&event)) {
            switch (event) {
                .KeyDown => {
                    // Hardcoded for now, 1 = ESCAPE
                    if (event.KeyDown.scancode == @intFromEnum(input.Scancode.Keyboard_Escape)) {
                        win.windowShouldClose(true);
                    } else {
                        std.debug.print("Event: {}\n", .{event});
                    }
                    if (event.KeyDown.scancode == @intFromEnum(input.Scancode.Keyboard_F)) {
                        try win.toggleFullscreen();
                    }
                },
                else => {
                    std.debug.print("Event: {}\n", .{event});
                },
            }
        }

        //while (win2.event_queue.poll(&event)) {
        //    std.debug.print("Event: {}\n", .{event});
        //}

        opengl32.glClearColor(1.0, 0.0, 1.0, 0.0);
        opengl32.glClear(opengl32.GL_COLOR_BUFFER_BIT);
        try win.swapBuffers();

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

pub fn framebufferSizeCallback(window: *Window, width: i32, height: i32) void {
    _ = window;
    opengl32.glViewport(0, 0, width, height);
}
