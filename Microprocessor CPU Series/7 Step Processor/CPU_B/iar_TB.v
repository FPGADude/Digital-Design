// TEST BENCH for iar.v
// Comments: Device Under Test (iar.v) is (** VERIFIED **)
// --------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module iar_TB;

	reg reset;
	reg s, e;
	reg [7:0] a_in;
	wire [7:0] a_out;

	iar DUT(.reset(reset), .s(s), .e(e), .a_in(a_in), .a_out(a_out));
	
	initial begin
		$dumpfile("iar.vcd");
		$dumpvars(0, iar_TB);
	end
	
	initial begin
		reset = 1'b0;
		s = 1'b0;
		e = 1'b0;
		a_in = 8'haa;
		#20;
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		e = 1'b1;
		#20;
		e = 1'b0;
		#20;
		
		reset = 1'b1;
		#20;
		reset = 1'b0;
		e = 1'b1;
		#20;
		e = 1'b0;
	
		#20 $finish;
	end

endmodule