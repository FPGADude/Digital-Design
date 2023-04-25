// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.18.2023
// Edited: 4.23.23
// Stepper Module
// A 7th step is not needed.
`timescale 1ns / 1ps
module stepper(
	input clk,								// stepper clock
	input reset,							// system reset
	output reg [5:0] step = 6'b10_0000		// begin at step 1
	);
	
	always @(posedge clk or posedge reset) begin
		if (reset)
			step <= 6'b10_0000;				// system reset back to step 1
		else
			if (step == 6'b00_0001)			// when we get to last step
				step <= 6'b10_0000;			// go back to the first step
			else
				step <= step >> 1;			// otherwise, shift right by 1 to next step
	end
endmodule