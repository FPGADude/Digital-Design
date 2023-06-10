// Created for CPU_B
// Written by David J. Marion
// Date: 6.2.2023
// Purpose:
//		Group all general purpose registers into one module that
//		will be a register file, for the CPU_B implementation. 
// *******************************************************************

`timescale 1ns / 1ps
module gpr_file(
	input [7:0] d_in,				// data in
	input s_r0, s_r1, s_r2, s_r3,	// gpr set signals
	input e_r0, e_r1, e_r2, e_r3,	// gpr enable signals
	output [7:0] d_out				// data out
);
	wire [7:0] o_r0, o_r1, o_r2, o_r3;

	gpr R0(.s(s_r0), .e(e_r0), .d_in(d_in), .d_out(o_r0));
	gpr R1(.s(s_r1), .e(e_r1), .d_in(d_in), .d_out(o_r1));
	gpr R2(.s(s_r2), .e(e_r2), .d_in(d_in), .d_out(o_r2));
	gpr R3(.s(s_r3), .e(e_r3), .d_in(d_in), .d_out(o_r3));
	
	assign d_out = e_r0 ? o_r0 : e_r1 ? o_r1 :
				   e_r2 ? o_r2 : e_r3 ? o_r3 : 8'h00;
		
endmodule