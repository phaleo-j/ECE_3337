`timescale 1ns / 1ps
module Physics #(
    parameter [9:0] HALF        = 10'd20,
    parameter [9:0] X_INIT       = 10'd320,
    parameter [9:0] GROUND_Y     = 10'd440,
    parameter [9:0] MOVE_STEP    = 2,

    parameter integer JUMP_V0    = -15,  // negative = up
    parameter integer GRAVITY    =  1
)(
    input  wire pixel_clk,
    //input  wire game_tick,
    input  wire game_over,
    input wire logic_tick,


    input  wire btnL,
    input  wire btnR,
    input  wire btnU,          // jump
    input  wire reset_btn,

    output reg  [9:0] player_x = X_INIT,
    output reg        moving   = 1'b0,
    output reg        in_air   = 1'b0,
    output reg  [9:0] player_y = GROUND_Y
);

    integer y_pos = GROUND_Y;
    integer vy    = 0;
    reg on_ground = 1'b1;

    integer next_vy;
    integer next_y;

    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            player_x  <= X_INIT;
            y_pos     <= GROUND_Y;
            vy        <= 0;
            on_ground <= 1'b1;

            player_y  <= GROUND_Y;
            moving    <= 1'b0;
            in_air    <= 1'b0;           // ? on ground at reset

        end else if (logic_tick && !game_over) begin

            // ---- Horizontal movement ----
            if (btnL && !btnR) begin
                if (player_x > (HALF + MOVE_STEP))
                    player_x <= player_x - MOVE_STEP;
                else
                    player_x <= HALF;
            end else if (btnR && !btnL) begin
                if (player_x < (10'd639 - HALF - MOVE_STEP))
                    player_x <= player_x + MOVE_STEP;
                else
                    player_x <= (10'd639 - HALF);
            end

            // ? moving flag for walk animation
            moving <= (btnL ^ btnR);

            // ---- Jump start ----
            if (on_ground && btnU) begin
                vy        <= JUMP_V0;
                on_ground <= 1'b0;
            end

            // ---- Vertical physics ----
            if (!on_ground) begin
                next_vy = vy + GRAVITY;
                next_y  = y_pos + next_vy;

                if (next_y >= GROUND_Y) begin
                    y_pos     <= GROUND_Y;
                    vy        <= 0;
                    on_ground <= 1'b1;
                end else begin
                    y_pos <= next_y;
                    vy    <= next_vy;
                end
            end

            // ? Drive output + in_air EVERY tick (this was missing)
            player_y <= y_pos[9:0];
            in_air   <= (y_pos < GROUND_Y);

        end
    end

endmodule