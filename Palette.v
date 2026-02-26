`timescale 1ns / 1ps

module Palette(
    input  wire        clk,        // NEW
    input  wire [3:0]  color_idx,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

    // 12-bit packed RGB (4 bits each)
    (* ram_style = "block" *)
    reg [11:0] mem [0:15];

    initial begin
        $readmemh("palette.mem", mem);
    end

    reg [11:0] rgb;

    always @(posedge clk) begin
        rgb <= mem[color_idx];
        {r,g,b} <= rgb;
    end

endmodule
