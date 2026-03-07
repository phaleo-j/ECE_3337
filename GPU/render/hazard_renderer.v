`timescale 1ns/1ps
module hazard_render #(
    parameter integer N_HAZARDS = 8,
    parameter integer HAZ_SIZE  = 16
)(
    input  wire [9:0] pixel_x,
    input  wire [8:0] pixel_y,
    input  wire [N_HAZARDS*32-1:0] hazards_flat,

    output reg  hazard_on
);
    integer i;

    reg        active;
    reg [9:0]  hx;
    reg [8:0]  hy;

    always @(*) begin
        hazard_on = 1'b0;

        for (i = 0; i < N_HAZARDS; i = i + 1) begin
            // extract entry i
            active = hazards_flat[i*32 + 31];
            hx     = hazards_flat[i*32 + 29 -: 10]; // [29:20]
            hy     = hazards_flat[i*32 + 19 -: 9];  // [19:11]

            if (active) begin
                if ( (pixel_x >= hx) && (pixel_x < (hx + HAZ_SIZE)) &&
                     (pixel_y >= hy) && (pixel_y < (hy + HAZ_SIZE)) ) begin
                    hazard_on = 1'b1;
                end
            end
        end
    end
endmodule