const std = @import("std");
const windows = std.os.windows;
const SourceLocation = std.builtin.SourceLocation;

const WINAPI = std.os.windows.WINAPI;

pub const GL_TRIANGLES = 0x0004;
pub const GL_FLOAT = 0x1406;
pub const GL_VENDOR = 0x1F00;
pub const GL_RENDERER = 0x1F01;
pub const GL_VERSION = 0x1F02;
pub const GL_EXTENSIONS = 0x1F03;
pub const GL_COLOR_BUFFER_BIT = 0x00004000;
pub const GL_FRAGMENT_SHADER = 0x8B30;
pub const GL_VERTEX_SHADER = 0x8B31;
pub const GL_ARRAY_BUFFER = 0x8892;
pub const GL_STATIC_DRAW = 0x88E4;

pub const GL_TRUE = 1;
pub const GL_FALSE = 0;

// TODO (Thomas): Make wrappers for these as been done in user32.zig
pub extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(WINAPI) ?windows.HGLRC;
pub extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
pub extern "opengl32" fn wglDeleteContext(hglrc: windows.HGLRC) callconv(WINAPI) windows.BOOL;
pub extern "opengl32" fn wglGetProcAddress(fn_name: windows.LPCSTR) callconv(WINAPI) ?windows.PVOID;
pub extern "opengl32" fn glGetString(name: KhrGLenum) callconv(WINAPI) [*:0]const u8;

extern "kernel32" fn GetProcAddress(h_module: windows.HMODULE, fn_name: windows.LPCSTR) callconv(windows.WINAPI) ?windows.FARPROC;
extern "kernel32" fn LoadLibraryA(fn_name: windows.LPCSTR) callconv(windows.WINAPI) ?windows.HMODULE;

// TODO (Thomas) Change this to GLenum instead to match OpenGL better
pub const KhrGLenum = c_uint;

pub const khronos_ssize_t = c_longlong;
pub const GLsizeiptr = khronos_ssize_t;
pub const GLint = c_int;
pub const GLuint = c_uint;
pub const GLsizei = c_int;
pub const GLboolean = u8;
pub const GLfloat = f32;
pub const GLbitfield = c_uint;
pub const GLchar = u8;
pub const GLFalse = 0;
pub const GLTrue = 1;

pub var glGenVertexArrays: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
pub var glDeleteVertexArrays: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = undefined;
pub var glGenBuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
pub var glDeleteBuffers: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = undefined;
pub var glGenFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
// TODO (Thomas): Why is the buffers pointers not const here? https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDeleteFramebuffers.xhtml
pub var glDeleteFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
pub var glDeleteProgram: *const fn (GLuint) callconv(.C) void = undefined;
pub var glGenRenderbuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
pub var glBindVertexArray: *const fn (GLuint) callconv(.C) void = undefined;
pub var glBindBuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined;
pub var glBufferData: *const fn (KhrGLenum, stride: GLsizeiptr, ?*const anyopaque, KhrGLenum) void = undefined;
pub var glBindFramebuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined;
pub var glFramebufferTexture2D: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint, GLint) callconv(.C) void = undefined;
pub var glBindRenderbuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined;
pub var glRenderbufferStorage: *const fn (KhrGLenum, KhrGLenum, GLsizei, GLsizei) callconv(.C) void = undefined;
pub var glFramebufferRenderbuffer: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint) callconv(.C) void = undefined;
pub var glCheckFramebufferStatus: *const fn (KhrGLenum) callconv(.C) KhrGLenum = undefined;
pub var glVertexAttribPointer: *const fn (
    GLuint,
    size: GLint,
    KhrGLenum,
    GLboolean,
    stride: GLsizei,
    pointer: ?*const anyopaque,
) callconv(.C) void = undefined;
pub var glEnableVertexAttribArray: *const fn (GLuint) callconv(.C) void = undefined;
pub var glViewport: *const fn (GLint, GLint, GLsizei, GLsizei) callconv(.C) void = undefined;
pub var glEnable: *const fn (KhrGLenum) callconv(.C) void = undefined;
pub var glClearColor: *const fn (GLfloat, GLfloat, GLfloat, GLfloat) callconv(.C) void = undefined;
pub var glClear: *const fn (GLbitfield) callconv(.C) void = undefined;
pub var glActiveTexture: *const fn (KhrGLenum) callconv(.C) void = undefined;
pub var glDrawArrays: *const fn (KhrGLenum, GLint, GLsizei) callconv(.C) void = undefined;
pub var glCreateShader: *const fn (KhrGLenum) callconv(.C) GLuint = undefined;
pub var glShaderSource: *const fn (GLuint, GLsizei, [*c]const [*c]const GLchar, [*c]const GLint) callconv(.C) void = undefined;
pub var glCompileShader: *const fn (GLuint) callconv(.C) void = undefined;
pub var glAttachShader: *const fn (GLuint, GLuint) callconv(.C) void = undefined;
pub var glCreateProgram: *const fn () callconv(.C) GLuint = undefined;
pub var glLinkProgram: *const fn (GLuint) callconv(.C) void = undefined;
pub var glDeleteShader: *const fn (GLuint) callconv(.C) void = undefined;
pub var glUseProgram: *const fn (GLuint) callconv(.C) void = undefined;
pub var glGetUniformLocation: *const fn (GLuint, [*c]const GLchar) callconv(.C) GLint = undefined;
pub var glUniform1i: *const fn (GLint, GLint) callconv(.C) void = undefined;
pub var glUniform1f: *const fn (GLint, GLfloat) callconv(.C) void = undefined;
pub var glUniform3f: *const fn (GLint, GLfloat, GLfloat, GLfloat) callconv(.C) void = undefined;
pub var glUniform3fv: *const fn (GLint, GLsizei, [*c]const GLfloat) callconv(.C) void = undefined;
pub var glUniformMatrix4fv: *const fn (GLint, GLsizei, GLboolean, [*c]const GLfloat) callconv(.C) void = undefined;
pub var glGetShaderiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = undefined;
pub var glGetShaderInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = undefined;
pub var glGetProgramiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = undefined;
pub var glGetProgramInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = undefined;
pub var glGenTextures: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined;
pub var glBindTexture: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined;
pub var glTexImage2D: *const fn (
    KhrGLenum,
    GLint,
    GLint,
    GLsizei,
    GLsizei,
    GLint,
    KhrGLenum,
    KhrGLenum,
    ?*const anyopaque,
) callconv(.C) void = undefined;
pub var glTexParameteri: *const fn (KhrGLenum, KhrGLenum, GLint) callconv(.C) void = undefined;
pub var glGenerateMipmap: *const fn (KhrGLenum) callconv(.C) void = undefined;
pub var glGetError: *const fn () callconv(.C) KhrGLenum = undefined;

