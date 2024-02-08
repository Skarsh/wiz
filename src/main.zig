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
    var win = try Window.init(allocator, window_width, window_height, WindowFormat.windowed, "win1");
    defer win.deinit() catch unreachable;

    // NOTE(Thomas): Set the Windows scheduler granularity to 1ms.
    // This is to make sleep() more granular
    // TODO (Thomas): Check return value here, also, this does not belon in the main function, should make a wrapper.
    _ = wiz.timeBeginPeriod(1);

    try win.makeModernOpenGLContext();
    try win.setVSync(false);

    win.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    const target_fps: i64 = 250; // This can be set to any desired value
    const target_frame_duration = wiz.ns_per_sec / target_fps; // In nanoseconds

    var delta_time: f32 = 0.0;
    var now: i64 = 0;
    try wiz.queryPerformanceCounter(&now);
    var last: i64 = 0;
    var frame_count: usize = 0;

    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    while (win.running) {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();

        last = now;
        try wiz.queryPerformanceCounter(&now);

        // Multiplying by 1000 to get the value in milliseconds
        var perf_freq: i64 = undefined;
        try wiz.queryPerformanceFrequency(&perf_freq);
        delta_time = @as(f32, @floatFromInt((now - last))) * (wiz.ms_per_sec / @as(f32, @floatFromInt(perf_freq)));
        frame_count += 1;

        if (@mod(frame_count, target_fps) == 0) {
            std.debug.print("delta_time: {d:.4}ms, {d}fps\n", .{ delta_time, wiz.ms_per_sec / delta_time });
        }

        try Window.processMessages();
        while (win.event_queue.poll(&event)) {
            switch (event) {
                .KeyDown => {
                    // Hardcoded for now, 1 = ESCAPE
                    if (event.KeyDown.scancode == @intFromEnum(input.Scancode.Keyboard_Escape)) {
                        win.windowShouldClose(true);
                    }
                    if (event.KeyDown.scancode == @intFromEnum(input.Scancode.Keyboard_F)) {
                        try win.toggleFullscreen();
                    }
                    if (event.KeyDown.scancode == @intFromEnum(wiz.Scancode.Keyboard_R)) {
                        try win.setCaptureCursor(!win.capture_cursor);
                    }
                },
                else => {},
            }
        }

        opengl32.glClearColor(0.2, 0.3, 0.3, 1.0);
        opengl32.glClear(opengl32.GL_COLOR_BUFFER_BIT);
        try win.swapBuffers();

        // TODO (Thomas): This is not a great way of doing this, find a better way. It's OK for now.
        // Calculate frame duration and adjust sleep time
        if (!win.is_vsync) {
            var frame_end_time: i64 = 0;
            try wiz.queryPerformanceCounter(&frame_end_time);
            const frame_processing_time = frame_end_time - last; // Time taken for current frame
            const sleep_duration = if (target_frame_duration > frame_processing_time) target_frame_duration - frame_processing_time else 0;
            if (sleep_duration > 0) {
                std.time.sleep(@intCast(sleep_duration));
            }
        }
    }

    std.debug.print("Exiting app\n", .{});
}

pub fn framebufferSizeCallback(window: *Window, width: i32, height: i32) void {
    _ = window;
    opengl32.glViewport(0, 0, width, height);
}
