`timescale 1ns / 1ps

module sevenseg_tasks(
    input  wire       clk,
    input  wire       reset,

    input  wire [3:0] digit3,       // driven to constant 0 (no thousands value)
    input  wire [3:0] digit2,       // hundreds
    input  wire [3:0] digit1,       // tens
    input  wire [3:0] digit0,       // ones

    output reg  [6:0] seg,
    output reg  [3:0] an
);

    reg [16:0] refresh_count;
    wire [1:0] active_digit;

    assign active_digit = refresh_count[16:15];

    always @(posedge clk) begin
        if (reset)
            refresh_count <= 0;
        else
            refresh_count <= refresh_count + 1'b1;
    end

    always @(*) begin
        case (active_digit)
            2'b00: select_digit(4'b1110, digit0);
            2'b01: select_digit(4'b1101, digit1);
            2'b10: select_digit(4'b1011, digit2);
            2'b11: select_digit(4'b0111, digit3);
            default: select_digit(4'b1111, 4'd0);
        endcase
    end

    // Task 1:
    // Selects which physical digit is active,
    // then calls another task to decode the number
    task select_digit;
        input [3:0] anode_value;
        input [3:0] number;
        begin
            an = anode_value;
            decode_digit(number);
        end
    endtask

    // Task 2:
    // Converts a 4-bit number into seven-segment pattern
    // Basys 3 seven-segment display is active-low
    task decode_digit;
        input [3:0] number;
        begin
            case (number)
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
    endtask

endmodule
