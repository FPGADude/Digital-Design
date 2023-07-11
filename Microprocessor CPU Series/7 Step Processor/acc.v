// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// Accumulator Register
//
// * No changes required for CPU_B
//
// * Changed output assignment from 8'bz to 8'b0
// ***********************************************************************

`timescale 1ns / 1ps
module acc(
	input s,
	input e,
	input [7:0] d_in,
	output [7:0] d_out
	);
	
	reg [7:0] data_reg = 8'h00;
	
	always @(*)
		if(s == 1'b1)
			data_reg = d_in;
	
	assign d_out = e ? data_reg : 8'b0;
	
endmodule