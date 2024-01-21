const std = @import("std");
const windows = std.os.windows;
const kernel32 = windows.kernel32;
const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const opengl32 = @import("opengl32.zig");
const input = @import("input.zig");
const wiz = @import("wiz.zig");
const Event = input.Event;
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const Window = @import("windows.zig").Window;
const WindowOptions = @import("windows.zig").WindowOptions;
const WindowFormat = @import("windows.zig").WindowFormat;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const window_width = 640;
    const window_height = 480;
    var win = try Window.init(allocator, window_width, window_height, WindowFormat.fullscreen, "win1");

    try win.makeOpenGLContext();
    opengl32.loadOpenGLFunctions();
    opengl32.glViewport(0, 0, win.width, win.height);

    win.setWindowSizeCallback(windowSizeCallback);
    win.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    //const win2 = try Window.init(allocator, win_opts, "win2");
    //win2.setWindowSizeCallback(windowSizeCallback);

    var perf_counter: i64 = 0;
    var perf_freq: i64 = 0;
    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    while (win.running) {
        try wiz.queryPerformanceCounter(&perf_counter);
        try wiz.queryPerformanceFrequency(&perf_freq);
        try Window.processMessages();
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

        // Equals 4ms sleep, just so CPU don't blow up
        std.time.sleep(4_000_000);
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
