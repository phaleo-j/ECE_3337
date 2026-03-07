`timescale 1ns / 1ps

module Font_ROM(
    input  wire       clk,
    input  wire [7:0] ch,
    input  wire [2:0] row,
    output reg  [7:0] bits
);
    // Address = {ch,row} = 8+3 = 11 bits => 2048 deep
    wire [10:0] addr = {ch, row};

    (* ram_style = "block" *)
    reg [7:0] mem [0:2047];

    initial begin
        $readmemh("font.mem", mem); // 2048 lines, each 2 hex bytes (00..FF)
    end

    always @(posedge clk) begin
        bits <= mem[addr];
    end
endmodule