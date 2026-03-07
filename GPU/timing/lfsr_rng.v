`timescale 1ns/1ps
module lfsr_rng (
    input  wire clk,
    input  wire rst,
    input  wire enable,         // advance RNG when 1
    output reg  [15:0] rand
);
    // taps example: x^16 + x^14 + x^13 + x^11 + 1 (common)
    wire feedback = rand[15] ^ rand[13] ^ rand[12] ^ rand[10];

    always @(posedge clk) begin
        if (rst) begin
            rand <= 16'hACE1;    // non-zero seed
        end else if (enable) begin
            rand <= {rand[14:0], feedback};
        end
    end
endmodule