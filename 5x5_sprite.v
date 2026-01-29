`timescale 1ns / 1ps
module top(
    input  wire clk,        // 100 MHz Basys 3 clock
    output reg  Hsync,      // Horizontal sync
    output reg  Vsync,      // Vertical sync
    output reg [3:0] vgaRed,   // 4-bit RGB outputs
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
    reg [9:0] pixel_X = 320;
    reg [9:0] pixel_y = 240;
);

    reg [1:0] clk_div = 0;
    always @(posedge clk)
        clk_div <= clk_div + 1;
    wire pixel_clk = clk_div[1];

    parameter H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48, H_TOTAL = 800;
    parameter V_VISIBLE = 480, V_FRONT = 10, V_SYNC = 2, V_BACK = 33, V_TOTAL = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge pixel_clk) begin
        if (h_count == H_TOTAL-1) begin
            h_count <= 0;
            if (v_count == V_TOTAL-1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end
    end

    always @(*) begin
        Hsync = ~(h_count >= (H_VISIBLE + H_FRONT) && h_count < (H_VISIBLE + H_FRONT + H_SYNC));
        Vsync = ~(v_count >= (V_VISIBLE + V_FRONT) && v_count < (V_VISIBLE + V_FRONT + V_SYNC));
    end

    localparam [9:0] HALF = 10'd2;
    
    always @(*) begin
        // Default black
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        // Only draw in visible area
        if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
            // 5x5 square (sprite) centered at (pixel_x, pixel_y)
             if ( (h_count >= (pixel_x - HALF)) && (h_count <= (pixel_x + HALF)) &&
             (v_count >= (pixel_y - HALF)) && (v_count <= (pixel_y + HALF)) ) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hF;
                vgaBlue  = 4'hF;
            end
        end
    end
