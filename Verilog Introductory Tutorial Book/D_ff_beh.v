

/********************************************************************
 Title       : D_ff_beh.v	     		 
 Design      : A D-Type Flip-Flop 
 Author      : David J. Marion		     	
 Func. Check : None
 Information : This module contains a D Type Flip Flop
*********************************************************************/

module D_ff_beh(
	input CLOCK, 
	input D, 
	
	output Q,
	output Q_not

);	

wire CLOCK, D, Q_not;
reg  Q;

assign Q_not = !Q;

always@ (posedge CLOCK) begin
	Q <= D;
  end

endmodule	