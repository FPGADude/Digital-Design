

/********************************************************************
 Title       : NAND_gate_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : NAND_gate.v
*********************************************************************/

module NAND_gate_TB();	

reg A;			
reg B;		

wire O;		

//Instantiate module under test:
NAND_gate N1(
	.A(A), 
	.B(B), 
	.O(O)
);

//Simulation stimulation timeline
initial begin

	//Row1 of truth table
	A = 0;
	B = 0;
	#50
	
	//Row2 of truth table
	A = 0;
	B = 1;
	#50
	
	//Row3 of truth table
	A= 1;
	B = 0;
	#50
	
	//Row4 of truth table
	A = 1;
	B = 1;
	#50

	//Set time out for simulation	
	#500 $finish;
	
  end
 
//Set up output files for GTKWave
initial begin
    $dumpfile("NAND_gate_TB.vcd");
	$dumpvars(0, NAND_gate_TB);
  end

endmodule