`timescale 1ns / 1ps
module rainbow_sprite(
    input  wire        clk,
    input  wire [6:0]  rel_x,    // 0..127
    input  wire [5:0]  rel_y,    // 0..63
    output reg  [3:0]  color_idx // 0 = transparent
);
    wire [12:0] addr = {rel_y, rel_x}; // 64*128 = 8192 entries

    (* ram_style="block" *)
    reg [3:0] mem [0:8191];

    initial begin
        $readmemh("rainbow_128x64.mem", mem);
    end

    always @(posedge clk) begin
        color_idx <= mem[addr];
    end
endmodule