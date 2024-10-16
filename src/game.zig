const std = @import("std");
const rl = @import("raylib");
const pretty = @import("pretty");

var GPAllocator = std.heap.GeneralPurposeAllocator(.{}){};

const GameState = struct {
    allocator: std.mem.Allocator,
};

pub export fn init() *anyopaque {
    rl.initWindow(1280, 720, "Zig Hot-Reload");
    rl.setWindowState(.{
        .window_resizable = true,
    });
    rl.setTargetFPS(rl.getMonitorRefreshRate(rl.getCurrentMonitor()));
    rl.setExitKey(.key_q);

    var allocator = GPAllocator.allocator();

    const game_state = allocator.create(GameState) catch @panic("Out of memory.");
    game_state.* = GameState{ .allocator = allocator };
    return game_state;
}

pub export fn reload(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    _ = game_state;
}

pub export fn update(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    _ = game_state;
}

pub export fn draw(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    _ = game_state;
    rl.clearBackground(rl.Color.ray_white);

    var buf: [256]u8 = undefined;
    const slice = std.fmt.bufPrintZ(
        &buf,
        "fps: {d}\ntime: {d:5.2}",
        .{ rl.getFPS(), rl.getTime() },
    ) catch "error";
    rl.drawText(slice, 10, 10, 20, rl.Color.black);
}
