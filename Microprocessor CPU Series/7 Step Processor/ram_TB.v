// From the book: "But How Do It Know?" pg. 52
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.1.2023
//
// Main Memory 
//
// TEST BENCH for the main memory module.
`timescale 1ns / 1ps
module ram_TB;

	// Test Bench Variables
	reg [7:0] a;
	reg sa, s, e;
	reg [7:0] bus_reg;
	wire [7:0] bus_wire;
	integer i;				// for loop iterator
	
	assign bus_wire = s ? bus_reg : 8'bz;		// drive bus wire only when setting memory
	
	// Instantiate device under test
	ram DUT(
		.a(a),					// current memory address
		.sa(sa),				// set memory address in memory address register
		.s(s),					// set data in memory at current address
		.e(e),					// enabledata out from memory at address
		.bus(bus_wire)			// 8-bit data bus
	);

	initial begin
		$dumpfile("ram.vcd");
		$dumpvars(0, ram_TB);
	end


	initial begin
		// Initialize values
		a = 8'b0;
		sa = 0;
		s = 0;
		e = 0;
		bus_reg = 8'b0;
		
		// Conduct test sequence
		// Load RAM with values
		for(i = 0; i < 256; i++) begin
			a = i;					// start at address value 0
			#1 sa = 1;				// latch address value in address register
			#1 sa = 0;
			
			bus_reg = i + 1;		// put address value plus 1 in bus reg
			#1 s = 1;				// load data in reg to memory at address reg
			#1 s = 0;				
			
		end
	
		// Read values from RAM
		for(i = 0; i < 256; i++) begin
			a = i;					// start at address value 0
			#1 sa = 1;				// latch address value in address register
			#1 sa = 0;
		
			#1 e = 1;				// read out data at memory address reg
			#1 e = 0;
		
		end
	
		$finish;
	end


endmodule