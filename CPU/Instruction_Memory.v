`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 10:30:10 AM
// Design Name: 
// Module Name: Instruction_Memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Instruction_Memory(
    input  wire [15:0] addr,
    output wire [15:0] instruction
);

    // 256-word instruction memory, only using lower 8 bit for now
    reg [15:0] memory [0:255];

    integer i;   //  Moved declaration here

    initial begin
        // Example for a working program
        memory[0] = 16'b0001_001_000_000111; // ADDI R1, R0, 7
        memory[1] = 16'b0001_001_001_000011; // ADDI R1, R1, 3
        memory[2] = 16'b0000_010_001_000000; // ADD  R2, R1, R0
        memory[3] = 16'b1111_000_000_000000; // HALT

        // Clear rest of memory
        for (i = 4; i < 256; i = i + 1)
            memory[i] = 16'b0;
    end

    assign instruction = memory[addr];
endmodule
