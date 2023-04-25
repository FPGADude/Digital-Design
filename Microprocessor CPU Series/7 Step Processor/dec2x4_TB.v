// From the book: "But How Do It Know?" pg. 102
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.4.2023
//
// TEST BENCH for the 2 to 4 Decoder
`timescale 1ns / 1ps
module dec2x4_TB;
	reg [1:0] dec_in;
	wire [3:0] dec_out;
	
	// Instantiate device under test (DUT) and connect test bench signals to DUT I/O
	dec2x4 DUT(
		.dec_in(dec_in),
		.dec_out(dec_out)
	);

	initial begin
		$dumpfile("dec2x4.vcd");
		$dumpvars(0, dec2x4_TB);
	end
	
	initial begin
		dec_in = 2'b00;
		#1;
		dec_in = 2'b01;
		#1;
		dec_in = 2'b10;
		#1;
		dec_in = 2'b11;
		#1;
	
		$finish;
	end

endmodule