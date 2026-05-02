`timescale 1ns/1ps

module seg7_control(
    input clk_100MHz,
    input reset,
    input [3:0] ones,
    input [3:0] tens,
    input [3:0] hundreds,
    input [3:0] thousands,
    output reg [0:6] seg,
    output reg [3:0] digit
);

    parameter ZERO  = 7'b0000001;
    parameter ONE   = 7'b1001111;
    parameter TWO   = 7'b0010010;
    parameter THREE = 7'b0000110;
    parameter FOUR  = 7'b1001100;
    parameter FIVE  = 7'b0100100;
    parameter SIX   = 7'b0100000;
    parameter SEVEN = 7'b0001111;
    parameter EIGHT = 7'b0000000;
    parameter NINE  = 7'b0000100;

    reg [1:0] digit_select;
    reg [16:0] digit_timer;

    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            digit_select <= 2'b00;
            digit_timer <= 17'd0;
        end
        else if(digit_timer == 17'd99_999) begin
            digit_timer <= 17'd0;
            digit_select <= digit_select + 1'b1;
        end
        else begin
            digit_timer <= digit_timer + 1'b1;
        end
    end

    always @(*) begin
        case(digit_select)
            2'b00: digit = 4'b1110;
            2'b01: digit = 4'b1101;
            2'b10: digit = 4'b1011;
            2'b11: digit = 4'b0111;
            default: digit = 4'b1111;
        endcase
    end

    always @(*) begin
        case(digit_select)
            2'b00: begin
                case(ones)
                    4'd0: seg = ZERO;
                    4'd1: seg = ONE;
                    4'd2: seg = TWO;
                    4'd3: seg = THREE;
                    4'd4: seg = FOUR;
                    4'd5: seg = FIVE;
                    4'd6: seg = SIX;
                    4'd7: seg = SEVEN;
                    4'd8: seg = EIGHT;
                    4'd9: seg = NINE;
                    default: seg = 7'b1111111;
                endcase
            end

            2'b01: begin
                case(tens)
                    4'd0: seg = ZERO;
                    4'd1: seg = ONE;
                    4'd2: seg = TWO;
                    4'd3: seg = THREE;
                    4'd4: seg = FOUR;
                    4'd5: seg = FIVE;
                    4'd6: seg = SIX;
                    4'd7: seg = SEVEN;
                    4'd8: seg = EIGHT;
                    4'd9: seg = NINE;
                    default: seg = 7'b1111111;
                endcase
            end

            2'b10: begin
                case(hundreds)
                    4'd0: seg = ZERO;
                    4'd1: seg = ONE;
                    4'd2: seg = TWO;
                    4'd3: seg = THREE;
                    4'd4: seg = FOUR;
                    4'd5: seg = FIVE;
                    4'd6: seg = SIX;
                    4'd7: seg = SEVEN;
                    4'd8: seg = EIGHT;
                    4'd9: seg = NINE;
                    default: seg = 7'b1111111;
                endcase
            end

            2'b11: begin
                case(thousands)
                    4'd0: seg = ZERO;
                    4'd1: seg = ONE;
                    4'd2: seg = TWO;
                    4'd3: seg = THREE;
                    4'd4: seg = FOUR;
                    4'd5: seg = FIVE;
                    4'd6: seg = SIX;
                    4'd7: seg = SEVEN;
                    4'd8: seg = EIGHT;
                    4'd9: seg = NINE;
                    default: seg = 7'b1111111;
                endcase
            end

            default: seg = 7'b1111111;
        endcase
    end

endmodule