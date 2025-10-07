const std = @import("std");
const rl = @import("raylib");
const g = @import("game.zig");

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    cell_size: i32,
    grid_width: i32,
    grid_height: i32,
    game_state: g.Game,
    dead_color: rl.Color,
    alive_color: rl.Color,

    pub fn new() Renderer {
        return Renderer{
            .allocator = undefined,
            .cell_size = 0,
            .grid_width = 0,
            .grid_height = 0,
            .game_state = g.Game.new(),
            .dead_color = rl.colorFromHSV(210, 1.0, 1.0),
            .alive_color = rl.colorFromHSV(100, 1.0, 1.0),
        };
    }

    pub fn init(self: *Renderer, allocator: std.mem.Allocator, rows: i32, cols: i32, screen_width: i32, screen_height: i32) !void {
        self.allocator = allocator;
        self.dead_color = rl.colorFromHSV(210, 0.5, 0.9);
        self.alive_color = rl.colorFromHSV(100, 1.0, 0.9);
        if (@divFloor(screen_width, cols) < @divFloor(screen_height, rows)) {
            self.cell_size = @divFloor(screen_width, cols);
        } else {
            self.cell_size = @divFloor(screen_height, rows);
        }
        self.grid_width = self.cell_size * cols;
        self.grid_height = self.cell_size * rows;
        try self.game_state.init(allocator, @intCast(rows), @intCast(cols));
    }

    pub fn deinit(self: *Renderer) void {
        self.game_state.deinit();
    }

    pub fn update(self: *Renderer) void {
        self.game_state.update();
    }

    pub fn draw(self: *Renderer) void {
        std.debug.print("Drawing game state...\n", .{});
        for (0..@intCast(self.game_state.rows)) |r| {
            for (0..@intCast(self.game_state.cols)) |c| {
                const cell = self.game_state.cells[self.game_state.index(@intCast(r), @intCast(c))];
                const x = @as(i32, @intCast(c)) * self.cell_size;
                const y = @as(i32, @intCast(r)) * self.cell_size;
                var color = self.dead_color;
                if (cell == g.Cell.Alive) {
                    std.debug.print("Cell at ({}, {}) is alive\n", .{r, c});
                    color = self.alive_color;
                }
                rl.drawRectangle(x, y, self.cell_size - 1, self.cell_size - 1, color);
            }
        }
    }

    pub fn randomize(self: *Renderer) void {
        self.game_state.randomize();
    }
};

