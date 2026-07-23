`timescale 1ns / 1ps

// ============================================================================
// Module: font_rom
// Project: FPGA Motion Security System
//
// Purpose:
//   Implements a combinational 8x8 bitmap font used by the VGA renderer.
//
// Inputs:
//   char_code - ASCII code of the requested character.
//   row       - bitmap row number, 0 through 7.
//
// Output:
//   pixels    - eight horizontal pixels for the selected character row.
//               Bit 7 is the leftmost pixel and bit 0 is the rightmost.
//
// Notes:
//   Only characters required by the security-system interface are included.
//   Unsupported characters return a blank row.
// ============================================================================
module font_rom (
    input  logic [7:0] char_code,
    input  logic [2:0] row,
    output logic [7:0] pixels
);

    // Combinational lookup: character code first, then glyph row.
    always_comb begin
        pixels = 8'b00000000;

        case (char_code)

            // Space and punctuation used by the interface.
            " ": pixels = 8'b00000000;

            ":": case (row)
                1, 2, 5, 6: pixels = 8'b00011000;
                default:    pixels = 8'b00000000;
            endcase

            "=": case (row)
                2, 4:    pixels = 8'b01111110;
                default: pixels = 8'b00000000;
            endcase

            ".": case (row)
                6, 7:    pixels = 8'b00011000;
                default: pixels = 8'b00000000;
            endcase

            // Decimal and hexadecimal digits.
            "0": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01101110; 3: pixels=8'b01110110;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "1": case (row)
                0: pixels=8'b00011000; 1: pixels=8'b00111000;
                2: pixels=8'b00011000; 3: pixels=8'b00011000;
                4: pixels=8'b00011000; 5: pixels=8'b00011000;
                6: pixels=8'b01111110;
                default: pixels=0;
            endcase

            "2": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b00000110; 3: pixels=8'b00001100;
                4: pixels=8'b00110000; 5: pixels=8'b01100000;
                6: pixels=8'b01111110;
                default: pixels=0;
            endcase

            "3": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b00000110; 3: pixels=8'b00011100;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "4": case (row)
                0: pixels=8'b00001100; 1: pixels=8'b00011100;
                2: pixels=8'b00101100; 3: pixels=8'b01001100;
                4: pixels=8'b01111110; 5: pixels=8'b00001100;
                6: pixels=8'b00011110;
                default: pixels=0;
            endcase

            "5": case (row)
                0: pixels=8'b01111110; 1: pixels=8'b01100000;
                2: pixels=8'b01111100; 3: pixels=8'b00000110;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "6": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100000; 3: pixels=8'b01111100;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "7": case (row)
                0: pixels=8'b01111110; 1: pixels=8'b01100110;
                2: pixels=8'b00001100; 3: pixels=8'b00011000;
                4: pixels=8'b00011000; 5: pixels=8'b00011000;
                6: pixels=8'b00011000;
                default: pixels=0;
            endcase

            "8": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100110; 3: pixels=8'b00111100;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "9": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100110; 3: pixels=8'b00111110;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            // Uppercase alphabet characters required by screen messages.
            "A": case (row)
                0: pixels=8'b00011000; 1: pixels=8'b00111100;
                2: pixels=8'b01100110; 3: pixels=8'b01100110;
                4: pixels=8'b01111110; 5: pixels=8'b01100110;
                6: pixels=8'b01100110;
                default: pixels=0;
            endcase

            "B": case (row)
                0: pixels=8'b01111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100110; 3: pixels=8'b01111100;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b01111100;
                default: pixels=0;
            endcase

            "C": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100000; 3: pixels=8'b01100000;
                4: pixels=8'b01100000; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "D": case (row)
                0: pixels=8'b01111000; 1: pixels=8'b01101100;
                2: pixels=8'b01100110; 3: pixels=8'b01100110;
                4: pixels=8'b01100110; 5: pixels=8'b01101100;
                6: pixels=8'b01111000;
                default: pixels=0;
            endcase

            "E": case (row)
                0: pixels=8'b01111110; 1: pixels=8'b01100000;
                2: pixels=8'b01100000; 3: pixels=8'b01111100;
                4: pixels=8'b01100000; 5: pixels=8'b01100000;
                6: pixels=8'b01111110;
                default: pixels=0;
            endcase

            "F": case (row)
                0: pixels=8'b01111110; 1: pixels=8'b01100000;
                2: pixels=8'b01100000; 3: pixels=8'b01111100;
                4: pixels=8'b01100000; 5: pixels=8'b01100000;
                6: pixels=8'b01100000;
                default: pixels=0;
            endcase

            "G": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100000; 3: pixels=8'b01101110;
                4: pixels=8'b01100110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "H": case (row)
                0,1,2,4,5,6: pixels=8'b01100110;
                3: pixels=8'b01111110;
                default: pixels=0;
            endcase

            "I": case (row)
                0,6: pixels=8'b00111100;
                1,2,3,4,5: pixels=8'b00011000;
                default: pixels=0;
            endcase

            "L": case (row)
                0,1,2,3,4,5: pixels=8'b01100000;
                6: pixels=8'b01111110;
                default: pixels=0;
            endcase

            "M": case (row)
                0: pixels=8'b01100011; 1: pixels=8'b01110111;
                2: pixels=8'b01111111; 3: pixels=8'b01101011;
                4,5,6: pixels=8'b01100011;
                default: pixels=0;
            endcase

            "N": case (row)
                0: pixels=8'b01100011; 1: pixels=8'b01110011;
                2: pixels=8'b01111011; 3: pixels=8'b01101111;
                4: pixels=8'b01100111; 5,6: pixels=8'b01100011;
                default: pixels=0;
            endcase

            "O": case (row)
                0: pixels=8'b00111100; 1,2,3,4,5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "P": case (row)
                0: pixels=8'b01111100; 1,2: pixels=8'b01100110;
                3: pixels=8'b01111100; 4,5,6: pixels=8'b01100000;
                default: pixels=0;
            endcase

            "R": case (row)
                0: pixels=8'b01111100; 1,2: pixels=8'b01100110;
                3: pixels=8'b01111100; 4: pixels=8'b01101100;
                5,6: pixels=8'b01100110;
                default: pixels=0;
            endcase

            "S": case (row)
                0: pixels=8'b00111100; 1: pixels=8'b01100110;
                2: pixels=8'b01100000; 3: pixels=8'b00111100;
                4: pixels=8'b00000110; 5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "T": case (row)
                0: pixels=8'b01111110; 1: pixels=8'b01011010;
                2,3,4,5: pixels=8'b00011000;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "U": case (row)
                0,1,2,3,4,5: pixels=8'b01100110;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase

            "V": case (row)
                0,1,2,3,4: pixels=8'b01100110;
                5: pixels=8'b00111100;
                6: pixels=8'b00011000;
                default: pixels=0;
            endcase

            "W": case (row)
                0,1,2: pixels=8'b01100011;
                3: pixels=8'b01101011;
                4: pixels=8'b01111111;
                5: pixels=8'b01110111;
                6: pixels=8'b01100011;
                default: pixels=0;
            endcase

            "Y": case (row)
                0,1: pixels=8'b01100110;
                2: pixels=8'b00111100;
                3,4,5: pixels=8'b00011000;
                6: pixels=8'b00111100;
                default: pixels=0;
            endcase


            "Z": case (row)
                0: pixels=8'b01111110;
                1: pixels=8'b00000110;
                2: pixels=8'b00001100;
                3: pixels=8'b00011000;
                4: pixels=8'b00110000;
                5: pixels=8'b01100000;
                6: pixels=8'b01111110;
                default: pixels=0;
            endcase

            default:
                pixels = 8'b00000000;

        endcase
    end

endmodule
