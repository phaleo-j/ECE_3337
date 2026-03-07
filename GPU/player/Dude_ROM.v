`timescale 1ns / 1ps

module Dude_ROM(
    input  wire        clk,
    input  wire [1:0]  pose,     // 00 stand, 01 walkA, 10 walkB, 11 jump
    input  wire [3:0]  x,        // 0..15
    input  wire [3:0]  y,        // 0..15
    output reg         on,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);
    // addr = {pose(2), y(4), x(4)} => 10 bits => 1024 deep
    wire [9:0] addr = {pose, y, x};

    // Data packed as: [12]=on, [11:8]=r, [7:4]=g, [3:0]=b  (13 bits)
    (* ram_style = "block" *)
    reg [12:0] mem [0:1023];

    initial begin
        $readmemh("dude.mem", mem);
    end

    reg [12:0] q;
    always @(posedge clk) begin
        q  <= mem[addr];
        on <= q[12];
        r  <= q[11:8];
        g  <= q[7:4];
        b  <= q[3:0];
    end
endmodule