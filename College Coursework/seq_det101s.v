/********************************************************************
 Title       : seq_det101s.v	     		 
 Design      : 101 Sequence Detector	 
 Author      : David J. Marion		     	
 Assignment  : Homework #4      	 
 Course      : EE352 Digital Design II
 Incl. Mods  : ms_dff.v
 Stimulus    : seq_det101s_TB.v
 Func. Check : Sequence detection checks GOOD
			   Preset and clear 
 Information : This module contains three d flip flops that 
			   combinationally trigger an output with a 101 
			   state. Inputs are fed serially to the first
			   flip flop which feeds the next and the next.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module seq_det101s(
	output Y,		//101 sequence output = dffA & !dffB & dffC
	
	input CLOCK,
	input nPRESET,
	input nCLEAR,
	input X			//Serial input
);

wire CLOCK, nPRESET, nCLEAR, X, Y, 
	 A, A_not, B, B_not, C, C_not;

//Define output Y
and (Y, A, B_not, C);

ms_dff dffA(
	.Q(A),
	.Q_not(A_not),
	
	.CLOCK(CLOCK),
	.nPRESET(nPRESET),
	.nCLEAR(nCLEAR),
	.DATA(X)
);

ms_dff dffB(
	.Q(B),
	.Q_not(B_not),
	
	.CLOCK(CLOCK),
	.nPRESET(nPRESET),
	.nCLEAR(nCLEAR),
	.DATA(A)
);

ms_dff dffC(
	.Q(C),
	.Q_not(C_not),
	
	.CLOCK(CLOCK),
	.nPRESET(nPRESET),
	.nCLEAR(nCLEAR),
	.DATA(B)
);

endmodule