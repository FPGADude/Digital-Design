// From the book: "But How Do It Know?" pg. 139
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 4.5.2023
// Updated: 6.14.2023
//
// Control Section for the 7-Step Processor
//
// * Changes required for CPU_B:
//		- add stepper as an output and output flags_detected signal
//		- remove BUS0 control signal, as it is no longer needed
//
// *Other changes: 
//		- replaced AND gate A21 and NOT gate N3 with NAND gate NA1
//		- fixed I/O issue where step 4 was activated for input operation
//
// -------------------------------------------------------------------------------------------------------------------

`timescale 1ns / 1ps
module control(
// Inputs
		input sys_clk,														// main system input clock
		input reset,														// system reset
		input [0:7] instruction,											// 8-bit data from IR
		input [3:0] flags,													// from Flags Register 3:C 2:A 1:E 0:Z
// Outputs
	// All sets
		output s_R0, output s_R1, output s_R2, output s_R3,					// gp registers set inputs
	
		output s_MAR, output s_RAM,											// main memory inputs
	
		output s_IR, output s_IAR, output s_ACC, 							// registers set inputs
		
		output s_FLAGS,														// flag register set input
	
		output [2:0] OPCODE,												// alu input
	
		output BUS1, output s_TMP,											// alu operand b data path inputs
	
	// All enables
		output e_R0, output e_R1, output e_R2, output e_R3,					// gp register enable inputs
	
		output e_RAM, output e_IAR, output e_ACC,							// memory, registers enable inputs
	
	// I/O Bus
		output IO_clk_e, output IO_clk_s, 									// I/O clock e and clock s
		output IO_input_or_output, output IO_data_or_address, 				// I/O input/output, I/O data/address 	
		
	// Added outputs for CPU_B
		output [1:6] step, output flags_detected,

	// Added for CPU Initialization
		output stepper_clk, output clk_e, output clk_s
);
	// Internal Wire Signals
		//wire clk_e, clk_s, stepper_clk;
		wire [1:0] dec1_in, dec2_in, dec3_in;
		wire [3:0] dec1_out, dec2_out, dec3_out;
		wire [2:0] dec4_in;
		wire [7:0] dec4_out;
		wire flagC, flagA, flagE, flagZ;
		wire na1;
		wire n1, n2;
		wire o6, o7, o8, o9, oa, ob, oc, od, oe, of, o10;
		wire a28, a5, a6, a7, a8, a9, aa, ab, ac, a1f, a1e, a1b, a1d, a2b, 
			 a26, a25, a23, a27, a2a, a29, a18, a24, a1c, a1a, a19, a22,
			 a10, a11, a12, a13, a14, a15, a16, a17, a20, a21; 
		
	// Included Modules
		stepper STEPPER(.clk(stepper_clk), .reset(reset), .step(step));
		clock_gen CLOCKS(.sys_clk(sys_clk),	.clk(stepper_clk), .clk_e(clk_e), .clk_s(clk_s));					
		dec2x4 DEC1(.dec_in(dec1_in), .dec_out(dec1_out));
		dec2x4 DEC2(.dec_in(dec2_in), .dec_out(dec2_out));
		dec2x4 DEC3(.dec_in(dec3_in), .dec_out(dec3_out));
		dec3x8 DEC4(.dec_in(dec4_in), .dec_out(dec4_out));
		
	// Gate Level Logic Description
		and A1(e_IAR, clk_e, o6);											// enable IAR
		and A2(e_RAM, clk_e, o7);											// enable RAM
		and A3(e_ACC, clk_e, o8);											// enable ACC
		and A4(IO_clk_e, clk_e, a28);										// I/O clock e
		
		and A5(a5, clk_e, o9, dec1_out[0]);
		and A6(a6, clk_e, o9, dec1_out[1]);
		and A7(a7, clk_e, o9, dec1_out[2]);
		and A8(a8, clk_e, o9, dec1_out[3]);

		and A9(a9, clk_e, oa, dec2_out[0]);
		and AA(aa, clk_e, oa, dec2_out[1]);
		and AB(ab, clk_e, oa, dec2_out[2]);
		and AC(ac, clk_e, oa, dec2_out[3]);
		
		and AD(OPCODE[0], step[5], instruction[0], instruction[3]);			// opcode output
		and AE(OPCODE[1], step[5], instruction[0], instruction[2]);			// opcode output
		and AF(OPCODE[2], step[5], instruction[0], instruction[1]);			// opcode output
		
		or O1(e_R0, a5, a9);												// enable R0 output
		or O2(e_R1, a6, aa);												// enable R1 output
		or O3(e_R2, a7, ab);												// enable R2 output
		or O4(e_R3, a8, ac);												// enable R3 output
		
		or O5(BUS1, step[1], a1f, a1e, a1b);								// Bus 1 output
		or O6(o6, step[1], a1b, a1d, a1e);
		or O7(o7, step[2], a2b, a26, a25, a23);
		or O8(o8, step[3], a27, a2a, a29);
		or O9(o9, a18, a24, a1c, a20);
		or OA(oa, a1a, a19, a22);
		
		not N1(n1, instruction[0]);
		
		and A10(a10, n1, dec4_out[0]);
		and A11(a11, n1, dec4_out[1]);
		and A12(a12, n1, dec4_out[2]);
		and A13(a13, n1, dec4_out[3]);
		and A14(a14, n1, dec4_out[4]);
		and A15(a15, n1, dec4_out[5]);
		and A16(a16, n1, dec4_out[6]);
		and A17(a17, n1, dec4_out[7]);
		
		and A18(a18, step[4], instruction[0]);
		and A19(a19, step[4], a10);
		and A1A(a1a, step[4], a11);
		and A1B(a1b, step[4], a12);
		and A1C(a1c, step[4], a13);
		and A1D(a1d, step[4], a14);
		and A1E(a1e, step[4], a15);
		and A1F(a1f, step[4], a16);
		and A20(a20, step[4], a17, instruction[4]);		// added output instruction[4] to fix I/O issue
		
		and FC(flagC, flags[3], instruction[4]);
		and FA(flagA, flags[2], instruction[5]);
		and FE(flagE, flags[1], instruction[6]);
		and FZ(flagZ, flags[0], instruction[7]);

		not N2(n2, instruction[4]);

		// replace A21 and N3 with one NAND gate below
		nand NA1(na1, instruction[1], instruction[2], instruction[3]);

		and A22(a22, step[5], instruction[0]);
		and A23(a23, step[5], a10);
		and A24(a24, step[5], a11);
		and A25(a25, step[5], a12);
		and A26(a26, step[5], a14);
		and A27(a27, step[5], a15);
		and A28(a28, step[5], a17, n2);
		
		or OB(ob, flagC, flagA, flagE, flagZ);
		
		and A29(a29, step[6], instruction[0], na1);				// replace n3 with na1 nand output
		and A2A(a2a, step[6], a12);
		and A2B(a2b, step[6], a15, ob);
		
		or OC(oc, step[1], a1b, a1e, a19, a1a, a1d);
		or OD(od, step[3], a1c, a26, a27, a2a, a2b);
		or OE(oe, step[1], a1b, a1e, a22);
		or OF(of, a1f, a22);
		or O10(o10, a23, a29, a25, a28);
		
		and A2C(s_IR, clk_s, step[2]);							// set IR output	
		and A2D(s_MAR, clk_s, oc);								// set MAR output
		and A2E(s_IAR, clk_s, od);								// set IAR output
		and A2F(s_ACC, clk_s, oe);								// set ACC output
		and A30(s_RAM, clk_s, a24);								// set RAM output
		and A31(s_TMP, clk_s, a18);								// set TMP output
		and A32(s_FLAGS, clk_s, of);							// set Flags output

		and A33(IO_clk_s, clk_s, a20);							// I/O clock s output
		and A34(s_R0, clk_s, o10, dec3_out[0]);
		and A35(s_R1, clk_s, o10, dec3_out[1]);
		and A36(s_R2, clk_s, o10, dec3_out[2]);
		and A37(s_R3, clk_s, o10, dec3_out[3]);
		
	// Added AND gates for I/O
		and A39(IO_data_or_address, a17, instruction[5]);		// I/O data/address output
		and A3A(IO_input_or_output, a17, instruction[4]);		// I/O input/output output
		
	// Internal Wire Assignments
		assign dec1_in = {instruction[6], instruction[7]};
		assign dec2_in = {instruction[4], instruction[5]};
		assign dec3_in = {instruction[6], instruction[7]};
		assign dec4_in = {instruction[1], instruction[2], instruction[3]};	
		
	// Added for CPU_B
		assign flags_detected = ob;		// OR gate OB

endmodule