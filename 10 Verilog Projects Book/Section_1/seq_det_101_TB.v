
module seq_det_101_TB;
	reg  clock;
	reg  reset;
	reg  serial_in;
	wire detect_101;

	sequence_detector_101 DUT(.clock(clock), .reset(reset), 
							  .serial_in(serial_in), 
							  .detect_101(detect_101));

	always #2 clock = ~clock;

	initial begin
		$dumpfile("seq_det_101_TB.vcd");
		$dumpvars(0, seq_det_101_TB);
	end

	reg [15:0] data = 16'b0100_1010_0101_1011;

	integer i;
	
	initial begin
		clock = 0;
		reset = 0;
		serial_in = 0;
		#9 reset = 1;
		
		for(i = 0; i < 16; i = i + 1) begin
			serial_in = data[i];
			#4;
		end
		
		#4 $finish;
	end

endmodule


