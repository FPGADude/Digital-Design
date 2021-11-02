/********************************************************************
 Title       : traffic_controller_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : traffic_controller.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module traffic_controller_TB;

reg RESET;
reg CLOCK;
reg CLK_24hr;
reg WALK;
reg CAR;
reg EMERGENCY;

wire rA_Maj, rMR_Maj, yA_Maj, yLR_Maj, gA_Maj, gLR_Maj, 
	 rLR_min, yA_min, yLR_min, gA_min, gLR_min,
	 h_Maj, i_Maj,
	 W_Maj, DW_Maj, W_min, DW_min, a_min, b_min, c_min, d_min, e_min, f_min,
	 g_min, h_min, i_min, a_Maj, b_Maj, c_Maj, d_Maj, e_Maj, f_Maj, g_Maj;

//Instantiate module under test
traffic_controller TC0(
	.CLOCK(CLOCK),
	.RESET(RESET),	
	.CLK_24hr(CLK_24hr),
	.WALK(WALK),
	.CAR(CAR),
	.EMERGENCY(EMERGENCY),
	
	.rA_Maj(rA_Maj),
	.rMR_Maj(rMR_Maj),
	.yA_Maj(yA_Maj),
	.yLR_Maj(yLR_Maj),
	.gA_Maj(gA_Maj),
	.gLR_Maj(gLR_Maj),
	
	.rLR_min(rLR_min),
	.yA_min(yA_min),
	.yLR_min(yLR_min),
	.gA_min(gA_min),
	.gLR_min(gLR_min),
	
	.W_Maj(W_Maj),
	.DW_Maj(DW_Maj),
	
	.W_min(W_min),
	.DW_min(DW_min),
	
	.a_Maj(a_Maj),
	.b_Maj(b_Maj),
	.c_Maj(c_Maj),
	.d_Maj(d_Maj),
	.e_Maj(e_Maj),
	.f_Maj(f_Maj),
	.g_Maj(g_Maj),
	.h_Maj(h_Maj),
	.i_Maj(i_Maj),
	
	.a_min(a_min),
	.b_min(b_min),
	.c_min(c_min),
	.d_min(d_min),
	.e_min(e_min),
	.f_min(f_min),
	.g_min(g_min),
	.h_min(h_min),
	.i_min(i_min)	
);

//Create the clock
always
  #5 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("traffic_controller_TB.vcd") ;
  $dumpvars(0, traffic_controller_TB) ;
end

//Test Sequence
initial
begin
		EMERGENCY   = 0 ;	//Emergency mode disabled at 0
		WALK     	= 0 ;	//not enabled in timer mode
		CAR  		= 0 ;	//not enabled in timer mode
		CLK_24hr 	= 1 ;	//CLK_24hr: 1 = timer mode, 0 = sensor mode
		CLOCK    	= 0 ;
		RESET    	= 1 ;
  #6 	RESET    	= 0 ;

  #606	CLK_24hr	= 0 ;	//Switch to sensor mode
  #45	WALK 		= 1 ;	//Activate WALK sensor
  #1	WALK		= 0 ;
  #500  CAR			= 1 ;	//Activate CAR sensor
  #1	CAR			= 0 ;
  #1000 EMERGENCY   = 1 ;	//Enable emergency mode
  #200  EMERGENCY   = 0 ;
  #200  CLK_24hr    = 1 ;	//Switch to timer mode
  #500  EMERGENCY   = 1 ;	//Enable emergency mode
  #500  EMERGENCY	= 0 ;	//When disabling EMERGENCY here,
							//timer mode should begin again.
  #180	CLK_24hr	= 0 ;	//Switch to sensor mode in the middle of timer mode
  #100  CLK_24hr    = 1 ;	//Switch back to time mode

  //Set time out 
  #10000 $finish ; 
end
 
endmodule