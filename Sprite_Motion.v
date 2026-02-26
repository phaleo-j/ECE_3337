`timescale 1ns / 1ps
module Sprite_Motion #(
    parameter [9:0] HALF       = 10'd20,   // half-size of player square
    parameter [9:0] X_INIT      = 10'd320,  // start centered
    parameter [9:0] Y_GROUND    = 10'd440,  // fixed ground Y for player
    parameter [9:0] MOVE_STEP   = 10'd6     // pixels per game_tick
)(
    input  wire pixel_clk,      // 25 MHz pixel clock
    input  wire game_tick,       // 1 pulse every N frames (speed control)
    input  wire btnL,            // move left
    input  wire btnR,            // move right
    output reg  [9:0] player_x = X_INIT,
    output reg  [9:0] player_y = Y_GROUND
);

    // Keep Y locked to ground (so this step is ONLY horizontal movement)
    always @(posedge pixel_clk) begin
        player_y <= Y_GROUND;
    end

    // Move ONLY when game_tick is asserted (not every refresh, not every clock)
    always @(posedge pixel_clk) begin
        if (game_tick) begin
            // Left (and NOT right) pressed
            if (btnL && !btnR) begin
                // Clamp so you never go past x=0
                if (player_x > (HALF + MOVE_STEP))
                    player_x <= player_x - MOVE_STEP;
                else
                    player_x <= HALF;
            end
            // Right (and NOT left) pressed
            else if (btnR && !btnL) begin
                // Clamp so you never go past x=639
                if (player_x < (10'd639 - HALF - MOVE_STEP))
                    player_x <= player_x + MOVE_STEP;
                else
                    player_x <= (10'd639 - HALF);
            end
            // else: both or neither => no movement
        end
    end
endmodule
