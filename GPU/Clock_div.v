`timescale 1ns / 1ps
module clock_div(
    input  wire clk_in,      // 100 MHz
    output wire clk_out       // 25 MHz
);
    reg [1:0] clk_div = 2'd0;

    always @(posedge clk_in)
        clk_div <= clk_div + 1'b1;

    assign clk_out = clk_div[1];
endmodule
