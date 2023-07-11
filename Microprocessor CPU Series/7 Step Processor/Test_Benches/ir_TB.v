// TEST BENCH for ir.v
// Comments: Device Under Test (ir.v) is (** VERIFIED **)
// --------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module ir_TB;

	reg s;
	reg [7:0] i_in;
	wire [7:0] i_out;

	ir DUT(.s(s), .i_in(i_in), .i_out(i_out));
	
	initial begin
		$dumpfile("ir.vcd");
		$dumpvars(0, ir_TB);
	end
	
	initial begin
		s = 1'b0;
		i_in = 8'haa;
		#20;
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		
		i_in = 8'h55;
		#20;
		s = 1'b1;
		#20;
		s = 1'b0;
	
		#20	$finish;
	end

endmodule