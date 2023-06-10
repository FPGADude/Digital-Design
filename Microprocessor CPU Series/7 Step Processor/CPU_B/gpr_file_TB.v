// TEST BENCH for gpr_file.v
// Comments: Device Under Test (gpr_file.v) is (** VERIFIED **)
// --------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module gpr_file_TB;
	// I/O signals
	reg [7:0] d_in;
	reg s_r0, s_r1, s_r2, s_r3;
	reg e_r0, e_r1, e_r2, e_r3;
	wire [7:0] d_out;

	// device under test
	gpr_file DUT(.d_in(d_in), .s_r0(s_r0), .s_r1(s_r1), .s_r2(s_r2), .s_r3(s_r3),
				 .e_r0(e_r0), .e_r1(e_r1), .e_r2(e_r2), .e_r3(e_r3), .d_out(d_out));	

	// system directives for icarus verilog
	initial begin
		$dumpfile("gpr_file.vcd");
		$dumpvars(0, gpr_file_TB);
	end

	// test simulation process
	initial begin
		// initialize regs
		d_in = 8'h11;
		s_r0 = 1'b0;
		s_r1 = 1'b0;
		s_r2 = 1'b0;
		s_r3 = 1'b0;
		e_r0 = 1'b0;
		e_r1 = 1'b0;
		e_r2 = 1'b0;
		e_r3 = 1'b0;
		#20;
		
		// initialize GPRs within the GPR file
		s_r0 = 1'b1;		// R0 <= hex 11
		#20;
		d_in = 8'h55;		
		s_r0 = 1'b0;
		s_r1 = 1'b1;		// R1 <= hex 55
		#20;
		d_in = 8'haa;
		s_r1 = 1'b0;
		s_r2 = 1'b1;		// R2 <= hex AA
		#20;
		d_in = 8'hff;
		s_r2 = 1'b0;
		s_r3 = 1'b1;		// R3 <= hex FF
		#20;
		s_r3 = 1'b0;
		
		#20;
		
		// enable output of each GPR within the GPR file
		e_r0 = 1'b1;
		#20;
		e_r0 = 1'b0;
		e_r1 = 1'b1;
		#20;
		e_r1 = 1'b0;
		e_r2 = 1'b1;
		#20;
		e_r2 = 1'b0;
		e_r3 = 1'b1;
		#20;
		e_r3 = 1'b0;
		
		
		#20 $finish;
	end

endmodule