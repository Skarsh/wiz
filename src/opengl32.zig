const std = @import("std");
const windows = std.os.windows;
const SourceLocation = std.builtin.SourceLocation;

const opengl = @import("opengl.zig");

const WINAPI = windows.WINAPI;
const BOOL = windows.BOOL;
const FARPROC = windows.FARPROC;
const FLOAT = windows.FLOAT;
const HDC = windows.HDC;
const HGLRC = windows.HGLRC;
const HMODULE = windows.HMODULE;
const INT = windows.INT;
const UINT = windows.UINT;
const LPCSTR = windows.LPCSTR;
const PVOID = windows.PVOID;

pub const GL_TRUE = opengl.GL_TRUE;
pub const GL_FALSE = opengl.GL_FALSE;

// NOTE(Thomas):
// Taken from here: https://github.com/KhronosGroup/OpenGL-Registry/blob/ca491a0576d5c026f06ebe29bfac7cbbcf1e8332/api/GL/wglext.h#L154
// only grabbing the ones that are needed for now.
pub const WGL_DRAW_TO_WINDOW_ARB = 0x2001;
pub const WGL_SUPPORT_OPENGL_ARB = 0x2010;
pub const WGL_DOUBLE_BUFFER_ARB = 0x2011;
pub const WGL_PIXEL_TYPE_ARB = 0x2013;
pub const WGL_COLOR_BITS_ARB = 0x2014;
pub const WGL_DEPTH_BITS_ARB = 0x2022;
pub const WGL_STENCIL_BITS_ARB = 0x2023;
pub const WGL_TYPE_RGBA_ARB = 0x202B;

pub const WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
pub const WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;

pub const WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126;
pub const WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001;
pub const WGL_CONTEXT_DEBUG_BIT_ARB = 0x00000001;
pub const WGL_CONTEXT_FLAGS_ARB = 0x2094;

// TODO (Thomas): Make wrappers for these as been done in user32.zig
pub extern "opengl32" fn wglCreateContext(hdc: HDC) callconv(WINAPI) ?HGLRC;
pub extern "opengl32" fn wglMakeCurrent(hdc: HDC, hglrc: HGLRC) callconv(WINAPI) BOOL;
pub extern "opengl32" fn wglDeleteContext(hglrc: HGLRC) callconv(WINAPI) BOOL;
pub extern "opengl32" fn wglGetProcAddress(fn_name: LPCSTR) callconv(WINAPI) ?PVOID;
pub extern "opengl32" fn glGetString(name: opengl.KhrGLenum) callconv(WINAPI) [*:0]const u8;

extern "kernel32" fn GetProcAddress(h_module: HMODULE, fn_name: LPCSTR) callconv(WINAPI) ?FARPROC;
extern "kernel32" fn LoadLibraryA(fn_name: LPCSTR) callconv(WINAPI) ?HMODULE;

pub var wglSwapIntervalEXT: *const fn (INT) callconv(WINAPI) BOOL = undefined;
pub var wglGetSwapIntervalEXT: *const fn () callconv(WINAPI) INT = undefined;
pub var wglGetExtensionsStringARB: *const fn (?HDC) callconv(WINAPI) ?[*:0]const u8 = undefined;
pub var wglCreateContextAttribsARB: *const fn (hdc: ?HDC, hShareContext: ?HGLRC, attribList: [*c]INT) callconv(WINAPI) ?HGLRC = undefined;

pub var wglChoosePixelFormatARB: *const fn (
    hdc: ?HDC,
    piAttribIList: [*c]const INT,
    pfAttribFList: [*c]const FLOAT,
    nMaxFormats: UINT,
    piFormats: *INT,
    nNumFormats: *UINT,
) callconv(WINAPI) BOOL = undefined;

