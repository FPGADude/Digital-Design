
module reg_file(
	input clock,
	input write_enable,
	input [2:0] write_address,
	input [2:0] read_address,
	input [7:0] write_data,
	output [7:0] read_data
);

	reg [7:0] reg_file [7:0];

	always @(posedge clock )
		if(write_enable)
			reg_file[write_address] <= write_data;
	
	assign read_data = reg_file[read_address];

endmodule


