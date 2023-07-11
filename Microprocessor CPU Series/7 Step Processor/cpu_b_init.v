// -----------------------------------------------------------------------------------------------------------------------------------
// Written by David J. Marion
// Date: 6.7.2023
//
// TOP MODULE for 7-Step Processor CPU_B
// -----------------------------------------------------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module cpu_b(
// Inputs
		input in_clk,						// system input clock
		input reset,						// button or switch
		
		// Added inputs for CPU Initialization
		input loading_ram,
		input set_mar_init,
		input [7:0] addr_init,
		input set_ram_init,
		input [7:0] instr_from_rom,

// Bidirectional
		inout [7:0] cpu_interface,			// bidirectional input/output, to/from cpu, outside module comms channel

// Outputs
		output enable_input,				// other system module control signal
		output set_output,					// other system module control signal
		output data_address,				// other system module control signal	
		
		// Added outputs for CPU Initialization
		output step_clk,
		output clk_e,
		output clk_s
);

// Internal Signals ------------------------------------------------------------------------------------------------------------------
		// Data/Address Bus
		wire [7:0] to_mar;
		wire [7:0] to_ram, from_ram;
		wire [7:0] to_alua, to_tmp, tmp_to_bus1, bus1_to_alub, alu_to_acc, from_acc;
		wire [7:0] to_ir;
		wire [7:0] to_gpr, from_gpr;
		wire [7:0] to_iar, from_iar;
		wire [7:0] to_io, from_io;
		
		// Other signals
		wire [2:0] alu_opcode;
		wire [1:6] step;
		wire [0:7] ir_to_control;
		wire [3:0] alu_to_flags;
		wire [3:0] flags_to_control;
		
		// 4-bit high-order nibble from IR to DATA BUS and IO
		wire [0:3] instr_to_data_bus_io;
		assign instr_to_data_bus_io = ir_to_control[0:3];
		
		// 1-bit from 8-bit instruction from IR to DATA BUS
		wire ir_io;
		assign ir_io = ir_to_control[4];	// designates operation as input or output
		
		// Sets from Control Unit
		wire s_mar, s_ram;
		wire s_tmp;
		wire s_ir;
		wire s_acc;
		wire s_iar;
		wire s_flags;
		wire s_r0, s_r1, s_r2, s_r3;
		
		// Enables from Control Unit
		wire e_ram;
		wire e_acc;
		wire e_iar;
		wire e_r0, e_r1, e_r2, e_r3;
		
		// For IO operations from Control Unit to IO module
		wire IO_data_address, IO_input_output, IO_clk_e, IO_clk_s;
		
		// Added logic for CPU Initialization
		wire mux_set_mar, mux_set_ram;
		wire [7:0] mux_mar_in, mux_ram_in;
		assign mux_set_mar = loading_ram ? set_mar_init : s_mar;
		assign mux_set_ram = loading_ram ? set_ram_init : s_ram;
		assign mux_mar_in = loading_ram ? addr_init : to_mar;
		assign mux_ram_in = loading_ram ? instr_from_rom : to_ram;
		

