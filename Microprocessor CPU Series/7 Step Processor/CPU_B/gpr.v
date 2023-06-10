// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 6.3.2023
//
// General Purpose Register
//
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
// *******************************************************************************************

`timescale 1ns / 1ps
module gpr(
	input s,								// set
	input e,								// enable
	input [7:0] d_in,						// data in
	output [7:0] d_out						// data out
	);
	
	reg [7:0] data_reg = 8'h00;
	
	always @(*)
		if(s == 1'b1)
			data_reg <= d_in;
			
	assign d_out = e ? data_reg : 8'h00;
	
endmodule