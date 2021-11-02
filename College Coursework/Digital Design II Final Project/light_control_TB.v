/********************************************************************
 Title       : light_control_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : light_control.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module light_control_TB;
//For timer mode outputs T0-T9
reg T0;
reg T1;
reg T2;
reg T3;
reg T4;
reg T5;
reg T6;
reg T7;
reg T8;
reg T9;
//For sensor mode outputs S0-S4
reg S0;
reg S1;
reg S2;
reg S3;
reg S4;
//For flashing yellow
reg CLOCK;

wire rL_Maj, rMR_Maj, yA_Maj, yLR_Maj, gA_Maj, gLR_Maj,
     rLR_min, yA_min, yLR_min, gA_min, gLR_min,


//Instantiate module under test
light_control LC0(
	.T0(T0),
	.T1(T1),
	.T2(T2),
	.T3(T3),
	.T4(T4),
	.T5(T5),
	.T6(T6),
	.T7(T7),
	.T8(T8),
	.T9(T9),
	
	.S0(S0),
	.S1(S1),
	.S2(S2),
	.S3(S3),
	.S4(S4),
	
	.CLOCK(CLK_int),
	
	.rL_Maj(rL_Maj),
	.rMR_Maj(rMR_Maj),
	.yA_Maj(yA_Maj),
	.yLR_Maj(yLR_Maj),
	.gA_Maj(gA_Maj),
	.gLR_Maj(gLR_Maj),
	.rLR_min(rLR_min),
	.yA_min(yA_min),
	.yLR_min(yLR_min),
	.gA_min(gA_min),
	.gLR_min(gLR_min)	
);	 

//Create the clock
always
  #10 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("light_control_TB.vcd") ;
  $dumpvars(0, light_control_TB) ;
end

//Test Sequence
initial
begin
	T0;
	T1;
	T2;
	T3;
	T4;
	T5;
	T6;
	T7;
	T8;
	T9;

	S0;
	S1;
	S2;
	S3;
	S4;
//For flashing yellow
reg CLOCK;

  //Set time out 
  #5000 $finish ; 
end

endmodule