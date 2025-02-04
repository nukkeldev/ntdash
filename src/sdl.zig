const std = @import("std");
const log = std.log;

pub const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
});

pub const Context = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,

    const E = Ret.Err;
    const W = Ret.Warn;
    const EM = Ret.ErrWithMsg;
    const WM = Ret.WarnWithMsg;

    pub fn new(title: []const u8, window_size: struct { u32, u32 }, config: Config) !Context {
        // Bypass the requirement for the entrypoint to be "SDL_main".
        c.SDL_SetMainReady();

        // Initialize SDL with the configured flags, only video by default.
        try E(c.SDL_Init(config.initialization_flags), "Init");

        // Create the window with the supplied title and the renderer
        const window: *c.SDL_Window, const renderer: *c.SDL_Renderer = create_window_and_renderer: {
            var window: ?*c.SDL_Window = null;
            var renderer: ?*c.SDL_Renderer = null;
            try E(
                c.SDL_CreateWindowAndRenderer(
                    @ptrCast(title),
                    @intCast(window_size[0]),
                    @intCast(window_size[1]),
                    0,
                    &window,
                    &renderer,
                ),
                "CreateWindowAndRenderer",
            );

            break :create_window_and_renderer .{ window.?, renderer.? };
        };

        return .{ .window = window, .renderer = renderer };
    }

    // Hints

    pub fn setHint(_: *Context, name: []const u8, value: []const u8) void {
        WM(
            c.SDL_SetHint(@ptrCast(name), @ptrCast(value)),
            "Failed to set hint '{s}' to '{s}'!",
            .{ name, value },
        );
    }

    // Graphics

    /// Clears the window with a color.
    pub fn clear(self: *Context, color: Color) !void {
        // Set the renderer's draw color
        if (!c.SDL_SetRenderDrawColor(
            self.renderer,
            color.red,
            color.blue,
            color.green,
            color.alpha,
        )) {
            log.err("Failed to ", .{});
        }

        // Clear the screen with the draw color
        _ = c.SDL_RenderClear(self.renderer);
    }

    /// Presents the rendered graphics since the last call on the window.
    pub fn present(self: *Context) !void {
        if (!c.SDL_RenderPresent(self.renderer)) {
            log.err(
                "Failed to present rendered graphics to the window! Error: {s}",
                .{c.SDL_GetError()},
            );
            return error.SDLError;
        }
    }

    // Destroy

    pub fn quit(self: *Context) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);

        c.SDL_Quit();
    }

    // Structs

    pub const Config = struct {
        initialization_flags: c.SDL_InitFlags = c.SDL_INIT_VIDEO,
        window_flags: c.SDL_WindowFlags = 0,
    };
};

pub const Color = packed struct {
    red: u8,
    green: u8,
    blue: u8,
    alpha: u8 = 0xff,

    pub const BLACK: Color = .{ .red = 0, .green = 0, .blue = 0 };
    pub const WHITE: Color = .{ .red = 0xff, .green = 0xff, .blue = 0xff };
};

pub const Ret = struct {
    fn _Ret(ret: bool, out: fn (comptime []const u8, anytype) void, comptime msg: []const u8, args: anytype) !void {
        if (!ret) {
            out(msg ++ " SDL Error: {s}", args ++ .{c.SDL_GetError()});
            return error.SDLError;
        }
    }

    pub fn Err(ret: bool, @"fn": []const u8) !void {
        return _Ret(ret, log.err, "Failed to call '{s}'!", .{@"fn"});
    }

    pub fn Warn(ret: bool, @"fn": []const u8) void {
        _ = _Ret(ret, log.warn, "Failed to call '{s}'!", .{@"fn"}) catch {};
    }

    pub fn ErrWithMsg(ret: bool, comptime msg_fmt: []const u8, args: anytype) !void {
        return _Ret(ret, log.err, msg_fmt, args);
    }

    pub fn WarnWithMsg(ret: bool, comptime msg_fmt: []const u8, args: anytype) void {
        _ = _Ret(ret, log.warn, msg_fmt, args) catch {};
    }

    // Tests

    test "expected formatting" {
        const eql = std.testing.expectEqual;
        try eql(@typeName(@TypeOf(c.SDL_Init)), "SDL_Init");
    }
};

test {
    _ = Ret;
}
