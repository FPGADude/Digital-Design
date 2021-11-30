
/********************************************************************
 Title       : D_ff_beh_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : D_ff_beh.v
 Incl. Mods. : None
*********************************************************************/

module D_ff_beh_TB();	

reg CLOCK, D;				

wire Q, Q_not;		

//Instantiate module under test
D_ff_beh D1(
	.CLOCK(CLOCK),
	.D(D),
	.Q(Q),
	.Q_not(Q_not)
);

//Create the CLOCK
always begin
	#10 CLOCK = !CLOCK; 
  end

//Simulation stimulation timeline
initial begin
	CLOCK = 0;	//Initialize both registers
	D = 0;
	
	#50
	D = 1;
	
	#100	
	D = 0;
	
	#20
	D = 1;

	#40
	D = 0;
	
	#1000 $finish;	
  end
  
//Set up output files for GTKWave
initial begin
    $dumpfile("D_ff_beh_TB.vcd");
	$dumpvars(0, D_ff_beh_TB);
  end
  
endmodule