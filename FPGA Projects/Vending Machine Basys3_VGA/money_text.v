// ============================================================================
// money_text.v
// ----------------------------------------------------------------------------
// Draws a money value on the VGA screen in the format $D.CC.
//
// The input value is stored in cents, which keeps the FSM arithmetic simple.
// For example:
//   75  -> $0.75
//   125 -> $1.25
//   200 -> $2.00
//
// This module breaks the cent value into decimal digits and uses char_pixel.v
// to draw each character.
// ============================================================================
`timescale 1ns / 1ps

module money_text #(
    parameter integer X0 = 0,
    parameter integer Y0 = 0,
    parameter integer SCALE = 2
)(
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [8:0] cents,
    output wire       on
);

    // Draws a value as $D.CC. This is plenty for this demo, where values
    // stay below five dollars.
    wire [3:0] dollars = cents / 100;
    wire [8:0] rem     = cents % 100;
    wire [3:0] tens    = rem / 10;
    wire [3:0] ones    = rem % 10;

    wire c0, c1, c2, c3, c4;

    char_pixel #(.X0(X0 +  0*SCALE*8), .Y0(Y0), .SCALE(SCALE)) ch0(.x(x), .y(y), .char_code("$"), .on(c0));
    char_pixel #(.X0(X0 +  1*SCALE*8), .Y0(Y0), .SCALE(SCALE)) ch1(.x(x), .y(y), .char_code("0" + dollars), .on(c1));
    char_pixel #(.X0(X0 +  2*SCALE*8), .Y0(Y0), .SCALE(SCALE)) ch2(.x(x), .y(y), .char_code("."), .on(c2));
    char_pixel #(.X0(X0 +  3*SCALE*8), .Y0(Y0), .SCALE(SCALE)) ch3(.x(x), .y(y), .char_code("0" + tens), .on(c3));
    char_pixel #(.X0(X0 +  4*SCALE*8), .Y0(Y0), .SCALE(SCALE)) ch4(.x(x), .y(y), .char_code("0" + ones), .on(c4));

    assign on = c0 | c1 | c2 | c3 | c4;
endmodule
