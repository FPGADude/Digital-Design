/********************************************************************
 Title       : counter1_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : counter1.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter1_TB;

reg CLOCK;
reg RESET;

wire control_signal;

//Instantiate module under test 
counter1 CTR(
	.CLOCK(CLOCK),
	.RESET(RESET),
	.control_signal(control_signal)
	);

//Create the clock
always
  #20 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("counter1_TB.vcd") ;
  $dumpvars(0, counter1_TB) ;
end

//Test Sequence
initial
begin
		CLOCK  = 0 ;
		RESET  = 1 ;
  #40 	RESET  = 0 ;

  //Set time out 
  #10000 $finish ; 
end
 
endmodule