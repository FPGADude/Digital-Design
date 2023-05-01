`timescale 1ns / 1ps
// Multiply an 8-bit Celsius temperature by a constant of 9
// and output a 16-bit value
//
// Written by David Marion
// 4.20.2023
module multiply_by_9(
    input [7:0] x,
    output reg [15:0] y
    );
    
    always @(*) begin
        y = x * 9;
    end
endmodule
