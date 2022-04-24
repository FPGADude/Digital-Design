
module reg_file_p_TB;
	parameter ADDR_WIDTH = 4;
	parameter DATA_WIDTH = 16;
	reg  clock;
	reg  write_enable;
	reg  [ADDR_WIDTH-1:0] write_address;
	reg  [ADDR_WIDTH-1:0] read_address;
	reg  [DATA_WIDTH-1:0] write_data;
	wire [DATA_WIDTH-1:0] read_data;
	
	reg_file_p #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) 
			   DUT(.clock(clock), .write_enable(write_enable), 
				   .write_address(write_address), 
				   .read_address(read_address), 
				   .write_data(write_data), .read_data(read_data));
				 
	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("reg_file_p_TB.vcd");
		$dumpvars(0, reg_file_p_TB);
		end
	
	integer i;
	
	initial begin
		clock = 0;
		write_enable = 0;
		write_address = 0;
		read_address = 0;
		write_data = 0;
		#5 write_enable = 1'b1;
		for(i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
			write_address = i;
			write_data = i * 16;
			#4;
			end
		#8 write_enable = 1'b0;
		for(i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
			read_address = i;
			#4;
			end
		$finish;
	end	
endmodule


