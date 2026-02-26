`timescale 1ns / 1ps

module Tile_Address #(
    parameter integer MAP_W_TILES = 160  // 160 tiles = 2560 px = 4 screens wide
)(
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire [15:0] scroll_x,     // NEW: bigger scroll range (world pixels)
    output wire [7:0]  tile_x,        // NEW: bigger world tile index
    output wire [4:0]  tile_y,        // 0..29
    output wire [3:0]  px,            // 0..15
    output wire [3:0]  py             // 0..15
);

    localparam integer MAP_W_PX = MAP_W_TILES * 16;

    // world_x = h_count + scroll_x (in pixels)
    wire [16:0] world_x_sum = {1'b0,scroll_x} + {7'b0,h_count};

    // wrap to map width (keeps it in 0..MAP_W_PX-1)
    wire [16:0] world_x =
        (world_x_sum >= MAP_W_PX) ? (world_x_sum - MAP_W_PX) : world_x_sum;

    assign tile_x = world_x[16:4];   // divide by 16
    assign px     = world_x[3:0];

    assign tile_y = v_count[9:4];
    assign py     = v_count[3:0];

endmodule
