`timescale 1ns / 1ps
// Add a constant value of 32 to obtain the Fahrenheit temperature
//
// Written by David Marion
// 4.20.2023
module add_32(
    input [7:0] x,
    output reg [7:0] y
    );
    
    always @(*) begin
        y = x + 32;
    end
    
endmodule
