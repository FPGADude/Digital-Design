// TEST BENCH for tmp.v
// Comments: Device Under Test (tmp.v) is (** VERIFIED **)
// --------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module tmp_TB;
	reg s;
	reg [7:0] t_in;
	wire [7:0] t_out;

	tmp DUT(.s(s), .t_in(t_in), .t_out(t_out));
	
	initial begin
		$dumpfile("tmp.vcd");
		$dumpvars(0, tmp_TB);
	end
	
	initial begin
		s = 1'b0;
		
		t_in = 8'h11;
		#20;	
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		
		t_in = 8'h55;
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		
		t_in = 8'haa;
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		
		t_in = 8'hff;
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
	
	
		$finish;
	end
	
endmodule