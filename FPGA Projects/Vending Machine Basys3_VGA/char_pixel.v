// ============================================================================
// char_pixel.v
// ----------------------------------------------------------------------------
// Draws one 8x8 font character at a fixed VGA screen location.
//
// This module is a small wrapper around text_rom.  The current VGA pixel
// coordinate, x/y, is compared against the character box.  If the pixel is
// inside the box, the module converts the screen coordinate into a font row
// and column and asserts on when that font pixel should be lit.
//
// Used by money_text.v to draw values such as $1.25 one character at a time.
// ============================================================================
`timescale 1ns / 1ps

module char_pixel #(
    parameter integer X0 = 0,
    parameter integer Y0 = 0,
    parameter integer SCALE = 2
)(
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [7:0] char_code,
    output wire       on
);

    // Single-character version of text_pixel. Coordinates are also clamped
    // outside the character box to prevent any out-of-range font indexing
    // from creating VGA artifacts after synthesis.

    wire in_box = (x >= X0) && (x < X0 + 8*SCALE) &&
                  (y >= Y0) && (y < Y0 + 8*SCALE);

    wire [9:0] local_x = in_box ? (x - X0) : 10'd0;
    wire [9:0] local_y = in_box ? (y - Y0) : 10'd0;
    wire [2:0] font_col = local_x / SCALE;
    wire [2:0] font_row = local_y / SCALE;

    wire [7:0] font_pixels;

    text_rom rom_inst(
        .char_code(in_box ? char_code : " "),
        .row(font_row),
        .pixels(font_pixels)
    );

    assign on = in_box && font_pixels[7-font_col];
endmodule
