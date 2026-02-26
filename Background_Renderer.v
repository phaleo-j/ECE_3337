`timescale 1ns / 1ps

module Background_Renderer(
    input  wire        pixel_clk,
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire [9:0]  scroll_x,
    output wire [3:0]  bgR,
    output wire [3:0]  bgG,
    output wire [3:0]  bgB
);
    wire visible = (h_count < 10'd640) && (v_count < 10'd480);

    // pipeline visible for BRAM latency (tilemap+tile+palette = 3 cycles)
    reg [2:0] vis_d = 3'b000;
    always @(posedge pixel_clk) begin
        vis_d <= {vis_d[1:0], visible};
    end
    wire visible_d = vis_d[2];

    wire [7:0] tile_x;
    wire [4:0] tile_y;
    wire [3:0] px, py;

    wire [7:0] tile_id;
    wire [3:0] color_idx;

    // pipeline px/py to match tilemap BRAM latency (1 cycle)
    reg [3:0] px_d, py_d;
    always @(posedge pixel_clk) begin
        px_d <= px;
        py_d <= py;
    end

    Tile_Address u_addr(
        .h_count(h_count),
        .v_count(v_count),
        .scroll_x(scroll_x),
        .tile_x(tile_x),
        .tile_y(tile_y),
        .px(px),
        .py(py)
    );

    Tilemap_ROM u_map(
        .clk(pixel_clk),
        .tile_x(tile_x),
        .tile_y(tile_y),
        .tile_id(tile_id)
    );

    Tile_ROM u_tiles(
        .clk(pixel_clk),
        .tile_id(tile_id),
        .px(px_d),
        .py(py_d),
        .color_idx(color_idx)
    );

    wire [3:0] pr, pg, pb;
    Palette u_pal(
        .clk(pixel_clk),
        .color_idx(color_idx),
        .r(pr),
        .g(pg),
        .b(pb)
    );

    assign bgR = visible_d ? pr : 4'h0;
    assign bgG = visible_d ? pg : 4'h0;
    assign bgB = visible_d ? pb : 4'h0;

endmodule