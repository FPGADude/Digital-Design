
module ram(
	input        clock,
	input        write_enable,
	input  [3:0] address,
	input  [7:0] data_in,
	output [7:0] data_out
);

	reg [7:0] ram [15:0];
	
	always @(posedge clock)
		if(write_enable)
			ram[address] <= data_in;
			
	assign data_out = ram[address];

endmodule


