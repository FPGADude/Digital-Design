`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: sevenseg_decimal_or_status
//
// Basys 3 four-digit seven-segment driver.
//
// When show_status = 0, displays an unsigned decimal value from 0000 to 9999.
// When show_status = 1, displays a 16-bit hexadecimal diagnostic/error code.
//
// Segment convention:
//   seg[0]=A, seg[1]=B, seg[2]=C, seg[3]=D,
//   seg[4]=E, seg[5]=F, seg[6]=G
// All segments and anodes are active-low.
//
// Display modes:
//   show_status = 0:
//       decimal_value is converted into thousands, hundreds, tens, and ones.
//       This mode is used for the filtered centimeter measurement.
//
//   show_status = 1:
//       status_value is displayed directly as four hexadecimal nibbles.
//       This mode exposes initialization progress and error codes.
//
// Multiplexing:
//   Only one physical digit is enabled at a time. digit_select advances at the
//   requested per-digit refresh rate, producing a complete four-digit frame at
//   four times that period. Persistence of vision makes all digits appear lit.
//////////////////////////////////////////////////////////////////////////////////

module sevenseg_decimal_or_status #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DIGIT_REFRESH_HZ = 1000
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        show_status,
    input  wire [13:0] decimal_value,
    input  wire [15:0] status_value,
    output reg  [6:0]  seg,
    output reg  [3:0]  an
);

    // Number of 100 MHz system clocks between digit changes.
    localparam integer DIVISOR = CLK_FREQ_HZ / (DIGIT_REFRESH_HZ * 4);
    localparam integer COUNT_WIDTH = $clog2(DIVISOR);

    // Multiplex timing and currently selected display digit.
    reg [COUNT_WIDTH-1:0] refresh_count;
    reg [1:0] digit_select;
    reg [3:0] digit;

    // Decimal conversion storage. Values beyond four decimal digits are
    // clamped to 9999 before digit extraction.
    reg [13:0] limited_value;
    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;

    // Digit refresh counter. The active anode rotates continuously.
    always @(posedge clk) begin
        if (reset) begin
            refresh_count <= 0;
            digit_select  <= 0;
        end else if (refresh_count == DIVISOR - 1) begin
            refresh_count <= 0;
            digit_select  <= digit_select + 1'b1;
        end else begin
            refresh_count <= refresh_count + 1'b1;
        end
    end

    // Combinational value conversion, digit selection, and segment decode.
    always @(*) begin
        limited_value = (decimal_value > 14'd9999) ? 14'd9999 : decimal_value;
        thousands = limited_value / 1000;
        hundreds  = (limited_value % 1000) / 100;
        tens      = (limited_value % 100) / 10;
        ones      = limited_value % 10;

        if (show_status) begin
            // Diagnostic mode: each display position receives one hexadecimal
            // nibble from the 16-bit status word.
            case (digit_select)
                2'd0: begin an = 4'b1110; digit = status_value[3:0]; end
                2'd1: begin an = 4'b1101; digit = status_value[7:4]; end
                2'd2: begin an = 4'b1011; digit = status_value[11:8]; end
                default: begin an = 4'b0111; digit = status_value[15:12]; end
            endcase
        end else begin
            // Measurement mode: select one of the four decimal digits.
            case (digit_select)
                2'd0: begin an = 4'b1110; digit = ones; end
                2'd1: begin an = 4'b1101; digit = tens; end
                2'd2: begin an = 4'b1011; digit = hundreds; end
                default: begin an = 4'b0111; digit = thousands; end
            endcase
        end

        // Active-low hexadecimal-to-seven-segment decoder.
        case (digit)
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
            default: seg = 7'b1111111;
        endcase
    end
endmodule
