const std = @import("std");
const builtin = @import("builtin");

pub const GL_COLOR_BUFFER_BIT = 0x00004000;

pub const GLfloat = f32;
pub const GLbitfield = c_uint;

pub var glClearColor: *const fn (GLfloat, GLfloat, GLfloat, GLfloat) callconv(.C) void = undefined;
pub var glClear: *const fn (GLbitfield) callconv(.C) void = undefined;

pub fn load() void {
    switch (builtin.os.tag) {
        .windows => {
            const opengl32 = @import("opengl32.zig");
            opengl32.loadOpenGLFunctions();
            glClear = opengl32.glClear;
            glClearColor = opengl32.glClearColor;
        },
        .linux => {
            const openglx = @import("openglx.zig");
            glClear = openglx.glClear;
            glClearColor = openglx.glClearColor;
        },
        else => {},
    }
}
