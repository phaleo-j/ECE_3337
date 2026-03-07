`timescale 1ns / 1ps
module Palette(
    input  wire        clk,
    input  wire [7:0]  color_idx,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);
    (* ram_style = "block" *)
    reg [11:0] mem [0:255];

    initial begin
        $readmemh("palette256.mem", mem);
    end

    always @(posedge clk) begin
        {r,g,b} <= mem[color_idx];
    end
endmodule
