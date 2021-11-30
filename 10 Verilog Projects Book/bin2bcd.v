module bin2bcd(
	input  [7:0] bin_in,
	output [7:0] bcd_out
);

	reg [3:0] tens, ones;

	always @(*) begin
		tens = bin_in / 10;
		ones = bin_in % 10;
	end

	assign bcd_out = {tens, ones};

endmodule


