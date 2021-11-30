/********************************************************************
 Title       : mux_4x1_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 MUT	     : mux_4x1.v
 Incl. Mods. : None
*********************************************************************/
module mux_4x1_TB;

reg [3:0] D;	// 4-bit data input
reg [1:0] AB;	// 2-bit selector input
wire Y;			// 1-bit data output

//Instantiate the Module Under Test(MUT)
mux_4x1 m41(.D(D), .AB(AB), .Y(Y));

//Test sequence
initial begin
	D = 4'b0000;
	AB = 2'b00;			// Y = 0
	
	#10 D = 4'b1010;	// Y = 0
	
	#10 AB = 2'b01;		// Y = 1
	#10 AB = 2'b10;		// Y = 0
	#10 AB = 2'b11;		// Y = 1
	
	#10 D = 4'b0101;	// Y = 0
	
	#10 AB = 2'b00;		// Y = 1
	#10 AB = 2'b01;		// Y = 0
	#10 AB = 2'b10;		// Y = 1
	#10 AB = 2'b11;		// Y = 0
	
	#10 D = 4'b0110;	// Y = 0
	
	#10 AB = 2'b00;		// Y = 0
	#10 AB = 2'b01;		// Y = 1
	#10 AB = 2'b10;		// Y = 1
	#10 AB = 2'b11;		// Y = 0
	
	#10 D = 4'b1001;	// Y = 1
	
	#10 AB = 2'b00;		// Y = 1
	#10 AB = 2'b01;		// Y = 0
	#10 AB = 2'b10;		// Y = 0
	#10 AB = 2'b11;		// Y = 1
	
	#1000 $finish;
end

//Set up file for GTKWave
initial begin
	$dumpfile("mux_4x1_TB.vcd");
	$dumpvars(0, mux_4x1_TB);
end

endmodule

