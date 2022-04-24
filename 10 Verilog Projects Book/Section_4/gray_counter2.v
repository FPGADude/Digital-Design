
module gray_counter2(
	input clock,
	input reset,
	output [2:0] gray_out
);

	reg [2:0] bin_counter;

	always @(posedge clock or negedge reset) begin
		if(~reset)
			bin_counter <= 0;
		else
			bin_counter <= bin_counter + 1;
	end

	assign gray_out[2] = bin_counter[2];
	assign gray_out[1] = bin_counter[2] ^ bin_counter[1];
	assign gray_out[0] = bin_counter[1] ^ bin_counter[0];

endmodule


