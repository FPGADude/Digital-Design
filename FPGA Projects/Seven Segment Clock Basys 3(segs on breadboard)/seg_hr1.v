`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_hr1(
    input [3:0] hours,
    output reg [3:0] hr1
    );
    
    always @(hours) begin
        case(hours)
            1   :   hr1 = 0;
            2   :   hr1 = 0;
            3   :   hr1 = 0;
            4   :   hr1 = 0;
            5   :   hr1 = 0;
            6   :   hr1 = 0;
            7   :   hr1 = 0;
            8   :   hr1 = 0;
            9   :   hr1 = 0;
            10  :   hr1 = 1;
            11  :   hr1 = 1;
            12  :   hr1 = 1;
        endcase
    end
endmodule


