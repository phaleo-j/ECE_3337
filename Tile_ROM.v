`timescale 1ns / 1ps

module Tile_ROM(
    input  wire        clk,       // <-- NEW (pixel clock)
    input  wire [7:0]  tile_id,
    input  wire [3:0]  px,
    input  wire [3:0]  py,
    output reg  [3:0]  color_idx
);
    // Tile IDs (same as before)
    localparam [7:0] T_SKY   = 8'd0;
    localparam [7:0] T_GRASS = 8'd1;
    localparam [7:0] T_CLOUD = 8'd2;
    localparam [7:0] T_SUN   = 8'd3;
    localparam [7:0] T_MTN   = 8'd4;

    // Map 8-bit tile_id -> small index 0..4 (3 bits)
    reg [2:0] tid;
    always @(*) begin
        case (tile_id)
            T_SKY:   tid = 3'd0;
            T_GRASS: tid = 3'd1;
            T_CLOUD: tid = 3'd2;
            T_SUN:   tid = 3'd3;
            T_MTN:   tid = 3'd4;
            default: tid = 3'd0;
        endcase
    end

    // Address = {tile_index(3), py(4), px(4)} => 11 bits => 2048 deep
    wire [10:0] addr = {tid, py, px};

    // BRAM-backed ROM
    (* ram_style = "block" *)
    reg [3:0] mem [0:2047];

    // Load from file (recommended / most reliable for BRAM init)
    initial begin
        $readmemh("tiles4bpp.mem", mem);  // 4-bit hex values (0..F) per line
    end

    // Synchronous read => BRAM inference (1-cycle latency)
    always @(posedge clk) begin
        color_idx <= mem[addr];
    end

endmodule