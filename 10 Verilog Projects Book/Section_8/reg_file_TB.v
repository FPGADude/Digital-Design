
module reg_file_TB;
	reg clock;
	reg write_enable;
	reg [2:0] write_address;
	reg [2:0] read_address;
	reg [7:0] write_data;
	wire [7:0] read_data;
	
	reg_file DUT(.clock(clock), .write_enable(write_enable), 
				 .write_address(write_address), 
				 .read_address(read_address), 
				 .write_data(write_data), .read_data(read_data));
				 
	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("reg_file_TB.vcd");
		$dumpvars(0, reg_file_TB);
	end
	
	integer i;
	
	initial begin
		clock = 0;
		write_enable = 1'b0;
		write_address = 3'b000;
		read_address = 3'b000;
		write_data = 8'h00;
		
		#5 write_enable = 1'b1;
		for(i = 0; i < 8; i = i + 1) begin
			write_address = i;
			write_data = i * 16;
			#4;
		end
	
		#8 write_enable = 1'b0;
		for(i = 0; i < 8; i = i + 1) begin
			read_address = i;
			#4;
		end
		
		$finish;
	end	
endmodule



