// Written by David J. Marion
// Date: 6.8.2023
//
// Purpose: CPU_B initialization circuit. Writes CPU instructions from an instruction ROM to CPU RAM.
// ---------------------------------------------------------------------------------------------------------------

`timescale 1ns / 1ps
module cpu_init(
	input reset,
	input step_clk,
	input clk_e,
	input clk_s,
	output loading_ram,
	output set_addr,
	output set_ram,
	output [7:0] address,
	output [7:0] instruction
);

	wire [7:0] number_of_instructions;
	wire en_rom;

	fsm_load_ram FSM(
		.step_clk(step_clk),							// stepper clock from CPU clock gen
		.reset(reset),							// hold state machine at state 0
		.clk_e(clk_e),							// enable clock from CPU clock gen
		.clk_s(clk_s),							// set clock from CPU clock gen
		.noi(number_of_instructions),						// number of instructions from ROM
		.loading_ram(loading_ram),						// loading RAM in progress
		.set_address(set_addr),						// signal ROM and RAM to set address
		.enable_rom(en_rom),						// signal ROM to enable instruction onto data bus
		.set_ram(set_ram),							// signal RAM to set instruction on data bus from ROM
		.address(address)
	);

	fibonacci_rom ROM(						// Change the name of the ROM file to be included
		.set_addr(set_addr),	
		.en_data(en_rom),	
		.addr(address),	
		.noi(number_of_instructions),
		.data(instruction)
	);

endmodule