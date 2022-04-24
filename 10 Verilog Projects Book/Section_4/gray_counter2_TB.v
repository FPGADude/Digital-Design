
module gray_counter2_TB;
	reg clock;
	reg reset;
	wire [2:0] gray_out;

	gray_counter2 DUT(.clock(clock), .reset(reset), 
					  .gray_out(gray_out));
	
	always #2 clock = ~clock;
	
	initial begin
		clock = 0;
		reset = 0;
		#9 reset = 1;
		
		#60 $finish;
	end
	
	initial begin
		$dumpfile("gray_counter2_TB.vcd");
		$dumpvars(0, gray_counter2_TB);
	end
	
endmodule


