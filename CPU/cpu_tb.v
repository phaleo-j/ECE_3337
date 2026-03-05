`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 10:53:02 AM
// Design Name: 
// Module Name: cpu_tb
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


module cpu_tb;

    // Testbench signals
    reg clk;
    reg reset;

    // Instantiate CPU
    cpu_top DUT (
        .clk(clk),
        .reset(reset)
    );

    // ===============================
    // Clock Generation (10ns period)
    // ===============================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end

    // ===============================
    // Reset Sequence
    // ===============================
    initial begin
        reset = 1'b1;
        #20;
        reset = 1'b0;
    end

    // ===============================
    // Simulation Runtime
    // ===============================
    initial begin
        #500;     // run 500ns
        $finish;
    end

endmodule