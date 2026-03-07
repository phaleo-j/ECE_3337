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

    // Objects (center coords)
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    input  wire       blk0_active,
    input  wire [9:0] blk0_x,
    input  wire [9:0] blk0_y,

    input  wire       blk1_active,
    input  wire [9:0] blk1_x,
    input  wire [9:0] blk1_y,

    input  wire       blk2_active,
    input  wire [9:0] blk2_x,
    input  wire [9:0] blk2_y,

    input  wire       blk3_active,
    input  wire [9:0] blk3_x,
    input  wire [9:0] blk3_y,

    input  wire [9:0] side_x,
    input  wire [9:0] side_y,
    input  wire [9:0] ufo_x,
    input  wire [9:0] ufo_y,

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
    // PLAYER SPRITE (16x16 source, scaled to 32x32 on screen)
    // =========================================================
    localparam [9:0] HALF_SPR = 10'd16;

    wire player_box =
        visible &&
        (h_count + HALF_SPR >= player_x) && (h_count <= player_x + (HALF_SPR - 1)) &&
        (v_count + HALF_SPR >= player_y) && (v_count <= player_y + (HALF_SPR - 1));

    reg player_box_d;
    always @(posedge pixel_clk) begin
        player_box_d <= player_box;
    end

    wire [9:0] rel_x10 = (h_count + HALF_SPR) - player_x;
    wire [9:0] rel_y10 = (v_count + HALF_SPR) - player_y;

    wire [3:0] rel_x = rel_x10[4:1];
    wire [3:0] rel_y = rel_y10[4:1];

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
    // HAZARDS: scale 40x40 hitbox -> 16x16 mask
    // =========================================================
    localparam [9:0] BOX_W = (HALF_BLOCK << 1);

    // -------------------------
    // Falling block 0
    // -------------------------
    wire block0_on =
        blk0_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk0_x) && (h_count <= blk0_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk0_y) && (v_count <= blk0_y + (HALF_BLOCK - 1));

    wire [9:0] block0_relx = (h_count + HALF_BLOCK) - blk0_x;
    wire [9:0] block0_rely = (v_count + HALF_BLOCK) - blk0_y;

    wire [9:0] block0_rx_tmp = (block0_relx >= BOX_W) ? 10'd15 : ((block0_relx * 10'd16) / BOX_W);
    wire [9:0] block0_ry_tmp = (block0_rely >= BOX_W) ? 10'd15 : ((block0_rely * 10'd16) / BOX_W);
    wire [3:0] block0_rx_s   = block0_rx_tmp[3:0];
    wire [3:0] block0_ry_s   = block0_ry_tmp[3:0];

    reg       block0_on_d;
    reg [3:0] block0_rx_d, block0_ry_d;

    always @(posedge pixel_clk) begin
        block0_on_d <= block0_on;
        block0_rx_d <= block0_rx_s;
        block0_ry_d <= block0_ry_s;
    end

    wire block0_pix_on;
    block_sprite u_blockspr0 (
        .clk(pixel_clk),
        .rel_x(block0_rx_d),
        .rel_y(block0_ry_d),
        .on(block0_pix_on)
    );

    // -------------------------
    // Falling block 1
    // -------------------------
    wire block1_on =
        blk1_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk1_x) && (h_count <= blk1_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk1_y) && (v_count <= blk1_y + (HALF_BLOCK - 1));

    wire [9:0] block1_relx = (h_count + HALF_BLOCK) - blk1_x;
    wire [9:0] block1_rely = (v_count + HALF_BLOCK) - blk1_y;

    wire [9:0] block1_rx_tmp = (block1_relx >= BOX_W) ? 10'd15 : ((block1_relx * 10'd16) / BOX_W);
    wire [9:0] block1_ry_tmp = (block1_rely >= BOX_W) ? 10'd15 : ((block1_rely * 10'd16) / BOX_W);
    wire [3:0] block1_rx_s   = block1_rx_tmp[3:0];
    wire [3:0] block1_ry_s   = block1_ry_tmp[3:0];

    reg       block1_on_d;
    reg [3:0] block1_rx_d, block1_ry_d;

    always @(posedge pixel_clk) begin
        block1_on_d <= block1_on;
        block1_rx_d <= block1_rx_s;
        block1_ry_d <= block1_ry_s;
    end

    wire block1_pix_on;
    block_sprite u_blockspr1 (
        .clk(pixel_clk),
        .rel_x(block1_rx_d),
        .rel_y(block1_ry_d),
        .on(block1_pix_on)
    );

    // -------------------------
    // Falling block 2
    // -------------------------
    wire block2_on =
        blk2_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk2_x) && (h_count <= blk2_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk2_y) && (v_count <= blk2_y + (HALF_BLOCK - 1));

    wire [9:0] block2_relx = (h_count + HALF_BLOCK) - blk2_x;
    wire [9:0] block2_rely = (v_count + HALF_BLOCK) - blk2_y;

    wire [9:0] block2_rx_tmp = (block2_relx >= BOX_W) ? 10'd15 : ((block2_relx * 10'd16) / BOX_W);
    wire [9:0] block2_ry_tmp = (block2_rely >= BOX_W) ? 10'd15 : ((block2_rely * 10'd16) / BOX_W);
    wire [3:0] block2_rx_s   = block2_rx_tmp[3:0];
    wire [3:0] block2_ry_s   = block2_ry_tmp[3:0];

    reg       block2_on_d;
    reg [3:0] block2_rx_d, block2_ry_d;

    always @(posedge pixel_clk) begin
        block2_on_d <= block2_on;
        block2_rx_d <= block2_rx_s;
        block2_ry_d <= block2_ry_s;
    end

    wire block2_pix_on;
    block_sprite u_blockspr2 (
        .clk(pixel_clk),
        .rel_x(block2_rx_d),
        .rel_y(block2_ry_d),
        .on(block2_pix_on)
    );

    // -------------------------
    // Falling block 3
    // -------------------------
    wire block3_on =
        blk3_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk3_x) && (h_count <= blk3_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk3_y) && (v_count <= blk3_y + (HALF_BLOCK - 1));

    wire [9:0] block3_relx = (h_count + HALF_BLOCK) - blk3_x;
    wire [9:0] block3_rely = (v_count + HALF_BLOCK) - blk3_y;

    wire [9:0] block3_rx_tmp = (block3_relx >= BOX_W) ? 10'd15 : ((block3_relx * 10'd16) / BOX_W);
    wire [9:0] block3_ry_tmp = (block3_rely >= BOX_W) ? 10'd15 : ((block3_rely * 10'd16) / BOX_W);
    wire [3:0] block3_rx_s   = block3_rx_tmp[3:0];
    wire [3:0] block3_ry_s   = block3_ry_tmp[3:0];

    reg       block3_on_d;
    reg [3:0] block3_rx_d, block3_ry_d;

    always @(posedge pixel_clk) begin
        block3_on_d <= block3_on;
        block3_rx_d <= block3_rx_s;
        block3_ry_d <= block3_ry_s;
    end

    wire block3_pix_on;
    block_sprite u_blockspr3 (
        .clk(pixel_clk),
        .rel_x(block3_rx_d),
        .rel_y(block3_ry_d),
        .on(block3_pix_on)
    );

    // -------------------------
    // Side block region
    // -------------------------
    wire side_on =
        visible &&
        (h_count + HALF_BLOCK >= side_x) && (h_count <= side_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= side_y) && (v_count <= side_y + (HALF_BLOCK - 1));

    wire [9:0] side_relx = (h_count + HALF_BLOCK) - side_x;
    wire [9:0] side_rely = (v_count + HALF_BLOCK) - side_y;

    wire [9:0] side_rx_tmp = (side_relx >= BOX_W) ? 10'd15 : ((side_relx * 10'd16) / BOX_W);
    wire [9:0] side_ry_tmp = (side_rely >= BOX_W) ? 10'd15 : ((side_rely * 10'd16) / BOX_W);
    wire [3:0] side_rx_s   = side_rx_tmp[3:0];
    wire [3:0] side_ry_s   = side_ry_tmp[3:0];

    reg       side_on_d;
    reg [3:0] side_rx_d, side_ry_d;

    always @(posedge pixel_clk) begin
        side_on_d <= side_on;
        side_rx_d <= side_rx_s;
        side_ry_d <= side_ry_s;
    end

    wire side_pix_on;
    side_sprite u_sidespr (
        .clk(pixel_clk),
        .rel_x(side_rx_d),
        .rel_y(side_ry_d),
        .on(side_pix_on)
    );

    // =========================================================
    // TERRARIA-STYLE GROUND
    // =========================================================
    localparam [9:0] HORIZON_Y = 10'd445;
    localparam [9:0] GRASS_H   = 10'd3;

    wire ground_on = visible && (v_count >= HORIZON_Y);
    wire grass_on  = ground_on && (v_count < (HORIZON_Y + GRASS_H));

    wire [3:0] noise = (h_count[3:0] ^ v_count[3:0] ^ h_count[7:4]);

    localparam [11:0] GRASS_MAIN = 12'h29F;
    localparam [11:0] GRASS_DARK = 12'h17C;
    localparam [11:0] GRASS_LITE = 12'h3BF;

    localparam [11:0] DIRT_MAIN  = 12'h742;
    localparam [11:0] DIRT_DARK  = 12'h521;
    localparam [11:0] DIRT_LITE  = 12'h963;

    reg [11:0] ground_rgb;
    always @(*) begin
        ground_rgb = 12'h000;

        if (grass_on) begin
            if (noise == 4'h0 || noise == 4'h7) ground_rgb = GRASS_DARK;
            else if (noise == 4'hF)             ground_rgb = GRASS_LITE;
            else                                ground_rgb = GRASS_MAIN;
        end
        else if (ground_on) begin
            if (noise == 4'h1 || noise == 4'h9) ground_rgb = DIRT_DARK;
            else if (noise == 4'hE)             ground_rgb = DIRT_LITE;
            else                                ground_rgb = DIRT_MAIN;
        end
    end

    wire [3:0] gR = ground_rgb[11:8];
    wire [3:0] gG = ground_rgb[7:4];
    wire [3:0] gB = ground_rgb[3:0];

    // =========================================================
    // UFO SPRITE - cropped draw region from 128x64 RGB444 ROM
    // scaled 2x on screen
    // ufo_x / ufo_y are CENTER coordinates
    // Transparent key color = 12'hF0F
    // =========================================================
    localparam [6:0] UFO_CROP_X = 7'd8;
    localparam [5:0] UFO_CROP_Y = 6'd0;
    localparam [6:0] UFO_SRC_W  = 7'd112;
    localparam [5:0] UFO_SRC_H  = 6'd64;

    localparam [7:0] UFO_DRAW_W = 8'd224;
    localparam [7:0] UFO_DRAW_H = 8'd128;

    wire [10:0] ufo_left_tmp = {1'b0, ufo_x} - (UFO_DRAW_W >> 1);
    wire [10:0] ufo_top_tmp  = {1'b0, ufo_y} - (UFO_DRAW_H >> 1);

    wire [9:0] ufo_left = ufo_left_tmp[10] ? 10'd0 : ufo_left_tmp[9:0];
    wire [9:0] ufo_top  = ufo_top_tmp[10]  ? 10'd0 : ufo_top_tmp[9:0];

    wire ufo_box =
        visible &&
        (h_count >= ufo_left) && (h_count < ufo_left + UFO_DRAW_W) &&
        (v_count >= ufo_top)  && (v_count < ufo_top + UFO_DRAW_H);

    wire [7:0] ufo_local_x = h_count - ufo_left;
    wire [7:0] ufo_local_y = v_count - ufo_top;

    wire [6:0] ufo_rx = UFO_CROP_X + ufo_local_x[7:1];
    wire [5:0] ufo_ry = UFO_CROP_Y + ufo_local_y[6:1];

    reg       ufo_box_d1;
    reg [6:0] ufo_rx_d1;
    reg [5:0] ufo_ry_d1;

    always @(posedge pixel_clk) begin
        ufo_box_d1 <= ufo_box;
        ufo_rx_d1  <= ufo_rx;
        ufo_ry_d1  <= ufo_ry;
    end

    wire [11:0] ufo_rgb_s1;
    UFO_ROM_64x32_4BPP u_ufo_rom (
        .clk(pixel_clk),
        .x(ufo_rx_d1),
        .y(ufo_ry_d1),
        .rgb(ufo_rgb_s1)
    );

    reg        ufo_box_d2;
    reg [11:0] ufo_rgb_s2;

    always @(posedge pixel_clk) begin
        ufo_box_d2 <= ufo_box_d1;
        ufo_rgb_s2 <= ufo_rgb_s1;
    end

    wire ufo_visible_pix;
    assign ufo_visible_pix = (ufo_rgb_s2 != 12'hF0F);

    // =========================================================
    // FINAL COMPOSITOR
    // UI > player > hazards > UFO > ground > background
    // =========================================================
    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
            vgaRed   = bgR;
            vgaGreen = bgG;
            vgaBlue  = bgB;

            if (ground_on) begin
                vgaRed   = gR;
                vgaGreen = gG;
                vgaBlue  = gB;
            end

            if (ufo_box_d2 && ufo_visible_pix) begin
                vgaRed   = ufo_rgb_s2[11:8];
                vgaGreen = ufo_rgb_s2[7:4];
                vgaBlue  = ufo_rgb_s2[3:0];
            end

            if ((block0_on_d && block0_pix_on) ||
                (block1_on_d && block1_pix_on) ||
                (block2_on_d && block2_pix_on) ||
                (block3_on_d && block3_pix_on)) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'h0;
                vgaBlue  = 4'h0;
            end
            else if (side_on_d && side_pix_on) begin
                vgaRed   = 4'h0;
                vgaGreen = 4'hF;
                vgaBlue  = 4'h0;
            end

            if (player_box_d && spr_on) begin
                vgaRed   = spr_r;
                vgaGreen = spr_g;
                vgaBlue  = spr_b;
            end

            if (game_over) begin
                vgaRed   = (vgaRed >> 1) + 4'h4;
                vgaGreen = (vgaGreen >> 2);
                vgaBlue  = (vgaBlue >> 2);
            end

            if (ui_on) begin
                vgaRed   = uiR;
                vgaGreen = uiG;
                vgaBlue  = uiB;
            end
        end
    end

endmodule