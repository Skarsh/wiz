const c = @cImport({
    @cInclude("GL/glx.h");
});

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

// TODO(Thomas): In general proper error handling would be nice here.
// Should really think about how we can unify this between the different
// platform as much as possible.
fn loadOpenGLFunction(comptime T: type, name: [*:0]const u8) !T {
    const proc = c.glXGetProcAddress(name) orelse return error.FailedToLoadOpenGLFunction;
    return @as(T, @ptrCast(proc));
}

// TODO(Thomas): There is missing a lot of functions compared to even the
// windows version implementation.
pub fn loadFunctions(comptime T: type) void {
    T.glCreateShader = loadOpenGLFunction(@TypeOf(T.glCreateShader), "glCreateShader") catch unreachable;
    T.glShaderSource = loadOpenGLFunction(@TypeOf(T.glShaderSource), "glShaderSource") catch unreachable;
    T.glCompileShader = loadOpenGLFunction(@TypeOf(T.glCompileShader), "glCompileShader") catch unreachable;
    T.glCreateProgram = loadOpenGLFunction(@TypeOf(T.glCreateProgram), "glCreateProgram") catch unreachable;
    T.glAttachShader = loadOpenGLFunction(@TypeOf(T.glAttachShader), "glAttachShader") catch unreachable;
    T.glLinkProgram = loadOpenGLFunction(@TypeOf(T.glLinkProgram), "glLinkProgram") catch unreachable;
    T.glDeleteShader = loadOpenGLFunction(@TypeOf(T.glDeleteShader), "glDeleteShader") catch unreachable;
    T.glGenVertexArrays = loadOpenGLFunction(@TypeOf(T.glGenVertexArrays), "glGenVertexArrays") catch unreachable;
    T.glGenBuffers = loadOpenGLFunction(@TypeOf(T.glGenBuffers), "glGenBuffers") catch unreachable;
    T.glBindVertexArray = loadOpenGLFunction(@TypeOf(T.glBindVertexArray), "glBindVertexArray") catch unreachable;
    T.glBindBuffer = loadOpenGLFunction(@TypeOf(T.glBindBuffer), "glBindBuffer") catch unreachable;
    T.glBufferData = loadOpenGLFunction(@TypeOf(T.glBufferData), "glBufferData") catch unreachable;
    T.glVertexAttribPointer = loadOpenGLFunction(@TypeOf(T.glVertexAttribPointer), "glVertexAttribPointer") catch unreachable;
    T.glEnableVertexAttribArray = loadOpenGLFunction(@TypeOf(T.glEnableVertexAttribArray), "glEnableVertexAttribArray") catch unreachable;
    T.glUseProgram = loadOpenGLFunction(@TypeOf(T.glUseProgram), "glUseProgram") catch unreachable;
    T.glClearColor = loadOpenGLFunction(@TypeOf(T.glClearColor), "glClearColor") catch unreachable;
    T.glClear = loadOpenGLFunction(@TypeOf(T.glClear), "glClear") catch unreachable;
    T.glDrawArrays = loadOpenGLFunction(@TypeOf(T.glDrawArrays), "glDrawArrays") catch unreachable;
    T.glViewport = loadOpenGLFunction(@TypeOf(T.glViewport), "glViewport") catch unreachable;
}
