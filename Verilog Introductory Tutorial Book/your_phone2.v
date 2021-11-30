

/********************************************************************
 Title       : your_phone2.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : OR_gate.v
*********************************************************************/

module your_phone2();	

reg Abby_has_lice;			//A register to drive input A of the AND gate
reg Billy_drinks_soda;		//A register to drive input B of the AND gate

wire shOw_me_the_money;		//A wire to capture the output O for evaluation

//Instantiate module under test below:
OR_gate O1(
	.A(Abby_has_lice), 
	.B(Billy_drinks_soda), 
	.O(shOw_me_the_money)
);

//Simulation stimulation timeline
initial begin

	//Row1 of truth table
	Abby_has_lice = 0;
	Billy_drinks_soda = 0;
	#50		//Delay 50 time units
	
	//Row2 of truth table
	Abby_has_lice = 0;
	Billy_drinks_soda = 1;
	#50		//Delay 50 time units
	
	//Row3 of truth table
	Abby_has_lice = 1;
	Billy_drinks_soda = 0;
	#50		//Delay 50 time units
	
	//Row4 of truth table
	Abby_has_lice = 1;
	Billy_drinks_soda = 1;
	#50		//Delay 50 time units	

	//Set time out for simulation	
	#500 $finish;
	
  end
 
//Set up output files for GTKWave wave simulator
initial begin
    $dumpfile("your_phone2.vcd");
	$dumpvars(0, your_phone2);
  end

endmodule