

/********************************************************************
 Title       : D_ff.v	     		 
 Design      : A D-Type Flip-Flop 
 Author      : David J. Marion		     	
 Incl. Mods	 : NAND_gate.v
 Func. Check : Good
 Information : This module contains a D Type Flip Flop
*********************************************************************/

module D_ff(
	input CLOCK, 
	input D, 
	
	output Q,
	output Q_not
);	

wire CLOCK, D, D_not, Q, Q_not, temp1, temp2;

assign D_not = !D;					//This takes care of the NOT gate

NAND_gate N1(
	.A(D),
	.B(CLOCK),
	.O(temp1)
);
NAND_gate N2(
	.A(CLOCK),
	.B(D_not),
	.O(temp2)
);
NAND_gate N3(
	.A(temp1),
	.B(Q_not),
	.O(Q)
);
NAND_gate N4(
	.A(Q),
	.B(temp2),
	.O(Q_not)
);

endmodule	