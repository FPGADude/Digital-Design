
module seq_det_101c(
	input clock,
	input reset,
	input serial_in,
	output detect_101
);

	parameter S0 = 2'b00;
	parameter S1 = 2'b01;
	parameter S2 = 2'b10;
	parameter S3 = 2'b11;
	
	reg [1:0] current_state, next_state;

	always @(posedge clock or negedge reset)
		if(~reset)
			current_state <= S0;
		else
			current_state <= next_state;
			
	always @(*)
		case(current_state)
			S0 : next_state = (serial_in == 1) ? S1 : S0;
			S1 : next_state = (serial_in == 0) ? S2 : S1;
			S2 : next_state = (serial_in == 1) ? S3 : S0;
			S3 : next_state = (serial_in == 1) ? S1 : S2;
		endcase

	assign detect_101 = (current_state == S3) ? 1 : 0;

endmodule


