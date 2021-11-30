/********************************************************************
 Title       : mux_4x1.v	     		 
 Design      : 4-to-1 Multiplexer 
 Author      : David J. Marion		     	
 Func. Check : None
 Include Mods: None
*********************************************************************/
module mux_4x1(
	//Inputs
	input [3:0] D,	// 4-bit data input
	input [1:0] AB,	// 2-bit selector input
	//Ouputs
	output reg Y	// Data output
);

always @ (*) begin
	case (AB)
		2'b00 : Y = D[0];
		2'b01 : Y = D[1];
		2'b10 : Y = D[2];
		2'b11 : Y = D[3];
		default : Y = D[0];
	endcase
end

endmodule

