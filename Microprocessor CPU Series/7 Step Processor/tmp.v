// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// Temporary Register
//
// * No changes required for CPU_B
// **************************************************************************************

`timescale 1ns / 1ps
module tmp(
	input s,
	input [7:0] t_in,
	output reg [7:0] t_out = 8'h00
	);
	
	always @(*)
		if(s == 1'b1)
			t_out <= t_in;

endmodule