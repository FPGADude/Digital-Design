

/********************************************************************
 Title       : NAND_gate2.v	     		 
 Design      : A simple NAND logic gate 
 Author      : David J. Marion		     	
 Func. Check : Complete
 Information : This module contains a 2-input NAND gate. The function
				is obtained by using DeMorgan's Law
				!(A & B) == !A | !B
*********************************************************************/

module NAND_gate2(input A, input B, output O);	

wire A;		
wire B;		

wire O;		

assign O = !A | !B;	

endmodule	