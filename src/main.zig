const std = @import("std");
const rl = @import("raylib");
// const gr = @import("gameRenderer.zig");

pub fn main() !void {
    const screenWidth = 1536;
    const screenHeight = 1536;

    rl.initWindow(screenWidth, screenHeight, "Conway's Game of Life");
    defer rl.closeWindow();

    // rl.setTargetFPS(60);

    const gridWidth = 1536;
    const gridHeight = 1536;

    var rtA = try rl.loadRenderTexture(gridWidth, gridHeight);
    var rtB = try rl.loadRenderTexture(gridWidth, gridHeight);
    defer rl.unloadRenderTexture(rtA);
    defer rl.unloadRenderTexture(rtB);

    rl.setTextureFilter(rtA.texture, rl.TextureFilter.point);
    rl.setTextureFilter(rtB.texture, rl.TextureFilter.point);

    const vsPath = "src/vertex.vs";
    const fsPath = "src/frag.fs";

    const shader = try rl.loadShader(vsPath, fsPath);
    defer rl.unloadShader(shader);
    if (shader.id == 0) {
        std.debug.print("Shader failed to load!\n", .{});
    }


    const locPrevState = rl.getShaderLocation(shader, "prevState");
    const locTexelSize = rl.getShaderLocation(shader, "texelSize");

    var image = rl.genImageColor(gridWidth, gridHeight, rl.Color.white);
    var random = @as(u64, @intCast(std.time.milliTimestamp()));
    random = splitMix64(random);

    for (0..gridWidth) |x| {
        for (0..gridHeight) |y| {
            random = splitMix64(random);
            const alive = (random % 16) == 0;
            const c = if (alive) rl.Color.white else rl.Color.black;
            rl.imageDrawPixel(&image, @intCast(x), @intCast(y), c);
        }
    }

    // save image to file for debugging
    _ = rl.exportImage(image, "initial_state.png");

    const texture = try rl.loadTextureFromImage(image);
    defer rl.unloadTexture(texture);
    rl.unloadImage(image);

    rl.beginTextureMode(rtA);
    rl.clearBackground(rl.Color.black);
    rl.drawTexture(texture, 0, 0, rl.Color.white);
    rl.endTextureMode();

    var cur = &rtA;
    var next = &rtB;

    
    while (!rl.windowShouldClose()) {
        const texelSize = [_]f32{1.0 / @as(f32, gridWidth), 1.0 / @as(f32, gridHeight)};
        rl.beginTextureMode(next.*);
        rl.clearBackground(rl.Color.black);

        rl.beginShaderMode(shader);
        rl.setShaderValueTexture(shader, locPrevState, cur.*.texture);
        rl.setShaderValue(shader, locTexelSize, &texelSize, rl.ShaderUniformDataType.vec2);
        
        rl.drawTextureRec(
            cur.*.texture,
            rl.Rectangle{ 
                .x = 0, 
                .y = 0, 
                .width = @as(f32, @floatFromInt(cur.*.texture.width)), 
                .height = -@as(f32, @floatFromInt(cur.*.texture.height)) 
            },
            rl.Vector2{ .x = 0, .y = 0 },
            rl.Color.white,
        );

        rl.endShaderMode();
        rl.endTextureMode();
        
        const tmp = cur;
        cur = next;
        next = tmp;

        rl.beginDrawing();
        rl.clearBackground(rl.Color.blue);
        rl.drawTextureRec(
            cur.*.texture,
            rl.Rectangle{ 
                .x = 0, 
                .y = 0, 
                .width = @as(f32, @floatFromInt(cur.*.texture.width)), 
                .height = -@as(f32, @floatFromInt(cur.*.texture.height)) 
            },
            rl.Vector2{ .x = 0, .y = 0 },
            rl.Color.white,
        );
        rl.drawFPS(10, 10);
        defer rl.endDrawing();

    }
}

fn splitMix64(x: u64) u64{
    var y = (x ^ (x >> 30)) *% 0xbf58476d1ce4e5b9;
    y = (y ^ (y >> 27)) *% 0x94d049bb133111eb;
    return y ^ (y >> 31);
}
