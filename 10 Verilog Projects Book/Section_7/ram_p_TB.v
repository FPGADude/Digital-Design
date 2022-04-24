
module ram_p_TB;
	parameter ADDR_WIDTH = 8, DATA_WIDTH = 16;
	reg        			  clock;
	reg  	   			  write_enable;
	reg  [ADDR_WIDTH-1:0] address;
	reg  [DATA_WIDTH-1:0] data_in;
	wire [DATA_WIDTH-1:0] data_out;
	
	ram_p #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) 
			DUT(.clock(clock), .write_enable(write_enable), 
				.address(address), 
				.data_in(data_in), .data_out(data_out));
	
	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("ram_p_TB.vcd");
		$dumpvars(0, ram_p_TB);
	end
	
	integer i;
	
	initial begin
		clock = 0;
		write_enable = 0;
		address = 0;
		data_in = 0;
		#9 write_enable = 1;
		
		for(i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
			address = i;
			data_in = i * (2**ADDR_WIDTH);
			#4;
		end
		
		write_enable = 0;
		
		for(i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
			address = i;
			#4;
		end
		
		#4 $finish;	
	end
endmodule

