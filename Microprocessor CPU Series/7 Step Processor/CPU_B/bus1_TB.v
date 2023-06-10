// Test bench for bus1.v
// *** TEST GOOD ***

module bus1_TB;
	reg [7:0] d_in;
	reg b1;
	wire [7:0] d_out;

	bus1 DUT(
		.d_in(d_in),
		.e_b1(b1),
		.d_out(d_out)
	);

	initial begin
		$dumpfile("bus1.vcd");
		$dumpvars(0, bus1_TB);
	end
	
	initial begin
		d_in = 8'haa;
		b1 = 0;
		#20 b1 = 1;
		#20 b1 = 0;
		#20 d_in = 8'h66;
		#20 b1 = 1;
		#20 b1 = 0;
		#20 $finish;
	end

endmodule