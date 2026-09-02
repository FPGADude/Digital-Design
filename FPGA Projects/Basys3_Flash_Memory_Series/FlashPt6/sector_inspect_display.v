`timescale 1ns / 1ps

// ============================================================================
// Four-digit hexadecimal display for the sector inspection demo.
//
// display_value is shown directly as four hexadecimal digits.
// ============================================================================

module sector_inspect_display (
    input  wire        clk,
    input  wire [15:0] display_value,

    output reg  [6:0]  seg,
    output reg  [3:0]  an
);

    reg [17:0] refresh_counter = 18'd0;
    reg [3:0]  hex_digit;

    always @(posedge clk)
        refresh_counter <= refresh_counter + 1'b1;


    always @(*) begin

        case (refresh_counter[17:16])

            2'b00: begin
                an        = 4'b1110;
                hex_digit = display_value[3:0];
            end

            2'b01: begin
                an        = 4'b1101;
                hex_digit = display_value[7:4];
            end

            2'b10: begin
                an        = 4'b1011;
                hex_digit = display_value[11:8];
            end

            default: begin
                an        = 4'b0111;
                hex_digit = display_value[15:12];
            end

        endcase
    end


    // seg[6:0] = {g,f,e,d,c,b,a}; 0 turns a segment ON.
    always @(*) begin

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
            default: seg = 7'b1111111;
        endcase
    end

endmodule
