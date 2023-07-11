`timescale 1ns / 1ps
module cpu_b_test;

	reg cpu_reset, init_reset;
	reg sys_clk;
	wire loading_ram;
	wire set_mar, set_ram;
	wire [7:0] address, instruction, cpu_interface;
	wire step_clk, clk_e, clk_s;	
	wire enable_input, set_output, data_address;

	cpu_b CPU(
	// Inputs
		.in_clk(sys_clk),						// system input clock
		.reset(cpu_reset),						// button or switch
		
		// Added inputs for CPU Initialization
		.loading_ram(loading_ram),
		.set_mar_init(set_mar),
		.addr_init(address),
		.set_ram_init(set_ram),
		.instr_from_rom(instruction),

	// Bidirectional
		.cpu_interface(cpu_interface),			// bidirectional input/output, to/from cpu, outside module comms channel

	// Outputs
		.enable_input(enable_input),				// other system module control signal
		.set_output(set_output),					// other system module control signal
		.data_address(data_address),					// other system module control signal	
		
		// Added outputs for CPU Initialization
		.step_clk(step_clk),
		.clk_e(clk_e),
		.clk_s(clk_s)
	);
	
	
	cpu_init CPU_INIT(
		.reset(init_reset),
		.step_clk(step_clk),			// 1 stepper clock cycle = 160ns
		.clk_e(clk_e),
		.clk_s(clk_s),
		.loading_ram(loading_ram),
		.set_addr(set_mar),
		.set_ram(set_ram),
		.address(address),
		.instruction(instruction)
	);

	always #20 sys_clk = ~sys_clk;
	
	initial begin
		$dumpfile("cpu_b_test.vcd");
		$dumpvars(0, cpu_b_test);
	end

	initial begin
		sys_clk = 1'b0;
		cpu_reset = 1'b1;
		init_reset = 1'b1;
		
		
		// wait for 600ns (40ns shy of the start of a stepper clock cycle), turn off init_reset
		#600 init_reset = 1'b0;
		
		// For sum5 program
		// wait 5400ns for init to finish, turn off cpu_reset
		//#5400 cpu_reset = 1'b0;
		// let simulation run for at least 24,000ns to allow cpu to process all instructions
		//#25000 $finish;
		
		
		// For fibonacci program
		// wait ????ns for init to finish, turn off cpu_reset
		#8000 cpu_reset = 1'b0;
		// let simulation run for at least ?????ns to allow cpu to process all instructions
		#45000 $finish;
	
	end
endmodule