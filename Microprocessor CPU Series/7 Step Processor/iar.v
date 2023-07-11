// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Edited: 6.3.23
// Instruction Address Register (IAR)
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
// *******************************************************************************************

`timescale 1ns / 1ps
module iar(
	input reset,							// system reset
	input s,								// set
	input e,								// enable
	input [7:0] a_in,						// address in
	output [7:0] a_out						// address out
	);
	
	reg [7:0] addr_reg = 8'h00;				// initialize IAR to beginning of RAM memory space
	
	always @(*) begin
		if(reset)
			addr_reg = 8'h00;				// reset instruction address to the beginning of memory space
		else if(s)
			addr_reg = a_in;				// set IAR with input address
	end
	
	assign a_out = e ? addr_reg : 8'h00;	
	
endmodule