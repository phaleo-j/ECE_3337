`timescale 1ns / 1ps
module Tile_ROM(
    input  wire        clk,
    input  wire [7:0]  tile_id,   // we will clamp to 0..7
    input  wire [3:0]  px,
    input  wire [3:0]  py,
    output reg  [3:0]  color_idx
);
    // addr = {tile_id[2:0], py[3:0], px[3:0]} = 3+4+4 = 11 bits => 2048
    wire [10:0] addr = {tile_id[2:0], py, px};

    (* ram_style = "block" *)
    reg [3:0] mem [0:65535];

    initial begin
        $readmemh("tiles256_4bpp.mem", mem);
    end

    always @(posedge clk)
        color_idx <= mem[addr];
endmodule