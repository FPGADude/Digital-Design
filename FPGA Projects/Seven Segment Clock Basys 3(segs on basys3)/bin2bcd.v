`timescale 1ns / 1ps

module bin2bcd(
    input [5:0] bin_in,
    output reg [2:0] tens,      // max value 101
    output reg [3:0] ones       // max value 1001
    );
    
    always @* begin
        tens <= bin_in / 10;
        ones <= bin_in % 10;
    end
    
endmodule
