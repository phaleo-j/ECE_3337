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
    wire game_over;

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

    // --- Renderer (draw player + falling block) ---
    Sprite_Renderer u_render (
        .h_count(h_count),
        .v_count(v_count),
        .player_x(player_x),
        .player_y(player_y),
        .block_x(block_x),   
        .block_y(block_y),
        .side_x(side_x),
        .side_y(side_y),  
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
    .game_tick(game_tick),
    .game_over(game_over),

    .btnL(btnL),
    .btnR(btnR),
    .btnU(btnU),
    .reset_btn(btnC),

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


assign hit_any = hit_fall | hit_side;
    // LED debug 
    assign LED[0] = btnL;
    assign LED[1] = btnR;
    assign LED[2] = btnU;
    assign LED[3] = btnD;
    assign LED[4] = btnC;
    assign LED[5] = game_tick;   // should blink
    assign LED[6] = hit_any;     // should light when overlap happens
    assign LED[7] = game_over;   // should latch ON after a hit
    assign LED[15:12] = player_x[9:6];
    assign LED[11:8] =  side_x[9:6];

endmodule
