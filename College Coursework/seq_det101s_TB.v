/********************************************************************
 Title       : seq_det101s_TB.v	     		 
 Design      : ***STIMULUS***	 
 Author      : David J. Marion		     	
 Assignment  : Homework #4      	 
 Course      : EE352 Digital Design II
 MUT	     : seq_det101s.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module seq_det101s_TB;

reg CLOCK;
reg nCLEAR;
reg nPRESET;

reg [31:0] serial_data = 32'b0001_1100_1000_1010_1001_0101_0010_1010;
integer counter = 0;

reg X = 0;
wire Y;

seq_det101s SD0(
	.CLOCK(CLOCK),
	.nCLEAR(nCLEAR),
	.nPRESET(nPRESET),
	.X(X),
	.Y(Y)
);

always @(posedge CLOCK)
begin
	X = serial_data[counter];
	counter = counter + 1;
end

//Create the clock
always
  #10 CLOCK = !CLOCK ;
  
//Set up output files for gtkwave simulator
initial
begin
  $dumpfile("seq_det101s_TB.vcd") ;
  $dumpvars(0, seq_det101s_TB) ;
end

//Test Sequence
initial
begin
		CLOCK   = 0 ;
		nCLEAR  = 1 ;
		nPRESET = 1 ;
#500	nPRESET = 0 ;
#100	nPRESET = 1 ;
#100	nCLEAR  = 0 ;
#100	nCLEAR	= 1 ;
		
  //Set time out 
  #5000 $finish ; 
end

endmodule