pub var wglSwapIntervalEXT: *const fn (windows.INT) callconv(WINAPI) windows.BOOL = undefined;
pub var wglGetSwapIntervalEXT: *const fn () callconv(WINAPI) windows.INT = undefined;

// TODO (Thomas): If loading of any of these fails the app will crash.
// That might be reasonable for now because its pretty useless without rendering.
// One can imagine that one can try other graphics APIs as fallbacks later?
pub fn loadOpenGLFunctions() void {
    // TODO (Thomas): Do this more programtically by iterating over all variables in the OpenGL struct,
    // fetech their signature and name and then set the like above here.

    // Load legacy OpenGL functions first
    const opengl_lib = LoadLibraryA("opengl32.dll");
    if (opengl_lib != null) {
        glViewport = @as(@TypeOf(glViewport), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glViewport"))));
        glEnable = @as(@TypeOf(glEnable), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glEnable"))));
        glClearColor = @as(@TypeOf(glClearColor), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClearColor"))));
        glClear = @as(@TypeOf(glClear), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClear"))));
        glTexImage2D = @as(@TypeOf(glTexImage2D), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexImage2D"))));
        glTexParameteri = @as(@TypeOf(glTexParameteri), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexParameteri"))));
        glDrawArrays = @as(@TypeOf(glDrawArrays), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glDrawArrays"))));
        glGenTextures = @as(@TypeOf(glGenTextures), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGenTextures"))));
        glBindTexture = @as(@TypeOf(glBindTexture), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glBindTexture"))));
        glGetError = @as(@TypeOf(glGetError), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGetError"))));
    } else {
        std.log.err("Unable to load opengl32.dll", .{});
    }

    wglSwapIntervalEXT = @as(@TypeOf(wglSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglSwapIntervalEXT"))));
    wglGetSwapIntervalEXT = @as(@TypeOf(wglGetSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglGetSwapIntervalEXT"))));

    // Load OpenGL extensions functions, which is defined by Windows as version > OpenGL 1.1
    glGenVertexArrays = @as(@TypeOf(glGenVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glGenVertexArrays"))));
    glDeleteVertexArrays = @as(@TypeOf(glDeleteVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glDeleteVertexArrays"))));
    glGenBuffers = @as(@TypeOf(glGenBuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenBuffers"))));
    glDeleteBuffers = @as(@TypeOf(glDeleteBuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteBuffers"))));
    glGenFramebuffers = @as(@TypeOf(glGenFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenFramebuffers"))));
    glDeleteFramebuffers = @as(@TypeOf(glDeleteFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteFramebuffers"))));
    glDeleteProgram = @as(@TypeOf(glDeleteProgram), @ptrCast(@alignCast(wglGetProcAddress("glDeleteProgram"))));
    glGenRenderbuffers = @as(@TypeOf(glGenRenderbuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenRenderbuffers"))));
    glBindVertexArray = @as(@TypeOf(glBindVertexArray), @ptrCast(@alignCast(wglGetProcAddress("glBindVertexArray"))));
    glBindBuffer = @as(@TypeOf(glBindBuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindBuffer"))));
    glBufferData = @as(@TypeOf(glBufferData), @ptrCast(@alignCast(wglGetProcAddress("glBufferData"))));
    glBindFramebuffer = @as(@TypeOf(glBindFramebuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindFramebuffer"))));
    glFramebufferTexture2D = @as(
        @TypeOf(glFramebufferTexture2D),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferTexture2D"))),
    );
    glBindRenderbuffer = @as(@TypeOf(glBindRenderbuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindRenderbuffer"))));
    glRenderbufferStorage = @as(@TypeOf(glRenderbufferStorage), @ptrCast(@alignCast(wglGetProcAddress("glRenderbufferStorage"))));
    glFramebufferRenderbuffer = @as(
        @TypeOf(glFramebufferRenderbuffer),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferRenderbuffer"))),
    );
    glCheckFramebufferStatus = @as(
        @TypeOf(glCheckFramebufferStatus),
        @ptrCast(@alignCast(wglGetProcAddress("glCheckFramebufferStatus"))),
    );
    glVertexAttribPointer = @as(@TypeOf(glVertexAttribPointer), @ptrCast(@alignCast(wglGetProcAddress("glVertexAttribPointer"))));
    glEnableVertexAttribArray = @as(
        @TypeOf(glEnableVertexAttribArray),
        @ptrCast(@alignCast(wglGetProcAddress("glEnableVertexAttribArray"))),
    );
    glActiveTexture = @as(@TypeOf(glActiveTexture), @ptrCast(@alignCast(wglGetProcAddress("glActiveTexture"))));
    glCreateShader = @as(@TypeOf(glCreateShader), @ptrCast(@alignCast(wglGetProcAddress("glCreateShader"))));
    glShaderSource = @as(@TypeOf(glShaderSource), @ptrCast(@alignCast(wglGetProcAddress("glShaderSource"))));
    glCompileShader = @as(@TypeOf(glCompileShader), @ptrCast(@alignCast(wglGetProcAddress("glCompileShader"))));
    glAttachShader = @as(@TypeOf(glAttachShader), @ptrCast(@alignCast(wglGetProcAddress("glAttachShader"))));
    glCreateProgram = @as(@TypeOf(glCreateProgram), @ptrCast(@alignCast(wglGetProcAddress("glCreateProgram"))));
    glLinkProgram = @as(@TypeOf(glLinkProgram), @ptrCast(@alignCast(wglGetProcAddress("glLinkProgram"))));
    glDeleteShader = @as(@TypeOf(glDeleteShader), @ptrCast(@alignCast(wglGetProcAddress("glDeleteShader"))));
    glUseProgram = @as(@TypeOf(glUseProgram), @ptrCast(@alignCast(wglGetProcAddress("glUseProgram"))));
    glGetUniformLocation = @as(@TypeOf(glGetUniformLocation), @ptrCast(@alignCast(wglGetProcAddress("glGetUniformLocation"))));
    glUniform1i = @as(@TypeOf(glUniform1i), @ptrCast(@alignCast(wglGetProcAddress("glUniform1i"))));
    glUniform1f = @as(@TypeOf(glUniform1f), @ptrCast(@alignCast(wglGetProcAddress("glUniform1f"))));
    glUniform3f = @as(@TypeOf(glUniform3f), @ptrCast(@alignCast(wglGetProcAddress("glUniform3f"))));
    glUniform3fv = @as(@TypeOf(glUniform3fv), @ptrCast(@alignCast(wglGetProcAddress("glUniform3fv"))));
    glUniformMatrix4fv = @as(@TypeOf(glUniformMatrix4fv), @ptrCast(@alignCast(wglGetProcAddress("glUniformMatrix4fv"))));
    glGetShaderiv = @as(@TypeOf(glGetShaderiv), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderiv"))));
    glGetShaderInfoLog = @as(@TypeOf(glGetShaderInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderInfoLog"))));
    glGetProgramiv = @as(@TypeOf(glGetProgramiv), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramiv"))));
    glGetProgramInfoLog = @as(@TypeOf(glGetProgramInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramInfoLog"))));
    glGenerateMipmap = @as(@TypeOf(glGenerateMipmap), @ptrCast(@alignCast(wglGetProcAddress("glGenerateMipmap"))));
}
