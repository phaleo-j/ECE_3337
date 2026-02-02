`timescale 1ns / 1ps
module falling_block #(
    parameter [9:0] HALF      = 10'd20,
    parameter [9:0] X_INIT    = 10'd200,  // fixed X for now
    parameter [9:0] Y_INIT    = 10'd0,
    parameter [9:0] FALL_STEP = 10'd6
)(
    input  wire pixel_clk,
    input  wire game_tick,
    input  wire reset_block,
    output reg  [9:0] block_x = X_INIT,
    output reg  [9:0] block_y = Y_INIT
);

    localparam [9:0] Y_MAX = 10'd479;

    always @(posedge pixel_clk) begin
        if (reset_block) begin
            block_x <= X_INIT;
            block_y <= 10'd0;
        end else if (game_tick) begin
            // fall
            if (block_y + FALL_STEP > (Y_MAX + HALF)) begin
                // respawn at top (predictable for now)
                block_x <= X_INIT;
                block_y <= 10'd0;
            end else begin
                block_y <= block_y + FALL_STEP;
            end
        end
    end

endmodule
