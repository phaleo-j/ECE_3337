`timescale 1ns / 1ps

module Tilemap_ROM #(
    parameter integer MAP_W = 160,  // <-- 160 tiles wide (4 screens)
    parameter integer MAP_H = 30
)(
    input  wire        clk,
    input  wire [7:0]  tile_x,   // <-- 0..159
    input  wire [4:0]  tile_y,   // 0..29
    output reg  [7:0]  tile_id
);

    // Pipeline tile coords to match BRAM timing (clean + stable)
    reg [7:0] tile_x_d;
    reg [4:0] tile_y_d;

    always @(posedge clk) begin
        tile_x_d <= tile_x;
        tile_y_d <= tile_y;
    end

    // Index = y*MAP_W + x
    // Max = (30*160 - 1) = 4799 -> needs 13 bits
    wire [12:0] idx = (tile_y_d * MAP_W) + tile_x_d;

    (* ram_style = "block" *)
    reg [7:0] map [0:MAP_W*MAP_H-1];

    initial begin
        // IMPORTANT: you must generate this file for 160x30 (4800 entries)
        $readmemh("tilemap160x30.mem", map);
    end

    always @(posedge clk) begin
        tile_id <= map[idx];  // 1-cycle latency
    end

endmodule