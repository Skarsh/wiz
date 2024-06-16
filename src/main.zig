const std = @import("std");
const Allocator = std.mem.Allocator;
const opengl = @import("opengl.zig");
const input = @import("input.zig");
const wiz = @import("wiz.zig");
const FrameTimes = wiz.FrameTimes;
const tracy = @import("tracy.zig");
const build_options = @import("build_options");
const Event = input.Event;
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const PlatformWindow = wiz.PlatformWindow;
const WindowFormat = wiz.WindowFormat;
const WindowData = wiz.WindowData;
const enable_tracy = build_options.enable_tracy;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    errdefer _ = gpa.deinit();
    const gpa_allocator = gpa.allocator();

    const window_memory = try gpa_allocator.alloc(u8, 100_000);
    errdefer gpa_allocator.free(window_memory);

    var fba = std.heap.FixedBufferAllocator.init(window_memory);
    const fba_allocator = fba.allocator();

    const window_width = 640;
    const window_height = 480;
    var win = try PlatformWindow.init(fba_allocator, window_width, window_height, WindowFormat.windowed, "win1");
    //defer win.deinit();

    //var frame_times = try FrameTimes.new(fba_allocator, 1000);

    //try win.makeModernOpenGLContext();
    //try win.setVSync(false);

    //win.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    //const target_fps: i64 = 250; // This can be set to any desired value
    //const target_frame_duration = wiz.ns_per_sec / target_fps; // In nanoseconds

    //var delta_time: f32 = 0.0;
    //var now: i64 = 0;
    //try wiz.queryPerformanceCounter(&now);
    //var last: i64 = 0;
    //var frame_count: usize = 0;

    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    while (win.isRunning()) {
        //const tracy_zone = tracy.trace(@src());
        //defer tracy_zone.end();

        //last = now;
        //try wiz.queryPerformanceCounter(&now);

        // Multiplying by 1000 to get the value in milliseconds
        //var perf_freq: i64 = undefined;
        //try wiz.queryPerformanceFrequency(&perf_freq);
        //delta_time = @as(f32, @floatFromInt((now - last))) * (wiz.ms_per_sec / @as(f32, @floatFromInt(perf_freq)));
        //frame_times.push(delta_time);

        //frame_count += 1;

        //if (@mod(frame_count, target_fps) == 0) {
        //    const mean_frame_time = frame_times.calculateMeanFrameTime();
        //    std.debug.print("mean_frame_time: {d:.4}ms, {d:.2}fps\n", .{ mean_frame_time, wiz.ms_per_sec / mean_frame_time });
        //}

        try win.processMessages();
        while (win.pollEvent(&event)) {
            switch (event) {
                .MouseButtonDown => {
                    std.debug.print("MouseButtonDown {}\n", .{event.MouseButtonDown.button});
                },
                .MouseButtonUp => {
                    std.debug.print("MouseButtonUp {}\n", .{event.MouseButtonUp.button});
                },
                .KeyDown => {
                    std.debug.print("KeyDown {}\n", .{event.KeyDown.scancode});
                    // Hardcoded for now, 1 = ESCAPE
                    if (event.KeyDown.scancode == @intFromEnum(input.Key.key_escape)) {
                        win.windowShouldClose(true);
                    }
                    if (event.KeyDown.scancode == @intFromEnum(input.Key.key_f)) {
                        try win.toggleFullscreen();
                    }
                    if (event.KeyDown.scancode == @intFromEnum(input.Key.key_r)) {
                        try win.setCaptureCursor(!win.getCaptureCursor());
                        if (!win.getRawMouseMotion()) {
                            win.enableRawMouseMotion();
                        } else {
                            win.disableRawMouseMotion();
                        }
                    }
                },
                .KeyUp => {
                    std.debug.print("KeyUp {}\n", .{event.KeyUp.scancode});
                },
                else => {},
            }
        }

        //opengl.glClearColor(0.2, 0.3, 0.3, 1.0);
        //opengl.glClear(opengl.GL_COLOR_BUFFER_BIT);
        //try win.swapBuffers();

        //// TODO (Thomas): This is not a great way of doing this, find a better way. It's OK for now.
        //// Calculate frame duration and adjust sleep time
        //if (!win.isVSync()) {
        //    var frame_end_time: i64 = 0;
        //    try wiz.queryPerformanceCounter(&frame_end_time);
        //    const frame_processing_time = frame_end_time - last; // Time taken for current frame
        //    const sleep_duration = if (target_frame_duration > frame_processing_time) target_frame_duration - frame_processing_time else 0;
        //    if (sleep_duration > 0) {
        //        std.time.sleep(@intCast(sleep_duration));
        //    }
        //}
    }

    std.debug.print("Exiting app\n", .{});
}

pub fn framebufferSizeCallback(window: *WindowData, width: i32, height: i32) void {
    _ = window;
    opengl.glViewport(0, 0, width, height);
}

