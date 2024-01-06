const std = @import("std");
const windows = std.os.windows;

const WINAPI = std.os.windows.WINAPI;

const GLenum = c_uint;
const GLboolean = u8;
const GLbitfield = c_uint;
const GLbyte = i8;
const GLshort = c_short;
const GLint = c_int;
const GLsizei = c_int;
const GLubyte = u8;
const GLushort = c_ushort;
const GLuint = c_uint;
const GLfloat = f32;
const GLclampf = f32;
const GLdouble = f64;
const GLclampd = f64;
const GLvoid = void;

pub const GL_VENDOR = 0x1F00;
pub const GL_RENDERER = 0x1F01;
pub const GL_VERSION = 0x1F02;
pub const GL_EXTENSIONS = 0x1F03;
pub const GL_COLOR_BUFFER_BIT = 0x00004000;

pub const GL_TRUE = 1;
pub const GL_FALSE = 0;

// TODO (Thomas): Make wrappers for these as been done in user32.zig
pub extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(WINAPI) ?windows.HGLRC;
pub extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
pub extern "opengl32" fn wglDeleteContext(hglrc: windows.HGLRC) callconv(WINAPI) windows.BOOL;
pub extern "opengl32" fn wglGetProcAddress(fn_name: windows.LPCSTR) callconv(WINAPI) ?windows.PVOID;
pub extern "opengl32" fn glGetString(name: GLenum) callconv(WINAPI) [*:0]u8;

pub extern "opengl32" fn glClear(mask: GLbitfield) callconv(WINAPI) void;
pub extern "opengl32" fn glClearColor(red: GLclampf, green: GLclampf, blue: GLclampf, alpha: GLclampf) callconv(WINAPI) void;
pub extern "opengl32" fn glViewport(x: i32, y: i32, width: i32, height: i32) callconv(WINAPI) void;
