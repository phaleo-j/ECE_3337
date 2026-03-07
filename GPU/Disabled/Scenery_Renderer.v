`timescale 1ns / 1ps
module Scenery_Renderer (
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire [9:0] scroll_x,

    output reg  [3:0] bgR,
    output reg  [3:0] bgG,
    output reg  [3:0] bgB
);

    // Visible area
    wire visible = (h_count < 10'd640) && (v_count < 10'd480);

    // Simple parallax offsets
    wire [9:0] far_x  = h_count + scroll_x;
    wire [9:0] mid_x  = h_count + (scroll_x >> 1);
    wire [9:0] near_x = h_count + (scroll_x >> 2);

    always @(*) begin
        // default black
        bgR = 4'h0;
        bgG = 4'h0;
        bgB = 4'h0;

        if (visible) begin
            // ---- SKY ----
            bgR = 4'h3;
            bgG = 4'h7;
            bgB = 4'hF;

            // ---- FAR MOUNTAINS ----
            if (v_count > (10'd180 + (far_x[6:4] << 2))) begin
                bgR = 4'h5;
                bgG = 4'h5;
                bgB = 4'h7;
            end

            // ---- MID HILLS ----
            if (v_count > (10'd260 + (mid_x[5:3] << 2))) begin
                bgR = 4'h3;
                bgG = 4'h6;
                bgB = 4'h4;
            end

            // ---- GROUND ----
            if (v_count > 10'd420) begin
                bgR = 4'h1;
                bgG = 4'hC;
                bgB = 4'h1;
            end

            // ---- SUN ----
            if ((h_count-10'd80)*(h_count-10'd80) +
                (v_count-10'd80)*(v_count-10'd80) < 20'd900) begin
                bgR = 4'hF;
                bgG = 4'hE;
                bgB = 4'h3;
            end
        end
    end

endmodule
