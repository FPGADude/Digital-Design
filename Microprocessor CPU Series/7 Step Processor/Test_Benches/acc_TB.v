// TEST BENCH for acc.v
//
//
`timescale 1ns / 1ps
module acc_TB;
	
	reg s, e;
	reg [7:0] d_in;
	wire [7:0] d_out;

	acc DUT(
		.s(s),
		.e(e),
		.d_in(d_in),
		.d_out(d_out)
	);

	initial begin
		$dumpfile("acc.vcd");
		$dumpvars(0, acc_TB);
	end

	initial begin
		s = 1'b0;
		e = 1'b0;
		d_in = 8'h55;
		#20;
		
		e = 1'b1;
		#20;
		e = 1'b0;
		#20;
		
		s = 1'b1;
		#20;
		s = 1'b0;
		#20;
		
		e = 1'b1;
		#20;
		e = 1'b0;
		#20;
		
		$finish;
	end

endmodule