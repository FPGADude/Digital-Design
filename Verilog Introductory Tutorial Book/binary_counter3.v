/********************************************************************
 Title       : binary_counter3.v	     		 
 Design      : 3-bit Binary Counter 
 Author      : David J. Marion		     	
 Func. Check : None
 Information : This module contains a 3-bit binary counter
*********************************************************************/

module binary_counter3(
	//Inputs
	input CLOCK, 
	input ENABLE,
	//Outputs
	output reg [2:0] ctr3 = 3'b000
);	

always @ (posedge CLOCK) begin
	if (!ENABLE) begin
		ctr3 <= ctr3;
	end
	else begin
		ctr3 <= ctr3 + 1;
	end
end

endmodule			