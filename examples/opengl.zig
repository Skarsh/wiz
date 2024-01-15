const std = @import("std");

const wiz = @import("wiz");

const gl = wiz.opengl32;
const Event = wiz.Event;
const KeyEvent = wiz.KeyEvent;
const Window = wiz.Window;
const WindowFormat = wiz.WindowFormat;

const vertex_shader_source: [:0]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\};
;

const fragment_shader_source: [:0]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\};
;

const vertices = [_]f32{
    0.0, 0.5, 0.0, // top right
    0.5, -0.5, 0.0, // bottom right
    -0.5, -0.5, 0.0, // bottom let
};

pub fn main() !void {
    std.debug.print("hello world!\n", .{});

    var window = try Window.init(std.heap.page_allocator, 640, 480, WindowFormat.windowed, "opengl-example");
    try window.makeOpenGLContext();
    gl.loadOpenGLFunctions();
    gl.glViewport(0, 0, window.width, window.height);
    window.setWindowFramebufferSizeCallback(framebufferSizeCallback);

    // build and compile our shader program
    const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    const vertex_src_ptr: ?[*]const u8 = vertex_shader_source.ptr;
    gl.glShaderSource(vertex_shader, 1, &vertex_src_ptr, null);
    gl.glCompileShader(vertex_shader);
    errdefer gl.glDeleteShader(vertex_shader);

    const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    const fragment_shader_src_ptr: ?[*]const u8 = fragment_shader_source.ptr;
    gl.glShaderSource(fragment_shader, 1, &fragment_shader_src_ptr, null);
    gl.glCompileShader(fragment_shader);
    errdefer gl.glDeleteShader(fragment_shader);

    const shader_program = gl.glCreateProgram();
    gl.glAttachShader(shader_program, vertex_shader);
    gl.glAttachShader(shader_program, fragment_shader);
    gl.glLinkProgram(shader_program);
    errdefer gl.glDeleteProgram(shader_program);

    var vao: u32 = 0;
    var vbo: u32 = 0;
    errdefer gl.glDeleteBuffers(1, &vbo);
    gl.glGenVertexArrays(1, &vao);
    gl.glGenBuffers(1, &vbo);

    gl.glBindVertexArray(vao);

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.GL_STATIC_DRAW);

    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), null);
    gl.glEnableVertexAttribArray(0);

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0);

    gl.glBindVertexArray(0);

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
        gl.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        gl.glUseProgram(shader_program);
        gl.glBindVertexArray(vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);

        try window.swapBuffers();

        std.time.sleep(1_000_000);
    }

    std.debug.print("Exiting app\n", .{});
}

pub fn framebufferSizeCallback(window: *Window, width: i32, height: i32) void {
    _ = window;
    gl.glViewport(0, 0, width, height);
}
