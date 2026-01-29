`timescale 1ns / 1ps
module top(
    input  wire clk,             // 100 MHz Basys 3 clock
    output reg  Hsync,            // VGA HSYNC (active low)
    output reg  Vsync,            // VGA VSYNC (active low)
    output reg [3:0] vgaRed,      // VGA R[3:0]
    output reg [3:0] vgaGreen,    // VGA G[3:0]
    output reg [3:0] vgaBlue      // VGA B[3:0]
);

    reg [9:0] pixel_x = 10'd320;          // sprite center X (0..639 visible)
    reg [9:0] pixel_y = 10'd240;          // sprite center Y (0..479 visible)
    reg signed [10:0] dx = 11'sd3;        // X step per frame (signed)
    reg signed [10:0] dy = 11'sd2;        // Y step per frame (signed)

    localparam [9:0] HALF = 10'd20;

    reg [1:0] clk_div = 2'd0;
    always @(posedge clk)
        clk_div <= clk_div + 1'b1;

    wire pixel_clk;
    assign pixel_clk = clk_div[1];        // 25 MHz pixel clock

    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    reg [9:0] h_count = 10'd0;            // X scan: 0..799
    reg [9:0] v_count = 10'd0;            // Y scan: 0..524

    always @(posedge pixel_clk) begin
        if (h_count == H_TOTAL-1) begin
            h_count <= 10'd0;
            if (v_count == V_TOTAL-1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 1'b1;
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    always @(*) begin
        Hsync = ~(h_count >= (H_VISIBLE + H_FRONT) &&
                  h_count <  (H_VISIBLE + H_FRONT + H_SYNC));

        Vsync = ~(v_count >= (V_VISIBLE + V_FRONT) &&
                  v_count <  (V_VISIBLE + V_FRONT + V_SYNC));
    end

    reg vsync_d = 1'b1;                    // delayed Vsync
    wire new_frame;
    assign new_frame = (vsync_d == 1'b1) && (Vsync == 1'b0);  // falling edge

    always @(posedge pixel_clk)
        vsync_d <= Vsync;

    always @(posedge pixel_clk) begin
        if (new_frame) begin
            // Bounce left/right edges
            if (pixel_x + dx > (10'd639 - HALF))
                dx <= -dx;
            else if (pixel_x + dx < HALF)
                dx <= -dx;

            // Bounce top/bottom edges
            if (pixel_y + dy > (10'd479 - HALF))
                dy <= -dy;
            else if (pixel_y + dy < HALF)
                dy <= -dy;

            // Update position
            pixel_x <= pixel_x + dx;
            pixel_y <= pixel_y + dy;
        end
    end

    always @(*) begin
        // Default: black
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        // Only draw in visible region
        if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
            // Draw a filled square centered at (pixel_x, pixel_y)
            // Use "+ HALF >= center" form to avoid underflow issues.
            if ( (h_count + HALF >= pixel_x) && (h_count <= pixel_x + HALF) &&
                 (v_count + HALF >= pixel_y) && (v_count <= pixel_y + HALF) ) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hF;
                vgaBlue  = 4'hF;
            end
        end
    end

endmodule
