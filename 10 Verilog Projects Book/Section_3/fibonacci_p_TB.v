
module fibonacci_p_TB;
	parameter W = 32;
	reg clock;
	reg reset;
	wire [W-1:0] fib_out;
	
	fibonacci_p #(.W(W)) DUT(.clock(clock), .reset(reset), 
						     .fib_out(fib_out));

	always #2 clock = ~clock;

	initial begin
		clock = 0;
		reset = 0;
		#9 reset = 1;
		
		#500 $finish;
	end

	initial begin
		$dumpfile("fibonacci_p_TB.vcd");
		$dumpvars(0, fibonacci_p_TB);
	end

endmodule

