/******************************************************************
 Title       : decoder_TB.v	     		 
 Design      : ***Stimulus*** 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II     
 MUT		 : light_decoder.v
******************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module decoder_TB;

reg [3:0] select;

wire out0, out1, out2, out3, out4, out5, out6, out7, out8, out9 ;

parameter
  sel0 = 4'b0000, sel1 = 4'b0001, sel2 = 4'b0010, sel3 = 4'b0011, sel4 = 4'b0100,
  sel5 = 4'b0101, sel6 = 4'b0110, sel7 = 4'b0111, sel8 = 4'b1000, sel9 = 4'b1001;

//Instantiate the module under test (light_decoder)
light_decoder LDec(
	.select(select),
	.out0(out0),
	.out1(out1),
	.out2(out2),
	.out3(out3),
	.out4(out4),
	.out5(out5),
	.out6(out6),
	.out7(out7),
	.out8(out8),
	.out9(out9)
	);

//Set up .vcd output file for gtkwave
initial
begin
  $dumpfile("decoder_TB.vcd") ;
  $dumpvars(0, decoder_TB) ;
end

//Test sequence
initial
begin
		select = sel0 ;
	#20	select = sel1 ;
	#20	select = sel2 ;
	#20	select = sel3 ;
	#20	select = sel4 ;
	#20	select = sel5 ;
	#20	select = sel6 ;
	#20	select = sel7 ;
	#20	select = sel8 ;
	#20	select = sel9 ;
	#20 select = sel0 ;
	#20	select = sel9 ;
	#20	select = sel8 ;
	#20	select = sel7 ;
	#20	select = sel6 ;
	#20	select = sel5 ;
	#20	select = sel4 ;
	#20	select = sel3 ;
	#20	select = sel2 ;
	#20	select = sel1 ;
	#20 select = sel0 ;
	//Set time out 
	#500 $finish ; 
end
 
endmodule