// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// Stepper Module
`timescale 1ns / 1ps
module stepper(
	input clk,
	output reg [5:0] step
	);
	
	parameter [2:0] ONE   = 3'o0,
					TWO   = 3'o1,
					THREE = 3'o2,
					FOUR  = 3'o3,
					FIVE  = 3'o4,
					SIX   = 3'o5,
					SEVEN = 3'o6;
	
	reg [2:0] state = ONE;
	reg [2:0] next_state;
					
	always @(posedge clk)
		state <= next_state;
		
	always @*
		case(state)
			ONE: 	begin
						next_state = TWO;
						step = 6'b10_0000;
					end
			TWO:	begin
						next_state = THREE;
						step = 6'b01_0000;
					end
			THREE: begin
						next_state = FOUR;
						step = 6'b00_1000;
					end
			FOUR:	begin
						next_state = FIVE;
						step = 6'b00_0100;
					end
			FIVE: 	begin
						next_state = SIX;
						step = 6'b00_0010;
					end
			SIX:	begin
						next_state = SEVEN;
						step = 6'b00_0001;
					end
			SEVEN:	begin
						next_state = ONE;
						step = 6'b00_0000;
					end
		endcase
	
endmodule