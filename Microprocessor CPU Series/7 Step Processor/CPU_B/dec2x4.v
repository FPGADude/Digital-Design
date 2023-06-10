// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// 2 to 4 Decoder in the Control Unit
//
// * No changes required for CPU_B
// ******************************************************************************
`timescale 1ns / 1ps
module dec2x4(
	input [1:0] dec_in,			// 2-bit select
	output [3:0] dec_out 		// 4 output bits
	);
	
	assign dec_out[3] = (dec_in == 2'b11) ? 1'b1 : 1'b0;
	assign dec_out[2] = (dec_in == 2'b10) ? 1'b1 : 1'b0;
	assign dec_out[1] = (dec_in == 2'b01) ? 1'b1 : 1'b0;
	assign dec_out[0] = (dec_in == 2'b00) ? 1'b1 : 1'b0;
	
endmodule