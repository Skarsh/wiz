//pub var glClearColor: *const fn (f32, f32, f32, f32) callconv(.C) void = undefined;
//pub var glClear: *const fn (c_uint) callconv(.C) void = fn a{}void;

fn glClearColor(r: f32, g: f32, b: f32, a: f32) callconv(.C) void {
    _ = r;
    _ = g;
    _ = b;
    _ = a;
}

fn glClear(val: c_uint) callconv(.C) void {
    _ = val;
}

pub const OpenGL = struct {
    glClearColor: *const fn (f32, f32, f32, f32) callconv(.C) void = glClearColor,
    glClear: *const fn (c_uint) callconv(.C) void = undefined,
};
