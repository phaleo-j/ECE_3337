`timescale 1ns / 1ps
module Sprite_Renderer #(
    parameter [9:0] HALF = 10'd20
)(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue,
    output reg  [9:0] player_x,
    output reg  [9:0] player_y
);

    localparam H_VISIBLE = 640;
    localparam V_VISIBLE = 480;

    always @(*) begin
        // default black
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        // Only draw in visible region
        if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
            // Range check (underflow-safe form)
            if ( (h_count + HALF >= player_x) && (h_count <= player_x + HALF) &&
                 (v_count + HALF >= player_y) && (v_count <= player_y + HALF) ) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hF;
                vgaBlue  = 4'hF;
            end
        end
    end

endmodule

