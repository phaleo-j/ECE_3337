`timescale 1ns / 1ps
module BG_ROM_320x240_4BPP(
    input  wire        clk,
    input  wire [8:0]  x,    // 0..319
    input  wire [7:0]  y,    // 0..239
    output reg  [7:0]  idx
);
    // 320*240 = 76800 pixels => needs 17 bits
    wire [16:0] addr = y * 9'd320 + x;

    (* ram_style="block" *)
    reg [7:0] mem [0:76800-1];

    initial begin
        $readmemh("bg_320x240_8bpp.mem", mem);
    end

    always @(posedge clk) begin
        idx <= mem[addr];
    end
endmodule