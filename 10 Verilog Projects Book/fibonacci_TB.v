
module fibonacci_TB;
	reg clock;
	reg reset;
	wire [15:0] fib_out;
	
	fibonacci DUT(.clock(clock), .reset(reset), 
				  .fib_out(fib_out));

	always #2 clock = ~clock;

	initial begin
		clock = 0;
		reset = 0;
		#9 reset = 1;
		
		#100 $finish;
	end

	initial begin
		$dumpfile("fibonacci_TB.vcd");
		$dumpvars(0, fibonacci_TB);
	end

endmodule


