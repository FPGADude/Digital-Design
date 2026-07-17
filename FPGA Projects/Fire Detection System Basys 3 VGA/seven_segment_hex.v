`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: seven_segment_hex
//
// Purpose:
//   Multiplexes the Basys 3 four-digit seven-segment display and shows a 16-bit
//   value as four hexadecimal digits. The display is common-anode, so both the
//   segment outputs and digit-enable outputs are active-low.
//
// Display order:
//   an[0] shows value[3:0] and an[3] shows value[15:12].
//////////////////////////////////////////////////////////////////////////////////
module seven_segment_hex (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] value,
    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output wire        dp
);

    // Upper counter bits select one of the four physical digits.
    reg [16:0] refresh_counter;
    wire [1:0] digit_select = refresh_counter[16:15];
    reg [3:0] digit_value;

    // Decimal point is active-low and is intentionally disabled.
    assign dp = 1'b1;

    // Free-running refresh divider for display multiplexing.
    always @(posedge clk) begin
        if (reset)
            refresh_counter <= 17'd0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    // Select the active-low anode and matching four-bit nibble.
    always @(*) begin
        case (digit_select)
            2'b00: begin an=4'b1110; digit_value=value[3:0]; end
            2'b01: begin an=4'b1101; digit_value=value[7:4]; end
            2'b10: begin an=4'b1011; digit_value=value[11:8]; end
            default: begin an=4'b0111; digit_value=value[15:12]; end
        endcase
    end

    // Hexadecimal-to-seven-segment decoder. Segment outputs are active-low.
    always @(*) begin
        case (digit_value)
            4'h0: seg=7'b1000000; 4'h1: seg=7'b1111001;
            4'h2: seg=7'b0100100; 4'h3: seg=7'b0110000;
            4'h4: seg=7'b0011001; 4'h5: seg=7'b0010010;
            4'h6: seg=7'b0000010; 4'h7: seg=7'b1111000;
            4'h8: seg=7'b0000000; 4'h9: seg=7'b0010000;
            4'hA: seg=7'b0001000; 4'hB: seg=7'b0000011;
            4'hC: seg=7'b1000110; 4'hD: seg=7'b0100001;
            4'hE: seg=7'b0000110; default: seg=7'b0001110;
        endcase
    end
endmodule
