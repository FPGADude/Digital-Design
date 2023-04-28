// Add a constant value of 32 to obtain the Fahrenheit temperature
//
// Written by David Marion
`timescale 1ns / 1ps
module add_32(
    input [7:0] x,
    output reg [7:0] y
    );
    
    always @(*) begin
        y = x + 32;
    end
    
endmodule
