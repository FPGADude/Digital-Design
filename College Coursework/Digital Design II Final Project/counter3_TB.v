/********************************************************************
 Title       : counter3_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : counter3.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter3_TB;

reg ENABLE;
reg RESET;
reg CLOCK;

wire latch_reset;

//Instantiate module under test
counter3 ctr3(
	.CLOCK(CLOCK),
	.ENABLE(ENABLE),
	.RESET(RESET),	
	.latch_reset(latch_reset)
);


//Create the clock
always
  #10 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("counter3_TB.vcd") ;
  $dumpvars(0, counter3_TB) ;
end

//Test Sequence
initial
begin
		ENABLE = 0 ;
		CLOCK  = 0 ;
		RESET  = 1 ;
  #40 	RESET  = 0 ;
  #100  ENABLE = 1 ;
  #500  ENABLE = 0 ;
  #40   RESET  = 1 ;
  #40   RESET  = 0 ;

  //Set time out 
  #5000 $finish ; 
end
 
endmodule