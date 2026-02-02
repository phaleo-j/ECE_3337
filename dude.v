`timescale 1ns / 1ps

module dude(
    input  wire [3:0] rel_x,
    input  wire [3:0] rel_y,
    output reg        sprite_on,
    output reg  [3:0] r,
    output reg  [3:0] g,
    output reg  [3:0] b
);

    // Verilog-friendly: return 1-bit value as reg
    function automatic mask_bit;
        input [15:0] rowmask;
        input [3:0]  x;
        begin
            mask_bit = rowmask[15 - x];
        end
    endfunction

    function automatic [15:0] hair_row;
        input [3:0] y;
        begin
            case (y)
                4'd0: hair_row = 16'h07E0;
                4'd1: hair_row = 16'h0FF0;
                4'd2: hair_row = 16'h0FF0;
                default: hair_row = 16'h0000;
            endcase
        end
    endfunction

    function automatic [15:0] skin_row;
        input [3:0] y;
        begin
            case (y)
                4'd3: skin_row = 16'h07E0;
                4'd4: skin_row = 16'h0FF0;
                4'd5: skin_row = 16'h0FF0;
                default: skin_row = 16'h0000;
            endcase
        end
    endfunction

    function automatic [15:0] shirt_row;
        input [3:0] y;
        begin
            case (y)
                4'd6: shirt_row = 16'h07E0;
                4'd7: shirt_row = 16'h0FF0;
                4'd8: shirt_row = 16'h1FF8;
                4'd9: shirt_row = 16'h1FF8;
                default: shirt_row = 16'h0000;
            endcase
        end
    endfunction

    function automatic [15:0] pants_row;
        input [3:0] y;
        begin
            case (y)
                4'd10: pants_row = 16'h1E78;
                4'd11: pants_row = 16'h1E78;
                4'd12: pants_row = 16'h1C38;
                default: pants_row = 16'h0000;
            endcase
        end
    endfunction

    function automatic [15:0] shoes_row;
        input [3:0] y;
        begin
            case (y)
                4'd13: shoes_row = 16'h1C38;
                4'd14: shoes_row = 16'h1C38;
                default: shoes_row = 16'h0000;
            endcase
        end
    endfunction

    always @(*) begin
        sprite_on = 1'b0;
        r = 4'h0; g = 4'h0; b = 4'h0;

        // Priority: hair > skin > shirt > pants > shoes
        if (mask_bit(hair_row(rel_y), rel_x)) begin
            sprite_on = 1'b1;
            r = 4'h0; g = 4'h0; b = 4'h0;        // hair black
        end else if (mask_bit(skin_row(rel_y), rel_x)) begin
            sprite_on = 1'b1;
            r = 4'hF; g = 4'hC; b = 4'h8;        // skin
        end else if (mask_bit(shirt_row(rel_y), rel_x)) begin
            sprite_on = 1'b1;
            r = 4'hF; g = 4'h0; b = 4'h0;        // red shirt
        end else if (mask_bit(pants_row(rel_y), rel_x)) begin
            sprite_on = 1'b1;
            r = 4'h0; g = 4'h0; b = 4'hF;        // blue pants
        end else if (mask_bit(shoes_row(rel_y), rel_x)) begin
            sprite_on = 1'b1;
            r = 4'hF; g = 4'h0; b = 4'h0;        // red shoes
        end
    end

endmodule
