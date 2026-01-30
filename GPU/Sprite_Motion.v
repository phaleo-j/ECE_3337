`timescale 1ns / 1ps
module Sprite_Motion #(
    parameter [9:0] HALF   = 10'd20,
    parameter signed [10:0] DX_INIT = 11'sd3,
    parameter signed [10:0] DY_INIT = 11'sd2,
    parameter [9:0] X_INIT  = 10'd320,
    parameter [9:0] Y_INIT  = 10'd240
)(
    input  wire pixel_clk,
    input  wire new_frame,
    output reg  [9:0] pixel_x = X_INIT,
    output reg  [9:0] pixel_y = Y_INIT
);

    reg signed [10:0] dx = DX_INIT;
    reg signed [10:0] dy = DY_INIT;

    always @(posedge pixel_clk) begin
        if (new_frame) begin
            // Bounce on left/right edges (keep entire sprite visible)
            if (pixel_x + dx > (10'd639 - HALF))
                dx <= -dx;
            else if (pixel_x + dx < HALF)
                dx <= -dx;

            // Bounce on top/bottom edges
            if (pixel_y + dy > (10'd479 - HALF))
                dy <= -dy;
            else if (pixel_y + dy < HALF)
                dy <= -dy;

            // Update position
            pixel_x <= pixel_x + dx;
            pixel_y <= pixel_y + dy;
        end
    end

endmodule
