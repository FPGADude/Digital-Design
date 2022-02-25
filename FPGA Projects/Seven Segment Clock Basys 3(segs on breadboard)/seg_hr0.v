`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_hr0(
    input [3:0] hours,
    output reg [3:0] hr0
    );
    
    always @(hours) begin
        case(hours)
            1   :   hr0 = 1;
            2   :   hr0 = 2;
            3   :   hr0 = 3;
            4   :   hr0 = 4;
            5   :   hr0 = 5;
            6   :   hr0 = 6;
            7   :   hr0 = 7;
            8   :   hr0 = 8;
            9   :   hr0 = 9;
            10  :   hr0 = 0;
            11  :   hr0 = 1;
            12  :   hr0 = 2;
        endcase
    end
endmodule


