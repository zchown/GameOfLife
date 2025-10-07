pub const std = @import("std");

pub const Cell = enum(u1) {
    Dead = 0,
    Alive = 1,
};

pub const Game = struct {
    alloc: std.mem.Allocator,
    rows: i32,
    cols: i32,
    cells: []Cell,

    pub fn new() Game {
        return Game{
            .alloc = undefined,
            .rows = 0,
            .cols = 0,
            .cells = &[_]Cell{},
        };
    }

    pub fn init(self: *Game, allocator: std.mem.Allocator, rows: i32, cols: i32) !void {
        self.alloc = allocator;
        self.rows = rows;
        self.cols = cols;
        const total_cells = (rows * cols);
        self.cells = try allocator.alloc(Cell, @intCast(total_cells));
        var rng: u64 = 0xdeadbeefdeadbeef;
        for (0..@intCast(total_cells)) |i| {
            rng = splitMix64(rng);
            if ((rng % 2) == 0) {
                self.cells[i] = Cell.Alive;
            } else {
                self.cells[i] = Cell.Dead;
            }
        }

    }

    pub fn deinit(self: *Game) void {
        self.alloc.free(self.cells);
    }

    pub fn randomize(self: *Game) void {
        var rng: u64 = 0xdeadbeefdeadbeef;
        for (0..@intCast(self.rows * self.cols)) |i| {
            rng = splitMix64(rng);
            if ((rng % 2) == 0) {
                self.cells[i] = Cell.Alive;
            }
        }
    }

    pub fn update(self: *Game) void {
        std.debug.print("Updating game state...\n", .{});
        var newCells: []Cell = self.alloc.alloc(Cell, @intCast(self.rows * self.cols)) catch {
            return;
        };
        for (0..@intCast(self.rows)) |r| {
            for (0..@intCast(self.cols)) |c| {
                const aliveNeighbors = self.countAliveNeighbors(@intCast(r), @intCast(c));
                const idx = self.index(@intCast(r), @intCast(c));
                switch (self.cells[idx]) {
                    Cell.Alive => {
                        if (aliveNeighbors < 2 or aliveNeighbors > 3) {
                            newCells[idx] = Cell.Dead;
                        } else {
                            newCells[idx] = Cell.Alive;
                        }
                    },
                    Cell.Dead => {
                        if (aliveNeighbors == 3) {
                            newCells[idx] = Cell.Alive;
                        } else {
                            newCells[idx] = Cell.Dead;
                        }
                    },
                }
            }
        }
        self.cells = newCells;
    }

    pub fn index(self: *Game, row: u32, col: u32) usize {
        return @as(usize, @as(usize, @intCast(row)) * @as(usize, @intCast(self.cols)) + @as(usize, @intCast(col)));
    }

    pub fn setCell(self: *Game, row: u32, col: u32, state: Cell) void {
        if (row < self.rows and col < self.cols) {
            self.cells[self.index(row, col)] = state;
        }
    }

    fn countAliveNeighbors(self: *Game, row: u32, col: u32) u8 {
        var count: u8 = 0;
        for ( 0..2) |pdr| {
            const dr: i32 = @as(i32, @intCast(pdr)) - 1;
            for ( 0..2) |pdc| {
                const dc: i32 = @as(i32, @intCast(pdc)) - 1;
                if (dr == 0 and dc == 0) continue;
                const newRow = @as(i32, @intCast(row)) + dr;
                const newCol = @as(i32, @intCast(col)) + dc;
                if (newRow >= 0 and newRow < self.rows and newCol >= 0 and newCol < self.cols) {
                    if (self.cells[self.index(@intCast(newRow), @intCast(newCol))] == Cell.Alive) {
                        count += 1;
                    }
                }
            }
        }
        return count;
    }
};

fn splitMix64(x: u64) u64 {
    var y = (x ^ (x >> 30)) *% 0xbf58476d1ce4e5b9;
    y = (y ^ (y >> 27)) *% 0x94d049bb133111eb;
    return y ^ (y >> 31);
}
