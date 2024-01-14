const input = @import("input.zig");
pub const Event = input.Event;
pub const KeyEvent = input.KeyEvent;

const windows = @import("windows.zig");
pub const Window = windows.Window;
pub const WindowFormat = windows.WindowFormat;

pub const opengl32 = @import("opengl32.zig");

test {
    const std = @import("std");

    // TODO (Thomas): refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(input);
    std.testing.refAllDeclsRecursive(windows);
}
