`timescale 1ns / 1ps

module block_sprite(
    input  wire       clk,
    input  wire [3:0] rel_x,     // 0..15
    input  wire [3:0] rel_y,     // 0..15
    output reg        on         // 1 = draw pixel
);
    wire [7:0] addr = {rel_y, rel_x}; // 256 deep

    (* ram_style = "block" *)
    reg mem [0:255];

    initial begin
        $readmemb("block_mask.mem", mem); // 256 lines of 0/1
    end

    always @(posedge clk) begin
        on <= mem[addr];
    end
endmodule