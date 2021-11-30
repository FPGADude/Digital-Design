
module traffic_controller_TB;
	reg clock;
	reg reset;
	reg sensor;
	wire [2:0] major;
	wire [2:0] minor;
	
	traffic_controller DUT(.clock(clock), .reset(reset), 
						   .sensor(sensor), 
						   .major(major), .minor(minor));
						   
	always #2 clock = ~clock;
	
	initial begin
		$dumpfile("traffic_controller_TB.vcd");
		$dumpvars(0, traffic_controller_TB);
	end
	
	initial begin
		clock = 0;
		reset = 0;
		sensor = 0;
		
		#5 reset = 1;
		
		#4 sensor = 1;
		#20 sensor = 0;
		
		#50 $finish;
	end
	
endmodule



