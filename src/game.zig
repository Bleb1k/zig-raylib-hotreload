const std = @import("std");
const rl = @import("raylib");
const pretty = @import("pretty");

var GPAllocator = std.heap.GeneralPurposeAllocator(.{}){};

const GameState = struct {
    allocator: std.mem.Allocator,
    radius: f32 = 0,
    screen_w: f32 = 0,
    screen_h: f32 = 0,
    grab_mouse: bool = false,
};
const config_filepath = "config/radius.txt";

pub export fn init() *anyopaque {
    rl.initWindow(1280, 720, "Zig Hot-Reload");
    rl.setWindowState(.{
        .window_resizable = true,
    });
    rl.setTargetFPS(rl.getMonitorRefreshRate(rl.getCurrentMonitor()));
    rl.setExitKey(.key_q);

    var allocator = GPAllocator.allocator();

    const game_state = allocator.create(GameState) catch @panic("Out of memory.");
    game_state.* = GameState{
        .allocator = allocator,
        .radius = 20,
        .screen_w = @floatFromInt(rl.getScreenWidth()),
        .screen_h = @floatFromInt(rl.getScreenHeight()),
        .grab_mouse = false,
    };
    return game_state;
}

pub export fn reload(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    game_state.radius = game_state.radius;
}

pub export fn update(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    game_state.radius = @mod(game_state.radius + rl.getFrameTime() * 50, 100.0);
    if (rl.isWindowResized()) {
        game_state.screen_w = @floatFromInt(rl.getScreenWidth());
        game_state.screen_h = @floatFromInt(rl.getScreenHeight());
    }

    if (rl.isMouseButtonPressed(.mouse_button_middle))
        game_state.grab_mouse = !game_state.grab_mouse;

    if (game_state.grab_mouse) rl.setMousePosition(@mod(@as(i32, @intFromFloat(rl.getTime() * 50.0)), @as(i32, @intFromFloat(game_state.screen_w))), @as(i32, @intFromFloat(game_state.screen_h / 2.0)));
}

pub export fn draw(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    rl.clearBackground(rl.Color.ray_white);

    var buf: [256]u8 = undefined;
    const slice = std.fmt.bufPrintZ(
        &buf,
        "time: {d:.02}, radius: {d:.02}",
        .{ rl.getTime(), game_state.radius },
    ) catch "error";
    rl.drawText(slice, 10, 10, 20, rl.Color.black);

    const circle_x: f32 = @mod(@as(f32, @floatCast(rl.getTime())) * 50.0, game_state.screen_w);
    rl.drawCircleV(.{ .x = circle_x, .y = game_state.screen_h / 2 }, game_state.radius, rl.Color.blue);
    rl.drawRectangleLinesEx(.{
        .x = 0,
        .y = 0,
        .width = game_state.screen_w,
        .height = game_state.screen_h,
    }, 10, rl.Color.black);
}
