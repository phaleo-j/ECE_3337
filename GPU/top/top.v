`timescale 1ns / 1ps
module top(
    input  wire        CLK100MHZ,
    input  wire        btnL, btnR, btnU, btnD, btnC,
    output wire [15:0] LED,
    output wire        Hsync, Vsync,
    output wire [3:0]  vgaRed, vgaGreen, vgaBlue
);

    wire [9:0] ufo_x, ufo_y;
    wire       drop_pulse;
    wire [9:0] drop_x;
    wire [9:0] fall_step, side_step;

    // -----------------------------
    // Clocking
    // -----------------------------
    wire pixel_clk;
    Clock_div u_clk (
        .clk_in(CLK100MHZ),
        .pixel_clk(pixel_clk)
    );

    // -----------------------------
    // VGA timing (RAW)
    // -----------------------------
    wire [9:0] h_count, v_count;
    wire       new_frame;
    wire       Hsync_raw, Vsync_raw;

    vga_timing u_vga (
        .pixel_clk(pixel_clk),
        .h_count(h_count),
        .v_count(v_count),
        .Hsync(Hsync_raw),
        .Vsync(Vsync_raw),
        .new_frame(new_frame)
    );

    // -----------------------------
    // 3-stage pipeline for sync + pixel coords
    // -----------------------------
    reg [9:0] h1, v1, h2, v2, h3, v3;
    reg hs1, vs1, hs2, vs2, hs3, vs3;

    always @(posedge pixel_clk) begin
        h1  <= h_count;
        v1  <= v_count;
        hs1 <= Hsync_raw;
        vs1 <= Vsync_raw;

        h2  <= h1;
        v2  <= v1;
        hs2 <= hs1;
        vs2 <= vs1;

        h3  <= h2;
        v3  <= v2;
        hs3 <= hs2;
        vs3 <= vs2;
    end

    assign Hsync = hs3;
    assign Vsync = vs3;

    // -----------------------------
    // Game tick
    // -----------------------------
    wire game_tick;

    Game_tick #(
        .UPDATE_DIV(4)
    ) u_game_tick (
        .pixel_clk(pixel_clk),
        .new_frame(new_frame),
        .game_tick(game_tick)
    );

    // -----------------------------
    // Scroll control
    // -----------------------------
    reg [9:0] scroll_x = 10'd0;
    reg [2:0] scroll_div = 3'd0;

    always @(posedge pixel_clk) begin
        if (btnC) begin
            scroll_x   <= 10'd0;
            scroll_div <= 3'd0;
        end else if (new_frame) begin
            scroll_div <= scroll_div + 1'b1;
            if (scroll_div == 3'd7) begin
                scroll_div <= 3'd0;
                if (scroll_x == 10'd639) scroll_x <= 10'd0;
                else                      scroll_x <= scroll_x + 1'b1;
            end
        end
    end

    // -----------------------------
    // Objects / state
    // -----------------------------
    wire [9:0] player_x, player_y;
    wire [9:0] side_x,   side_y;

    // 4 random falling blocks
    wire       blk0_active, blk1_active, blk2_active, blk3_active;
    wire [9:0] blk0_x, blk0_y;
    wire [9:0] blk1_x, blk1_y;
    wire [9:0] blk2_x, blk2_y;
    wire [9:0] blk3_x, blk3_y;

    wire moving;
    wire in_air;
    wire logic_tick;
    wire [1:0] pose;

    wire hit_fall0, hit_fall1, hit_fall2, hit_fall3;
    wire hit_side;
    wire hit_any = hit_fall0 | hit_fall1 | hit_fall2 | hit_fall3 | hit_side;

    wire game_over;

    // -----------------------------
    // Background
    // -----------------------------
    wire [3:0] bgR, bgG, bgB;

    Background_Renderer u_bg (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .scroll_x(scroll_x),
        .bgR(bgR),
        .bgG(bgG),
        .bgB(bgB)
    );

    UFO u_ufoctl (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick),
        .reset(btnC),

        .ufo_x(ufo_x),
        .ufo_y(ufo_y),

        .drop_pulse(drop_pulse),
        .drop_x(drop_x),

        .fall_step(fall_step),
        .side_step(side_step)
    );

    // -----------------------------
    // 4-block random falling manager
    // -----------------------------
    Falling_Block_Manager u_blocks (
        .clk(pixel_clk),
        .rst(btnC),
        .game_tick(game_tick),
        .ufo_x(ufo_x),
        .ufo_y(ufo_y),

        .blk0_active(blk0_active),
        .blk0_x(blk0_x),
        .blk0_y(blk0_y),

        .blk1_active(blk1_active),
        .blk1_x(blk1_x),
        .blk1_y(blk1_y),

        .blk2_active(blk2_active),
        .blk2_x(blk2_x),
        .blk2_y(blk2_y),

        .blk3_active(blk3_active),
        .blk3_x(blk3_x),
        .blk3_y(blk3_y)
    );

    // -----------------------------
    // Side block
    // -----------------------------
    side_block #(
        .HALF(10'd20),
        .Y_INIT(10'd440)
    ) u_side (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick),
        .game_over(game_over),
        .reset(btnC),

        .side_step(side_step),

        .block_x(side_x),
        .block_y(side_y)
    );

    // -----------------------------
    // Player physics
    // -----------------------------
    Physics u_player (
        .pixel_clk(pixel_clk),
        .game_over(game_over),

        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .reset_btn(btnC),

        .moving(moving),
        .in_air(in_air),
        .logic_tick(logic_tick),

        .player_x(player_x),
        .player_y(player_y)
    );

    Logic_tick u_logic (
        .pixel_clk(pixel_clk),
        .logic_tick(logic_tick)
    );

    // -----------------------------
    // Collision detect
    // -----------------------------
    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall0 (
        .ax(player_x), .ay(player_y),
        .bx(blk0_x),   .by(blk0_y),
        .hit(hit_fall0)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall1 (
        .ax(player_x), .ay(player_y),
        .bx(blk1_x),   .by(blk1_y),
        .hit(hit_fall1)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall2 (
        .ax(player_x), .ay(player_y),
        .bx(blk2_x),   .by(blk2_y),
        .hit(hit_fall2)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall3 (
        .ax(player_x), .ay(player_y),
        .bx(blk3_x),   .by(blk3_y),
        .hit(hit_fall3)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_side (
        .ax(player_x), .ay(player_y),
        .bx(side_x),   .by(side_y),
        .hit(hit_side)
    );

    // -----------------------------
    // Game over latch
    // -----------------------------
    You_died u_go (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick),
        .hit(hit_any),
        .reset_btn(btnC),
        .game_over(game_over)
    );

    // -----------------------------
    // Pose / animation
    // -----------------------------
    Anim_Pose #(.TOGGLE_TICKS(8)) u_pose (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick),
        .reset_btn(btnC),
        .moving(moving),
        .in_air(in_air),
        .pose(pose)
    );

    // -----------------------------
    // UI
    // -----------------------------
    wire ui_on;
    wire [3:0] uiR, uiG, uiB;

    UI_Renderer u_ui (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .visible((h3 < 10'd640) && (v3 < 10'd480)),
        .game_over(game_over),

        .score_thousands(4'd0),
        .score_hundreds (4'd0),
        .score_tens     (4'd0),
        .score_ones     (4'd0),

        .ui_on(ui_on),
        .uiR(uiR),
        .uiG(uiG),
        .uiB(uiB)
    );

    // -----------------------------
    // Sprite renderer
    // -----------------------------
    Sprite_Renderer u_render (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),

        .bgR(bgR),
        .bgG(bgG),
        .bgB(bgB),

        .ui_on(ui_on),
        .uiR(uiR),
        .uiG(uiG),
        .uiB(uiB),

        .player_x(player_x),
        .player_y(player_y),

        .blk0_active(blk0_active),
        .blk0_x(blk0_x),
        .blk0_y(blk0_y),

        .blk1_active(blk1_active),
        .blk1_x(blk1_x),
        .blk1_y(blk1_y),

        .blk2_active(blk2_active),
        .blk2_x(blk2_x),
        .blk2_y(blk2_y),

        .blk3_active(blk3_active),
        .blk3_x(blk3_x),
        .blk3_y(blk3_y),

        .side_x(side_x),
        .side_y(side_y),

        .ufo_x(ufo_x),
        .ufo_y(ufo_y),

        .pose(pose),
        .game_over(game_over),

        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

    assign LED = 16'h0000;

endmodule