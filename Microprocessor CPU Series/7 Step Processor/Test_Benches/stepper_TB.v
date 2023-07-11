// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// TEST BENCH for Stepper Module
`timescale 1ns / 1ps
module stepper_TB;

	reg clk;
	reg reset;
	wire [5:0] step;
	
	stepper STEPPER(
		.clk(clk),
		.reset(reset),
		.step(step)
	);

	always #1 clk = ~clk;
	
	initial begin
		$dumpfile("stepper.vcd");
		$dumpvars(0, stepper_TB);
	end
	
	initial begin
		clk = 0;	// Initialize clock 
		reset = 1;
		#10 reset = 0;
		
		#50 reset = 1;
		#20 reset = 0;
			
		#50 $finish;
	end


endmodule