
module rom(
	input  [3:0] address,
	output reg [7:0] data
);

	always @(*)
		case(address)
			4'h0 : data = 8'h00;
			4'h1 : data = 8'h11;
			4'h2 : data = 8'h22;
			4'h3 : data = 8'h33;
			4'h4 : data = 8'h44;
			4'h5 : data = 8'h55;
			4'h6 : data = 8'h66;
			4'h7 : data = 8'h77;
			4'h8 : data = 8'h88;
			4'h9 : data = 8'h99;
			4'ha : data = 8'haa;
			4'hb : data = 8'hbb;
			4'hc : data = 8'hcc;
			4'hd : data = 8'hdd;
			4'he : data = 8'hee;
			4'hf : data = 8'hff;
		endcase

endmodule


