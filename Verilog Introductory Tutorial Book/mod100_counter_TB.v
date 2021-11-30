/********************************************************************
 Title       : mod100_counter_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : mod100_counter.v
 Incl. Mods. : None
*********************************************************************/
module mod100_counter_TB;

reg CLOCK, RESET;
wire sig100;

//Instantiate the Module Under Test(MUT)
mod100_counter ctr100(.CLOCK(CLOCK), .RESET(RESET), .sig100(sig100));

always #5 CLOCK = ~CLOCK;	//Create the clock

//Test sequence
initial begin
	CLOCK = 0;
	RESET = 0;
	
	#100 RESET = 1;
	#50  RESET = 0;
	
	#5000 $finish;
end

//Set up file for GTKWave
initial begin
	$dumpfile("mod100_counter_TB.vcd");
	$dumpvars(0, mod100_counter_TB);
end

endmodule