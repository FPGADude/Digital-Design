
module reg_file_p #(parameter ADDR_WIDTH = 3,
							  DATA_WIDTH = 8)
(
	input 					clock,
	input 					write_enable,
	input  [ADDR_WIDTH-1:0] write_address,
	input  [ADDR_WIDTH-1:0] read_address,
	input  [DATA_WIDTH-1:0] write_data,
	output [DATA_WIDTH-1:0] read_data
);

	reg [DATA_WIDTH-1:0] reg_file [2**ADDR_WIDTH-1:0];

	always @(posedge clock)
		if(write_enable)
			reg_file[write_address] <= write_data;

	assign read_data = reg_file[read_address];

endmodule


