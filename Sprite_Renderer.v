`timescale 1ns / 1ps

module Sprite_Renderer #(
    parameter [9:0] HALF_BLOCK = 10'd20
)(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       pixel_clk,

    // Background from tile engine
    input  wire [3:0] bgR,
    input  wire [3:0] bgG,
    input  wire [3:0] bgB,

    // UI overlay
    input  wire       ui_on,
    input  wire [3:0] uiR,
    input  wire [3:0] uiG,
    input  wire [3:0] uiB,

    // Objects
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire [9:0] block_x,
    input  wire [9:0] block_y,
    input  wire [9:0] side_x,
    input  wire [9:0] side_y,

    // Player pose
    input  wire [1:0] pose,

    // Game state
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

    // =========================================================
    // PLAYER SPRITE (16x16) + 1-cycle pipeline (BRAM latency)
    // =========================================================
    localparam [9:0] HALF_SPR = 10'd8;

    wire player_box =
        visible &&
        (h_count + HALF_SPR >= player_x) && (h_count <= player_x + (HALF_SPR-1)) &&
        (v_count + HALF_SPR >= player_y) && (v_count <= player_y + (HALF_SPR-1));

    reg player_box_d;
    always @(posedge pixel_clk) begin
        player_box_d <= player_box;
    end

    wire [9:0] rel_x10 = (h_count + HALF_SPR) - player_x;
    wire [9:0] rel_y10 = (v_count + HALF_SPR) - player_y;

    wire [3:0] rel_x = rel_x10[3:0];
    wire [3:0] rel_y = rel_y10[3:0];

    wire spr_on;
    wire [3:0] spr_r, spr_g, spr_b;

    dude u_dude (
        .pixel_clk(pixel_clk),
        .rel_x(rel_x),
        .rel_y(rel_y),
        .pose(pose),
        .sprite_on(spr_on),
        .r(spr_r),
        .g(spr_g),
        .b(spr_b)
    );

    // =========================================================
    // HAZARDS (BLOCK + SIDE) BOTH BRAM-MASKED (1-cycle latency)
    // =========================================================

    // ---- Falling block bounds (rect gate) ----
    wire block_on =
        visible &&
        (h_count + HALF_BLOCK >= block_x) && (h_count <= block_x + HALF_BLOCK) &&
        (v_count + HALF_BLOCK >= block_y) && (v_count <= block_y + HALF_BLOCK);

    // Relative coords (16x16 sample)
    wire [9:0] block_relx10 = (h_count + HALF_BLOCK) - block_x;
    wire [9:0] block_rely10 = (v_count + HALF_BLOCK) - block_y;
    wire [3:0] block_rx     = block_relx10[3:0];
    wire [3:0] block_ry     = block_rely10[3:0];

    // Pipeline rect gate to match BRAM read
    reg block_on_d;
    always @(posedge pixel_clk) begin
        block_on_d <= block_on;
    end

    // BRAM-backed 16x16 mask
    wire block_pix_on;
    block_sprite u_blockspr (
        .clk(pixel_clk),
        .rel_x(block_rx),
        .rel_y(block_ry),
        .on(block_pix_on)
    );

    // ---- Side hazard bounds (rect gate) ----
    wire side_on =
        visible &&
        (h_count + HALF_BLOCK >= side_x) && (h_count <= side_x + HALF_BLOCK) &&
        (v_count + HALF_BLOCK >= side_y) && (v_count <= side_y + HALF_BLOCK);

    // Relative coords (16x16 sample)
    wire [9:0] side_relx10 = (h_count + HALF_BLOCK) - side_x;
    wire [9:0] side_rely10 = (v_count + HALF_BLOCK) - side_y;
    wire [3:0] side_rx     = side_relx10[3:0];
    wire [3:0] side_ry     = side_rely10[3:0];

    // Pipeline rect gate to match BRAM read
    reg side_on_d;
    always @(posedge pixel_clk) begin
        side_on_d <= side_on;
    end

    // BRAM-backed 16x16 mask
    wire side_pix_on;
    side_sprite u_sidespr (
        .clk(pixel_clk),
        .rel_x(side_rx),
        .rel_y(side_ry),
        .on(side_pix_on)
    );

    // =========================================================
    // HYBRID BACKGROUND ART (SUN + MOUNTAINS) (unchanged)
    // =========================================================

    localparam [9:0] SUN_X = 10'd70;
    localparam [9:0] SUN_Y = 10'd70;
    localparam [9:0] SUN_R = 10'd35;

    wire signed [11:0] sx = $signed({1'b0,h_count}) - $signed({1'b0,SUN_X});
    wire signed [11:0] sy = $signed({1'b0,v_count}) - $signed({1'b0,SUN_Y});
    wire [23:0] sun_d2 = sx*sx + sy*sy;
    wire [23:0] sun_r2 = SUN_R*SUN_R;

    wire sun_core = (sun_d2 <= sun_r2);

    wire sun_ray =
        ( (sx == 0) && (sy >  35) && (sy <  55) ) ||
        ( (sx == 0) && (sy < -35) && (sy > -55) ) ||
        ( (sy == 0) && (sx >  35) && (sx <  55) ) ||
        ( (sy == 0) && (sx < -35) && (sx > -55) ) ||
        ( (sx ==  sy) && (sx >  28) && (sx <  40) ) ||
        ( (sx ==  sy) && (sx < -28) && (sx > -40) ) ||
        ( (sx == -sy) && (sx >  28) && (sx <  40) ) ||
        ( (sx == -sy) && (sx < -28) && (sx > -40) );

    wire sun_on = visible && (sun_core || sun_ray);

    localparam [9:0] HORIZON_Y = 10'd360;

    localparam [9:0] M1X = 10'd120;
    localparam [9:0] M1W = 10'd220;
    localparam [9:0] M1H = 10'd140;

    localparam [9:0] M2X = 10'd360;
    localparam [9:0] M2W = 10'd260;
    localparam [9:0] M2H = 10'd170;

    localparam [9:0] M3X = 10'd560;
    localparam [9:0] M3W = 10'd200;
    localparam [9:0] M3H = 10'd120;

    function mtn_on_fn;
        input [9:0] xc;
        input [9:0] halfw;
        input [9:0] h;
        reg   [9:0] ax;
        reg   [21:0] rise;
        reg   [9:0] ridge_y;
        begin
            if (h_count > xc) ax = h_count - xc;
            else              ax = xc - h_count;

            if (ax > halfw) begin
                mtn_on_fn = 1'b0;
            end else begin
                rise = (ax * h) / halfw;
                ridge_y = (HORIZON_Y - h) + rise[9:0];
                mtn_on_fn = (v_count >= ridge_y) && (v_count < HORIZON_Y);
            end
        end
    endfunction

    wire mtn1_on = visible && mtn_on_fn(M1X, M1W, M1H);
    wire mtn2_on = visible && mtn_on_fn(M2X, M2W, M2H);
    wire mtn3_on = visible && mtn_on_fn(M3X, M3W, M3H);

    wire mtn_on = mtn1_on || mtn2_on || mtn3_on;

    // =========================================================
    // FINAL COMPOSITOR
    // =========================================================
    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
            // 1) Base background
            vgaRed   = bgR;
            vgaGreen = bgG;
            vgaBlue  = bgB;

            // 2) Background art overlays
            if (mtn_on) begin
                vgaRed   = 4'h2;
                vgaGreen = 4'h2;
                vgaBlue  = 4'h3;
            end

            if (sun_on) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hE;
                vgaBlue  = 4'h2;
            end

            // 3) Hazards (BRAM-masked)
            if (block_on_d && block_pix_on) begin
                vgaRed   = 4'hF; vgaGreen = 4'h0; vgaBlue = 4'h0;
            end else if (side_on_d && side_pix_on) begin
                vgaRed   = 4'h0; vgaGreen = 4'hF; vgaBlue = 4'h0;
            end

            // 4) Player
            if (player_box_d && spr_on) begin
                vgaRed   = spr_r;
                vgaGreen = spr_g;
                vgaBlue  = spr_b;
            end

            // 5) Game-over effect
            if (game_over) begin
                vgaRed   = (vgaRed >> 1) + 4'h4;
                vgaGreen = (vgaGreen >> 2);
                vgaBlue  = (vgaBlue >> 2);
            end

            // 6) UI LAST
            if (ui_on) begin
                vgaRed   = uiR;
                vgaGreen = uiG;
                vgaBlue  = uiB;
            end
        end
    end

endmodule