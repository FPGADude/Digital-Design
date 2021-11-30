/********************************************************************
 Title       : binary_counter3_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : binary_counter3.v
 Incl. Mods. : None
*********************************************************************/
module binary_counter3_TB;	
reg CLOCK, ENABLE;				
wire [2:0] OUT;	
	
//Instantiate module under test
binary_counter3 BC3(.CLOCK(CLOCK), .ENABLE(ENABLE), .ctr3(OUT));

//Create the clock
always #10 CLOCK = !CLOCK;

//Simulation stimulation timeline
initial begin
	CLOCK = 0;
	ENABLE = 0;
	#50 ENABLE = 1;
	#200 ENABLE = 0;
	#400 $finish;	
  end
  
//Set up output files for GTKWave
initial begin
    $dumpfile("binary_counter3_TB.vcd");
	$dumpvars(0, binary_counter3_TB);
  end
  
endmodule
