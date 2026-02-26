`timescale 1ns / 1ps

module Tilemap_ROM(
    input  wire        clk,        // NEW: pixel_clk
    input  wire [5:0]  tile_x,     // 0..39
    input  wire [4:0]  tile_y,     // 0..29
    output reg  [7:0]  tile_id
);
    // Address = tile_y*40 + tile_x  (0..1199) => need 11 bits
    wire [10:0] addr = (tile_y * 11'd40) + tile_x;

    (* ram_style = "block" *)
    reg [7:0] mem [0:1199];

    initial begin
        $readmemh("tilemap.mem", mem);  // 1200 lines, 2 hex chars each (00..FF)
    end

    // Synchronous read => BRAM inference (1-cycle latency)
    always @(posedge clk) begin
        tile_id <= mem[addr];
    end

endmodule