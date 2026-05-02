`timescale 1ns / 1ps

module bin8_to_bcd(
    input [7:0] bin_in,
    output [3:0] ones,
    output [3:0] tens,
    output [3:0] hundreds,
    output [3:0] thousands
    );
    
    assign ones      = bin_in % 10;
    assign tens      = (bin_in / 10) % 10;
    assign hundreds  = (bin_in / 100) % 10;
    assign thousands = 4'd0;
    
endmodule
