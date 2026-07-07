// ============================================================================
// text_rom.v
// ----------------------------------------------------------------------------
// Small 8x8 bitmap font ROM used by the VGA text renderers.
//
// This is intentionally not a complete ASCII font.  It only includes the
// uppercase letters, numbers, punctuation, and symbols needed by the vending
// machine display.  Keeping the font small helps keep the renderer simple and
// easy to explain in the video.
// ============================================================================
`timescale 1ns / 1ps

module text_rom(
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] pixels
);

    // Simple 8x8 uppercase font. Only the characters used by this project are included.
    always @(*) begin
        pixels = 8'b00000000;
        case (char_code)
            "A": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0; endcase
            "B": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b01111100;default:pixels=0; endcase
            "C": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "D": case(row) 0:pixels=8'b01111000;1:pixels=8'b01101100;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01101100;6:pixels=8'b01111000;default:pixels=0; endcase
            "E": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0; endcase
            "F": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01100000;default:pixels=0; endcase
            "G": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01101110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "H": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0; endcase
            "I": case(row) 0:pixels=8'b00111100;1:pixels=8'b00011000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00111100;default:pixels=0; endcase
            "K": case(row) 0:pixels=8'b01100110;1:pixels=8'b01101100;2:pixels=8'b01111000;3:pixels=8'b01110000;4:pixels=8'b01111000;5:pixels=8'b01101100;6:pixels=8'b01100110;default:pixels=0; endcase
            "L": case(row) 0:pixels=8'b01100000;1:pixels=8'b01100000;2:pixels=8'b01100000;3:pixels=8'b01100000;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0; endcase
            "M": case(row) 0:pixels=8'b01100011;1:pixels=8'b01110111;2:pixels=8'b01111111;3:pixels=8'b01101011;4:pixels=8'b01100011;5:pixels=8'b01100011;6:pixels=8'b01100011;default:pixels=0; endcase
            "N": case(row) 0:pixels=8'b01100110;1:pixels=8'b01110110;2:pixels=8'b01111110;3:pixels=8'b01111110;4:pixels=8'b01101110;5:pixels=8'b01100110;6:pixels=8'b01100110;default:pixels=0; endcase
            "O": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "P": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01100000;5:pixels=8'b01100000;6:pixels=8'b01100000;default:pixels=0; endcase
            "Q": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01101110;5:pixels=8'b00111100;6:pixels=8'b00000110;default:pixels=0; endcase
            "R": case(row) 0:pixels=8'b01111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01111100;4:pixels=8'b01111000;5:pixels=8'b01101100;6:pixels=8'b01100110;default:pixels=0; endcase
            "S": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b00111100;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "T": case(row) 0:pixels=8'b01111110;1:pixels=8'b00011000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00011000;default:pixels=0; endcase
            "U": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "V": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b01100110;4:pixels=8'b01100110;5:pixels=8'b00111100;6:pixels=8'b00011000;default:pixels=0; endcase
            "W": case(row) 0:pixels=8'b01100011;1:pixels=8'b01100011;2:pixels=8'b01100011;3:pixels=8'b01101011;4:pixels=8'b01111111;5:pixels=8'b01110111;6:pixels=8'b01100011;default:pixels=0; endcase
            "Y": case(row) 0:pixels=8'b01100110;1:pixels=8'b01100110;2:pixels=8'b00111100;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00011000;default:pixels=0; endcase
            "0": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01101110;3:pixels=8'b01110110;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "1": case(row) 0:pixels=8'b00011000;1:pixels=8'b00111000;2:pixels=8'b00011000;3:pixels=8'b00011000;4:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b01111110;default:pixels=0; endcase
            "2": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b00000110;3:pixels=8'b00001100;4:pixels=8'b00110000;5:pixels=8'b01100000;6:pixels=8'b01111110;default:pixels=0; endcase
            "3": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b00000110;3:pixels=8'b00011100;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "4": case(row) 0:pixels=8'b00001100;1:pixels=8'b00011100;2:pixels=8'b00101100;3:pixels=8'b01001100;4:pixels=8'b01111110;5:pixels=8'b00001100;6:pixels=8'b00001100;default:pixels=0; endcase
            "5": case(row) 0:pixels=8'b01111110;1:pixels=8'b01100000;2:pixels=8'b01111100;3:pixels=8'b00000110;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "6": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100000;3:pixels=8'b01111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "7": case(row) 0:pixels=8'b01111110;1:pixels=8'b00000110;2:pixels=8'b00001100;3:pixels=8'b00011000;4:pixels=8'b00110000;5:pixels=8'b00110000;6:pixels=8'b00110000;default:pixels=0; endcase
            "8": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b00111100;4:pixels=8'b01100110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            "9": case(row) 0:pixels=8'b00111100;1:pixels=8'b01100110;2:pixels=8'b01100110;3:pixels=8'b00111110;4:pixels=8'b00000110;5:pixels=8'b01100110;6:pixels=8'b00111100;default:pixels=0; endcase
            ":": case(row) 1:pixels=8'b00011000;2:pixels=8'b00011000;5:pixels=8'b00011000;6:pixels=8'b00011000;default:pixels=0; endcase
            ".": case(row) 6:pixels=8'b00011000;default:pixels=0; endcase
            "$": case(row) 0:pixels=8'b00011000;1:pixels=8'b00111110;2:pixels=8'b01100000;3:pixels=8'b00111100;4:pixels=8'b00000110;5:pixels=8'b01111100;6:pixels=8'b00011000;default:pixels=0; endcase
            "[": case(row) 0:pixels=8'b00111100;1:pixels=8'b00110000;2:pixels=8'b00110000;3:pixels=8'b00110000;4:pixels=8'b00110000;5:pixels=8'b00110000;6:pixels=8'b00111100;default:pixels=0; endcase
            "]": case(row) 0:pixels=8'b00111100;1:pixels=8'b00001100;2:pixels=8'b00001100;3:pixels=8'b00001100;4:pixels=8'b00001100;5:pixels=8'b00001100;6:pixels=8'b00111100;default:pixels=0; endcase
            "-": case(row) 3:pixels=8'b00111100;default:pixels=0; endcase
            "=": case(row) 2:pixels=8'b01111110;4:pixels=8'b01111110;default:pixels=0; endcase
            " ": pixels = 8'b00000000;
            default: pixels = 8'b00000000;
        endcase
    end
endmodule
