`timescale 1ns / 1ps
module top(
    input  wire clk,             // 100 MHz Basys 3 clock
    output wire Hsync,
    output wire Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);

    // ---- Pixel clock ----
    wire pixel_clk;

    clock_div u_clkdiv (
        .clk_in(clk),
        .clk_out(pixel_clk)       // 25 MHz
    );

    // ---- VGA timing ----
    wire [9:0] h_count;
    wire [9:0] v_count;
    wire new_frame;

    vga_timing u_vga (
        .pixel_clk(pixel_clk),
        .hsync(Hsync),
        .vsync(Vsync),
        .h_count(h_count),
        .v_count(v_count),
        .new_frame(new_frame)
    );

    // ---- Sprite position / motion ----
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    Sprite_Motion #(
        .HALF(10'd20),
        .DX_INIT(11'sd3),
        .DY_INIT(11'sd2),
        .X_INIT(10'd320),
        .Y_INIT(10'd240)
    ) u_motion (
        .pixel_clk(pixel_clk),
        .new_frame(new_frame),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // ---- Rendering ----
    Sprite_Renderer #(
        .HALF(10'd20)
    ) u_render (
        .h_count(h_count),
        .v_count(v_count),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

endmodule
