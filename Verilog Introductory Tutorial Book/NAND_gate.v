

/********************************************************************
 Title       : NAND_gate.v	     		 
 Design      : A simple NAND logic gate 
 Author      : David J. Marion		     	
 Func. Check : Complete
 Information : This module contains a 2-input NAND gate
*********************************************************************/

module NAND_gate(input A, input B, output O);	

wire A;		
wire B;		

wire O;		

assign O = !(A & B);	

endmodule			