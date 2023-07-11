// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.18.2023
// Edited: 6.14.23
// Stepper Module
//
// * Adding a step 0 for a reset state.
// * Now the CPU is a 7-Step Processor again.
// **************************************************************************************
`timescale 1ns / 1ps
module stepper(
	input clk,								// stepper clock
	input reset,							// system reset
	output [5:0] step						// control unit signals
	);
	
	reg [6:0] step_reg = 7'b100_0000;		// start at step 0
	
	always @(posedge clk or posedge reset) begin
		if (reset)
			step_reg <= 7'b100_0000;				// system reset back to step 0
		else
			if (step_reg == 7'b000_0001)			// when we get to step 6
				step_reg <= 7'b010_0000;			// go back to step 1, not step 0
			else
				step_reg <= step_reg >> 1;			// otherwise, shift right by 1 to next step
	end
	
	assign step = step_reg[5:0];					// Only output 6/7 steps
	
endmodule
