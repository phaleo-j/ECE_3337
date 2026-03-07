`timescale 1ns / 1ps
module side_block #(
    parameter [9:0] HALF   = 10'd20,
    parameter [9:0] Y_INIT = 10'd440
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       game_over,
    input  wire       reset,

    input  wire [9:0] side_step,

    output reg  [9:0] block_x,
    output reg  [9:0] block_y
);
    localparam [9:0] X_MAX = 10'd639;

    always @(posedge pixel_clk) begin
        if (reset) begin
            block_x <= 10'd0;
            block_y <= Y_INIT;
        end else if (game_tick && !game_over) begin
            if (block_x > (X_MAX + HALF)) begin
                block_x <= 10'd0;
            end else begin
                block_x <= block_x + side_step;
            end
        end
    end
endmodule