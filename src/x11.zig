const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @import("input.zig");
const EventQueue = input.EventQueue;

const wiz = @import("wiz.zig");

const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/keysymdef.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("GL/glx.h");
});

pub var glXCreateContextAttribsARB: ?*const fn (
    display: ?*c.Display,
    fbconfig: c.GLXFBConfig,
    shareContext: c.GLXContext,
    direct: c.Bool,
    attribList: [*:0]const c_int,
) c.GLXContext = null;

pub const Window = struct {
    allocator: Allocator,
    window_data: *wiz.WindowData,
    //display: *c.Display,
    display: ?*anyopaque,
    //window_id: c.Window,
    window_id: c_ulong,
    width: i32,
    height: i32,
    name: []const u8,
    running: bool,
    capture_cursor: bool,
    raw_mouse_motion: bool,
    is_vsync: bool,
    event_queue: EventQueue,
    keycodes: [256]u16,
    scancodes: [@intFromEnum(input.Key.key_last)]u16,
    gl_context: ?*anyopaque,
    visual: ?*anyopaque,

    pub fn init(
        allocator: Allocator,
        window_data: *wiz.WindowData,
        width: i32,
        height: i32,
        window_format: wiz.WindowFormat,
        comptime name: []const u8,
    ) !*Window {
        var window = try allocator.create(Window);

        window.allocator = allocator;
        window.window_data = window_data;
        window.width = width;
        window.height = height;
        window.name = name;
        window.running = true;

        const event_queue_size: usize = 1000;
        window.event_queue = try EventQueue.init(allocator, event_queue_size);

        _ = window_format;

        const display = c.XOpenDisplay(null);
        if (display == null) {
            std.log.err("Could not open display", .{});
            return error.CouldNotOpenDisplay;
        }

        window.display = display.?;

        const screen = c.DefaultScreenOfDisplay(display);
        _ = screen;
        const screen_id = c.DefaultScreen(display);

        // Check GLX version
        var major_glx: i32 = 0;
        var minor_glx: i32 = 0;

        _ = c.glXQueryVersion(@ptrCast(display), &major_glx, &minor_glx);
        // TODO(Thomas): This should be dependent on some backend options that we'll
        // pass in at some point in the future. If the backend is software then this does
        // not make sense. If the backend requires higher versions, then that's what we should
        // check against instead of this.
        if (major_glx <= 1 and minor_glx < 2) {
            std.log.err("GLX 1.2 or greater is required.\n", .{});
            _ = c.XCloseDisplay(@ptrCast(display));
            window.running = false;
            return error.IncorrectGLXVersion;
        } else {
            // Client
            std.log.info("GLX client version: {s}", .{c.glXGetClientString(@ptrCast(display), c.GLX_VERSION)});
            std.log.info("GLX client vendor: {s}", .{c.glXGetClientString(@ptrCast(display), c.GLX_VENDOR)});
            std.log.info("GLX client extensions:\n\t {s}", .{c.glXGetClientString(@ptrCast(display), c.GLX_EXTENSIONS)});

            // Server
            std.log.info("GLX server version: {s}\n", .{c.glXQueryServerString(@ptrCast(display), screen_id, c.GLX_VERSION)});
            std.log.info("GLX server vendor: {s}\n", .{c.glXQueryServerString(@ptrCast(display), screen_id, c.GLX_VENDOR)});
            std.log.info("GLX server extensions:\n\t {s}", .{c.glXQueryServerString(@ptrCast(display), screen_id, c.GLX_EXTENSIONS)});
        }

        var glx_attribs = [_]i32{
            c.GLX_X_RENDERABLE,  c.True,
            c.GLX_DRAWABLE_TYPE, c.GLX_WINDOW_BIT,
            c.GLX_RENDER_TYPE,   c.GLX_RGBA_BIT,
            c.GLX_X_VISUAL_TYPE, c.GLX_TRUE_COLOR,
            c.GLX_RED_SIZE,      8,
            c.GLX_GREEN_SIZE,    8,
            c.GLX_BLUE_SIZE,     8,
            c.GLX_ALPHA_SIZE,    8,
            c.GLX_STENCIL_SIZE,  8,
            c.GLX_DOUBLEBUFFER,  c.True,
            c.None,
        };

        const best_fbc_config = try findBestFBConfig(@ptrCast(display), screen_id, &glx_attribs);

        const visual = c.glXGetVisualFromFBConfig(@ptrCast(display), best_fbc_config);
        if (visual == 0) {
            std.log.err("Could not create correct visual window.\n", .{});
            _ = c.XCloseDisplay(@ptrCast(display));
            window.running = false;
            return error.IncorrectVisualWindow;
        }
        window.visual = visual;

        if (screen_id != visual.*.screen) {
            std.log.err("screen_id({}) does not match visual.screen({})", .{ screen_id, visual.*.screen });
            _ = c.XCloseDisplay(@ptrCast(display));
            window.running = false;
            return error.NonMatchingScreenIdWithVisualScreen;
        }

        // Open the window
        var window_attribs = c.XSetWindowAttributes{
            .border_pixel = c.BlackPixel(display, screen_id),
            .background_pixel = c.WhitePixel(display, screen_id),
            .override_redirect = @intFromBool(true),
            .colormap = c.XCreateColormap(@ptrCast(display), c.RootWindow(display, screen_id), visual.*.visual, c.AllocNone),
            .event_mask = c.ExposureMask,
        };

        const x_window = c.XCreateWindow(
            @ptrCast(display),
            c.RootWindow(display, screen_id),
            0,
            0,
            @intCast(width),
            @intCast(height),
            0,
            visual.*.depth,
            c.InputOutput,
            visual.*.visual,
            c.CWBackPixel | c.CWColormap | c.CWBorderPixel | c.CWEventMask,
            &window_attribs,
        );

        const key_mask = c.KeyPressMask | c.KeyReleaseMask;
        const button_mask = c.ButtonPressMask | c.ButtonReleaseMask;
        const window_mask = c.EnterWindowMask | c.LeaveWindowMask;
        _ = c.XSelectInput(
            display,
            x_window,
            key_mask | c.KeymapStateMask | c.PointerMotionMask | button_mask | window_mask | c.ExposureMask,
        );

        // Name the window
        _ = c.XStoreName(display, x_window, @ptrCast(name));

        window.window_id = x_window;

        // Create GLX OpenGL context

        glXCreateContextAttribsARB = @as(
            @TypeOf(glXCreateContextAttribsARB),
            @ptrCast(@alignCast(c.glXGetProcAddress("glXCreateContextAttribsARB"))),
        );

        const glxExts = c.glXQueryExtensionsString(@ptrCast(display), screen_id);
        std.log.info("Late extensions:\n\t{s}\n\t", .{glxExts});
        if (glXCreateContextAttribsARB == null) {
            std.log.err("glxCreateContextAttribsARB() not found.\n", .{});
        }

        const context_attribs = [_]i32{
            c.GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
            c.GLX_CONTEXT_MINOR_VERSION_ARB, 2,
            c.GLX_CONTEXT_FLAGS_ARB,         c.GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB,
            c.None,
        };

        var context: c.GLXContext = null;

        if (isExtensionSupported(glxExts, "GLX_ARB_create_context")) {
            context = c.glXCreateNewContext(display, best_fbc_config, c.GLX_RGBA_TYPE, null, c.True);
        } else {
            // TODO(Thomas): the glxCreateXontextAttribsARB seems to be broken here. Need to be verified and tested properly.
            context = glXCreateContextAttribsARB.?(@ptrCast(display), best_fbc_config, null, c.True, @ptrCast(&context_attribs));
        }

        window.gl_context = context;

        _ = c.XSync(@ptrCast(display), c.False);

        if (c.glXIsDirect(@ptrCast(display), context) == 0) {
            std.log.info("Indirect GLX rendering context obtained", .{});
        } else {
            std.log.info("Direct GLX rendering context obtained", .{});
        }

        _ = c.glXMakeCurrent(@ptrCast(display), x_window, context);

        std.log.info("GL Vendor: {s}\n", .{c.glGetString(c.GL_VENDOR)});
        std.log.info("GL Renderer: {s}\n", .{c.glGetString(c.GL_RENDERER)});
        std.log.info("GL Version: {s}\n", .{c.glGetString(c.GL_VERSION)});
        std.log.info("GL Shading Language: {s}\n", .{c.glGetString(c.GL_SHADING_LANGUAGE_VERSION)});

        // Show the window
        _ = c.XClearWindow(display, x_window);
        _ = c.XMapRaised(display, x_window);

        return window;
    }

    pub fn deinit(self: Window) void {
        //self.allocator.destroy(self.event_queue);

        // Cleanup GLX
        // TODO(Thomas): Not entirely sure how to do this yet.
        //c.glXDestroyWindow(@ptrCast(self.display), ????);

        // Cleanup X11
        _ = c.XFree(self.visual);

        // TODO(Thomas): Not entirely sure how to do this yet.
        //_ = c.XFreeColormap(@ptrCast(self.display), ?????);
        _ = c.XDestroyWindow(@ptrCast(self.display), self.window_id);
        _ = c.XCloseDisplay(@ptrCast(self.display));
    }

    pub fn makeModernOpenGLContext(self: *Window) !void {
        _ = self;
    }

    pub fn setVSync(self: *Window, value: bool) !void {
        _ = self;
        _ = value;
    }

    pub fn windowShouldClose(self: *Window, value: bool) void {
        self.running = !value;
    }

    pub fn toggleFullscreen(self: *Window) !void {
        _ = self;
    }

    pub fn setCaptureCursor(self: *Window, value: bool) !void {
        _ = self;
        _ = value;
    }

    pub fn enableRawMouseMotion(self: *Window) void {
        _ = self;
    }

    pub fn disableRawMouseMotion(self: *Window) void {
        _ = self;
    }

    pub fn swapBuffers(self: *Window) !void {
        c.glXSwapBuffers(@ptrCast(self.display), self.window_id);
    }

    pub fn processMessages(self: *Window) !void {
        _ = c.XPending(@ptrCast(self.display));
        while (c.QLength(self.display) != 0) {
            var x_event = std.mem.zeroes(c.XEvent);
            _ = c.XNextEvent(@ptrCast(self.display), &x_event);
            switch (x_event.type) {
                c.ButtonPress => {
                    const button = xButtonToWizButton(x_event.xbutton);
                    if (button) |val| {
                        const event = input.Event{
                            .MouseButtonDown = .{
                                .button = val,
                                .x = @intCast(x_event.xbutton.x),
                                .y = @intCast(x_event.xbutton.y),
                            },
                        };
                        self.event_queue.enqueue(event);
                    }
                },
                c.ButtonRelease => {
                    const button = xButtonToWizButton(x_event.xbutton);
                    if (button) |val| {
                        const event = input.Event{
                            .MouseButtonUp = .{
                                .button = val,
                                .x = @intCast(x_event.xbutton.x),
                                .y = @intCast(x_event.xbutton.y),
                            },
                        };
                        self.event_queue.enqueue(event);
                    }
                },

                c.KeyPress => {
                    const keysym = c.XKeycodeToKeysym(@ptrCast(self.display), @intCast(x_event.xkey.keycode), 0);
                    const key = translateX11KeyToWizKey(keysym);
                    if (key) |val| {
                        const event = input.Event{ .KeyDown = input.KeyEvent{ .scancode = @intFromEnum(val) } };
                        self.event_queue.enqueue(event);
                    }
                },
                c.KeyRelease => {
                    const keysym = c.XKeycodeToKeysym(@ptrCast(self.display), @intCast(x_event.xkey.keycode), 0);
                    const key = translateX11KeyToWizKey(keysym);
                    if (key) |val| {
                        const event = input.Event{ .KeyUp = input.KeyEvent{ .scancode = @intFromEnum(val) } };
                        self.event_queue.enqueue(event);
                    }
                },
                else => {},
            }
        }

        _ = c.XFlush(@ptrCast(self.display));
    }

    pub fn createKeyTables(self: *Window) void {
        // TODO(Thomas): Add check for xkb availability

        const desc = c.XkbGetMap(@ptrCast(self.display), 0, c.XkbUseCoreKbd);
        c.XkbGetNames(@ptrCast(self.display), c.XkbKeyNamesMask | c.XkbKeyAliasesMask, desc);
    }
};

