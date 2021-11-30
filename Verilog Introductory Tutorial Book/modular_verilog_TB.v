/********************************************************************
 Title       : modular_verilog_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : modular_verilog.v
 Include Mods: binary_counter3.v, decoder_3x8.v
*********************************************************************/
module modular_verilog_TB;	

reg CLOCK, ENABLE;				
wire [7:0] OUT;	
	
//Instantiate module under test
modular_verilog MV1(.CLOCK(CLOCK), .ENABLE(ENABLE), .OUT(OUT));

//Create the clock
always #10 CLOCK = !CLOCK;

//Simulation stimulation timeline
initial begin
	CLOCK = 0;
	ENABLE = 0;
	#50 ENABLE = 1;
	
	#500 $finish;	
  end
  
//Set up output files for GTKWave
initial begin
    $dumpfile("modular_verilog_TB.vcd");
	$dumpvars(0, modular_verilog_TB);
  end
  
endmodule

