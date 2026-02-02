`timescale 1ns / 1ps

module Sprite_Renderer #(
    parameter [9:0] HALF_BLOCK  = 10'd20
)(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    input  wire [9:0] block_x,
    input  wire [9:0] block_y,

    input  wire [9:0] side_x,
    input  wire [9:0] side_y,

    input  wire       game_over,

    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue
);

    // -------------------------------
    // Visible region
    // -------------------------------
    localparam [9:0] H_VISIBLE = 10'd640;
    localparam [9:0] V_VISIBLE = 10'd480;
    wire visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // -------------------------------
    // Background constants
    // -------------------------------
    localparam [9:0] GROUND_Y = 10'd440;

    // Sun
    localparam [9:0] SUN_X = 10'd60;
    localparam [9:0] SUN_Y = 10'd60;
    localparam [19:0] SUN_R2 = 20'd1600; // 40*40

    // Clouds
    localparam [9:0] C1X = 10'd220, C1Y = 10'd90;
    localparam [9:0] C2X = 10'd260, C2Y = 10'd80;
    localparam [9:0] C3X = 10'd300, C3Y = 10'd92;
    localparam [19:0] CR2 = 20'd625;     // 25*25

    // -------------------------------
    // Falling + side blocks (rects)
    // -------------------------------
    wire block_on =
        visible &&
        (h_count + HALF_BLOCK >= block_x) && (h_count <= block_x + HALF_BLOCK) &&
        (v_count + HALF_BLOCK >= block_y) && (v_count <= block_y + HALF_BLOCK);

    wire side_on =
        visible &&
        (h_count + HALF_BLOCK >= side_x) && (h_count <= side_x + HALF_BLOCK) &&
        (v_count + HALF_BLOCK >= side_y) && (v_count <= side_y + HALF_BLOCK);

    // -------------------------------
    // 16x16 PLAYER SPRITE SETUP
    // -------------------------------
    localparam [9:0] HALF_SPR = 10'd8;

    wire player_box =
        visible &&
        (h_count + HALF_SPR >= player_x) && (h_count <= player_x + (HALF_SPR-1)) &&
        (v_count + HALF_SPR >= player_y) && (v_count <= player_y + (HALF_SPR-1));
        
    wire [9:0] rel_x10 = (h_count + HALF_SPR) - player_x;  // 0..15 when player_box=1
    wire [9:0] rel_y10 = (v_count + HALF_SPR) - player_y;

    wire [3:0] rel_x = rel_x10[3:0];
    wire [3:0] rel_y = rel_y10[3:0];

    wire spr_on;
    wire [3:0] spr_r, spr_g, spr_b;

    dude u_dude (
        .rel_x(rel_x),
        .rel_y(rel_y),
        .sprite_on(spr_on),
        .r(spr_r),
        .g(spr_g),
        .b(spr_b)
    );

    // -------------------------------
    // Sun + cloud math
    // -------------------------------
    wire signed [11:0] dx_sun = $signed({1'b0,h_count}) - $signed(SUN_X);
    wire signed [11:0] dy_sun = $signed({1'b0,v_count}) - $signed(SUN_Y);
    wire [19:0] sun_d2 = dx_sun*dx_sun + dy_sun*dy_sun;
    wire sun_on = (sun_d2 <= SUN_R2);

    wire signed [11:0] dx_c1 = $signed({1'b0,h_count}) - $signed(C1X);
    wire signed [11:0] dy_c1 = $signed({1'b0,v_count}) - $signed(C1Y);
    wire [19:0] c1d2 = dx_c1*dx_c1 + dy_c1*dy_c1;

    wire signed [11:0] dx_c2 = $signed({1'b0,h_count}) - $signed(C2X);
    wire signed [11:0] dy_c2 = $signed({1'b0,v_count}) - $signed(C2Y);
    wire [19:0] c2d2 = dx_c2*dx_c2 + dy_c2*dy_c2;

    wire signed [11:0] dx_c3 = $signed({1'b0,h_count}) - $signed(C3X);
    wire signed [11:0] dy_c3 = $signed({1'b0,v_count}) - $signed(C3Y);
    wire [19:0] c3d2 = dx_c3*dx_c3 + dy_c3*dy_c3;

    wire cloud_on = (c1d2 <= CR2) || (c2d2 <= CR2) || (c3d2 <= CR2);

    // -------------------------------
    // FINAL DRAW PIPELINE
    // -------------------------------
    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
            if (game_over) begin
                // GAME OVER tint
                vgaRed   = 4'h8;
                vgaGreen = 4'h0;
                vgaBlue  = 4'h0;
            end else begin
                // --- Background ---
                if (v_count >= GROUND_Y) begin
                    // grass
                    vgaRed   = 4'h0;
                    vgaGreen = 4'hC;
                    vgaBlue  = 4'h0;
                end else begin
                    // sky
                    vgaRed   = 4'h3;
                    vgaGreen = 4'h7;
                    vgaBlue  = 4'hF;
                end

                if (sun_on && v_count < GROUND_Y) begin
                    vgaRed   = 4'hF;
                    vgaGreen = 4'hE;
                    vgaBlue  = 4'h2;
                end

                if (cloud_on && v_count < GROUND_Y) begin
                    vgaRed   = 4'hF;
                    vgaGreen = 4'hF;
                    vgaBlue  = 4'hF;
                end

                // --- Sprites (priority) ---
                if (player_box && spr_on) begin
                    vgaRed   = spr_r;
                    vgaGreen = spr_g;
                    vgaBlue  = spr_b;
                end else if (block_on) begin
                    vgaRed   = 4'hF;
                    vgaGreen = 4'h0;
                    vgaBlue  = 4'h0;
                end else if (side_on) begin
                    vgaRed   = 4'h0;
                    vgaGreen = 4'hF;
                    vgaBlue  = 4'h0;
                end
            end
        end
    end

endmodule