//const std = @import("std");
//
//const c = @cImport({
//    @cInclude("X11/X.h");
//    @cInclude("X11/Xlib.h");
//    @cInclude("GL/gl.h");
//    @cInclude("GL/glx.h");
//});
//
//pub fn main() !void {
//    const display = c.XOpenDisplay(0);
//    const root_window = c.DefaultRootWindow(display);
//    _ = c.DefaultScreen(display);
//    const window = c.XCreateWindow(display, root_window, 0, 0, 1280, 720, 0, 0, 0, 0, 0, 0);
//    _ = c.XMapWindow(display, window);
//    _ = c.XFlush(display);
//
//    while (true) {}
//}

//const std = @import("std");
//
//const c = @cImport({
//    @cInclude("X11/Xlib.h");
//    @cInclude("X11/Xutil.h");
//    @cInclude("X11/keysymdef.h");
//});
//
//pub fn main() !void {
//    const display = c.XOpenDisplay(null);
//    if (display == null) {
//        std.log.err("Could not open display", .{});
//        std.os.linux.exit(1);
//    }
//
//    const screen = c.DefaultScreenOfDisplay(display);
//    const screen_id = c.DefaultScreen(display);
//
//    // Open the window
//    const window = c.XCreateSimpleWindow(
//        display,
//        c.RootWindowOfScreen(screen),
//        0,
//        0,
//        320,
//        200,
//        1,
//        c.BlackPixel(display, screen_id),
//        c.WhitePixel(display, screen_id),
//    );
//
//    _ = c.XSelectInput(
//        display,
//        window,
//        c.KeyPressMask | c.KeyReleaseMask | c.KeymapStateMask | c.PointerMotionMask | c.ButtonPressMask | c.ButtonReleaseMask | c.EnterWindowMask | c.LeaveWindowMask | c.ExposureMask,
//    );
//
//    // Name the window
//    _ = c.XStoreName(display, window, "Named Window");
//
//    // Show the window
//    _ = c.XClearWindow(display, window);
//    _ = c.XMapRaised(display, window);
//
//    // How large is the window
//    var attribs = c.XWindowAttributes{};
//    _ = c.XGetWindowAttributes(display, window, &attribs);
//    std.debug.print("Window width: {}, height: {}\n", .{ attribs.width, attribs.height });
//
//    // Resize window
//    const change_values = c.CWWidth | c.CWHeight;
//    var values = c.XWindowChanges{};
//    values.width = 800;
//    values.height = 600;
//    _ = c.XConfigureWindow(display, window, change_values, &values);
//
//    var str = [_]u8{0} ** 25;
//    var keysym: c_ulong = 0;
//    var len: c_int = 0;
//    var running = true;
//    var x: i32 = 0;
//    var y: i32 = 0;
//
//    var ev = c.XEvent{ .type = 0 };
//    // Enter message loop
//    while (running) {
//        _ = c.XNextEvent(display, &ev);
//
//        switch (ev.type) {
//            c.KeymapNotify => {
//                _ = c.XRefreshKeyboardMapping(&ev.xmapping);
//            },
//            c.KeyPress => {
//                _ = c.XLookupString(&ev.xkey, &str, 25, &keysym, null);
//                if (len > 0) {
//                    std.debug.print("Key pressed: {s} - {} - {}\n", .{ str, len, keysym });
//                }
//                if (keysym == c.XK_Escape) {
//                    running = false;
//                }
//            },
//            c.KeyRelease => {
//                len = c.XLookupString(&ev.xkey, &str, 25, &keysym, null);
//                if (len > 0) {
//                    std.debug.print("Key released: {s} - {} - {}\n", .{ str, len, keysym });
//                }
//            },
//            c.ButtonPress => {
//                switch (ev.xbutton.button) {
//                    1 => {
//                        std.debug.print("Left mouse button down\n", .{});
//                    },
//                    2 => {
//                        std.debug.print("Middle mouse button down\n", .{});
//                    },
//                    3 => {
//                        std.debug.print("Right mouse button down\n", .{});
//                    },
//                    4 => {
//                        std.debug.print("Mouse scroll up\n", .{});
//                    },
//                    5 => {
//                        std.debug.print("Mouse scroll down\n", .{});
//                    },
//                    else => {},
//                }
//            },
//            c.ButtonRelease => {
//                switch (ev.xbutton.button) {
//                    1 => {
//                        std.debug.print("Left mouse button up\n", .{});
//                    },
//                    2 => {
//                        std.debug.print("Middle mouse button up\n", .{});
//                    },
//                    3 => {
//                        std.debug.print("Right mouse button up\n", .{});
//                    },
//                    else => {},
//                }
//            },
//            c.MotionNotify => {
//                x = ev.xmotion.x;
//                y = ev.xmotion.y;
//                std.debug.print("Mouse X: {}, Y: {}\n", .{ x, y });
//            },
//            c.EnterNotify => {
//                std.debug.print("Mouse enter\n", .{});
//            },
//            c.LeaveNotify => {
//                std.debug.print("Mouse leave\n", .{});
//            },
//            c.Expose => {
//                std.debug.print("Expose event fired", .{});
//                _ = c.XGetWindowAttributes(display, window, &attribs);
//                std.debug.print("\tWindow width: {}, height: {}\n", .{ attribs.width, attribs.height });
//            },
//            else => {},
//        }
//    }
//
//    // Cleanup
//    _ = c.XDestroyWindow(display, window);
//    _ = c.XCloseDisplay(display);
//}
