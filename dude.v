`timescale 1ns / 1ps

module dude(
    input  wire        pixel_clk,   // NEW: BRAM clock
    input  wire [3:0]  rel_x,
    input  wire [3:0]  rel_y,
    input  wire [1:0]  pose,         // 00 stand, 01 walkA, 10 walkB, 11 jump
    output reg         sprite_on,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

    // BRAM ROM read (1-cycle latency)
    wire rom_on;
    wire [3:0] rom_r, rom_g, rom_b;

    Dude_ROM U_DUDE_ROM (
        .clk(pixel_clk),
        .pose(pose),
        .x(rel_x),
        .y(rel_y),
        .on(rom_on),
        .r(rom_r),
        .g(rom_g),
        .b(rom_b)
    );

    always @(*) begin
        sprite_on = rom_on;
        r = rom_r;
        g = rom_g;
        b = rom_b;
    end

endmodule
