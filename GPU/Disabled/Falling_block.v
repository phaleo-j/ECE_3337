`timescale 1ns / 1ps
module Falling_block #(
    parameter [9:0] HALF   = 10'd20,
    parameter [9:0] Y_INIT = 10'd0
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       game_over,
    input  wire       reset,

    input  wire       spawn_pulse,
    input  wire [9:0] spawn_x,

    input  wire [9:0] fall_step,

    output reg  [9:0] block_x,
    output reg  [9:0] block_y
);
    localparam [9:0] Y_MAX = 10'd479;

    always @(posedge pixel_clk) begin
        if (reset) begin
            block_x <= 10'd200;
            block_y <= Y_INIT;
        end else if (spawn_pulse) begin
            block_x <= spawn_x;
            block_y <= Y_INIT;
        end else if (game_tick && !game_over) begin
            if (block_y + fall_step > (Y_MAX + HALF)) begin
                // offscreen waiting for next spawn
                block_y <= Y_MAX + HALF;
            end else begin
                block_y <= block_y + fall_step;
            end
        end
    end
endmodule