fn xButtonToWizButton(x_button_event: c.XButtonEvent) ?input.MouseButton {
    const button: ?input.MouseButton = switch (x_button_event.button) {
        1 => .left,
        2 => .middle,
        3 => .right,
        4 => .wheel_up,
        5 => .wheel_down,

        // TODO(Thomas): These don't seem to work
        //6 => .nav_backward,
        //7 => .nav_forward,
        else => null,
    };
    return button;
}

test "XButtonToWizButtonTest" {
    var x_button = std.mem.zeroes(c.XButtonEvent);
    var wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(null, wiz_button);

    x_button.button = 1;
    wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(.left, wiz_button);

    x_button.button = 2;
    wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(.middle, wiz_button);

    x_button.button = 3;
    wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(.right, wiz_button);

    x_button.button = 4;
    wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(.wheel_up, wiz_button);

    x_button.button = 5;
    wiz_button = xButtonToWizButton(x_button);
    try std.testing.expectEqual(.wheel_down, wiz_button);
}

// TODO(Thomas): Translating to scancodes for now, but this probably should
// be mapped to our own WizKey type or something similar.
// NOTE(Thomas): Not completed due to waiting to figure out how to solve this properly
pub fn translateX11KeyToWizKey(keysym: c.KeySym) ?input.Key {
    const result = switch (keysym) {
        c.XK_a => input.Key.key_a,
        c.XK_b => input.Key.key_b,
        c.XK_c => input.Key.key_c,
        c.XK_d => input.Key.key_d,
        c.XK_e => input.Key.key_e,
        c.XK_f => input.Key.key_f,
        c.XK_g => input.Key.key_g,
        c.XK_h => input.Key.key_h,
        c.XK_i => input.Key.key_i,
        c.XK_j => input.Key.key_j,
        c.XK_k => input.Key.key_k,
        c.XK_l => input.Key.key_l,
        c.XK_m => input.Key.key_m,
        c.XK_n => input.Key.key_n,
        c.XK_o => input.Key.key_o,
        c.XK_p => input.Key.key_p,
        c.XK_q => input.Key.key_q,
        c.XK_r => input.Key.key_r,
        c.XK_s => input.Key.key_s,
        c.XK_t => input.Key.key_t,
        c.XK_u => input.Key.key_u,
        c.XK_v => input.Key.key_v,
        c.XK_w => input.Key.key_w,
        c.XK_x => input.Key.key_x,
        c.XK_y => input.Key.key_y,
        c.XK_z => input.Key.key_z,
        c.XK_1 => input.Key.key_1,
        c.XK_2 => input.Key.key_2,
        c.XK_3 => input.Key.key_3,
        c.XK_4 => input.Key.key_4,
        c.XK_5 => input.Key.key_5,
        c.XK_6 => input.Key.key_6,
        c.XK_7 => input.Key.key_7,
        c.XK_8 => input.Key.key_8,
        c.XK_9 => input.Key.key_9,
        c.XK_0 => input.Key.key_0,
        c.XK_Return => input.Key.key_return,
        c.XK_Escape => input.Key.key_escape,
        else => return null,
    };

    return result;
}

