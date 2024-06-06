const std = @import("std");
const windows = std.os.windows;
const SourceLocation = std.builtin.SourceLocation;

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
pub extern "opengl32" fn glGetString(name: KhrGLenum) callconv(WINAPI) [*:0]const u8;

extern "kernel32" fn GetProcAddress(h_module: HMODULE, fn_name: LPCSTR) callconv(WINAPI) ?FARPROC;
extern "kernel32" fn LoadLibraryA(fn_name: LPCSTR) callconv(WINAPI) ?HMODULE;

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

// TODO (Thomas): Where does this belong, in GLEnum??
pub const color_buffer_bit: c_int = 0x00004000;

// TODO (Thomas): Think about whether it would be nice to split this into different enums
// that tells us more about what they are meant to represent, they need to be represented as u32s in the end anwyays.
pub const GlEnum = enum(u32) {
    false = 0,
    true = 1,
    unsigned_byte = 0x1401,
    float = 0x1406,
    array_buffer = 0x8892,
    frame_buffer = 0x8D40,
    render_buffer = 0x8D41,
    static_draw = 0x88E4,
    color_attachment_0 = 0x8CE0,
    texture_2d = 0x0DE1,
    depth24_stencil8 = 0x88F0,
    depth_attachment = 0x8D00,
    framebuffer_complete = 0x8CD5,
    depth_test = 0x0B71,
    color_buffer_bit = 0x00004000,
    depth_buffer_bit = 0x00000100,
    texture_0 = 0x84C0,
    triangles = 0x0004,
    fragment_shader = 0x8B30,
    vertex_shader = 0x8B31,
    compile_status = 0x8B81,
    link_status = 0x8B82,
    rgb = 0x1907,
    repeat = 0x2901,
    linear = 0x2601,
    texture_mag_filter = 0x2800,
    texture_min_filter = 0x2801,
    texture_wrap_s = 0x2802,
    texture_wrap_t = 0x2803,
};

const GlErrorFlags = enum(u32) {
    NoError = 0,
    /// Given when an enumeration parameter is not a legal enumeration for that function. This is given only for local problems;
    /// if the spec allows the enumeration in certain circumstances, where other parameters or state dictate those circumstances,
    /// then GL_INVALID_OPERATION is the result instead.
    InvalidEnum = 0x0500,
    /// Given when a value parameter is not a legal value for that function. This is only given for local problems;
    /// if the spec allows the value in certain circumstances, where other parameters or state dictate those circumstances,
    /// then GL_INVALID_OPERATION is the result instead.
    InvalidValue = 0x0501,
    /// Given when the set of state for a command is not legal for the parameters given to that command.
    /// It is also given for commands where combinations of parameters define what the legal parameters are.
    InvalidOperation = 0x0502,
    /// Given when a stack pushing operation cannot be done because it would overflow the limit of that stack's size.
    StackOverflow = 0x0503,
    /// Given when a stack popping operation cannot be done because the stack is already at its lowest point.
    StackUnderflow = 0x504,
    /// Given when performing an operation that can allocate memory, and the memory cannot be allocated.
    /// The results of OpenGL functions that return this error are undefined;
    /// it is allowable for partial execution of an operation to happen in this circumstance.
    OutOfMemory = 0x0505,
    /// Given when doing anything that would attempt to read from or write/render to a framebuffer that is not complete.
    InvalidFramebufferOperation = 0x0506,
    /// (With OpenGL4.5 or  ARB_KHR_robustness) Given if the OpenGL context has been lost, due to a graphics card reset.
    ContextLost = 0x0507,
};

const GlError = error{
    InvalidEnum,
    InvalidValue,
    InvalidOperation,
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
    InvalidFramebufferOperation,
    ContextLost,
    IllegalError,
};

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

