`timescale 1ns / 1ps

// ============================================================================
// Four-Digit Seven-Segment Hex Display
//
// Display format:
//
//       digit 3   digit 2   digit 1   digit 0
//         TXH       TXL       RXH       RXL
//
// Example after programming and reading back 0x5A:
//
//                       5 A 5 A
//
// Before the flash operation completes, the readback side is blank.
//
// IMPORTANT BASYS 3 SEGMENT ORDER
// -------------------------------
// In the standard Basys 3 XDC:
//
//     seg[0] = CA
//     seg[1] = CB
//     seg[2] = CC
//     seg[3] = CD
//     seg[4] = CE
//     seg[5] = CF
//     seg[6] = CG
//
// Therefore the Verilog vector seg[6:0] is:
//
//     {CG, CF, CE, CD, CC, CB, CA}
//       g   f   e   d   c   b   a
//
// All segment outputs and digit enables are active LOW.
// ============================================================================

module sevenseg_hex_compare (
    input  wire       clk,
    input  wire [7:0] programmed_byte,
    input  wire [7:0] readback_byte,
    input  wire       complete,

    output reg  [6:0] seg,
    output reg  [3:0] an,
    output wire       dp
);

    // ------------------------------------------------------------------------
    // Refresh counter
    //
    // Bits [17:16] select one of the four digits.
    // ------------------------------------------------------------------------

    reg [17:0] refresh_counter = 18'd0;

    reg [3:0] hex_digit;
    reg       blank_digit;


    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1'b1;
    end


    // Decimal point unused.
    assign dp = 1'b1;


    // ------------------------------------------------------------------------
    // Digit multiplexer
    // ------------------------------------------------------------------------

    always @(*) begin

        hex_digit   = 4'h0;
        blank_digit = 1'b0;

        case (refresh_counter[17:16])

            // Rightmost digit: readback low nibble.
            2'b00: begin

                an = 4'b1110;

                if (complete)
                    hex_digit = readback_byte[3:0];
                else
                    blank_digit = 1'b1;

            end


            // Readback high nibble.
            2'b01: begin

                an = 4'b1101;

                if (complete)
                    hex_digit = readback_byte[7:4];
                else
                    blank_digit = 1'b1;

            end


            // Selected/programmed low nibble.
            2'b10: begin

                an        = 4'b1011;
                hex_digit = programmed_byte[3:0];

            end


            // Leftmost digit: selected/programmed high nibble.
            default: begin

                an        = 4'b0111;
                hex_digit = programmed_byte[7:4];

            end

        endcase
    end


    // ------------------------------------------------------------------------
    // Hexadecimal decoder
    //
    // seg[6:0] = {g,f,e,d,c,b,a}
    //
    // 0 = segment ON
    // 1 = segment OFF
    // ------------------------------------------------------------------------

    always @(*) begin

        if (blank_digit) begin

            seg = 7'b1111111;

        end else begin

            case (hex_digit)

                4'h0: seg = 7'b1000000;
                4'h1: seg = 7'b1111001;
                4'h2: seg = 7'b0100100;
                4'h3: seg = 7'b0110000;
                4'h4: seg = 7'b0011001;
                4'h5: seg = 7'b0010010;
                4'h6: seg = 7'b0000010;
                4'h7: seg = 7'b1111000;

                4'h8: seg = 7'b0000000;
                4'h9: seg = 7'b0010000;
                4'hA: seg = 7'b0001000;
                4'hB: seg = 7'b0000011;
                4'hC: seg = 7'b1000110;
                4'hD: seg = 7'b0100001;
                4'hE: seg = 7'b0000110;
                4'hF: seg = 7'b0001110;

                default:
                    seg = 7'b1111111;

            endcase
        end
    end

endmodule
