// TEST BENCH for io.v
// by David J. Marion
// Comments: Device Under Test is (** VERIFIED **)
// Date: 6.6.2023
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps
module io_TB;
	reg d_a;
	reg i_o;
	reg clk_e;
	reg clk_s;
	reg [7:0] from_cpu;
	reg[7:0] mod_data;
	reg [0:3] instr = 4'h7;
	wire [7:0] to_cpu;
	wire enable_input, set_output, data_address;
	wire [7:0] cpu_in_out;
	

	assign cpu_in_out = i_o ? from_cpu :
						clk_e ? mod_data : 8'bz;

	io DUT(
	// Inputs
		// IO control signals from Control Unit
			.IO_data_address(d_a),		// 0 = data, 1 = address
			.IO_input_output(i_o),		// 0 = input, 1 = output
			.IO_clk_e(clk_e),			// for input operations
			.IO_clk_s(clk_s),			// for output operations
			.instruction(instr),		// 0111 for IO instr
		// Outgoing data from CPU to outside module
			.cpu_out(from_cpu),
	// Outputs	
		// Incoming data to CPU from outside module
			.cpu_in(to_cpu),	
		// Control signals to outside module
			.enable_input(enable_input),
			.set_output(set_output),
			.data_address(data_address),
	// Inout	
		// Outside module data/address communication channel
			.cpu_in_out(cpu_in_out)
	);
	
	initial begin
		$dumpfile("io.vcd");
		$dumpvars(0, io_TB);
	end

	initial begin
		d_a = 0;		// 0 = data
		i_o = 0;		// input operation
		clk_e = 0;
		clk_s = 0;
		mod_data = 8'h55;
		from_cpu = 8'h11;
		#20;
		
		clk_e = 1;
		#20;
		clk_e = 0;
		#20;
		
		i_o = 1;		// output operation
		clk_s = 1;
		#20;
		clk_s = 0;
		#20;
		
		d_a = 1;		// 1 = address
		mod_data = 8'haa;
		from_cpu = 8'hff;
		i_o = 0;		// input operation
		#20;		
		
		clk_e = 1;
		#20;
		clk_e = 0;
		#20;
		
		i_o = 1;		// output operation
		clk_s = 1;
		#20;
		clk_s = 0;
		#20;
		
		#20 $finish;
	end

endmodule