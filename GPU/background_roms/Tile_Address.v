`timescale 1ns / 1ps

module Tile_Address #(
    parameter integer MAP_W_TILES = 160  // 160 tiles = 2560 px = 4 screens wide
)(
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire [15:0] scroll_x,     // world scroll in pixels
    output wire [7:0]  tile_x,        // 0..MAP_W_TILES-1 (fits in 8 bits for 160)
    output wire [4:0]  tile_y,        // 0..29 for 480p
    output wire [3:0]  px,            // 0..15
    output wire [3:0]  py             // 0..15
);

    localparam integer MAP_W_PX   = MAP_W_TILES * 16;     // 2560 px
    localparam integer WORLD_BITS = $clog2(MAP_W_PX);     // 12 for 2560

    // Make a wide sum, then wrap with modulo so it NEVER goes out of range.
    wire [31:0] world_x_sum = {16'b0, scroll_x} + {22'b0, h_count};

    // world_x in range 0..MAP_W_PX-1 always
    wire [WORLD_BITS-1:0] world_x = world_x_sum % MAP_W_PX;

    assign tile_x = world_x[WORLD_BITS-1:4]; // /16  -> 0..159
    assign px     = world_x[3:0];

    assign tile_y = v_count[9:4];            // 0..29
    assign py     = v_count[3:0];

endmodule