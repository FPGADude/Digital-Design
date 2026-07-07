// ============================================================================
// sevenseg_money.v
// ----------------------------------------------------------------------------
// Multiplexed four-digit seven-segment display driver for the current credit.
//
// The VGA display shows the full vending machine interface, but the Basys 3
// seven-segment display gives a second hardware verification point for money
// input.  It displays the active credit amount and returns to 0 after a
// successful vend/reset, matching the design behavior tested on hardware.
//
// Digits are active-low on the Basys 3.  Segment patterns below are also for
// the active-low common-anode display.
// ============================================================================
`timescale 1ns / 1ps

module sevenseg_money(
    input  wire       clk,
    input  wire       reset,
    input  wire [8:0] cents,
    output reg  [6:0] seg,
    output reg        dp,
    output reg  [3:0] an
);

    reg [16:0] refresh_count;
    wire [1:0] digit_sel = refresh_count[16:15];

    wire [3:0] dollars = cents / 100;
    wire [8:0] rem     = cents % 100;
    wire [3:0] tens    = rem / 10;
    wire [3:0] ones    = rem % 10;

    reg [3:0] digit;

    always @(posedge clk) begin
        if (reset)
            refresh_count <= 17'd0;
        else
            refresh_count <= refresh_count + 1'b1;
    end

    always @(*) begin
        an    = 4'b1111;
        dp    = 1'b1;
        digit = 4'd0;

        case (digit_sel)
            2'd0: begin an = 4'b1110; digit = ones;    dp = 1'b1; end
            2'd1: begin an = 4'b1101; digit = tens;    dp = 1'b1; end
            2'd2: begin an = 4'b1011; digit = dollars; dp = 1'b0; end
            2'd3: begin an = 4'b0111; digit = 4'd0;    dp = 1'b1; end
        endcase
    end

    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
