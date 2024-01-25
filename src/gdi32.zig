const std = @import("std");
const windows = std.os.windows;
const BOOL = windows.BOOL;
const DWORD = windows.DWORD;
const WINAPI = windows.WINAPI;
const HDC = windows.HDC;
const HGLRC = windows.HGLRC;
const WORD = windows.WORD;
const BYTE = windows.BYTE;

pub const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: WORD = @sizeOf(PIXELFORMATDESCRIPTOR),
    nVersion: WORD,
    dwFlags: DWORD,
    iPixelType: BYTE,
    cColorBits: BYTE,
    cRedBits: BYTE,
    cRedShift: BYTE,
    cGreenBits: BYTE,
    cGreenShift: BYTE,
    cBlueBits: BYTE,
    cBlueShift: BYTE,
    cAlphaBits: BYTE,
    cAlphaShift: BYTE,
    cAccumBits: BYTE,
    cAccumRedBits: BYTE,
    cAccumGreenBits: BYTE,
    cAccumBlueBits: BYTE,
    cAccumAlphaBits: BYTE,
    cDepthBits: BYTE,
    cStencilBits: BYTE,
    cAuxBuffers: BYTE,
    iLayerType: BYTE,
    bReserved: BYTE,
    dwLayerMask: DWORD,
    dwVisibleMask: DWORD,
    dwDamageMask: DWORD,

    pub fn default() PIXELFORMATDESCRIPTOR {
        return PIXELFORMATDESCRIPTOR{
            .nVersion = 0,
            .dwFlags = 0,
            .iPixelType = 0,
            .cColorBits = 0,
            .cRedBits = 0,
            .cRedShift = 0,
            .cGreenBits = 0,
            .cGreenShift = 0,
            .cBlueBits = 0,
            .cBlueShift = 0,
            .cAlphaBits = 0,
            .cAlphaShift = 0,
            .cAccumBits = 0,
            .cAccumRedBits = 0,
            .cAccumGreenBits = 0,
            .cAccumBlueBits = 0,
            .cAccumAlphaBits = 0,
            .cDepthBits = 0,
            .cStencilBits = 0,
            .cAuxBuffers = 0,
            .iLayerType = 0,
            .bReserved = 0,
            .dwLayerMask = 0,
            .dwVisibleMask = 0,
            .dwDamageMask = 0,
        };
    }
};

pub const PFD_TYPE_RGBA: u8 = 0;
pub const PFD_DOUBLEBUFFER: u32 = 0x00000001;
pub const PFD_DRAW_TO_WINDOW: u32 = 0x00000004;
pub const PFD_SUPPORT_OPENGL: u32 = 0x00000020;

pub extern "gdi32" fn SetPixelFormat(
    hdc: ?HDC,
    format: i32,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(WINAPI) windows.BOOL;

pub fn setPixelFormat(hdc: ?HDC, format: windows.INT, ppfd: ?*const PIXELFORMATDESCRIPTOR) !void {
    if (SetPixelFormat(hdc, format, ppfd) == 0) {
        switch (windows.kernel32.GetLastError()) {
            .INVALID_PARAMETER => unreachable,
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub extern "gdi32" fn ChoosePixelFormat(
    hdc: ?HDC,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(WINAPI) windows.INT;

pub fn choosePixelFormat(hdc: ?HDC, ppfd: ?*const PIXELFORMATDESCRIPTOR) !i32 {
    const pfd = ChoosePixelFormat(hdc, ppfd);
    if (pfd == 0) {
        switch (windows.kernel32.GetLastError()) {
            .INVALID_PARAMETER => unreachable,
            else => |err| return windows.unexpectedError(err),
        }
    }
    return pfd;
}

pub extern "gdi32" fn DescribePixelFormat(
    hdc: ?HDC,
    iPixelFormat: windows.INT,
    nBytes: windows.INT,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(WINAPI) windows.INT;

pub fn describePixelFormat(
    hdc: ?HDC,
    iPixelFormat: windows.INT,
    nBytes: windows.INT,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) !i32 {
    const result = DescribePixelFormat(hdc, iPixelFormat, nBytes, ppfd);
    if (result == 0) {
        switch (windows.kernel32.GetLastError()) {
            .INVALID_PARAMETER => unreachable,
            else => |err| return windows.unexpectedError(err),
        }
    }
    return result;
}

pub extern "gdi32" fn SwapBuffers(hdc: ?HDC) callconv(WINAPI) bool;
pub extern "gdi32" fn wglCreateContext(hdc: ?HDC) callconv(WINAPI) ?HGLRC;
pub extern "gdi32" fn wglMakeCurrent(hdc: ?HDC, hglrc: ?HGLRC) callconv(WINAPI) bool;
