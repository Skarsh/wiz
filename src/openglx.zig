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

pub fn glGenVertexArrays(a: GLsizei, b: [*c]GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glDeleteVertexArrays(a: GLsizei, b: [*c]const GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glGenBuffers(a: GLsizei, b: [*c]GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glDeleteBuffers(a: GLsizei, b: [*c]const GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glGenFramebuffers(a: GLsizei, b: [*c]GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glDeleteFramebuffers(a: GLsizei, b: [*c]GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glDeleteProgram(program: GLuint) callconv(.C) void {
    _ = program;
}

pub fn glGenRenderbuffers(a: GLsizei, b: [*c]GLuint) callconv(.C) void {
    _ = a;
    _ = b;
}

pub fn glBindVertexArray(array: GLuint) callconv(.C) void {
    _ = array;
}

pub fn glBindBuffer(target: KhrGLenum, buffer: GLuint) callconv(.C) void {
    _ = target;
    _ = buffer;
}

pub fn glBufferData(target: KhrGLenum, size: GLsizeiptr, data: ?*const anyopaque, usage: KhrGLenum) callconv(.C) void {
    _ = target;
    _ = size;
    _ = data;
    _ = usage;
}

pub fn glBindFramebuffer(target: KhrGLenum, framebuffer: GLuint) callconv(.C) void {
    _ = target;
    _ = framebuffer;
}

pub fn glFramebufferTexture2D(target: KhrGLenum, attachment: KhrGLenum, textarget: KhrGLenum, texture: GLuint, level: GLint) callconv(.C) void {
    _ = target;
    _ = attachment;
    _ = textarget;
    _ = texture;
    _ = level;
}

pub fn glBindRenderbuffer(target: KhrGLenum, renderbuffer: GLuint) callconv(.C) void {
    _ = target;
    _ = renderbuffer;
}

pub fn glRenderbufferStorage(target: KhrGLenum, internalformat: KhrGLenum, width: GLsizei, height: GLsizei) callconv(.C) void {
    _ = target;
    _ = internalformat;
    _ = width;
    _ = height;
}

pub fn glFramebufferRenderbuffer(target: KhrGLenum, attachment: KhrGLenum, renderbuffertarget: KhrGLenum, renderbuffer: GLuint) callconv(.C) void {
    _ = target;
    _ = attachment;
    _ = renderbuffertarget;
    _ = renderbuffer;
}

pub fn glCheckFramebufferStatus(target: KhrGLenum) callconv(.C) KhrGLenum {
    _ = target;
    return 0;
}

pub fn glVertexAttribPointer(index: GLuint, size: GLint, type_: KhrGLenum, normalized: GLboolean, stride: GLsizei, pointer: ?*const anyopaque) callconv(.C) void {
    _ = index;
    _ = size;
    _ = type_;
    _ = normalized;
    _ = stride;
    _ = pointer;
}

pub fn glEnableVertexAttribArray(index: GLuint) callconv(.C) void {
    _ = index;
}

pub fn glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) callconv(.C) void {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
}

pub fn glEnable(cap: KhrGLenum) callconv(.C) void {
    _ = cap;
}

pub fn glClearColor(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) callconv(.C) void {
    _ = r;
    _ = g;
    _ = b;
    _ = a;
}

pub fn glClear(mask: GLbitfield) callconv(.C) void {
    _ = mask;
}

pub fn glActiveTexture(texture: KhrGLenum) callconv(.C) void {
    _ = texture;
}

pub fn glDrawArrays(mode: KhrGLenum, first: GLint, count: GLsizei) callconv(.C) void {
    _ = mode;
    _ = first;
    _ = count;
}

pub fn glCreateShader(type_: KhrGLenum) callconv(.C) GLuint {
    _ = type_;
    return 0;
}

pub fn glShaderSource(shader: GLuint, count: GLsizei, string: [*c]const [*c]const GLchar, length: [*c]const GLint) callconv(.C) void {
    _ = shader;
    _ = count;
    _ = string;
    _ = length;
}

pub fn glCompileShader(shader: GLuint) callconv(.C) void {
    _ = shader;
}

pub fn glAttachShader(program: GLuint, shader: GLuint) callconv(.C) void {
    _ = program;
    _ = shader;
}

pub fn glCreateProgram() callconv(.C) GLuint {
    return 0;
}

pub fn glLinkProgram(program: GLuint) callconv(.C) void {
    _ = program;
}

pub fn glDeleteShader(shader: GLuint) callconv(.C) void {
    _ = shader;
}

pub fn glUseProgram(program: GLuint) callconv(.C) void {
    _ = program;
}

pub fn glGetUniformLocation(program: GLuint, name: [*c]const GLchar) callconv(.C) GLint {
    _ = program;
    _ = name;
    return 0;
}

pub fn glUniform1i(location: GLint, v0: GLint) callconv(.C) void {
    _ = location;
    _ = v0;
}

pub fn glUniform1f(location: GLint, v0: GLfloat) callconv(.C) void {
    _ = location;
    _ = v0;
}

pub fn glUniform3f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) callconv(.C) void {
    _ = location;
    _ = v0;
    _ = v1;
    _ = v2;
}

pub fn glUniform3fv(location: GLint, count: GLsizei, value: [*c]const GLfloat) callconv(.C) void {
    _ = location;
    _ = count;
    _ = value;
}

pub fn glUniformMatrix4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: [*c]const GLfloat) callconv(.C) void {
    _ = location;
    _ = count;
    _ = transpose;
    _ = value;
}

pub fn glGetShaderiv(shader: GLuint, pname: KhrGLenum, params: [*c]GLint) callconv(.C) void {
    _ = shader;
    _ = pname;
    _ = params;
}

pub fn glGetShaderInfoLog(shader: GLuint, bufSize: GLsizei, length: [*c]GLsizei, infoLog: [*c]GLchar) callconv(.C) void {
    _ = shader;
    _ = bufSize;
    _ = length;
    _ = infoLog;
}

pub fn glGetProgramiv(program: GLuint, pname: KhrGLenum, params: [*c]GLint) callconv(.C) void {
    _ = program;
    _ = pname;
    _ = params;
}

pub fn glGetProgramInfoLog(program: GLuint, bufSize: GLsizei, length: [*c]GLsizei, infoLog: [*c]GLchar) callconv(.C) void {
    _ = program;
    _ = bufSize;
    _ = length;
    _ = infoLog;
}

pub fn glGenTextures(n: GLsizei, textures: [*c]GLuint) callconv(.C) void {
    _ = n;
    _ = textures;
}

pub fn glBindTexture(target: KhrGLenum, texture: GLuint) callconv(.C) void {
    _ = target;
    _ = texture;
}

pub fn glTexImage2D(target: KhrGLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: KhrGLenum, type_: KhrGLenum, pixels: ?*const anyopaque) callconv(.C) void {
    _ = target;
    _ = level;
    _ = internalformat;
    _ = width;
    _ = height;
    _ = border;
    _ = format;
    _ = type_;
    _ = pixels;
}

pub fn glTexParameteri(target: KhrGLenum, pname: KhrGLenum, param: GLint) callconv(.C) void {
    _ = target;
    _ = pname;
    _ = param;
}

pub fn glGenerateMipmap(target: KhrGLenum) callconv(.C) void {
    _ = target;
}

pub fn glGetError() callconv(.C) KhrGLenum {
    return 0;
}

pub const OpenGL = struct {
    glGenVertexArrays: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glGenVertexArrays,
    glDeleteVertexArrays: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = glDeleteVertexArrays,
    glGenBuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glGenBuffers,
    glDeleteBuffers: *const fn (GLsizei, [*c]const GLuint) callconv(.C) void = glDeleteBuffers,
    glGenFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glGenFramebuffers,
    glDeleteFramebuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glDeleteFramebuffers,
    glDeleteProgram: *const fn (GLuint) callconv(.C) void = glDeleteProgram,
    glGenRenderbuffers: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glGenRenderbuffers,
    glBindVertexArray: *const fn (GLuint) callconv(.C) void = glBindVertexArray,
    glBindBuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = glBindBuffer,
    glBufferData: *const fn (KhrGLenum, stride: GLsizeiptr, ?*const anyopaque, KhrGLenum) callconv(.C) void = glBufferData,
    glBindFramebuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = glBindFramebuffer,
    glFramebufferTexture2D: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint, GLint) callconv(.C) void = glFramebufferTexture2D,
    glBindRenderbuffer: *const fn (KhrGLenum, GLuint) callconv(.C) void = glBindRenderbuffer,
    glRenderbufferStorage: *const fn (KhrGLenum, KhrGLenum, GLsizei, GLsizei) callconv(.C) void = glRenderbufferStorage,
    glFramebufferRenderbuffer: *const fn (KhrGLenum, KhrGLenum, KhrGLenum, GLuint) callconv(.C) void = glFramebufferRenderbuffer,
    glCheckFramebufferStatus: *const fn (KhrGLenum) callconv(.C) KhrGLenum = glCheckFramebufferStatus,
    glVertexAttribPointer: *const fn (GLuint, size: GLint, KhrGLenum, GLboolean, stride: GLsizei, pointer: ?*const anyopaque) callconv(.C) void = glVertexAttribPointer,
    glEnableVertexAttribArray: *const fn (GLuint) callconv(.C) void = glEnableVertexAttribArray,
    glViewport: *const fn (GLint, GLint, GLsizei, GLsizei) callconv(.C) void = glViewport,
    glEnable: *const fn (KhrGLenum) callconv(.C) void = glEnable,
    glClearColor: *const fn (GLfloat, GLfloat, GLfloat, GLfloat) callconv(.C) void = glClearColor,
    glClear: *const fn (GLbitfield) callconv(.C) void = glClear,
    glActiveTexture: *const fn (KhrGLenum) callconv(.C) void = glActiveTexture,
    glDrawArrays: *const fn (KhrGLenum, GLint, GLsizei) callconv(.C) void = glDrawArrays,
    glCreateShader: *const fn (KhrGLenum) callconv(.C) GLuint = glCreateShader,
    glShaderSource: *const fn (GLuint, GLsizei, [*c]const [*c]const GLchar, [*c]const GLint) callconv(.C) void = glShaderSource,
    glCompileShader: *const fn (GLuint) callconv(.C) void = glCompileShader,
    glAttachShader: *const fn (GLuint, GLuint) callconv(.C) void = glAttachShader,
    glCreateProgram: *const fn () callconv(.C) GLuint = glCreateProgram,
    glLinkProgram: *const fn (GLuint) callconv(.C) void = glLinkProgram,
    glDeleteShader: *const fn (GLuint) callconv(.C) void = glDeleteShader,
    glUseProgram: *const fn (GLuint) callconv(.C) void = glUseProgram,
    glGetUniformLocation: *const fn (GLuint, [*c]const GLchar) callconv(.C) GLint = glGetUniformLocation,
    glUniform1i: *const fn (GLint, GLint) callconv(.C) void = glUniform1i,
    glUniform1f: *const fn (GLint, GLfloat) callconv(.C) void = glUniform1f,
    glUniform3f: *const fn (GLint, GLfloat, GLfloat, GLfloat) callconv(.C) void = glUniform3f,
    glUniform3fv: *const fn (GLint, GLsizei, [*c]const GLfloat) callconv(.C) void = glUniform3fv,
    glUniformMatrix4fv: *const fn (GLint, GLsizei, GLboolean, [*c]const GLfloat) callconv(.C) void = glUniformMatrix4fv,
    glGetShaderiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = glGetShaderiv,
    glGetShaderInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = glGetShaderInfoLog,
    glGetProgramiv: *const fn (GLuint, KhrGLenum, [*c]GLint) callconv(.C) void = glGetProgramiv,
    glGetProgramInfoLog: *const fn (GLuint, GLsizei, [*c]GLsizei, [*c]GLchar) callconv(.C) void = glGetProgramInfoLog,
    glGenTextures: *const fn (GLsizei, [*c]GLuint) callconv(.C) void = glGenTextures,
    glBindTexture: *const fn (KhrGLenum, GLuint) callconv(.C) void = glBindTexture,
    glTexImage2D: *const fn (KhrGLenum, GLint, GLint, GLsizei, GLsizei, GLint, KhrGLenum, KhrGLenum, ?*const anyopaque) callconv(.C) void = glTexImage2D,
    glTexParameteri: *const fn (KhrGLenum, KhrGLenum, GLint) callconv(.C) void = glTexParameteri,
    glGenerateMipmap: *const fn (KhrGLenum) callconv(.C) void = glGenerateMipmap,
    glGetError: *const fn () callconv(.C) KhrGLenum = glGetError,
};
