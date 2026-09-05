`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Reusable 32x32 sprite renderer.
//
// For the current VGA pixel:
//   1) Check whether the pixel is inside the sprite bounding box.
//   2) Convert screen coordinates to local sprite coordinates.
//   3) Convert local x/y to a row-major ROM address.
//   4) Read RGB332 color from sprite ROM.
//   5) Treat 8'h00 as transparent.
//
// Outputs:
//   sprite_on  = 1 when this sprite owns the current pixel
//   sprite_rgb = RGB332 color for the current sprite pixel
// -----------------------------------------------------------------------------
module sprite_renderer (
    input  wire [9:0] pixel_x,          // from vga timing
    input  wire [9:0] pixel_y,          // from vga timing
    input  wire [9:0] sprite_x,         // from motion control
    input  wire [8:0] sprite_y,         // from motion control
    output wire       sprite_on,        // used in top module logic
    output wire [7:0] sprite_rgb        // used in top module logic
);

    localparam integer SPRITE_W = 32;
    localparam integer SPRITE_H = 32;
    localparam [7:0] TRANSPARENT_COLOR = 8'h00;     // reserved transparent value

    wire inside_x;
    wire inside_y;
    wire inside_box;

    // Bounding Box Horizontal
    assign inside_x = (pixel_x >= sprite_x) &&
                      (pixel_x <  sprite_x + SPRITE_W);

    // Bounding Box Vertical
    assign inside_y = (pixel_y >= sprite_y) &&
                      (pixel_y <  sprite_y + SPRITE_H);

    // Bounding Box Full Sprite
    assign inside_box = inside_x && inside_y;

    // Valid only when inside_box = 1.
    wire [5:0] local_x = pixel_x - sprite_x;
    wire [5:0] local_y = pixel_y - sprite_y;

    // 32 pixels/row = shift left by 5, then add column.
    wire [9:0] rom_addr = {local_y[4:0], 5'b00000} + local_x[4:0];

    wire [7:0] rom_data;

    sprite_rom u_sprite_rom (
        .addr (rom_addr),
        .data (rom_data)
    );

    assign sprite_rgb = rom_data;

    // A pixel belongs to the sprite only if it is inside the bounding box
    // AND the ROM pixel is not the transparent color.
    assign sprite_on = inside_box && (rom_data != TRANSPARENT_COLOR);

endmodule
