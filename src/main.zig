const std = @import("std");
const windows = std.os.windows;
const kernel32 = windows.kernel32;
const user32 = @import("user32.zig");
const gdi32 = @import("gdi32.zig");
const opengl32 = @import("opengl32.zig");
const input = @import("input.zig");
const Event = input.Event;
const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

const Window = @import("windows.zig").Window;
const WindowOptions = @import("windows.zig").WindowOptions;

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
    var win = try Window.init(allocator, win_opts, "win1");
    const monitor_handle = try user32.monitorFromWindow(win.hwnd, 0);
    var monitor_info = user32.MONITORINFO{
        .rcWork = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
        .rcMonitor = user32.RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
        .dwFlags = 0,
    };
    try user32.getMonitorInfoW(monitor_handle, &monitor_info);
    std.debug.print("monitor_info: {}", .{monitor_info});
    try win.makeOpenGLContext();
    win.setWindowSizeCallback(windowSizeCallback);
    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    const win2 = try Window.init(allocator, win_opts, "win2");
    _ = win2;
    while (win.running) {
        try Window.processMessages();
        while (win.event_queue.poll(&event)) {
            switch (event) {
                .KeyDown => {
                    // Hardcoded for now, 1 = ESCAPE
                    if (event.KeyDown.scancode == 1) {
                        win.windowShouldClose(true);
                    } else {
                        std.debug.print("Event: {}\n", .{event});
                    }
                },
                else => {
                    std.debug.print("Event: {}\n", .{event});
                },
            }
        }

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
