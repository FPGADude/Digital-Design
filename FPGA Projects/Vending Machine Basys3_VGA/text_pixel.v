// ============================================================================
// text_pixel.v
// ----------------------------------------------------------------------------
// Fixed-location VGA text renderer for short labels and instructions.
//
// The string is supplied as a Verilog parameter.  Each character is an 8x8
// bitmap from text_rom.v and may be scaled by SCALE.  The module outputs on=1
// when the current VGA pixel belongs to one of the visible text pixels.
//
// Important detail: the coordinate math is clamped when the current pixel is
// outside the text box.  That prevents out-of-range ROM/string indexing from
// creating stray VGA artifacts after synthesis.
// ============================================================================
`timescale 1ns / 1ps

module text_pixel #(
    parameter integer X0 = 0,
    parameter integer Y0 = 0,
    parameter integer SCALE = 2,
    parameter integer LEN = 32,
    parameter [8*64-1:0] TEXT = "                                                                "
)(
    input  wire [9:0] x,
    input  wire [9:0] y,
    output wire       on
);

    // --------------------------------------------------------------------
    // Safe text renderer for a fixed-length string.
    //
    // Earlier versions allowed x/y subtraction and string indexing to happen
    // even when the current pixel was outside the text box. The final output
    // was gated by in_box, but synthesis can still build logic for those
    // out-of-range cases. On VGA this can show up as little stray vertical
    // line artifacts near text. This version clamps everything outside the
    // text box to a normal SPACE character before the font ROM is read.
    // --------------------------------------------------------------------

    localparam integer CHAR_W = 8 * SCALE;
    localparam integer CHAR_H = 8 * SCALE;
    localparam integer TEXT_W = LEN * CHAR_W;

    wire in_box = (x >= X0) && (x < X0 + TEXT_W) &&
                  (y >= Y0) && (y < Y0 + CHAR_H);

    wire [9:0] local_x = in_box ? (x - X0) : 10'd0;
    wire [9:0] local_y = in_box ? (y - Y0) : 10'd0;

    wire [5:0] char_index = local_x / CHAR_W;
    wire [2:0] font_col   = (local_x % CHAR_W) / SCALE;
    wire [2:0] font_row   = (local_y % CHAR_H) / SCALE;

    reg [7:0] char_code;
    wire [7:0] font_pixels;

    text_rom rom_inst(
        .char_code(char_code),
        .row(font_row),
        .pixels(font_pixels)
    );

    always @(*) begin
        char_code = " ";
        if (in_box && (char_index < LEN)) begin
            char_code = TEXT[8*(LEN-1-char_index) +: 8];
        end
    end

    assign on = in_box && font_pixels[7-font_col];
endmodule