pub fn loadWGLFunctions() void {
    // Load Windows specific OpenGL extensions functions
    wglSwapIntervalEXT = @as(@TypeOf(wglSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglSwapIntervalEXT"))));
    wglGetSwapIntervalEXT = @as(@TypeOf(wglGetSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglGetSwapIntervalEXT"))));
    wglGetExtensionsStringARB = @as(@TypeOf(wglGetExtensionsStringARB), @ptrCast(@alignCast(wglGetProcAddress("wglGetExtensionsStringARB"))));
    wglCreateContextAttribsARB = @as(@TypeOf(wglCreateContextAttribsARB), @ptrCast(@alignCast(wglGetProcAddress("wglCreateContextAttribsARB"))));
    wglChoosePixelFormatARB = @as(@TypeOf(wglChoosePixelFormatARB), @ptrCast(@alignCast(wglGetProcAddress("wglChoosePixelFormatARB"))));
}

pub fn loadFunctions(comptime T: type) void {
    // TODO (Thomas): Do this more programtically by iterating over all variables in the OpenGL struct,
    // fetech their signature and name and then set the like above here.

    // Load legacy OpenGL functions first
    const opengl_lib = LoadLibraryA("opengl32.dll");
    if (opengl_lib != null) {
        T.glViewport = @as(@TypeOf(T.glViewport), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glViewport"))));
        T.glEnable = @as(@TypeOf(T.glEnable), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glEnable"))));
        T.glClearColor = @as(@TypeOf(T.glClearColor), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClearColor"))));
        T.glClear = @as(@TypeOf(T.glClear), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClear"))));
        T.glTexImage2D = @as(@TypeOf(T.glTexImage2D), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexImage2D"))));
        T.glTexParameteri = @as(@TypeOf(T.glTexParameteri), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexParameteri"))));
        T.glDrawArrays = @as(@TypeOf(T.glDrawArrays), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glDrawArrays"))));
        T.glGenTextures = @as(@TypeOf(T.glGenTextures), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGenTextures"))));
        T.glBindTexture = @as(@TypeOf(T.glBindTexture), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glBindTexture"))));
        T.glGetError = @as(@TypeOf(T.glGetError), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGetError"))));
    } else {
        std.log.err("Unable to load opengl32.dll", .{});
    }

    T.glGenVertexArrays = @as(@TypeOf(T.glGenVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glGenVertexArrays"))));
    T.glDeleteVertexArrays = @as(@TypeOf(T.glDeleteVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glDeleteVertexArrays"))));
    T.glGenBuffers = @as(@TypeOf(T.glGenBuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenBuffers"))));
    T.glDeleteBuffers = @as(@TypeOf(T.glDeleteBuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteBuffers"))));
    T.glGenFramebuffers = @as(@TypeOf(T.glGenFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenFramebuffers"))));
    T.glDeleteFramebuffers = @as(@TypeOf(T.glDeleteFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteFramebuffers"))));
    T.glDeleteProgram = @as(@TypeOf(T.glDeleteProgram), @ptrCast(@alignCast(wglGetProcAddress("glDeleteProgram"))));
    T.glGenRenderbuffers = @as(@TypeOf(T.glGenRenderbuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenRenderbuffers"))));
    T.glBindVertexArray = @as(@TypeOf(T.glBindVertexArray), @ptrCast(@alignCast(wglGetProcAddress("glBindVertexArray"))));
    T.glBindBuffer = @as(@TypeOf(T.glBindBuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindBuffer"))));
    T.glBufferData = @as(@TypeOf(T.glBufferData), @ptrCast(@alignCast(wglGetProcAddress("glBufferData"))));
    T.glBindFramebuffer = @as(@TypeOf(T.glBindFramebuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindFramebuffer"))));
    T.glFramebufferTexture2D = @as(
        @TypeOf(T.glFramebufferTexture2D),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferTexture2D"))),
    );
    T.glBindRenderbuffer = @as(@TypeOf(T.glBindRenderbuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindRenderbuffer"))));
    T.glRenderbufferStorage = @as(@TypeOf(T.glRenderbufferStorage), @ptrCast(@alignCast(wglGetProcAddress("glRenderbufferStorage"))));
    T.glFramebufferRenderbuffer = @as(
        @TypeOf(T.glFramebufferRenderbuffer),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferRenderbuffer"))),
    );
    T.glCheckFramebufferStatus = @as(
        @TypeOf(T.glCheckFramebufferStatus),
        @ptrCast(@alignCast(wglGetProcAddress("glCheckFramebufferStatus"))),
    );
    T.glVertexAttribPointer = @as(@TypeOf(T.glVertexAttribPointer), @ptrCast(@alignCast(wglGetProcAddress("glVertexAttribPointer"))));
    T.glEnableVertexAttribArray = @as(
        @TypeOf(T.glEnableVertexAttribArray),
        @ptrCast(@alignCast(wglGetProcAddress("glEnableVertexAttribArray"))),
    );
    T.glActiveTexture = @as(@TypeOf(T.glActiveTexture), @ptrCast(@alignCast(wglGetProcAddress("glActiveTexture"))));
    T.glCreateShader = @as(@TypeOf(T.glCreateShader), @ptrCast(@alignCast(wglGetProcAddress("glCreateShader"))));
    T.glShaderSource = @as(@TypeOf(T.glShaderSource), @ptrCast(@alignCast(wglGetProcAddress("glShaderSource"))));
    T.glCompileShader = @as(@TypeOf(T.glCompileShader), @ptrCast(@alignCast(wglGetProcAddress("glCompileShader"))));
    T.glAttachShader = @as(@TypeOf(T.glAttachShader), @ptrCast(@alignCast(wglGetProcAddress("glAttachShader"))));
    T.glCreateProgram = @as(@TypeOf(T.glCreateProgram), @ptrCast(@alignCast(wglGetProcAddress("glCreateProgram"))));
    T.glLinkProgram = @as(@TypeOf(T.glLinkProgram), @ptrCast(@alignCast(wglGetProcAddress("glLinkProgram"))));
    T.glDeleteShader = @as(@TypeOf(T.glDeleteShader), @ptrCast(@alignCast(wglGetProcAddress("glDeleteShader"))));
    T.glUseProgram = @as(@TypeOf(T.glUseProgram), @ptrCast(@alignCast(wglGetProcAddress("glUseProgram"))));
    T.glGetUniformLocation = @as(@TypeOf(T.glGetUniformLocation), @ptrCast(@alignCast(wglGetProcAddress("glGetUniformLocation"))));
    T.glUniform1i = @as(@TypeOf(T.glUniform1i), @ptrCast(@alignCast(wglGetProcAddress("glUniform1i"))));
    T.glUniform1f = @as(@TypeOf(T.glUniform1f), @ptrCast(@alignCast(wglGetProcAddress("glUniform1f"))));
    T.glUniform3f = @as(@TypeOf(T.glUniform3f), @ptrCast(@alignCast(wglGetProcAddress("glUniform3f"))));
    T.glUniform3fv = @as(@TypeOf(T.glUniform3fv), @ptrCast(@alignCast(wglGetProcAddress("glUniform3fv"))));
    T.glUniformMatrix4fv = @as(@TypeOf(T.glUniformMatrix4fv), @ptrCast(@alignCast(wglGetProcAddress("glUniformMatrix4fv"))));
    T.glGetShaderiv = @as(@TypeOf(T.glGetShaderiv), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderiv"))));
    T.glGetShaderInfoLog = @as(@TypeOf(T.glGetShaderInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderInfoLog"))));
    T.glGetProgramiv = @as(@TypeOf(T.glGetProgramiv), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramiv"))));
    T.glGetProgramInfoLog = @as(@TypeOf(T.glGetProgramInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramInfoLog"))));
    T.glGenerateMipmap = @as(@TypeOf(T.glGenerateMipmap), @ptrCast(@alignCast(wglGetProcAddress("glGenerateMipmap"))));
}
