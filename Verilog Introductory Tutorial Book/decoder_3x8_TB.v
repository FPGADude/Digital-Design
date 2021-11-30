

/********************************************************************
 Title       : decoder_3x8_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : D_ff_beh.v
 Incl. Mods. : None
*********************************************************************/

module decoder_3x8_TB();	

reg x, y, z;				

wire F0, F1, F2, F3, F4, F5, F6, F7;		

//Instantiate module under test
decoder_3x8 dec1(
	//Inputs
	.x(x),
	.y(y),
	.z(z),
	//Outputs
	.F0(F0),
	.F1(F1),
	.F2(F2),
	.F3(F3),
	.F4(F4),
	.F5(F5),
	.F6(F6),
	.F7(F7)
);

//Simulation stimulation timeline
initial begin
	x = 0;
	y = 0;
	z = 0;
	#50
	x = 0;
	y = 0;
	z = 1;
	#50
	x = 0;
	y = 1;
	z = 0;
	#50
	x = 0;
	y = 1;
	z = 1;
	#50
	x = 1;
	y = 0;
	z = 0;
	#50
	x = 1;
	y = 0;
	z = 1;
	#50
	x = 1;
	y = 1;
	z = 0;
	#50
	x = 1;
	y = 1;
	z = 1;
	#50
	
	x = 1;
	y = 1;
	z = 1;
	#50
	x = 1;
	y = 1;
	z = 0;
	#50
	x = 1;
	y = 0;
	z = 1;
	#50
	x = 1;
	y = 0;
	z = 0;
	#50
	x = 0;
	y = 1;
	z = 1;
	#50
	x = 0;
	y = 1;
	z = 0;
	#50
	x = 0;
	y = 0;
	z = 1;
	#50
	x = 0;
	y = 0;
	z = 0;
	#50
	
	
	#2000 $finish;	
  end
  
//Set up output files for GTKWave
initial begin
    $dumpfile("decoder_3x8_TB.vcd");
	$dumpvars(0, decoder_3x8_TB);
  end
  
endmodule