// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.16.2022
//
// Flags Register
//
// * No changes required for CPU_B
// ******************************************************************************

`timescale 1ns / 1ps
module flags(
	input s,
	input [3:0] caez_in,
	output reg [3:0] caez_out = 4'h0
	);
	
	always @(*)
		if(s == 1'b1)
			caez_out <= caez_in;
	
endmodule