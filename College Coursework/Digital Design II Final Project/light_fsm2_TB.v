/******************************************************************
 Title       : light_fsm2_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT 	     : light_fsm2.v
*******************************************************************/

`timescale 1ns/1ps

module light_fsm2_TB;

reg RESET  ; 	//Active HIGH
reg ENABLE ; 	//Active HIGH
reg CLOCK  ;

wire A, B, C ;

//Instantiate module under test
light_fsm2 LSFM2(
	.A(A),
	.B(B),
	.C(C),
	.RESET(RESET),
	.ENABLE(ENABLE),
	.CLOCK(CLOCK)
	);

//Create the clock
always
  #20 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("light_fsm2_TB.vcd") ;
  $dumpvars(0, light_fsm2_TB) ;
end

//Initialize the machine, set run time
initial
begin
		CLOCK  = 0 ;
		RESET  = 0 ;
		ENABLE = 1 ;
  #1	RESET  = 1 ;
  #40 	RESET  = 0 ;
  #330	ENABLE = 0 ;
  #300	ENABLE = 1 ;
  
  #1000 $finish ; 
end
 
endmodule