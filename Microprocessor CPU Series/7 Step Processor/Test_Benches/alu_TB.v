// From the book: "But How Do It Know?" pg. 87, 88
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
//
// TESTBENCH for Arithmetic and Logic Unit (ALU)
`timescale 1ns / 1ps
module alu_TB;
	reg [7:0] A, B;
	reg c_in;
	reg [2:0] op;
	wire [7:0] C;
	wire c_out, a_larger, equal, zero;

	// ALU Operation Codes
	parameter [2:0] ADD = 3'o0,
					RSH = 3'o1,
					LSH = 3'o2,
					//NOT = 3'o3,
					DEC = 3'o3,
					AND = 3'o4,
					OR  = 3'o5,
					XOR = 3'o6,
					CMP = 3'o7;

	// Instantiate the device under test (DUT) and connect test bench signals to DUT I/O
	alu DUT(
		.A(A),
		.B(B),
		.c_in(c_in),
		.op(op),
		.C(C),
		.c_out(c_out),
		.a_larger(a_larger),
		.equal(equal),
		.zero(zero)
	);

	initial begin
		$dumpfile("alu.vcd");	// specify the name of the file for GTKWave
		$dumpvars(0, alu_TB);	// specify the level of variables to dump to above file (0 = all)
	end
	
	initial begin
		// Initialize register values
		c_in = 0;
		A = 8'haa;		// <- 8'b1010_1010
		B = 8'h55;		// <- 8'b0101_0101
		
		op = ADD;		// -> 8'b1111_1111
		#1 c_in = 1;	// -> 8'b0000_0000, flags set -> zero, c_out
		#1 c_in = 0;
		#1;
		
		A = 8'h0c;		// <- 8'b0000_1100
		op = RSH;		// -> 8'b0000_0110
		#1 c_in = 1;	// -> 8'b1000_0110
		#1 c_in = 0;	// -> 8'b0000_0110
		#1;
		
		A = 8'h16;		// <- 8'b0001_0110
		op = LSH;		// -> 8'b0010_1100
		#1 c_in = 1;	// -> 8'b0010_1101
		#1 c_in = 0;	// -> 8'b0010_1100
		#1;
		
		A = 8'h81;		// <- 8'b1000_0001
		op = RSH;		// -> 8'b0100_0000, flags set -> c_out
		#1;
		
		A = 8'h81;		// -> 8'b1000_0001
		op = LSH;		// -> 8'b0000_0010, flags set -> c_out
		#1;
		
		A = 8'haa;		// <- 8'b1010_1010
		//op = NOT;		// -> 8'b0101_0101
		op = DEC;		// -> 8'b1010_1001
		#1;
		
		B = 8'h55;		// <- 8'b0101_0101
		op = AND;		// -> 8'b0000_0000, flags set -> zero
		#1;
		
		op = OR;		// -> 8'b1111_1111
		#1;
		
		op = XOR;		// -> 8'b1111_1111
		#1;
		
		B = 8'haa;		// <- 8'b1010_1010
		op = CMP;		// -> 8'b0000_0000, flags set -> equal, zero
		#1;
		
		A = 8'hac;		// <- 8'b1010_1100
		op = CMP;		// -> 8'b0000_0110, flags set -> a_larger
		#1;
		
		$finish;	
	end

endmodule