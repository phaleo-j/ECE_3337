`timescale 1ns / 1ps
module top(
    input  wire CLK100MHZ,
    input  wire btnL, btnR, btnU, btnD, btnC,
    output wire [15:0] LED,
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue
);

    // --- Clocks / timing ---
    wire pixel_clk;
    wire [9:0] h_count, v_count;
    wire new_frame;
    wire game_tick;

    // --- Game object positions ---
    wire [9:0] player_x, player_y;
    wire [9:0] side_x, side_y;
    wire [9:0] block_x, block_y;
    wire hit_fall, hit_side, hit_any;
    wire [3:0] bgR, bgG, bgB;
    wire game_over;
    wire moving;
    wire logic_tick;
    wire ui_on;
    wire [3:0] uiR, uiG, uiB;
    wire in_air;
    wire [1:0] pose;
    reg [15:0] scroll_x = 10'd0;
    reg [2:0] scroll_div = 3'd0;   // slows scrolling

always @(posedge pixel_clk) begin
    if (btnC) begin
        scroll_x   <= 10'd0;
        scroll_div <= 3'd0;
    end else if (new_frame) begin
        // scroll once every 8 frames (~7.5 px/sec @60fps)
        scroll_div <= scroll_div + 1'b1;
        if (scroll_div == 3'd7) begin
            scroll_div <= 3'd0;
            if (scroll_x == 10'd639) scroll_x <= 10'd0;
            else                      scroll_x <= scroll_x + 1'b1;
        end
    end
end

reg [9:0] h_d, v_d;

always @(posedge pixel_clk) begin
    h_d <= h_count;
    v_d <= v_count;
end

    // --- Clock divider: 100 MHz -> 25 MHz ---
    Clock_div u_clk (
        .clk_in(CLK100MHZ),
        .pixel_clk(pixel_clk)
    );

    // --- VGA timing (counters + syncs) ---
    vga_timing u_vga (
        .pixel_clk(pixel_clk),
        .h_count(h_count),
        .v_count(v_count),
        .Hsync(Hsync),
        .Vsync(Vsync),
        .new_frame(new_frame)
    );

    // --- Game tick (slower update enable) ---
    Game_tick u_tick (
        .pixel_clk(pixel_clk),
        .new_frame(new_frame),
        .game_tick(game_tick)
    );
    // --- Falling block motion ---
    Falling_block #(
        .HALF(10'd20),
        .X_INIT(10'd200),
        .Y_INIT(10'd0),
        .FALL_STEP(10'd6)
    ) u_fall (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick),
        .game_over(game_over),
        .reset_block(btnC),         // press center to respawn block
        .block_x(block_x),
        .block_y(block_y)
    );

   Sprite_Renderer u_render (
    .pixel_clk(pixel_clk),   // NEW (required)
    .h_count(h_d),
    .v_count(v_d),

    .bgR(bgR),
    .bgG(bgG),
    .bgB(bgB),

    .ui_on(ui_on),
    .uiR(uiR),
    .uiG(uiG),
    .uiB(uiB),

    .player_x(player_x),
    .player_y(player_y),
    .block_x(block_x),
    .block_y(block_y),
    .side_x(side_x),
    .side_y(side_y),

    .pose(pose),
    .game_over(game_over),

    .vgaRed(vgaRed),
    .vgaGreen(vgaGreen),
    .vgaBlue(vgaBlue)
);

    
    side_block #(
    .HALF(10'd20),
    .Y_INIT(10'd440),
    .DX(11'sd6)
) u_side (
    .pixel_clk(pixel_clk),
    .game_tick(game_tick),
    .game_over(game_over),
    .reset(btnC),        // reuse center button for reset
    .block_x(side_x),
    .block_y(side_y)
);

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

CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall (
    .ax(player_x), .ay(player_y),
    .bx(block_x),  .by(block_y),
    .hit(hit_fall)
);

CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_side (
    .ax(player_x), .ay(player_y),
    .bx(side_x),   .by(side_y),
    .hit(hit_side)
);

You_died u_go (
    .pixel_clk(pixel_clk),
    .game_tick(game_tick),
    .hit(hit_any),
    .reset_btn(btnC),
    .game_over(game_over)
);

Anim_Tick #(.TOGGLE_TICKS(8)) u_anim (
    .pixel_clk(pixel_clk),
    .game_tick(game_tick),
    .reset_btn(btnC),
    .moving(moving),
    .frame_sel(frame_sel)
);

Anim_Pose #(.TOGGLE_TICKS(8)) u_pose (
    .pixel_clk(pixel_clk),
    .game_tick(game_tick),
    .reset_btn(btnC),
    .moving(moving),
    .in_air(in_air),
    .pose(pose)
);

Logic_tick u_logic (
    .pixel_clk(pixel_clk),
    .logic_tick(logic_tick)
);


UI_Renderer u_ui (
    .pixel_clk(pixel_clk),   // NEW
    .h_count(h_d),
    .v_count(v_d),
    .visible((h_d < 10'd640) && (v_d < 10'd480)),

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

Background_Renderer u_bg (
    .pixel_clk(pixel_clk),
    .h_count(h_d),
    .v_count(v_d),
    .scroll_x(scroll_x),
    .bgR(bgR),
    .bgG(bgG),
    .bgB(bgB)
);
endmodule
