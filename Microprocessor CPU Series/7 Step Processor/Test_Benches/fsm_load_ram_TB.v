// Test Bench for fsm_load_ram.v
// *** TEST GOOD ***
// 6.10.2023
//
// Total nanoseconds to complete operation = 
// -----------------------------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module fsm_load_ram_TB;
	reg i_clk;
	reg reset;
	reg [7:0] number_of_instructions;			// simulated from a ROM
	wire cpu_clk, clk_e, clk_s;
	wire loading_ram, set_address, enable_rom, set_ram;
	wire [7:0] address;

	always #20 i_clk = ~i_clk;

	// The only piece of the CPU needed for testing; from control unit
	clock_gen CLOCKS(
		.sys_clk(i_clk),
		.clk(cpu_clk),
		.clk_e(clk_e),
		.clk_s(clk_s)
	);
	
	// Device under test
	fsm_load_ram DUT(
		.step_clk(cpu_clk),						// stepper clock
		.reset(reset),							// reset
		.clk_e(clk_e),							// enable clock
		.clk_s(clk_s),							// set clock
		.noi(number_of_instructions),			// number of instructions, from ROM output
		.loading_ram(loading_ram),				// loading RAM in progress, connect to CPU reset
		.set_address(set_address),				// to ROM and RAM
		.enable_rom(enable_rom),				// enable data (instruction) from program ROM
		.set_ram(set_ram),						// set data (instruction) into cpu RAM
		.address(address)						// to ROM and RAM
	);
	
	// Icarus Verilog and GTKWave requirements
	initial begin
		$dumpfile("fsm_load_ram.vcd");
		$dumpvars(0, fsm_load_ram_TB);
	end
	
	// Simulation
	initial begin
		// All that is needed is to initialze for the number of instructions in ROM
		reset = 1'b1;
		i_clk = 1'b1;
		number_of_instructions = 8'd14;		// the number of instructions in sum5_rom.v
		
		#240 reset = 1'b0;
		
		#7500 $finish;
	
	end
endmodule