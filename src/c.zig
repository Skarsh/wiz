const builtin = @import("builtin");

pub const c = if (builtin.os.tag == .linux) @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/keysymdef.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("GL/glx.h");
}) else @cImport({});
