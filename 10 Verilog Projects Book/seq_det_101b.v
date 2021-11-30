
module seq_det_101b(
	input clock,
	input reset,
	input serial_in,
	output detect_101
);

	reg [2:0] shift_reg;

	always @(posedge clock or negedge reset)
		if(~reset)
			shift_reg <= 0;
		else
			shift_reg <= {shift_reg[1:0], serial_in};
			
	assign detect_101 = (shift_reg == 3'b101) ? 1 : 0;

endmodule


