// From the book: "But How Do It Know?" pg. 90
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// Provides 0000_0001 at B input to ALU
// Bus 1
//
// * No changes required for CPU_B
// *****************************************************************************

`timescale 1ns / 1ps
module bus1(
	input e_b1,
	input [7:0] d_in,
	output [7:0] d_out
);
	
	assign d_out = e_b1 ? 8'h01 : d_in;
		
endmodule