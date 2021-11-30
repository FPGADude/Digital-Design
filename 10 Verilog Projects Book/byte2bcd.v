module byte2bcd(
	input  [7:0] bin_in,
	output [11:0] bcd_out
);

	reg [3:0] hundreds, tens, ones;
	reg [6:0] temp_reg;

	always @(*) begin
		hundreds = bin_in / 100;
		temp_reg = bin_in % 100;
		tens = temp_reg / 10;
		ones = temp_reg % 10;
	end

	assign bcd_out = {hundreds, tens, ones};

endmodule

