`timescale 1ns / 1ps

module Falling_Block_Manager(
    input  wire       clk,
    input  wire       rst,
    input  wire       game_tick,

    input  wire [9:0] ufo_x,
    input  wire [9:0] ufo_y,

    output reg        blk0_active,
    output reg [9:0]  blk0_x,
    output reg [9:0]  blk0_y,

    output reg        blk1_active,
    output reg [9:0]  blk1_x,
    output reg [9:0]  blk1_y,

    output reg        blk2_active,
    output reg [9:0]  blk2_x,
    output reg [9:0]  blk2_y,

    output reg        blk3_active,
    output reg [9:0]  blk3_x,
    output reg [9:0]  blk3_y
);

    localparam [9:0] SCREEN_H    = 10'd480;
    localparam [9:0] START_Y_OFF = 10'd20;

    reg [9:0] blk0_vy, blk1_vy, blk2_vy, blk3_vy;

    reg [7:0] lfsr;
    wire lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    reg [5:0] spawn_timer;
    reg [1:0] burst_left;

    // pattern system
    reg [2:0] pattern_id;
    reg [1:0] pattern_step;
    reg [1:0] pattern_len;

    function [9:0] clamp_x;
        input signed [10:0] x_in;
        begin
            if (x_in < 0)
                clamp_x = 10'd0;
            else if (x_in > 11'sd639)
                clamp_x = 10'd639;
            else
                clamp_x = x_in[9:0];
        end
    endfunction

    // lane selector:
    // 00 = far left
    // 01 = left
    // 10 = right
    // 11 = far right
    function [9:0] lane_to_x;
        input [1:0] lane;
        input [9:0] ufox;
        begin
            case (lane)
                2'b00: lane_to_x = clamp_x($signed({1'b0, ufox}) - 11'sd48);
                2'b01: lane_to_x = clamp_x($signed({1'b0, ufox}) - 11'sd16);
                2'b10: lane_to_x = clamp_x($signed({1'b0, ufox}) + 11'sd16);
                default: lane_to_x = clamp_x($signed({1'b0, ufox}) + 11'sd48);
            endcase
        end
    endfunction

    function [9:0] pick_speed;
        input [1:0] sel;
        begin
            case (sel)
                2'b00: pick_speed = 10'd4;
                2'b01: pick_speed = 10'd5;
                2'b10: pick_speed = 10'd6;
                default: pick_speed = 10'd7;
            endcase
        end
    endfunction

    function [5:0] pick_spawn_delay;
        input [2:0] sel;
        begin
            case (sel)
                3'b000: pick_spawn_delay = 6'd5;
                3'b001: pick_spawn_delay = 6'd7;
                3'b010: pick_spawn_delay = 6'd9;
                3'b011: pick_spawn_delay = 6'd11;
                3'b100: pick_spawn_delay = 6'd13;
                3'b101: pick_spawn_delay = 6'd16;
                3'b110: pick_spawn_delay = 6'd20;
                default: pick_spawn_delay = 6'd24;
            endcase
        end
    endfunction

    // choose lane from current pattern + step
    function [1:0] pattern_lane;
        input [2:0] pid;
        input [1:0] pstep;
        begin
            case (pid)
                // Pattern 0: far left -> left -> right -> far right
                3'd0: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b01;
                        2'd2: pattern_lane = 2'b10;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                // Pattern 1: far right -> right -> left -> far left
                3'd1: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b11;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b00;
                    endcase
                end

                // Pattern 2: center-heavy
                3'd2: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b01;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b10;
                    endcase
                end

                // Pattern 3: outer edges
                3'd3: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b11;
                        2'd2: pattern_lane = 2'b00;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                // Pattern 4: zig-zag
                3'd4: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                default: pattern_lane = 2'b01;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            blk0_active <= 1'b0;  blk0_x <= 10'd0;  blk0_y <= 10'd0;  blk0_vy <= 10'd5;
            blk1_active <= 1'b0;  blk1_x <= 10'd0;  blk1_y <= 10'd0;  blk1_vy <= 10'd5;
            blk2_active <= 1'b0;  blk2_x <= 10'd0;  blk2_y <= 10'd0;  blk2_vy <= 10'd5;
            blk3_active <= 1'b0;  blk3_x <= 10'd0;  blk3_y <= 10'd0;  blk3_vy <= 10'd5;

            lfsr        <= 8'hA7;
            spawn_timer <= 6'd12;
            burst_left  <= 2'd0;

            pattern_id   <= 3'd0;
            pattern_step <= 2'd0;
            pattern_len  <= 2'd3;   // 4 total drops: steps 0..3
        end
        else if (game_tick) begin
            lfsr <= {lfsr[6:0], lfsr_feedback};

            // move active blocks
            if (blk0_active) begin
                if (blk0_y >= (SCREEN_H - blk0_vy))
                    blk0_active <= 1'b0;
                else
                    blk0_y <= blk0_y + blk0_vy;
            end

            if (blk1_active) begin
                if (blk1_y >= (SCREEN_H - blk1_vy))
                    blk1_active <= 1'b0;
                else
                    blk1_y <= blk1_y + blk1_vy;
            end

            if (blk2_active) begin
                if (blk2_y >= (SCREEN_H - blk2_vy))
                    blk2_active <= 1'b0;
                else
                    blk2_y <= blk2_y + blk2_vy;
            end

            if (blk3_active) begin
                if (blk3_y >= (SCREEN_H - blk3_vy))
                    blk3_active <= 1'b0;
                else
                    blk3_y <= blk3_y + blk3_vy;
            end

            if (spawn_timer != 0) begin
                spawn_timer <= spawn_timer - 1'b1;
            end
            else begin
                // spawn using current pattern lane
                if (!blk0_active) begin
                    blk0_active <= 1'b1;
                    blk0_x  <= lane_to_x(pattern_lane(pattern_id, pattern_step), ufo_x);
                    blk0_y  <= ufo_y + START_Y_OFF;
                    blk0_vy <= pick_speed(lfsr[3:2]);
                end
                else if (!blk1_active) begin
                    blk1_active <= 1'b1;
                    blk1_x  <= lane_to_x(pattern_lane(pattern_id, pattern_step), ufo_x);
                    blk1_y  <= ufo_y + START_Y_OFF;
                    blk1_vy <= pick_speed(lfsr[5:4]);
                end
                else if (!blk2_active) begin
                    blk2_active <= 1'b1;
                    blk2_x  <= lane_to_x(pattern_lane(pattern_id, pattern_step), ufo_x);
                    blk2_y  <= ufo_y + START_Y_OFF;
                    blk2_vy <= pick_speed(lfsr[7:6]);
                end
                else if (!blk3_active) begin
                    blk3_active <= 1'b1;
                    blk3_x  <= lane_to_x(pattern_lane(pattern_id, pattern_step), ufo_x);
                    blk3_y  <= ufo_y + START_Y_OFF;
                    blk3_vy <= pick_speed({lfsr[0], lfsr[7]});
                end

                // advance pattern step or pick new pattern
                if (pattern_step >= pattern_len) begin
                    pattern_id   <= lfsr[2:0] % 5; // choose 0..4
                    pattern_step <= 2'd0;
                    pattern_len  <= 2'd3;
                end
                else begin
                    pattern_step <= pattern_step + 1'b1;
                end

                // timing logic
                if (burst_left != 0) begin
                    burst_left  <= burst_left - 1'b1;
                    spawn_timer <= 6'd3;
                end
                else if (lfsr[7:5] == 3'b111) begin
                    burst_left  <= 2'd2;
                    spawn_timer <= 6'd3;
                end
                else begin
                    spawn_timer <= pick_spawn_delay(lfsr[6:4]);
                end
            end
        end
    end

endmodule