fn isExtensionSupported(ext_list: [*c]const u8, extension: []const u8) bool {
    // Use span here to convert from [*c]const u8 to []const u8
    // which makes it easy to split on the whitespace delimiter and then compare.
    const extensions = std.mem.span(ext_list);
    var extensions_it = std.mem.split(u8, extensions, " ");
    while (extensions_it.next()) |ext| {
        if (std.mem.eql(u8, ext, extension)) {
            return true;
        }
    }

    return false;
}

test "isExtensionSupported" {
    const extensions: [*c]const u8 =
        \\GLX_ARB_get_proc_address GLX_ARB_multisample GLX_EXT_visual_info GLX_EXT_visual_rating GLX_EXT_import_context GLX_SGI_video_sync GLX_SGIX_fbconfig GLX_SGIX_pbuffer GLX_SGI_swap_control GLX_EXT_swap_control GLX_EXT_swap_control_tear GLX_EXT_buffer_age GLX_ARB_create_context GLX_ARB_create_context_profile GLX_NV_float_buffer GLX_ARB_fbconfig_float GLX_EXT_texture_from_pixmap GLX_EXT_framebuffer_sRGB GLX_NV_copy_image GLX_EXT_create_context_es_profile GLX_EXT_create_context_es2_profile GLX_ARB_create_context_no_error GLX_ARB_create_context_robustness GLX_NV_delay_before_swap GLX_EXT_stereo_tree GLX_ARB_context_flush_control GLX_NV_robustness_video_memory_purge GLX_NV_multigpu_context \0GLX_EXT_not_a_real_ext
    ;

    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_get_proc_address"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_multisample"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_visual_info"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_visual_rating"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_import_context"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_SGI_video_sync"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_SGIX_fbconfig"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_SGIX_pbuffer"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_SGI_swap_control"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_swap_control"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_swap_control_tear"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_buffer_age"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_create_context"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_create_context_profile"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_NV_float_buffer"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_fbconfig_float"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_texture_from_pixmap"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_framebuffer_sRGB"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_NV_copy_image"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_create_context_es_profile"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_create_context_es2_profile"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_create_context_no_error"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_create_context_robustness"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_NV_delay_before_swap"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_EXT_stereo_tree"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_ARB_context_flush_control"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_NV_robustness_video_memory_purge"));
    try std.testing.expect(isExtensionSupported(extensions, "GLX_NV_multigpu_context"));

    try std.testing.expect(!isExtensionSupported(extensions, "GLX_EXT_not_a_real_ext"));
}

