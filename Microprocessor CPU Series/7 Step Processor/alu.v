// From the book: "But How Do It Know?" pg. 87, 88
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Updated: 6.14.2023
//
// Arithmetic and Logic Unit (ALU)
//
// OPTION:
// *** Replace the NOT operation with a DEC operation that will decrement a value by 1.
// *** To me, this improves the utility for the processor for a loop variable.
//	   The NOT operation can still be accomplished by simply XORing the value with 0xFF,
//	   which will in effect flip all the bits in the value.
//
// *** Removed the carry in from the ADD operation.
// **************************************************************************************
`timescale 1ns / 1ps
module alu(
	input [7:0] A,			// input operand 1
	input [7:0] B,			// input operand 2
	input c_in,				// carry in signal
	input [2:0] op,			// 3-bit opcode = maximum 8 instructions
	output [7:0] C,			// output result 
	output c_out,			// carry out signal
	output a_larger,		// A > B signal
	output equal,			// A == B signal
	output zero				// ALU result = 0 signal
	);
	
	// All 8 opcodes symbolically defined
	parameter [2:0] ADD = 3'o0,
					RSH = 3'o1,	// right shift
					LSH = 3'o2,	// left shift
					NOT = 3'o3,
					//DEC = 3'o3,		// replace NOT with DEC operation (decrement by 1)
					AND = 3'o4,
					OR  = 3'o5,
					XOR = 3'o6,
					CMP = 3'o7;
	
	reg [8:0] out_reg = 9'b0;		// We need a ninth bit for the carry out from addition
	
	always @*
		case(op)
			ADD : out_reg = A + B;
			RSH : out_reg = {out_reg[8], c_in, A[7:1]};
			LSH : out_reg = {out_reg[8], A[6:0], c_in};
			NOT : out_reg = ~A;
			//DEC : out_reg = A - 1;
			AND : out_reg = A & B;
			OR  : out_reg = A | B;
			XOR : out_reg = A ^ B;
			CMP : out_reg = A ^ B;			// Compare, used to set flags
		endcase
			   
	assign C = out_reg[7:0];	// ALU result
	assign zero = ~|C;			// reduction NOR to determine if result = 0
	assign equal = ((op == CMP) && (zero == 1'b1)) ? 1'b1 : 1'b0;	
	assign a_larger = ((op == CMP) && (A > B)) ? 1'b1 : 1'b0;
	assign c_out = (op == ADD) ? out_reg[8]: (op == RSH) ? A[0]: (op == LSH) ? A[7]: 1'b0;
	
endmodule