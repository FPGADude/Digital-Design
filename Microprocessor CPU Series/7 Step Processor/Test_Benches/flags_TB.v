// Test bench for flags.v

module flags_TB;
	reg s;
	reg [3:0] data_driver;
	wire [3:0] data_receiver;

	flags DUT(
		.s(s),
		.caez_in(data_driver),
		.caez_out(data_receiver)
	);
	initial begin
		$dumpfile("flags.vcd");
		$dumpvars(0, flags_TB);
	end
	
	initial begin
		s = 0;
		data_driver = 4'h1;
		#1 s = 1;
		#1 s = 0;
		#1;
		data_driver = 4'h6;
		#1 s = 1;
		#1 s = 0;
		#1;
		data_driver = 4'ha;
		#1 s = 1;
		#1 s = 0;
	
		#1 $finish;
	end

endmodule