
module gray_counter(
	input clock,
	input reset,
	output reg [2:0] gray_out
);

	reg [2:0] bin_counter;

	always @(posedge clock or negedge reset) begin
		if(~reset)
			bin_counter <= 0;
		else
			bin_counter <= bin_counter + 1;
	end

	always @(bin_counter) begin
		case(bin_counter)
			3'b000 : gray_out = 3'b000;
			3'b001 : gray_out = 3'b001;
			3'b010 : gray_out = 3'b011;
			3'b011 : gray_out = 3'b010;
			3'b100 : gray_out = 3'b110;
			3'b101 : gray_out = 3'b111;
			3'b110 : gray_out = 3'b101;
			3'b111 : gray_out = 3'b100;
		endcase
	end

endmodule

