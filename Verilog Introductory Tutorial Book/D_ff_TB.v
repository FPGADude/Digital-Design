

/********************************************************************
 Title       : D_ff_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : D_ff.v
 Incl. Mods. : NAND_gate.v
*********************************************************************/

module D_ff_TB();	

reg CLOCK, D;				

wire Q, Q_not;		

//Instantiate module under test
D_ff D1(
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
    $dumpfile("D_ff_TB.vcd");
	$dumpvars(0, D_ff_TB);
  end
  
endmodule