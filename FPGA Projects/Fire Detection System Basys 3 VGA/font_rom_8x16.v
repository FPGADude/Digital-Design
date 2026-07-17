`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: font_rom_8x16
//
// Purpose:
//   Combinational bitmap font ROM used by the VGA renderer. Each supported ASCII
//   character is represented by an 8x8 glyph. The selected 8-bit row is repeated
//   for two adjacent scan lines, producing an 8x16 on-screen character.
//
// Inputs:
//   ascii - ASCII code of the requested character
//   row   - vertical row within the 16-pixel-high character cell
//
// Output:
//   pixels[7:0] - one horizontal glyph row, MSB displayed on the left
//
// Unsupported characters intentionally render as blank cells.
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Compact 8x16 Font ROM
//
// The 8x8 glyph data is doubled vertically to produce an 8x16 character.
// Only characters used by the flame detector interface are included.
// Unsupported characters render as blanks.
//////////////////////////////////////////////////////////////////////////////////

module font_rom_8x16 (
    input  wire [7:0] ascii,
    input  wire [3:0] row,
    output reg  [7:0] pixels
);

    // Dividing the 4-bit row by two repeats each 8x8 row twice vertically.
    wire [2:0] glyph_row = row[3:1];

    // Pure combinational ROM lookup; no clock or stored state is required.
    always @(*) begin
        pixels = 8'b00000000;

        // The outer case selects a character; each inner case selects one
        // horizontal row of its bitmap.
        case (ascii)

            8'h20: pixels = 8'b00000000; // space

            // Digits
            8'h30: case (glyph_row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01101110; 3: pixels=8'b01110110;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h31: case (glyph_row)
                0: pixels=8'b00011000; 1: pixels=8'b00111000;
                2: pixels=8'b00011000; 3: pixels=8'b00011000;
                4: pixels=8'b00011000; 5: pixels=8'b00011000;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h32: case (glyph_row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b00000110; 3: pixels=8'b00001100;
                4: pixels=8'b00110000; 5: pixels=8'b01100000;
                6: pixels=8'b01111110; default: pixels=8'b00000000;
            endcase
            8'h33: case (glyph_row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b00000110; 3: pixels=8'b00011100;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h34: case (glyph_row)
                0: pixels=8'b00001100; 1: pixels=8'b00011100;
                2: pixels=8'b00101100; 3: pixels=8'b01001100;
                4: pixels=8'b01111110; 5: pixels=8'b00001100;
                6: pixels=8'b00011110; default: pixels=8'b00000000;
            endcase
            8'h35: case (glyph_row)
                0: pixels=8'b01111110; 1: pixels=8'b01100000;
                2: pixels=8'b01111100; 3: pixels=8'b00000110;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h36: case (glyph_row)
                0: pixels=8'b00011100; 1: pixels=8'b00110000;
                2: pixels=8'b01100000; 3: pixels=8'b01111100;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h37: case (glyph_row)
                0: pixels=8'b01111110; 1: pixels=8'b01100110;
                2: pixels=8'b00000110; 3: pixels=8'b00001100;
                4: pixels=8'b00011000; 5: pixels=8'b00011000;
                6: pixels=8'b00011000; default: pixels=8'b00000000;
            endcase
            8'h38: case (glyph_row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100110; 3: pixels=8'b00111100;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100; default: pixels=8'b00000000;
            endcase
            8'h39: case (glyph_row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100110; 3: pixels=8'b00111110;
                4: pixels=8'b00000110; 5: pixels=8'b00001100;
                6: pixels=8'b00111000; default: pixels=8'b00000000;
            endcase

            // Colon
            8'h3A: case (glyph_row)
                2: pixels=8'b00011000;
                5: pixels=8'b00011000;
                default: pixels=8'b00000000;
            endcase

            // Letters A-Z
            8'h41: case (glyph_row)
                0:pixels=8'b00011000;1:pixels=8'b00111100;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01111110;5:pixels=8'b01100110;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h42: case (glyph_row)
                0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01111100;4:pixels=8'b01100110;5:pixels=8'b01100110;
                6:pixels=8'b01111100;default:pixels=0; endcase
            8'h43: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;
                3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100110;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h44: case (glyph_row)
                0:pixels=8'b01111000;1:pixels=8'b01101100;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01101100;
                6:pixels=8'b01111000;default:pixels=0; endcase
            8'h45: case (glyph_row)
                0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;
                3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;
                6:pixels=8'b01111110;default:pixels=0; endcase
            8'h46: case (glyph_row)
                0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;
                3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;
                6:pixels=8'b01100000;default:pixels=0; endcase
            8'h47: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;
                3:pixels=8'b01101110;4:pixels=8'b01100110;5:pixels=8'b01100110;
                6:pixels=8'b00111110;default:pixels=0; endcase
            8'h48: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01111110;4:pixels=8'b01100110;5:pixels=8'b01100110;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h49: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b00011000;2:pixels=8'b00011000;
                3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h4A: case (glyph_row)
                0:pixels=8'b00011110;1:pixels=8'b00001100;2:pixels=8'b00001100;
                3:pixels=8'b00001100;4:pixels=8'b01101100;5:pixels=8'b01101100;
                6:pixels=8'b00111000;default:pixels=0; endcase
            8'h4B: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01101100;2:pixels=8'b01111000;
                3:pixels=8'b01110000;4:pixels=8'b01111000;5:pixels=8'b01101100;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h4C: case (glyph_row)
                0:pixels=8'b01100000;1:pixels=8'b01100000;2:pixels=8'b01100000;
                3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100000;
                6:pixels=8'b01111110;default:pixels=0; endcase
            8'h4D: case (glyph_row)
                0:pixels=8'b01100011;1:pixels=8'b01110111;2:pixels=8'b01111111;
                3:pixels=8'b01101011;4:pixels=8'b01100011;5:pixels=8'b01100011;
                6:pixels=8'b01100011;default:pixels=0; endcase
            8'h4E: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01110110;2:pixels=8'b01111110;
                3:pixels=8'b01111110;4:pixels=8'b01101110;5:pixels=8'b01100110;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h4F: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h50: case (glyph_row)
                0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;
                6:pixels=8'b01100000;default:pixels=0; endcase
            8'h51: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01101110;5:pixels=8'b00111100;
                6:pixels=8'b00000110;default:pixels=0; endcase
            8'h52: case (glyph_row)
                0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01111100;4:pixels=8'b01111000;5:pixels=8'b01101100;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h53: case (glyph_row)
                0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;
                3:pixels=8'b00111100;4:pixels=8'b00000110;5:pixels=8'b01100110;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h54: case (glyph_row)
                0:pixels=8'b01111110;1:pixels=8'b01011010;2:pixels=8'b00011000;
                3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h55: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h56: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;
                3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b00111100;
                6:pixels=8'b00011000;default:pixels=0; endcase
            8'h57: case (glyph_row)
                0:pixels=8'b01100011;1:pixels=8'b01100011;2:pixels=8'b01100011;
                3:pixels=8'b01101011;4:pixels=8'b01111111;5:pixels=8'b01110111;
                6:pixels=8'b01100011;default:pixels=0; endcase
            8'h58: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b00111100;
                3:pixels=8'b00011000;4:pixels=8'b00111100;5:pixels=8'b01100110;
                6:pixels=8'b01100110;default:pixels=0; endcase
            8'h59: case (glyph_row)
                0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b00111100;
                3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;
                6:pixels=8'b00111100;default:pixels=0; endcase
            8'h5A: case (glyph_row)
                0:pixels=8'b01111110;1:pixels=8'b00000110;2:pixels=8'b00001100;
                3:pixels=8'b00011000;4:pixels=8'b00110000;5:pixels=8'b01100000;
                6:pixels=8'b01111110;default:pixels=0; endcase

            // Any character not explicitly defined above is blank.
            default: pixels = 8'b00000000;
        endcase
    end

endmodule
