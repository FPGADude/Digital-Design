`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: text_renderer.v
// Project: Pmod ACL VGA Display for Basys 3
//
// Reusable 8x8 text helper. Given a text origin, pixel coordinate, and character 
// code, it reports whether the current pixel should be lit for that character.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// Single-character text renderer.
// The main VGA renderer can use this block when it wants to draw one 8x8
// character at a chosen screen location.
module text_renderer(
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] text_x,
    input  wire [9:0] text_y,
    input  wire [7:0] char_code,
    output wire       pixel_on
);

    // True when the current VGA pixel lies inside this character cell.
    wire in_box = (x >= text_x) && (x < text_x + 8) &&
                  (y >= text_y) && (y < text_y + 8);

    wire [2:0] row = y[2:0] - text_y[2:0];
    wire [2:0] col = x[2:0] - text_x[2:0];
    wire [7:0] font_bits;

    font_rom u_font(
        .char_code(char_code),
        .row(row),
        .pixels(font_bits)
    );

    // Select the correct bit from the font row. The MSB is the leftmost pixel.
    assign pixel_on = in_box && font_bits[7-col];

endmodule

