module sequence_detector_101(
	input  clock,
	input  reset,
	input  serial_in,
	output detect_101
);

	wire a2b, b2c, c;

	d_ff DFFa(.clock(clock), .reset(reset), 
			  .data_in(serial_in), .q(a2b));
	d_ff DFFb(.clock(clock), .reset(reset), 
			  .data_in(a2b), .q(b2c));
	d_ff DFFc(.clock(clock), .reset(reset), 
			  .data_in(b2c), .q(c));

	assign detect_101 = a2b & ~b2c & c;

endmodule