fn findBestFBConfig(display: ?*c.Display, screen_id: i32, glx_attribs: [*c]i32) !c.GLXFBConfig {
    var fbcount: i32 = 0;

    const fbc = c.glXChooseFBConfig(display, screen_id, glx_attribs, &fbcount);
    defer _ = c.XFree(fbc.*.?); // Make sure to free this!

    if (fbc == null) {
        std.log.err("Failed to retrieve framebuffer.\n", .{});
        _ = c.XCloseDisplay(@ptrCast(display));
        return error.FailedToRetrieveFramebuffer;
    }

    std.log.info("Found {} matching framebuffers.\n", .{fbcount});

    // TODO(Thomas): This whole picking FB config/visual thing should be redone in a more robust way
    // Pick the FB config/visual with the most sampels per pixel
    std.log.info("Getting best XVisualInfo\n", .{});
    var best_fbc: i32 = -1;
    var wors_fbc: i32 = -1;
    var best_num_samp: i32 = -1;
    var worst_num_samp: i32 = 999;

    for (0..@intCast(fbcount)) |i| {
        const vi = c.glXGetVisualFromFBConfig(@ptrCast(display), fbc[i].?);
        if (vi != 0) {
            var samp_buf: i32 = 0;
            var samples: i32 = 0;
            _ = c.glXGetFBConfigAttrib(@ptrCast(display), fbc[i], c.GLX_SAMPLE_BUFFERS, &samp_buf);
            _ = c.glXGetFBConfigAttrib(@ptrCast(display), fbc[i], c.GLX_SAMPLES, &samples);

            if (best_fbc < 0 or (samp_buf == c.True and samples > best_num_samp)) {
                best_fbc = @intCast(i);
                best_num_samp = samples;
            }

            if (wors_fbc < 0 or samp_buf == c.False or samples < worst_num_samp) {
                wors_fbc = @intCast(i);
            }
            worst_num_samp = samples;
        }
        _ = c.XFree(vi);
    }

    std.log.info("Best visual info index: {}\n", .{best_fbc});
    const best_fbc_config = fbc[@intCast(best_fbc)];

    return best_fbc_config;
}
