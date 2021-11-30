/*****************************************************
 Title       : decoder_3x8.v	     		 
 Design      : A 3x8 Decoder
 Author      : David J. Marion		     	
 Func. Check : None
 Information : This module contains a 3x8 decoder
*****************************************************/

module decoder_3x8(
	input x, 
	input y,
	input z,	
	
	output F0,
	output F1,
	output F2, 
	output F3,
	output F4,
	output F5,
	output F6,
	output F7
);	

wire [2:0] select;
reg F0, F1, F2, F3, F4, F5, F6, F7;

assign select[2] = x;
assign select[1] = y;
assign select[0] = z;

always@ (*) begin
	
	case (select)
	3'b000: 
	  begin
		F0 = 1;
		F1 = 0;
		F2 = 0;
		F3 = 0;
		F4 = 0;
		F5 = 0;
		F6 = 0;
		F7 = 0;
	  end
	  
	3'b001: 
	  begin
		F0 = 0;
		F1 = 1;
		F2 = 0;
		F3 = 0;
		F4 = 0;
		F5 = 0;
		F6 = 0;
		F7 = 0;
	  end
	
	3'b010: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 1;
		F3 = 0;
		F4 = 0;
		F5 = 0;
		F6 = 0;
		F7 = 0;
	  end
	  
	3'b011: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 0;
		F3 = 1;
		F4 = 0;
		F5 = 0;
		F6 = 0;
		F7 = 0;
	  end  
	  
	3'b100: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 0;
		F3 = 0;
		F4 = 1;
		F5 = 0;
		F6 = 0;
		F7 = 0;
	  end
	  
	3'b101: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 0;
		F3 = 0;
		F4 = 0;
		F5 = 1;
		F6 = 0;
		F7 = 0;
	  end
	  
	3'b110: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 0;
		F3 = 0;
		F4 = 0;
		F5 = 0;
		F6 = 1;
		F7 = 0;
	  end  

	3'b111: 
	  begin
		F0 = 0;
		F1 = 0;
		F2 = 0;
		F3 = 0;
		F4 = 0;
		F5 = 0;
		F6 = 0;
		F7 = 1;
	  end
	  
	endcase

  end

endmodule	