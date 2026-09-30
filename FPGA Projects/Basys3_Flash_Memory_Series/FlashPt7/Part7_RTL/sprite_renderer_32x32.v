`timescale 1ns / 1ps

// ============================================================================
// 32x32 RGB332 Sprite Renderer
//
// Each source sprite contains 1024 bytes arranged row-major:
//   address = (row * 32) + column
//
// The source image is displayed at 4x scale, producing a 128x128 VGA sprite.
// Four VGA pixels in X and four in Y therefore map to one source pixel.
//
// RGB332 byte format:
//   bits [7:5] = red
//   bits [4:2] = green
//   bits [1:0] = blue
//
// 0x5A is reserved by the PNG conversion utility as the transparency key.
// 0x00 remains available as true visible black.
// ============================================================================
module sprite_renderer_32x32 (
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [9:0]  origin_x,
    input  wire [9:0]  origin_y,
    input  wire        enable,

    input  wire [7:0]  sprite_data,
    output reg  [9:0]  sprite_addr,

    output reg         sprite_on,
    output reg  [11:0] sprite_rgb
);

    reg [4:0] source_x;
    reg [4:0] source_y;

    always @(*) begin
        sprite_addr = 10'd0;
        sprite_on   = 1'b0;
        sprite_rgb  = 12'h000;
        source_x    = 5'd0;
        source_y    = 5'd0;

        // Determine whether the current VGA coordinate falls inside this
        // sprite's 128x128 displayed area.
        if (enable &&
            pixel_x >= origin_x &&
            pixel_x <  origin_x + 10'd128 &&
            pixel_y >= origin_y &&
            pixel_y <  origin_y + 10'd128) begin

            // Divide the local VGA coordinates by four to recover the
            // corresponding 32x32 source-image coordinate.
            source_x = (pixel_x - origin_x) >> 2;
            source_y = (pixel_y - origin_y) >> 2;

            // row * 32 + column
            sprite_addr = {source_y, 5'b00000} + source_x;

            if (sprite_data == 8'h5A) begin
                // Transparent pixels allow the lower-priority background
                // layer to remain visible.
                sprite_on  = 1'b0;
                sprite_rgb = 12'h000;
            end else begin
                sprite_on = 1'b1;

                // Expand RGB332 into the Basys 3 RGB444 VGA format by
                // replicating the available high-order color bits.
                sprite_rgb[11:8] = {sprite_data[7:5], sprite_data[7]};
                sprite_rgb[7:4]  = {sprite_data[4:2], sprite_data[4]};
                sprite_rgb[3:0]  = {sprite_data[1:0], sprite_data[1:0]};
            end
        end
    end

endmodule
