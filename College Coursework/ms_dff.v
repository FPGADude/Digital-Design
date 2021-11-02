/********************************************************************
 Title       : ms_dff.v	     		 
 Design      : Master Slave D Type Flip Flop w/ Preset and Clear	 
 Author      : David J. Marion		     	
 Assignment  : Homework #4      	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : ms_dff_TB.v
 Func. Check : A THING OF BEAUTY
 Information : This module contains a master slave d flip flop with
			   asynchronous preset and clear. Preset and clear are
			   active low.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

//*** Gate level model ***
module ms_dff(		
	output Q,
	output Q_not,
	
	input CLOCK,
	input nPRESET,
	input nCLEAR,
	input DATA
);

//Everything is a wire
wire DATA, not_DATA, CLOCK, not_CLOCK, Q, Q_not,
	 nPRESET, nCLEAR, temp1, temp2, temp3, temp4, temp5, temp6;

//Instantiated Verilog primitives
not inv0(not_CLOCK, CLOCK);
not inv1(not_DATA, DATA);	 
nand n0(temp1, not_CLOCK, DATA);
nand n1(temp2, not_CLOCK, not_DATA);
nand n2(temp3, temp2, nCLEAR, temp4);
nand n3(temp4, temp1, nPRESET, temp3);
nand n4(temp5, temp4, CLOCK);
nand n5(temp6, temp3, CLOCK);
nand n6(Q, temp5, nPRESET, Q_not);
nand n7(Q_not, temp6, nCLEAR, Q);

endmodule