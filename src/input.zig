pub const EvenType = enum {
    WindowResized,
    WindowDestroyed,
    AppTerminated,
    KeyDown,
    KeyUp,
    MouseButtonDown,
    MouseButtonUp,
    MouseMotion,
};

pub const KeyEvent = struct {
    scancode: u32,
};

pub const MouseMotionEvent = struct {
    x: i16,
    y: i16,
};

pub const MouseButtonEvent = struct {
    x: i16,
    y: i16,
    button: MouseButton,
};

// TODO(Thomas) Many mouses has way more buttons than this,
// we need to support that aswell.
pub const MouseButton = enum(u8) {
    left = 1,
    middle = 2,
    right = 3,
    wheel_up = 4,
    wheel_down = 5,
    nav_backward = 6,
    nav_forward = 7,
    _,
};
