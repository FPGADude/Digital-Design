// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// Instruction Register (IR)
//
// * No changes required for CPU_B
// **************************************************************************************

`timescale 1ns / 1ps
module ir(
	input s,							// set
	input [7:0] i_in,					// instruction in
	output reg [7:0] i_out = 8'h00		// instruction out
	);
	
	always @(*)
		if(s == 1'b1)
			i_out <= i_in;
	
endmodule