`timescale 1ns / 1ps

module Anim_Tick #(
    parameter integer TOGGLE_TICKS = 12  // toggle every 8 game ticks (~7.5 toggles/sec at 60Hz)
)(
    input  wire pixel_clk,
    input  wire game_tick,
    input  wire reset_btn,
    input  wire moving,
    output reg  frame_sel = 1'b0
);

    integer cnt = 0;

    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            cnt <= 0;
            frame_sel <= 1'b0;
        end else if (game_tick) begin
            if (moving) begin
                if (cnt >= (TOGGLE_TICKS-1)) begin
                    cnt <= 0;
                    frame_sel <= ~frame_sel;
                end else begin
                    cnt <= cnt + 1;
                end
            end else begin
                // standing still -> always frame0
                cnt <= 0;
                frame_sel <= 1'b0;
            end
        end
    end

endmodule
