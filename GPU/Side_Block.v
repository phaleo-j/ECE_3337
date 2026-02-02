`timescale 1ns / 1ps

module side_block #(
    parameter [9:0] HALF       = 10'd20,
    parameter [9:0] Y_INIT     = 10'd440,   // ground-level hazard
    parameter signed [10:0] DX = 11'sd6     // horizontal speed
)(
    input  wire pixel_clk,
    input  wire game_tick,
    input  wire reset,

    output reg  [9:0] block_x = 10'd0,
    output reg  [9:0] block_y = Y_INIT
);

    localparam [9:0] X_MAX = 10'd639;

    always @(posedge pixel_clk) begin
        if (reset) begin
            block_x <= 10'd0;
            block_y <= Y_INIT;
        end else if (game_tick) begin
            // Move right
            if (block_x > (X_MAX + HALF)) begin
                // Respawn off left side
                block_x <= 10'd0;
            end else begin
                block_x <= block_x + DX;
            end
        end
    end

endmodule
