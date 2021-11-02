/********************************************************************
 Title       : srl_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : srl.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module srl_TB;

reg SET = 0;
reg RESET = 0;

wire Q_out;

//Instantiate module under test
srl srl1(
	.SET(SET),
	.RESET(RESET),
	.Q_out(Q_out)
);
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("srl_TB.vcd") ;
  $dumpvars(0, srl_TB) ;
end

//Test Sequence
initial
begin
		SET   = 0 ;
		RESET = 1 ;
  #20 	RESET = 0 ;
  #160  SET   = 1 ;
  #100	SET   = 0 ;
  #25	RESET = 1 ;
  #25	RESET = 0 ;
  #100	
		SET   = 1 ;
		RESET = 1 ;
  #50   SET   = 0 ;
  #50	RESET = 0 ;
  #25	RESET = 1 ;
  #25   RESET = 0 ;

  //Set time out 
  #1000 $finish ; 
end
 endmodule