pub fn loadDummyGLfunctions(comptime T: type) void {
    // TODO (Thomas): Do this more programtically by iterating over all variables in the OpenGL struct,
    // fetech their signature and name and then set the like above here.

    // Load legacy OpenGL functions first
    const opengl_lib = LoadLibraryA("opengl32.dll");
    if (opengl_lib != null) {
        T.glViewport = @as(@TypeOf(glViewport), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glViewport"))));
        T.glEnable = @as(@TypeOf(glEnable), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glEnable"))));
        T.glClearColor = @as(@TypeOf(glClearColor), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClearColor"))));
        T.glClear = @as(@TypeOf(glClear), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glClear"))));
        T.glTexImage2D = @as(@TypeOf(glTexImage2D), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexImage2D"))));
        T.glTexParameteri = @as(@TypeOf(glTexParameteri), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glTexParameteri"))));
        T.glDrawArrays = @as(@TypeOf(glDrawArrays), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glDrawArrays"))));
        T.glGenTextures = @as(@TypeOf(glGenTextures), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGenTextures"))));
        T.glBindTexture = @as(@TypeOf(glBindTexture), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glBindTexture"))));
        T.glGetError = @as(@TypeOf(glGetError), @ptrCast(@alignCast(GetProcAddress(opengl_lib.?, "glGetError"))));
    } else {
        std.log.err("Unable to load opengl32.dll", .{});
    }

    // Load OpenGL extensions functions
    //wglSwapIntervalEXT = @as(@TypeOf(wglSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglSwapIntervalEXT"))));
    //wglGetSwapIntervalEXT = @as(@TypeOf(wglGetSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglGetSwapIntervalEXT"))));
    //wglGetExtensionsStringARB = @as(@TypeOf(wglGetExtensionsStringARB), @ptrCast(@alignCast(wglGetProcAddress("wglGetExtensionsStringARB"))));
    //wglCreateContextAttribsARB = @as(@TypeOf(wglCreateContextAttribsARB), @ptrCast(@alignCast(wglGetProcAddress("wglCreateContextAttribsARB"))));
    //wglChoosePixelFormatARB = @as(@TypeOf(wglChoosePixelFormatARB), @ptrCast(@alignCast(wglGetProcAddress("wglChoosePixelFormatARB"))));

    T.glGenVertexArrays = @as(@TypeOf(glGenVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glGenVertexArrays"))));
    T.glDeleteVertexArrays = @as(@TypeOf(glDeleteVertexArrays), @ptrCast(@alignCast(wglGetProcAddress("glDeleteVertexArrays"))));
    T.glGenBuffers = @as(@TypeOf(glGenBuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenBuffers"))));
    T.glDeleteBuffers = @as(@TypeOf(glDeleteBuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteBuffers"))));
    T.glGenFramebuffers = @as(@TypeOf(glGenFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenFramebuffers"))));
    T.glDeleteFramebuffers = @as(@TypeOf(glDeleteFramebuffers), @ptrCast(@alignCast(wglGetProcAddress("glDeleteFramebuffers"))));
    T.glDeleteProgram = @as(@TypeOf(glDeleteProgram), @ptrCast(@alignCast(wglGetProcAddress("glDeleteProgram"))));
    T.glGenRenderbuffers = @as(@TypeOf(glGenRenderbuffers), @ptrCast(@alignCast(wglGetProcAddress("glGenRenderbuffers"))));
    T.glBindVertexArray = @as(@TypeOf(glBindVertexArray), @ptrCast(@alignCast(wglGetProcAddress("glBindVertexArray"))));
    T.glBindBuffer = @as(@TypeOf(glBindBuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindBuffer"))));
    T.glBufferData = @as(@TypeOf(glBufferData), @ptrCast(@alignCast(wglGetProcAddress("glBufferData"))));
    T.glBindFramebuffer = @as(@TypeOf(glBindFramebuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindFramebuffer"))));
    T.glFramebufferTexture2D = @as(
        @TypeOf(glFramebufferTexture2D),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferTexture2D"))),
    );
    T.glBindRenderbuffer = @as(@TypeOf(glBindRenderbuffer), @ptrCast(@alignCast(wglGetProcAddress("glBindRenderbuffer"))));
    T.glRenderbufferStorage = @as(@TypeOf(glRenderbufferStorage), @ptrCast(@alignCast(wglGetProcAddress("glRenderbufferStorage"))));
    T.glFramebufferRenderbuffer = @as(
        @TypeOf(glFramebufferRenderbuffer),
        @ptrCast(@alignCast(wglGetProcAddress("glFramebufferRenderbuffer"))),
    );
    T.glCheckFramebufferStatus = @as(
        @TypeOf(glCheckFramebufferStatus),
        @ptrCast(@alignCast(wglGetProcAddress("glCheckFramebufferStatus"))),
    );
    T.glVertexAttribPointer = @as(@TypeOf(glVertexAttribPointer), @ptrCast(@alignCast(wglGetProcAddress("glVertexAttribPointer"))));
    T.glEnableVertexAttribArray = @as(
        @TypeOf(glEnableVertexAttribArray),
        @ptrCast(@alignCast(wglGetProcAddress("glEnableVertexAttribArray"))),
    );
    T.glActiveTexture = @as(@TypeOf(glActiveTexture), @ptrCast(@alignCast(wglGetProcAddress("glActiveTexture"))));
    T.glCreateShader = @as(@TypeOf(glCreateShader), @ptrCast(@alignCast(wglGetProcAddress("glCreateShader"))));
    T.glShaderSource = @as(@TypeOf(glShaderSource), @ptrCast(@alignCast(wglGetProcAddress("glShaderSource"))));
    T.glCompileShader = @as(@TypeOf(glCompileShader), @ptrCast(@alignCast(wglGetProcAddress("glCompileShader"))));
    T.glAttachShader = @as(@TypeOf(glAttachShader), @ptrCast(@alignCast(wglGetProcAddress("glAttachShader"))));
    T.glCreateProgram = @as(@TypeOf(glCreateProgram), @ptrCast(@alignCast(wglGetProcAddress("glCreateProgram"))));
    T.glLinkProgram = @as(@TypeOf(glLinkProgram), @ptrCast(@alignCast(wglGetProcAddress("glLinkProgram"))));
    T.glDeleteShader = @as(@TypeOf(glDeleteShader), @ptrCast(@alignCast(wglGetProcAddress("glDeleteShader"))));
    T.glUseProgram = @as(@TypeOf(glUseProgram), @ptrCast(@alignCast(wglGetProcAddress("glUseProgram"))));
    T.glGetUniformLocation = @as(@TypeOf(glGetUniformLocation), @ptrCast(@alignCast(wglGetProcAddress("glGetUniformLocation"))));
    T.glUniform1i = @as(@TypeOf(glUniform1i), @ptrCast(@alignCast(wglGetProcAddress("glUniform1i"))));
    T.glUniform1f = @as(@TypeOf(glUniform1f), @ptrCast(@alignCast(wglGetProcAddress("glUniform1f"))));
    T.glUniform3f = @as(@TypeOf(glUniform3f), @ptrCast(@alignCast(wglGetProcAddress("glUniform3f"))));
    T.glUniform3fv = @as(@TypeOf(glUniform3fv), @ptrCast(@alignCast(wglGetProcAddress("glUniform3fv"))));
    T.glUniformMatrix4fv = @as(@TypeOf(glUniformMatrix4fv), @ptrCast(@alignCast(wglGetProcAddress("glUniformMatrix4fv"))));
    T.glGetShaderiv = @as(@TypeOf(glGetShaderiv), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderiv"))));
    T.glGetShaderInfoLog = @as(@TypeOf(glGetShaderInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetShaderInfoLog"))));
    T.glGetProgramiv = @as(@TypeOf(glGetProgramiv), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramiv"))));
    T.glGetProgramInfoLog = @as(@TypeOf(glGetProgramInfoLog), @ptrCast(@alignCast(wglGetProcAddress("glGetProgramInfoLog"))));
    T.glGenerateMipmap = @as(@TypeOf(glGenerateMipmap), @ptrCast(@alignCast(wglGetProcAddress("glGenerateMipmap"))));
}

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

    // Load OpenGL extensions functions
    wglSwapIntervalEXT = @as(@TypeOf(wglSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglSwapIntervalEXT"))));
    wglGetSwapIntervalEXT = @as(@TypeOf(wglGetSwapIntervalEXT), @ptrCast(@alignCast(wglGetProcAddress("wglGetSwapIntervalEXT"))));
    wglGetExtensionsStringARB = @as(@TypeOf(wglGetExtensionsStringARB), @ptrCast(@alignCast(wglGetProcAddress("wglGetExtensionsStringARB"))));
    wglCreateContextAttribsARB = @as(@TypeOf(wglCreateContextAttribsARB), @ptrCast(@alignCast(wglGetProcAddress("wglCreateContextAttribsARB"))));
    wglChoosePixelFormatARB = @as(@TypeOf(wglChoosePixelFormatARB), @ptrCast(@alignCast(wglGetProcAddress("wglChoosePixelFormatARB"))));

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

pub const OpenGL = struct {
    glGenVertexArrays: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    glDeleteVertexArrays: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = undefined,
    glGenBuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    glDeleteBuffers: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = undefined,
    glGenFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    // TODO (Thomas): Why is the buffers pointers not const here? https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDeleteFramebuffers.xhtml
    glDeleteFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    glDeleteProgram: *const fn (GLuint) callconv(.C) void = undefined,
    glGenRenderbuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    glBindVertexArray: *const fn (GLuint) callconv(.C) void = undefined,
    glBindBuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined,
    glBufferData: *const fn (KhrGLenum, stride: GLsizeiptr, ?*const anyopaque, KhrGLenum) void = undefined,
    glBindFramebuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined,
    glFramebufferTexture2D: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint, GLint) callconv(.C) void = undefined,
    glBindRenderbuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined,
    glRenderbufferStorage: *const fn (KhrGLenum, KhrGLenum, GLsizei, GLsizei) callconv(.C) void = undefined,
    glFramebufferRenderbuffer: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint) callconv(.C) void = undefined,
    glCheckFramebufferStatus: *const fn (KhrGLenum) callconv(.C) KhrGLenum = undefined,
    glVertexAttribPointer: *const fn (
        GLuint,
        size: GLint,
        KhrGLenum,
        GLboolean,
        stride: GLsizei,
        pointer: ?*const anyopaque,
    ) callconv(.C) void = undefined,
    glEnableVertexAttribArray: *const fn (GLuint) callconv(.C) void = undefined,
    glViewport: *const fn (GLint, GLint, GLsizei, GLsizei) callconv(.C) void = undefined,
    glEnable: *const fn (KhrGLenum) callconv(.C) void = undefined,
    glClearColor: *const fn (GLfloat, GLfloat, GLfloat, GLfloat) callconv(.C) void = undefined,
    glClear: *const fn (GLbitfield) callconv(.C) void = undefined,
    glActiveTexture: *const fn (KhrGLenum) callconv(.C) void = undefined,
    glDrawArrays: *const fn (KhrGLenum, GLint, GLsizei) callconv(.C) void = undefined,
    glCreateShader: *const fn (KhrGLenum) callconv(.C) GLuint = undefined,
    glShaderSource: *const fn (GLuint, GLsizei, [*c]const [*c]const GLchar, [*c]const GLint) callconv(.C) void = undefined,
    glCompileShader: *const fn (GLuint) callconv(.C) void = undefined,
    glAttachShader: *const fn (GLuint, GLuint) callconv(.C) void = undefined,
    glCreateProgram: *const fn () callconv(.C) GLuint = undefined,
    glLinkProgram: *const fn (GLuint) callconv(.C) void = undefined,
    glDeleteShader: *const fn (GLuint) callconv(.C) void = undefined,
    glUseProgram: *const fn (GLuint) callconv(.C) void = undefined,
    glGetUniformLocation: *const fn (GLuint, [*c]const GLchar) callconv(.C) GLint = undefined,
    glUniform1i: *const fn (GLint, GLint) callconv(.C) void = undefined,
    glUniform1f: *const fn (GLint, GLfloat) callconv(.C) void = undefined,
    glUniform3f: *const fn (GLint, GLfloat, GLfloat, GLfloat) callconv(.C) void = undefined,
    glUniform3fv: *const fn (GLint, GLsizei, [*c]const GLfloat) callconv(.C) void = undefined,
    glUniformMatrix4fv: *const fn (GLint, GLsizei, GLboolean, [*c]const GLfloat) callconv(.C) void = undefined,
    glGetShaderiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = undefined,
    glGetShaderInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = undefined,
    glGetProgramiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = undefined,
    glGetProgramInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = undefined,
    glGenTextures: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = undefined,
    glBindTexture: *const fn (KhrGLenum, GLuint) callconv(.C) void = undefined,
    glTexImage2D: *const fn (
        KhrGLenum,
        GLint,
        GLint,
        GLsizei,
        GLsizei,
        GLint,
        KhrGLenum,
        KhrGLenum,
        ?*const anyopaque,
    ) callconv(.C) void = undefined,
    glTexParameteri: *const fn (KhrGLenum, KhrGLenum, GLint) callconv(.C) void = undefined,
    glGenerateMipmap: *const fn (KhrGLenum) callconv(.C) void = undefined,
    glGetError: *const fn () callconv(.C) KhrGLenum = undefined,

    pub fn load(self: *OpenGL) void {
        self.glGenVertexArrays = glGenVertexArrays;
        self.glDeleteVertexArrays = glDeleteVertexArrays;
        self.glGenBuffers = glGenBuffers;
        self.glDeleteBuffers = glDeleteBuffers;
        self.glGenFramebuffers = glGenFramebuffers;
        self.glDeleteFramebuffers = glDeleteFramebuffers;
        self.glDeleteProgram = glDeleteProgram;
        self.glGenRenderbuffers = glGenRenderbuffers;
        self.glBindVertexArray = glBindVertexArray;
        self.glBindBuffer = glBindBuffer;
        self.glBufferData = glBufferData;
        self.glBindFramebuffer = glBindFramebuffer;
        self.glFramebufferTexture2D = glFramebufferTexture2D;
        self.glBindRenderbuffer = glBindRenderbuffer;
        self.glRenderbufferStorage = glRenderbufferStorage;
        self.glFramebufferRenderbuffer = glFramebufferRenderbuffer;
        self.glCheckFramebufferStatus = glCheckFramebufferStatus;
        self.glVertexAttribPointer = glVertexAttribPointer;
        self.glEnableVertexAttribArray = glEnableVertexAttribArray;
        self.glViewport = glViewport;
        self.glEnable = glEnable;
        self.glClearColor = glClearColor;
        self.glClear = glClear;
        self.glActiveTexture = glActiveTexture;
        self.glDrawArrays = glDrawArrays;
        self.glCreateShader = glCreateShader;
        self.glShaderSource = glShaderSource;
        self.glCompileShader = glCompileShader;
        self.glAttachShader = glAttachShader;
        self.glCreateProgram = glCreateProgram;
        self.glLinkProgram = glLinkProgram;
        self.glDeleteShader = glDeleteShader;
        self.glDeleteShader = glDeleteShader;
        self.glUseProgram = glUseProgram;
        self.glGetUniformLocation = glGetUniformLocation;
        self.glUniform1i = glUniform1i;
        self.glUniform1f = glUniform1f;
        self.glUniform3f = glUniform3f;
        self.glUniform3fv = glUniform3fv;
        self.glUniformMatrix4fv = glUniformMatrix4fv;
        self.glGetShaderiv = glGetShaderiv;
        self.glGetShaderInfoLog = glGetShaderInfoLog;
        self.glGetProgramiv = glGetProgramiv;
        self.glGetProgramInfoLog = glGetProgramInfoLog;
        self.glGenTextures = glGenTextures;
        self.glBindTexture = glBindTexture;
        self.glTexImage2D = glTexImage2D;
        self.glTexParameteri = glTexParameteri;
        self.glGenerateMipmap = glGenerateMipmap;
        self.glGetError = glGetError;
    }

    pub inline fn genVertexArrays(self: *OpenGL, count: i32, arrays: [*c]u32) void {
        self.glGenVertexArrays(count, arrays);
    }

    pub inline fn deleteVertexArrays(self: *OpenGL, count: i32, arrays: [*c]u32) void {
        self.glDeleteVertexArrays(count, arrays);
    }

    pub inline fn genBuffers(self: *OpenGL, count: i32, buffers: [*c]u32) void {
        self.glGenBuffers(count, buffers);
    }

    pub inline fn deleteBuffers(self: *OpenGL, count: i32, buffers: [*c]u32) void {
        self.glDeleteBuffers(count, buffers);
    }

    pub inline fn genFramebuffers(self: *OpenGL, count: i32, frame_buffers: [*c]u32) void {
        self.glGenFramebuffers(count, frame_buffers);
    }

    pub inline fn deleteFramebuffers(self: *OpenGL, count: i32, framebuffers: [*c]u32) void {
        self.glDeleteFramebuffers(count, framebuffers);
    }

    pub inline fn deleteProgram(self: *OpenGL, program: u32) void {
        self.glDeleteProgram(program);
    }

    pub inline fn genRenderbuffers(self: *OpenGL, count: i32, render_buffers: [*c]u32) void {
        self.glGenRenderbuffers(count, render_buffers);
    }

    pub inline fn bindVertexArray(self: *OpenGL, vertex_array: u32) void {
        self.glBindVertexArray(vertex_array);
    }

    pub inline fn bindBuffer(self: *OpenGL, gl_enum: GlEnum, buffer: u32) void {
        self.glBindBuffer(@intFromEnum(gl_enum), buffer);
    }

    pub inline fn bufferData(self: *OpenGL, buffer_type: GlEnum, stride: i64, data: ?*const anyopaque, draw_type: GlEnum) void {
        self.glBufferData(@intFromEnum(buffer_type), stride, data, @intFromEnum(draw_type));
    }

    pub inline fn bindFramebuffer(self: *OpenGL, buffer_type: GlEnum, framebuffer: u32) void {
        self.glBindFramebuffer(@intFromEnum(buffer_type), framebuffer);
    }

    pub inline fn framebufferTexture2D(self: *OpenGL, target: GlEnum, attachment: GlEnum, texture_target: GlEnum, texture_id: u32, level: i32) void {
        self.glFramebufferTexture2D(@intFromEnum(target), @intFromEnum(attachment), @intFromEnum(texture_target), texture_id, level);
    }

    pub inline fn bindRenderbuffer(self: *OpenGL, target: GlEnum, renderbuffer: u32) void {
        self.glBindRenderbuffer(@intFromEnum(target), renderbuffer);
    }

    pub inline fn renderbufferStorage(self: *OpenGL, target: GlEnum, inernal_format: GlEnum, width: i32, height: i32) void {
        self.glRenderbufferStorage(@intFromEnum(target), @intFromEnum(inernal_format), width, height);
    }

    pub inline fn framebufferRenderbuffer(self: *OpenGL, target: GlEnum, attachment: GlEnum, renderbuffer_target: GlEnum, renderbuffer: u32) void {
        self.glFramebufferRenderbuffer(@intFromEnum(target), @intFromEnum(attachment), @intFromEnum(renderbuffer_target), renderbuffer);
    }

    // TODO (Thomas): Ideally the return type here should be its own error type covering
    pub inline fn checkFramebufferStatus(self: *OpenGL, target: GlEnum) GlEnum {
        return @enumFromInt(self.glCheckFramebufferStatus(@intFromEnum(target)));
    }

    pub inline fn vertexAttribPointer(self: *OpenGL, index: u32, size: i32, ty: GlEnum, normalized: bool, stride: i32, pointer: ?*const anyopaque) void {
        if (normalized) {
            self.glVertexAttribPointer(index, size, @intFromEnum(ty), @intFromEnum(GlEnum.true), stride, pointer);
        } else {
            self.glVertexAttribPointer(index, size, @intFromEnum(ty), @intFromEnum(GlEnum.false), stride, pointer);
        }
    }

    pub inline fn enableVertexAttribArray(self: *OpenGL, index: u32) void {
        self.glEnableVertexAttribArray(index);
    }

    pub inline fn viewport(self: *OpenGL, x: i32, y: i32, width: i32, height: i32) void {
        self.glViewport(x, y, width, height);
    }

    pub inline fn enable(self: *OpenGL, capability: GlEnum) void {
        self.glEnable(@intFromEnum(capability));
    }

    pub inline fn clearColor(self: *OpenGL, red: f32, green: f32, blue: f32, alpha: f32) void {
        self.glClearColor(red, green, blue, alpha);
    }

    // TODO (Thomas): Think about making a bitfield mask type like GLBitField?
    pub inline fn clear(self: *OpenGL, mask: u32) void {
        self.glClear(mask);
    }

    pub inline fn activeTexture(self: *OpenGL, texture: GlEnum) void {
        self.glActiveTexture(@intFromEnum(texture));
    }

    pub inline fn drawArrays(self: *OpenGL, mode: GlEnum, first: i32, count: i32) void {
        self.glDrawArrays(@intFromEnum(mode), first, count);
    }

    pub inline fn createShader(self: *OpenGL, shader_type: GlEnum) u32 {
        return self.glCreateShader(@intFromEnum(shader_type));
    }

    /// Set the source code in the shader
    /// Intended use is to pass one string along with its length here.
    pub inline fn shaderSource(
        self: *OpenGL,
        shader: u32,
        count: i32,
        source_str: []const u8,
        length: i32,
    ) void {
        // TODO (Thomas): To be compliant with the glShaderSource API it should take an array of strings
        // and an array of their lengths.
        if (length > 0) {
            self.glShaderSource(shader, count, &source_str.ptr, &length);
        } else {
            // NOTE (Thomas): This will assume that the string is null terminated!
            self.glShaderSource(shader, count, &source_str.ptr, null);
        }
    }

    pub inline fn compileShader(self: *OpenGL, shader: u32) void {
        self.glCompileShader(shader);
    }

    pub inline fn attachShader(self: *OpenGL, program: u32, shader: u32) void {
        self.glAttachShader(program, shader);
    }

    pub inline fn createProgram(
        self: *OpenGL,
    ) u32 {
        return self.glCreateProgram();
    }

    pub inline fn linkProgram(self: *OpenGL, program: u32) void {
        self.glLinkProgram(program);
    }

    pub inline fn deleteShader(self: *OpenGL, shader: u32) void {
        self.glDeleteShader(shader);
    }

    pub inline fn useProgram(self: *OpenGL, program: u32) void {
        self.glUseProgram(program);
    }

    pub inline fn getUniformLocation(self: *OpenGL, program: u32, name: [:0]const u8) i32 {
        return self.glGetUniformLocation(program, name);
    }

    pub inline fn uniform1i(self: *OpenGL, location: i32, val: i32) void {
        self.glUniform1i(location, val);
    }

    pub inline fn uniform1f(self: *OpenGL, location: i32, val: f32) void {
        self.glUniform1f(location, val);
    }

    pub inline fn uniform3f(self: *OpenGL, location: i32, val_0: f32, val_1: f32, val_2: f32) void {
        self.glUniform3f(location, val_0, val_1, val_2);
    }

    pub inline fn uniform3fv(self: *OpenGL, location: i32, count: i32, value: [*c]const f32) void {
        self.glUniform3fv(location, count, value);
    }

    pub inline fn uniformMatrix4fv(self: *OpenGL, location: i32, count: i32, transpose: bool, value: [*c]const f32) void {
        if (transpose) {
            self.glUniformMatrix4fv(location, count, @intFromEnum(GlEnum.true), value);
        } else {
            self.glUniformMatrix4fv(location, count, @intFromEnum(GlEnum.false), value);
        }
    }

    pub inline fn getShaderiv(self: *OpenGL, shader: u32, pname: GlEnum, params: [*c]i32) void {
        self.glGetShaderiv(shader, @intFromEnum(pname), params);
    }

    pub inline fn getShaderInfoLog(self: *OpenGL, shader: u32, max_length: i32, length: [*c]i32, info_log: [*c]u8) void {
        self.glGetShaderInfoLog(shader, max_length, length, info_log);
    }

    pub inline fn getProgramiv(self: *OpenGL, program: u32, pname: GlEnum, params: [*c]i32) void {
        self.glGetProgramiv(program, @intFromEnum(pname), params);
    }

    pub inline fn getProgramInfoLog(self: *OpenGL, program: u32, max_length: i32, length: [*c]i32, info_log: [*c]u8) void {
        self.glGetProgramInfoLog(program, max_length, length, info_log);
    }

    pub inline fn genTextures(self: *OpenGL, count: i32, textures: [*c]u32) void {
        self.glGenTextures(count, textures);
    }

    pub inline fn bindTexture(self: *OpenGL, target: GlEnum, texture: u32) void {
        self.glBindTexture(@intFromEnum(target), texture);
    }

    pub inline fn texImage2D(
        self: *OpenGL,
        target: GlEnum,
        level: i32,
        internal_format: GlEnum,
        width: i32,
        height: i32,
        border: i32,
        format: GlEnum,
        ty: GlEnum,
        data: ?*const anyopaque,
    ) void {
        self.glTexImage2D(
            @intFromEnum(target),
            level,
            // TODO (Thomas): Required casting the u32 to i32 here, ideally we should find a way
            // to not require casting. Potentially by making a i32 based internal_format type instead?
            @intCast(@intFromEnum(internal_format)),
            width,
            height,
            border,
            @intFromEnum(format),
            @intFromEnum(ty),
            data,
        );
    }

    pub inline fn texParameteri(self: *OpenGL, target: GlEnum, param_name: GlEnum, param: GlEnum) void {
        // TODO (Thomas): Required casting the u32 to i32 here, ideally we should find a way
        // to not require casting. Potentially by making a i32 based wrap_s, wrap_t and filter_min and filter_t type instead?
        self.glTexParameteri(@intFromEnum(target), @intFromEnum(param_name), @intCast(@intFromEnum(param)));
    }

    pub inline fn generateMipmap(self: *OpenGL, target: GlEnum) void {
        self.glGenerateMipmap(@intFromEnum(target));
    }

    pub fn checkError(self: *OpenGL, src: SourceLocation) void {
        const gl_error = self.glGetError();
        switch (gl_error) {
            @intFromEnum(GlErrorFlags.NoError) => {},
            @intFromEnum(GlErrorFlags.InvalidEnum) => {
                std.log.err("GL ERROR: INVALID_ENUM | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.InvalidOperation) => {
                std.log.err("GL ERROR: INVALID_OPERATION | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.StackOverflow) => {
                std.log.err("GL ERROR: StackOverflow | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.StackUnderflow) => {
                std.log.err("GL ERROR: StackUnderflow | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.OutOfMemory) => {
                std.log.err("GL ERROR: OutOfMemory | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.InvalidFramebufferOperation) => {
                std.log.err("GL ERROR: InvalidFramebufferOperation | file {s} ({})\n", .{ src.file, src.line });
            },
            @intFromEnum(GlErrorFlags.ContextLost) => {
                std.log.err("GL ERROR: ContextLost | file {s} ({})\n", .{ src.file, src.line });
            },
            // NOTE: This really should be impossible.
            else => unreachable,
        }
    }
};
