`timescale 1ns / 1ps
module UFO #(
    parameter [9:0] UFO_Y = 10'd120,
    parameter [9:0] UFO_HALF_W = 10'd64   // 128-wide sprite => half width = 64
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       reset,

    output reg  [9:0] ufo_x,
    output wire [9:0] ufo_y,

    output reg        drop_pulse,
    output reg  [9:0] drop_x,

    output reg  [9:0] fall_step,
    output reg  [9:0] side_step
);
    assign ufo_y = UFO_Y;

    // 16-bit LFSR
    reg [15:0] lfsr = 16'hACE1;
    wire fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    // 5-second ramp (300 ticks @ 60Hz)
    reg [8:0] sec5_cnt = 9'd0;
    reg [3:0] lvl = 4'd0;

    // drop timer
    reg [9:0] drop_cnt = 10'd0;

    function [9:0] drop_period;
        input [3:0] L;
        begin
            if (L >= 4'd12) drop_period = 10'd12;
            else if (L >= 4'd8) drop_period = 10'd20;
            else if (L >= 4'd4) drop_period = 10'd35;
            else drop_period = 10'd60;
        end
    endfunction

    function [2:0] ufo_step;
        input [3:0] L;
        begin
            if (L >= 4'd10) ufo_step = 3'd6;
            else if (L >= 4'd6) ufo_step = 3'd5;
            else if (L >= 4'd3) ufo_step = 3'd4;
            else ufo_step = 3'd3;
        end
    endfunction

    reg dir = 1'b1; // 1=right, 0=left

    always @(posedge pixel_clk) begin
        if (reset) begin
            // center coordinate
            ufo_x <= 10'd200;
            dir <= 1'b1;
            lfsr <= 16'hACE1;

            sec5_cnt <= 9'd0;
            lvl <= 4'd0;

            drop_cnt <= 10'd0;
            drop_pulse <= 1'b0;
            drop_x <= 10'd200;

            fall_step <= 10'd6;
            side_step <= 10'd6;
        end else begin
            drop_pulse <= 1'b0;

            if (game_tick) begin
                lfsr <= {lfsr[14:0], fb};

                if (sec5_cnt == 9'd299) begin
                    sec5_cnt <= 9'd0;
                    if (lvl != 4'hF) lvl <= lvl + 1'b1;
                end else begin
                    sec5_cnt <= sec5_cnt + 1'b1;
                end

                if (lvl >= 4'd10) fall_step <= 10'd16;
                else fall_step <= 10'd6 + {6'd0, lvl};

                if (lvl >= 4'd10) side_step <= 10'd14;
                else side_step <= 10'd6 + {6'd0, lvl};

                // move UFO using CENTER coordinates
                if (dir) begin
                    if (ufo_x + UFO_HALF_W + ufo_step(lvl) >= 10'd639) begin
                        dir <= 1'b0;
                        ufo_x <= 10'd639 - UFO_HALF_W;
                    end else begin
                        ufo_x <= ufo_x + ufo_step(lvl);
                    end
                end else begin
                    if (ufo_x <= UFO_HALF_W + ufo_step(lvl)) begin
                        dir <= 1'b1;
                        ufo_x <= UFO_HALF_W;
                    end else begin
                        ufo_x <= ufo_x - ufo_step(lvl);
                    end
                end

                if (drop_cnt >= drop_period(lvl)) begin
                    drop_cnt <= 10'd0;

                    begin : DROP
                        reg signed [10:0] jitter;
                        reg signed [10:0] xcalc;

                        // drop around UFO center with +-32 jitter
                        jitter = $signed({1'b0, lfsr[5:0]}) - 11'sd32;
                        xcalc  = $signed({1'b0, ufo_x}) + jitter;

                        if (xcalc < 0) drop_x <= 10'd0;
                        else if (xcalc > 639) drop_x <= 10'd639;
                        else drop_x <= xcalc[9:0];
                    end

                    drop_pulse <= 1'b1;
                end else begin
                    drop_cnt <= drop_cnt + 1'b1;
                end
            end
        end
    end

endmodule