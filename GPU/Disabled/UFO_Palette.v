`timescale 1ns / 1ps
module UFO_Palette(
    input  wire       clk,
    input  wire [3:0] color_idx,
    output reg  [3:0] r,
    output reg  [3:0] g,
    output reg  [3:0] b
);
    (* ram_style="block" *)
    reg [11:0] mem [0:15];

    initial begin
        $readmemh("ufo_palette.mem", mem);
    end

    always @(posedge clk) begin
        {r,g,b} <= mem[color_idx];
    end
endmodule