const std = @import("std");

const wiz = @import("wiz");

const opengl32 = wiz.opengl32;
const Event = wiz.Event;
const KeyEvent = wiz.KeyEvent;
const Window = wiz.Window;
const WindowFormat = wiz.WindowFormat;

pub fn main() !void {
    std.debug.print("hello world!\n", .{});

    var window = try Window.init(std.heap.page_allocator, 640, 480, WindowFormat.windowed, "opengl-example");
    try window.makeOpenGLContext();
    opengl32.glViewport(0, 0, window.width, window.height);

    var event: Event = Event{ .KeyDown = KeyEvent{ .scancode = 0 } };
    while (window.running) {
        try Window.processMessages();
        while (window.event_queue.poll(&event)) {
            switch (event) {
                .KeyDown => {
                    if (event.KeyDown.scancode == 1) {
                        window.windowShouldClose(true);
                    }
                    if (event.KeyDown.scancode == 33) {
                        try window.toggleFullscreen();
                    }
                },
                else => {},
            }
        }
        opengl32.glClearColor(1.0, 0.0, 1.0, 0.0);
        opengl32.glClear(opengl32.GL_COLOR_BUFFER_BIT);
        try window.swapBuffers();

        std.time.sleep(1_000_000);
    }

    std.debug.print("Exiting app\n", .{});
}
