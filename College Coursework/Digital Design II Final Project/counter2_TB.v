/********************************************************************
 Title       : counter2_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : counter2.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter2_TB;

reg CLOCK;
reg RESET;
reg ENABLE;

wire counter3_RST;
wire control_signal;
wire W;
wire X;
wire Y;
wire Z;

//Instantiate module under test 
counter2 CTR(
	.CLOCK(CLOCK),
	.RESET(RESET),
	.ENABLE(ENABLE),
	.counter3_RST(counter3_RST),
	.control_signal(control_signal),
	.W(W),
	.X(X),
	.Y(Y),
	.Z(Z)
);

//Create the clock
always
  #20 CLOCK = ~CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("counter2_TB.vcd") ;
  $dumpvars(0, counter2_TB) ;
end

//Test Sequence
initial
begin
		CLOCK  = 0 ;
		RESET  = 0 ;
		ENABLE = 0 ;
  #10	RESET  = 1 ;
  #31 	RESET  = 0 ;
  #200	ENABLE = 1 ;
  #250	RESET  = 1 ;
  #50	RESET  = 0 ;
  #950	ENABLE = 0 ;
  
  #2000 $finish ;  
end
 
endmodule