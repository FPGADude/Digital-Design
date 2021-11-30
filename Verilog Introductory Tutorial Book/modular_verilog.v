/********************************************************************
 Title       : modular_verilog.v	     		 
 Design      : Modular Verilog Design
 Author      : David J. Marion		     	
 Func. Check : None
 Include Mods: binary_counter3.v, decoder_3x8.v
*********************************************************************/
module modular_verilog(
	//Inputs
	input CLOCK,
	input ENABLE,
	//Outputs
	output [7:0] OUT	// 8-bit output from decoder
);

wire [2:0] connection;	// 3-bit wire connecting counter to decoder

//Instantiate including modules
binary_counter3 BC3(
	.CLOCK(CLOCK),
	.ENABLE(ENABLE),
	.ctr3(connection)
);

decoder_3x8 DEC(
	.x(connection[2]),
	.y(connection[1]),
	.z(connection[0]),
	.F0(OUT[0]),
	.F1(OUT[1]),
	.F2(OUT[2]),
	.F3(OUT[3]),
	.F4(OUT[4]),
	.F5(OUT[5]),
	.F6(OUT[6]),
	.F7(OUT[7])
);

endmodule

