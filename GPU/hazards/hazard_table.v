`timescale 1ns/1ps

module hazard_table #(
    parameter N_HAZARDS = 8,
    parameter SCREEN_W  = 640,
    parameter SCREEN_H  = 480,
    parameter HAZ_SIZE  = 16
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        vblank_tick,   // 1 pulse per frame
    input  wire [15:0] rand,          // from LFSR

    output reg [N_HAZARDS*32-1:0] hazards_flat
);

    // ------------------------------------------------------------
    // 8 x 32-bit hazard table (RAM)
    // ------------------------------------------------------------
    reg [31:0] mem [0:N_HAZARDS-1];

    // entry format:
    // [31] active
    // [30] type (0=fall,1=side)
    // [29:20] x (10)
    // [19:11] y (9)
    // [10:5] vx (6 signed)
    // [4:1]  vy (4)
    // [0] unused

    reg updating;
    reg [3:0] idx;
    reg [7:0] spawn_cnt;

    integer i;

    // unpack registers
    reg        active;
    reg        type;
    reg [9:0]  x;
    reg [8:0]  y;
    reg signed [5:0] vx;
    reg [3:0]  vy;

    reg [31:0] entry;

    // -----------------------------
    // Main logic
    // -----------------------------
    always @(posedge clk) begin
        if (rst) begin
            updating   <= 0;
            idx        <= 0;
            spawn_cnt  <= 8'd30;

            for (i = 0; i < N_HAZARDS; i = i + 1) begin
                mem[i] <= 32'd0;
            end

            hazards_flat <= {N_HAZARDS{32'd0}};
        end
        else begin

            // Start update window
            if (vblank_tick && !updating) begin
                updating <= 1;
                idx      <= 0;

                if (spawn_cnt != 0)
                    spawn_cnt <= spawn_cnt - 1;
            end

            // Update hazards one per clock
            if (updating) begin

                entry = mem[idx];

                // Unpack
                active = entry[31];
                type   = entry[30];
                x      = entry[29:20];
                y      = entry[19:11];
                vx     = entry[10:5];
                vy     = entry[4:1];

                if (active) begin

                    // Move
                    x = x + vx;
                    y = y + vy;

                    // Despawn if off screen
                    if (y >= SCREEN_H + HAZ_SIZE)
                        active = 0;
                    else if (x >= SCREEN_W + HAZ_SIZE)
                        active = 0;

                    // Repack
                    mem[idx][31]    <= active;
                    mem[idx][30]    <= type;
                    mem[idx][29:20] <= x;
                    mem[idx][19:11] <= y;
                    mem[idx][10:5]  <= vx;
                    mem[idx][4:1]   <= vy;
                    mem[idx][0]     <= 1'b0;

                end
                else begin
                    // Spawn only if timer expired
                    if (spawn_cnt == 0) begin

                        active = 1'b1;
                        type   = rand[15];

                        if (type == 0) begin
                            // Falling
                            x  = rand[9:0];
                            if (x >= SCREEN_W)
                                x = x - SCREEN_W;

                            y  = 0;
                            vx = 0;

                            vy = rand[5:4];
                            if (vy == 3)
                                vy = 2;
                            vy = vy + 1; // 1..3
                        end
                        else begin
                            // Side spawn
                            y = rand[8:0];
                            if (y >= SCREEN_H)
                                y = y - SCREEN_H;

                            vy = 0;

                            if (rand[14]) begin
                                x  = 0;
                                vx = 2;
                            end
                            else begin
                                x  = SCREEN_W - 1;
                                vx = -2;
                            end
                        end

                        mem[idx][31]    <= active;
                        mem[idx][30]    <= type;
                        mem[idx][29:20] <= x;
                        mem[idx][19:11] <= y;
                        mem[idx][10:5]  <= vx;
                        mem[idx][4:1]   <= vy;
                        mem[idx][0]     <= 1'b0;

                        spawn_cnt <= 8'd30;
                    end
                end

                // Advance index
                if (idx == N_HAZARDS-1) begin
                    updating <= 0;

                    // Cache table for renderer
                    hazards_flat[ 31:  0] <= mem[0];
                    hazards_flat[ 63: 32] <= mem[1];
                    hazards_flat[ 95: 64] <= mem[2];
                    hazards_flat[127: 96] <= mem[3];
                    hazards_flat[159:128] <= mem[4];
                    hazards_flat[191:160] <= mem[5];
                    hazards_flat[223:192] <= mem[6];
                    hazards_flat[255:224] <= mem[7];
                end
                else begin
                    idx <= idx + 1;
                end
            end
        end
    end

endmodule