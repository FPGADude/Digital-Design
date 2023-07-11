// Written by David J. Marion for CPU_B (New 7-Step Processor Design)
// Date: 6.6.2023


`timescale 1ns / 1ps
module io(
// Inputs
	// IO control signals from CPU Control Unit
		input IO_input_output,		// 0 = input, 1 = output
		input IO_data_address,		// 0 = data, 1 = address
		input IO_clk_e,
		input IO_clk_s,
		input [0:3] instruction,	// 0111 for IO instr
	// Outgoing data from CPU to outside module
		input [7:0] cpu_out,

// Outputs	
	// Incoming data to CPU from outside module
		output [7:0] cpu_in,		
	// Control signals to outside module
		output enable_input,
		output set_output,
		output data_address,

// Bidirectional input / output	
	// Outside module data/address communication channel
		inout [7:0] cpu_in_out
);
	// Input data to CPU
	assign cpu_in = (!IO_input_output & (instruction == 4'h7) & enable_input) ? 
					cpu_in_out : 8'h00;
	
	// Output data to outside module
	assign cpu_in_out = (IO_input_output & (instruction == 4'h7)) ? 
						cpu_out : 8'bz;
	
	// Output control signals
	assign enable_input = IO_clk_e;
	assign set_output = IO_clk_s;
	assign data_address = IO_data_address;
	
endmodule