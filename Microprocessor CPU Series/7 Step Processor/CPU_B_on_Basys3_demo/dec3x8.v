// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// 3 to 8 Decoder in the Control Unit
//
// * No changes required for CPU_B
// ******************************************************************************
`timescale 1ns / 1ps
module dec3x8(
	input [2:0] dec_in,			// 3-bit select
	output [7:0] dec_out		// 8 output bits
	);
	
	assign dec_out[7] = (dec_in == 3'b111) ? 1'b1 : 1'b0;
	assign dec_out[6] = (dec_in == 3'b110) ? 1'b1 : 1'b0;
	assign dec_out[5] = (dec_in == 3'b101) ? 1'b1 : 1'b0;
	assign dec_out[4] = (dec_in == 3'b100) ? 1'b1 : 1'b0;
	assign dec_out[3] = (dec_in == 3'b011) ? 1'b1 : 1'b0;
	assign dec_out[2] = (dec_in == 3'b010) ? 1'b1 : 1'b0;
	assign dec_out[1] = (dec_in == 3'b001) ? 1'b1 : 1'b0;
	assign dec_out[0] = (dec_in == 3'b000) ? 1'b1 : 1'b0;
	
endmodule