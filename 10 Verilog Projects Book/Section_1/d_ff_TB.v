
module d_ff_TB;
	reg  clock;
	reg  reset;
	reg  data_in;
	wire q;

	d_ff DUT(.clock(clock), .reset(reset), 
			 .data_in(data_in), .q(q));

	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("d_ff_TB.vcd");
		$dumpvars(0, d_ff_TB);
	end
	
	initial begin
		clock = 0;
		reset = 0;
		data_in = 0;		
		
		#9 reset = 1;
		   data_in = 1;
		
		#4 data_in = 0;
		#4 data_in = 1;
		#4 reset = 0;
		#4 reset = 1;
		
		#4 $finish;
	end
	
endmodule