// Included Modules - RAM256, ALU, CONTROL UNIT, TMP, BUS1, DATA BUS, GPR FILE, IR, IAR, ACC, FLAGS, IO ---------------------------------
		ram RAM256(
			.a(mux_mar_in),								// 8-bit memory address from DATA BUS
			.sa(mux_set_mar),						// set memory address in memory address register
			.s(mux_set_ram),								// set data in memory at address
			.e(e_ram),								// enable data out from memory at address
			.d_in(mux_ram_in),							// 8-bit data to RAM from DATA BUS
			.d_out(from_ram)						// 8-bit data to DATA BUS from RAM
		);

		alu ALU(
			.A(to_alua),							// 8-bit input operand A
			.B(bus1_to_alub),						// 8-bit input operand B
			.c_in(flags_to_control[3]),				// carry in signal (C-flag of Flags Reg)
			.op(alu_opcode),						// 3-bit opcode from CONTROL UNIT
			.C(alu_to_acc),							// 8-bit ALU result to ACC
			.c_out(alu_to_flags[3]),				// carry out bit
			.a_larger(alu_to_flags[2]),				// A > B bit
			.equal(alu_to_flags[1]),				// A == B bit
			.zero(alu_to_flags[0])					// ALU result == 0 bit
		);

		control CONTROL_UNIT(
			.sys_clk(in_clk),						// main system input clock
			.reset(reset),							// reset stepper to step 1
			.instruction(ir_to_control),			// 8-bit instruction from IR
			.flags(flags_to_control),				// 4-bit from FLAGS (CAEZ)
			.s_R0(s_r0), 							// set R0
			.s_R1(s_r1), 							// set R1
			.s_R2(s_r2), 							// set R2
			.s_R3(s_r3),							// set R3
			.s_MAR(s_mar),							// set MAR
			.s_RAM(s_ram),							// set RAM
			.s_IR(s_ir), 							// set IR
			.s_IAR(s_iar), 							// set IAR
			.s_ACC(s_acc),							// set ACC
			.s_TMP(s_tmp),							// set TMP
			.s_FLAGS(s_flags),						// set FLAGS
			.OPCODE(alu_opcode),					// 3-bit operation to ALU
			.BUS1(e_bus1), 							// enable BUS1
			.e_R0(e_r0), 							// enable R0
			.e_R1(e_r1), 							// enable R1
			.e_R2(e_r2), 							// enable R2
			.e_R3(e_r3),							// enable R3
			.e_RAM(e_ram), 							// enable RAM
			.e_IAR(e_iar), 							// enable IAR
			.e_ACC(e_acc),							// enable ACC
			.IO_clk_e(IO_clk_e),					// IO enable
			.IO_clk_s(IO_clk_s),					// IO set
			.IO_input_or_output(IO_input_output),	// IO input/output
			.IO_data_or_address(IO_data_address),	// IO data/address
			.step(step),							// 6-bit step to DATA BUS
			.flags_detected(flags_detected),		// 1-bit flag detected to DATA BUS
			.stepper_clk(step_clk),					// for CPU init
			.clk_e(clk_e),							// for CPU init
			.clk_s(clk_s)							// for CPU init
		);

		tmp TMP(
			.s(s_tmp),								// set TMP
			.t_in(to_tmp),							// 8-bit from DATA BUS to TMP
			.t_out(tmp_to_bus1)						// 8-bit from TMP to BUS1
		);

		bus1 BUS1(
			.e_b1(e_bus1),							// enable BUS1
			.d_in(tmp_to_bus1),						// 8-bit from TMP to BUS1
			.d_out(bus1_to_alub)					// 8-bit to ALU operand B
		);
		
		data_bus BUS(
			.i_gpr(from_gpr), 						// 8-bit from GPR to DATA BUS
			.i_ram(from_ram), 						// 8-bit from RAM to DATA BUS
			.i_acc(from_acc), 						// 8-bit from ACC to DATA BUS
			.i_iar(from_iar), 						// 8-bit from IAR to DATA BUS
			.i_io(from_io),							// 8-bit from IO to DATA BUS
			.step(step), 							// 6-bit step from CONTROL UNIT
			.instr(instr_to_data_bus_io), 			// 4-bit high-nibble of 8-bit instruction from IR
			.ir_io(ir_io), 							// 1-bit of instruction from IR to signal input or output
			.flags_detected(flags_detected),		// 1-bit to signal a flag has been detected from ALU op
			.o_ir(to_ir), 							// 8-bit from DATA BUS to IR
			.o_iar(to_iar), 						// 8-bit from DATA BUS to IAR
			.o_alua(to_alua), 						// 8-bit from DATA BUS to ALU operand A
			.o_gpr(to_gpr), 						// 8-bit from DATA BUS to GPR
			.o_mar(to_mar), 						// 8-bit from DATA BUS to MAR
			.o_ram(to_ram), 						// 8-bit from DATA BUS to RAM
			.o_io(to_io), 							// 8-bit from DATA BUS to IO
			.o_tmp(to_tmp)							// 8-bit from DATA BUS to TMP			
		);
	
		gpr_file GPR(
			.d_in(to_gpr),							// 8-bit data/address from DATA BUS to GPR
			.s_r0(s_r0), 							// set R0
			.s_r1(s_r1), 							// set R1
			.s_r2(s_r2), 							// set R2
			.s_r3(s_r3),							// set R3
			.e_r0(e_r0), 							// enable R0
			.e_r1(e_r1), 							// enable R1
			.e_r2(e_r2), 							// enable R2
			.e_r3(e_r3),							// enable R3
			.d_out(from_gpr)						// 8-bit data/address from GPR to DATA BUS
		);
		
		ir IR(
			.s(s_ir),								// set IR
			.i_in(to_ir),							// 8-bit instruction from DATA BUS to IR
			.i_out(ir_to_control)					// 8-bit instruction from IR to CONTROL UNIT
		);
		
		iar IAR(
			.s(s_iar),								// set IAR
			.e(e_iar),								// enable IAR
			.a_in(to_iar),							// 8-bit instr addr from DATA BUS to IAR
			.a_out(from_iar)						// 8-bit instr addr from IAR to DATA BUS
		);
		
		acc ACC(
			.s(s_acc),								// set ACC
			.e(e_acc),								// enable ACC
			.d_in(alu_to_acc),						// 8-bit result from ALU to ACC
			.d_out(from_acc)						// 8-bit from ACC to DATA BUS
		);
		
		flags FLAGS(
			.s(s_flags),							// set FLAGS
			.caez_in(alu_to_flags),					// 4-bit condition codes from ALU to FLAGS
			.caez_out(flags_to_control)				// 4-bit condition codes from FLAGS to CONTROL UNIT
		);
		
		io IO(
			.IO_data_address(IO_data_address),		// 0 = data, 1 = address
			.IO_input_output(IO_input_output),		// 0 = input, 1 = output
			.IO_clk_e(IO_clk_e),					// IO enable signal
			.IO_clk_s(IO_clk_s),					// IO set signal
			.instruction(instr_to_data_bus_io),		// 4-bit high-nibble of 8-bit instruction from IR
			.cpu_out(to_io),						// 8-bit outgoing data from CPU to outside module
			.cpu_in(from_io),						// 8-bit incoming data to CPU from outside module
			.enable_input(enable_input),			// enable outside module for input
			.set_output(set_output),				// set outside module for output
			.data_address(data_address),			// signal outside module data or address
			.cpu_in_out(cpu_interface)				// 8-bit outside module data/address communication channel
		);

endmodule