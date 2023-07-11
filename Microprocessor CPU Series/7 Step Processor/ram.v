// From the book: "But How Do It Know?" pg. 52
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Edited: 6.6.2023
//
// Main Memory 
//
// Main memory using RTL instead of gate level modeling.
//
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
// *******************************************************************************************

`timescale 1ns / 1ps
module ram(
	input [7:0] a,			// memory address
	input sa,				// set memory address in memory address register
	input s,				// set data in memory at address
	input e,				// enable data out from memory at address
	input [7:0] d_in,		// data in
	output [7:0] d_out		// data out
	);
	
	// Memory Address Register (MAR)
	reg [7:0] addr_reg = 8'h00;
	
	// Random Access Memory (RAM)
	reg [7:0] mem_reg[0:255];		// 256 memory addresses
	
	// Set MAR / Data Input
	always @(*) begin
		if(sa == 1'b1)
			addr_reg <= a;
		else if(s == 1'b1)
			mem_reg[addr_reg] <= d_in;
	end
	
	// Data Output
	assign d_out = e ? mem_reg[addr_reg] : 8'h00;

endmodule