// From the book: "But How Do It Know?" pg. 96, 97
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Edited: 4.23.23
// Clock Module
// Generates the 3 clock signals needed in the Processor:
//		1. stepper clock that drives the stepper through its steps
//		2. clock e for all register/memory/IO enables
//		3. clock s for all register/memory/IO sets
//
// * No changes required for CPU_B
// **************************************************************************************
`timescale 1ns / 1ps
module clock_gen(
	input sys_clk,					// system input clock of arbitrary frequency
	output clk,						// stepper clock
	output clk_e,					// enable clock
	output clk_s					// set clock
	);
	
	reg [1:0] clk_reg = 2'b00;		// counter
	
	always @(posedge sys_clk)		// when the input clock goes high
		clk_reg <= clk_reg + 1;		// increment counter by 1	
		
	assign clk = ((clk_reg == 2'b00) || (clk_reg == 2'b01)) ? 1'b1 : 1'b0;	// step cycle with 50% duty cycle
	assign clk_e = clk_reg == 2'b11 ? 1'b0 : 1'b1;							// 75% of step cycle
	assign clk_s = clk_reg == 2'b01 ? 1'b1 : 1'b0;							// 25% of step cycle
	
endmodule