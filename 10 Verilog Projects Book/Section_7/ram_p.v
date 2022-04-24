
module ram_p #(parameter ADDR_WIDTH = 4,
						 DATA_WIDTH = 8)
(
	input 					clock,
	input   				write_enable,
	input  [ADDR_WIDTH-1:0] address,
	input  [DATA_WIDTH-1:0] data_in,
	output [DATA_WIDTH-1:0] data_out
);

	reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
	
	always @(posedge clock)
		if(write_enable)
			ram[address] <= data_in;
			
	assign data_out = ram[address];
	
endmodule



