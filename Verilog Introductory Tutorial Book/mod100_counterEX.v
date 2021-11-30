
/********************************************************************
 Title       : mod100_counter.v	     		 
 Design      : 1/100th Clock Generator 
 Author      : David J. Marion		     	
 Func. Check : None
 Include Mods: None
*********************************************************************/
module mod100_counter(
	//Inputs
	input CLOCK,
	input RESET,
	//Ouputs
	output reg sig100 = 1'b0	// Initialize to zero
);

reg [6:0] counter100 = 0;	// 7 bits needed --> (2^7 = 128) & (128 > 100)

// Counter control
always @ (posedge CLOCK) begin
	if (RESET) 
		counter100 <= 0;
	else 
		if (counter100 == 99)	// Counting from 0 to 99 equals 100 ticks
			counter100 <= 0;
		else
			counter100 <= counter100 + 1;
end

// Output signal control
always @ (posedge CLOCK) begin
	if (counter100 == 98)
		sig100 <= 1;
	else
		sig100 <= 0;
end

endmodule