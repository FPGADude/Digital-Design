/********************************************************************
 Title       : ms_dff_TB.v	     		 
 Design      : ***STIMULUS***	 
 Author      : David J. Marion		     	
 Assignment  : Homework #4      	 
 Course      : EE352 Digital Design II
 MUT	     : ms_dff.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module ms_dff_TB;

reg DATA;
reg CLOCK;
reg nCLEAR;
reg nPRESET;

wire Q, Q_not;

ms_dff D0(
	.DATA(DATA),
	.CLOCK(CLOCK),
	.nCLEAR(nCLEAR),
	.nPRESET(nPRESET),
	
	.Q(Q),
	.Q_not(Q_not)
);


//Create the clock
always
  #10 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave simulator
initial
begin
  $dumpfile("ms_dff_TB.vcd") ;
  $dumpvars(0, ms_dff_TB) ;
end

//Test Sequence
initial
begin
		CLOCK   = 0 ;
		nCLEAR  = 1 ;
		nPRESET = 1 ;
		DATA	= 0 ;
#20 	nPRESET = 0 ;	//Activate preset 
#20 	nPRESET = 1 ;
#45		DATA 	= 1 ;
#100 	nCLEAR  = 0 ;	//Activate clear
#20 	nCLEAR  = 1 ;
#100	DATA	= 0 ;
#100	DATA	= 1 ;
#100	DATA	= 0 ;
		
  //Set time out 
  #5000 $finish ; 
end

endmodule