
module ram_TB;
	reg        clock;
	reg  	   write_enable;
	reg  [3:0] address;
	reg  [7:0] data_in;
	wire [7:0] data_out;
	
	ram DUT(.clock(clock), .write_enable(write_enable), 
			.address(address), 
			.data_in(data_in), .data_out(data_out));
	
	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("ram_TB.vcd");
		$dumpvars(0, ram_TB);
	end
	
	integer i;
	
	initial begin
		clock = 0;
		write_enable = 0;
		address = 4'h0;
		data_in = 8'h00;
		#9 write_enable = 1;
		
		for(i = 0; i < 16; i = i + 1) begin
			address = i;
			data_in = i * 16;
			#4;
		end
		
		write_enable = 0;
		
		for(i = 0; i < 16; i = i + 1) begin
			address = i;
			#4;
		end
		
		#4 $finish;
		
	end
	
endmodule



