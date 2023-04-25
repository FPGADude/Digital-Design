// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.4.2023
//
// TEST BENCH for the 3 to 8 Decoder
`timescale 1ns / 1ps
module dec3x8_TB;
	reg [2:0] dec_in;
	wire [7:0] dec_out;
	// integer i;
	
	// Instantiate device under test (DUT) and connect test bench signals to DUT I/O
	dec3x8 DUT(.dec_in(dec_in), .dec_out(dec_out));

	initial begin
		$dumpfile("dec3x8.vcd");
		$dumpvars(0, dec3x8_TB);
	end
	
	// Loop through all possible inputs 0 thru 7
	// initial begin
		// for(i = 0; i < 8; i++) begin
			// dec_in = i;
			// #1;
		// end
	
		// $finish;
	// end


// AUTOMATIC STIMULUS 
	reg clk = 0;
	always #5 clk = ~clk;
	
	initial begin
		$randomize; // Seed the random number generator based on the current time
	end
	
	// Define the automatic stimulus generator
	initial begin
		//$randomize; // Seed the random number generator based on the current time
	
		// Generate stimuli for all possible input addresses
		repeat (16) begin
			dec_in <= $random % 8;	// Randomly select an input between 0 and 7
			#10;	// Wait for a few clock cycles
		end
		$finish;	// End the simulation after generating all stimuli
	end
endmodule