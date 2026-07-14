`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: font_rom.v
// Project: Pmod ACL VGA Display for Basys 3
//
// 8x8 bitmap font ROM implemented as combinational case statements. It supports 
// the digits, signs, punctuation, capital letters, and the lowercase g/z
// characters needed by the VGA display.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// Small uppercase 8x8 font ROM.
// Inputs select an ASCII character and a row number. The output byte contains
// the eight pixels for that row, with bit 7 on the left.
module font_rom(
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] pixels
);

    // Combinational character/row lookup. Unsupported characters default to
    // blank pixels. Each case entry describes one 8-row glyph.
    always @(*) begin
        pixels = 8'b00000000;
        case (char_code)
            " ": pixels = 8'b00000000;
            ":": case(row) 1: pixels=8'b00011000; 2: pixels=8'b00011000; 5: pixels=8'b00011000; 6: pixels=8'b00011000; default: pixels=0; endcase
            "+": case(row) 1: pixels=8'b00011000; 2: pixels=8'b00011000; 3: pixels=8'b01111110; 4: pixels=8'b00011000; 5: pixels=8'b00011000; default: pixels=0; endcase
            "-": case(row) 3: pixels=8'b01111110; default: pixels=0; endcase
            ".": case(row) 6: pixels=8'b00011000; 7: pixels=8'b00011000; default: pixels=0; endcase
            "|": case(row) 0:pixels=8'b00011000;1:pixels=8'b00011000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00011000;7:pixels=8'b00011000;default:pixels=0;endcase
            "g": case(row) 1:pixels=8'b00111110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b00111110;5:pixels=8'b00000110;6:pixels=8'b00111100;default:pixels=0;endcase
            "z": case(row) 1:pixels=8'b01111110;2:pixels=8'b00001100;3:pixels=8'b00011000;4:pixels=8'b00110000;5:pixels=8'b01111110;default:pixels=0;endcase
            "/": case(row) 0:pixels=8'b00000110;1:pixels=8'b00001100;2:pixels=8'b00011000;3:pixels=8'b00110000;4:pixels=8'b01100000;5:pixels=8'b11000000;default:pixels=0;endcase
            "0": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01101110;3:pixels=8'b01110110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "1": case(row) 0:pixels=8'b00011000;1:pixels=8'b00111000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b01111110;default:pixels=0;endcase
            "2": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b00000110;3:pixels=8'b00001100;4:pixels=8'b00110000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0;endcase
            "3": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b00000110;3:pixels=8'b00011100;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "4": case(row) 0:pixels=8'b00001100;1:pixels=8'b00011100;2:pixels=8'b00101100;3:pixels=8'b01001100;4:pixels=8'b01111110;5:pixels=8'b00001100;6:pixels=8'b00011110;default:pixels=0;endcase
            "5": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01111100;3:pixels=8'b00000110;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "6": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "7": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100110;2:pixels=8'b00001100;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00011000;default:pixels=0;endcase
            "8": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b00111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "9": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b00111110;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "A": case(row) 0:pixels=8'b00011000;1:pixels=8'b00111100;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01111110;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0;endcase
            "B": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b01111100;default:pixels=0;endcase
            "C": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "D": case(row) 0:pixels=8'b01111000;1:pixels=8'b01101100;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01101100;6:pixels=8'b01111000;default:pixels=0;endcase
            "E": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0;endcase
            "F": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01100000;default:pixels=0;endcase
            "G": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01101110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "H": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0;endcase
            "I": case(row) 0:pixels=8'b00111100;1:pixels=8'b00011000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00111100;default:pixels=0;endcase
            "L": case(row) 0:pixels=8'b01100000;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0;endcase
            "M": case(row) 0:pixels=8'b01100011;1:pixels=8'b01110111;2:pixels=8'b01111111;3:pixels=8'b01101011;4:pixels=8'b01100011;5:pixels=8'b01100011;6:pixels=8'b01100011;default:pixels=0;endcase
            "N": case(row) 0:pixels=8'b01100011;1:pixels=8'b01110011;2:pixels=8'b01111011;3:pixels=8'b01101111;4:pixels=8'b01100111;5:pixels=8'b01100011;6:pixels=8'b01100011;default:pixels=0;endcase
            "O": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "P": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01100000;default:pixels=0;endcase
            "R": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01101100;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0;endcase
            "S": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b00111100;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "T": case(row) 0:pixels=8'b01111110;1:pixels=8'b01011010;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00111100;default:pixels=0;endcase
            "U": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0;endcase
            "V": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b00111100;6:pixels=8'b00011000;default:pixels=0;endcase
            "W": case(row) 0:pixels=8'b01100011;1:pixels=8'b01100011;2:pixels=8'b01100011;3:pixels=8'b01101011;4:pixels=8'b01111111;5:pixels=8'b01110111;6:pixels=8'b01100011;default:pixels=0;endcase
            "X": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b00111100;3:pixels=8'b00011000;4:pixels=8'b00111100;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0;endcase
            "Y": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b00111100;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00111100;default:pixels=0;endcase
            "Z": case(row) 0:pixels=8'b01111110;1:pixels=8'b00000110;2:pixels=8'b00001100;3:pixels=8'b00011000;4:pixels=8'b00110000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0;endcase
            default: pixels = 8'b00000000;
        endcase
    end
endmodule



