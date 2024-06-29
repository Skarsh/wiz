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
    defer win.deinit();

    var frame_times = try FrameTimes.new(fba_allocator, 1000);

    try win.makeModernOpenGLContext();
    try win.setVSync(false);

    // NOTE(Thomas): It's very important to load after making the context on Windows at least.
    opengl.load();

    win.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    const target_fps: i64 = 250; // This can be set to any desired value
    const target_frame_duration = wiz.ns_per_sec / target_fps; // In nanoseconds

    var delta_time: f32 = 0.0;
    var now: i64 = 0;
    try wiz.queryPerformanceCounter(&now);
    var last: i64 = 0;
    var frame_count: usize = 0;

    var event: Event = Event{ .KeyDown = input.KeyEvent{ .scancode = 0 } };
    while (win.isRunning()) {
        const tracy_zone = tracy.trace(@src());
        defer tracy_zone.end();

        last = now;
        try wiz.queryPerformanceCounter(&now);

        // Multiplying by 1000 to get the value in milliseconds
        var perf_freq: i64 = undefined;
        try wiz.queryPerformanceFrequency(&perf_freq);
        delta_time = @as(f32, @floatFromInt((now - last))) * (wiz.ms_per_sec / @as(f32, @floatFromInt(perf_freq)));
        frame_times.push(delta_time);

        frame_count += 1;

        if (@mod(frame_count, target_fps) == 0) {
            const mean_frame_time = frame_times.calculateMeanFrameTime();
            std.debug.print("mean_frame_time: {d:.4}ms, {d:.2}fps\n", .{ mean_frame_time, wiz.ms_per_sec / mean_frame_time });
        }

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

        opengl.glClearColor(0.2, 0.3, 0.3, 1.0);
        opengl.glClear(opengl.GL_COLOR_BUFFER_BIT);
        try win.swapBuffers();

        // TODO (Thomas): This is not a great way of doing this, find a better way. It's OK for now.
        // Calculate frame duration and adjust sleep time
        if (!win.isVSync()) {
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

pub fn framebufferSizeCallback(window: *WindowData, width: i32, height: i32) void {
    _ = window;
    opengl.glViewport(0, 0, width, height);
}
