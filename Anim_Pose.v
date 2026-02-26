`timescale 1ns / 1ps

module Anim_Pose #(
    parameter integer TOGGLE_TICKS = 8
)(
    input  wire pixel_clk,
    input  wire game_tick,
    input  wire reset_btn,
    input  wire moving,
    input  wire in_air,
    output reg  [1:0] pose = 2'b00
);

    reg walk_phase = 1'b0;
    integer cnt = 0;

    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            cnt <= 0;
            walk_phase <= 1'b0;
            pose <= 2'b00;
        end else if (game_tick) begin

            // Jump pose overrides everything
            if (in_air) begin
                pose <= 2'b11;       // JUMP
                cnt <= 0;
                walk_phase <= 1'b0;
            end else if (moving) begin
                // Toggle walk frames at a visible rate
                if (cnt >= (TOGGLE_TICKS-1)) begin
                    cnt <= 0;
                    walk_phase <= ~walk_phase;
                end else begin
                    cnt <= cnt + 1;
                end

                pose <= (walk_phase ? 2'b10 : 2'b01); // WALK B / WALK A
            end else begin
                // Standing
                pose <= 2'b00;
                cnt <= 0;
                walk_phase <= 1'b0;
            end
        end
    end

endmodule
