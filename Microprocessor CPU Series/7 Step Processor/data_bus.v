// Written by David J. Marion
// Date: 6.3.2023
// Purpose:
//		To replace the tristate CPU bus and inout ports for the 7-Step Processor
//
// Brief:
// 		A combinational switchboard circuit to route data to and from CPU components.
// ************************************************************************************

`timescale 1ns / 1ps	
module data_bus(
	// From components
		input [7:0] i_gpr,
		input [7:0] i_ram,
		input [7:0] i_acc,
		input [7:0] i_iar,
		input [7:0] i_io,	
	// Control (routing) signals
		input [1:6] step,			// Control Unit Stepper output
		input [0:3] instr,			// 4-bits from IR
		input ir_io,				// 1-bit from IR (designates input to or output from CPU on IO bus)
		input flags_detected,		// Control Unit OR gate OB	
	// To components
		output [7:0] o_ir,
		output [7:0] o_iar,
		output [7:0] o_alua,
		output [7:0] o_gpr,
		output [7:0] o_mar,
		output [7:0] o_ram,
		output [7:0] o_io,
		output [7:0] o_tmp
);
	
	assign o_ir = step[2] ? i_ram : 8'b0;
	assign o_mar = (step[1] | (((instr == 4'b0010) | (instr == 4'b0100) | (instr == 4'b0101))  & step[4])) ? i_iar :
				   ((instr == 4'b0000) | (instr == 4'b0001)) & (step[4]) ?  i_gpr : 8'b0;
	assign o_alua = (step[1] | (((instr == 4'b0010) | (instr == 4'b0101)) & step[4])) ? i_iar : 
					((instr[0] == 1'b1) & step[5]) ? i_gpr : 8'b0;
	assign o_iar = (step[3] | ((instr == 4'b0010) & step[6]) | ((instr == 4'b0101) & step[5])) ? i_acc :
				   ((instr == 4'b0011) & step[4]) ? i_gpr :
				   (((instr == 4'b0100) & step[5]) |  ((instr == 4'b0101) & step[6] & flags_detected))   ? i_ram : 8'b0;
	assign o_tmp = ((instr[0] == 1'b1) & step[4]) ? i_gpr : 8'b0;
	assign o_gpr = ((instr[0] == 1'b1) & step[6] & (instr[1:3] != 3'b111)) ? i_acc :
				   (((instr == 4'b0000) & step[5]) | ((instr == 4'b0010) & step[5])) ? i_ram :
				   ((instr == 4'b0111) & !ir_io & step[5]) ? i_io : 8'b0;
	assign o_ram = ((instr == 4'b0001) & step[5]) ? i_gpr : 8'b0;
	assign o_io = ((instr == 4'b0111) & ir_io & step[4]) ? i_gpr : 8'b0;
				   
endmodule