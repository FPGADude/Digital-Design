/********************************************************************
 Title       : timer_mode_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : timer_mode.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module timer_mode_TB;

reg CLOCK;
reg RESET;
reg enable_timer_mode;

wire D0, D1, D2, D3, D4, D5, D6, D7, D8, D9,
	 CD0_M, CD1_M, CD2_M, CD3_M, CD4_M, CD5_M
	 CD6_M, CD7_M, CD8_M, CD9_M, CD0_m, CD1_m,
	 CD2_m, CD3_m, CD4_m, CD5_m, CD6_m, CD7_m,
	 CD8_m, CD9_m, en_countdown_M, en_countdown_m;

//Instantiate the module under test
timer_mode TM(
	.CLOCK(CLOCK),
	.RESET(RESET),
	.enable_timer_mode(enable_timer_mode),
	
	.D0(D0),
	.D1(D1),
	.D2(D2),
	.D3(D3),
	.D4(D4),
	.D5(D5),
	.D6(D6),
	.D7(D7),
	.D8(D8),
	.D9(D9),
	
	.CD0_M(CD0_M),
	.CD1_M(CD1_M),
	.CD2_M(CD2_M),
	.CD3_M(CD3_M),
	.CD4_M(CD4_M),
	.CD5_M(CD5_M),
	.CD6_M(CD6_M),
	.CD7_M(CD7_M),
	.CD8_M(CD8_M),
	.CD9_M(CD9_M),
	
	.CD0_m(CD0_m),
	.CD1_m(CD1_m),
	.CD2_m(CD2_m),
	.CD3_m(CD3_m),
	.CD4_m(CD4_m),
	.CD5_m(CD5_m),
	.CD6_m(CD6_m),
	.CD7_m(CD7_m),
	.CD8_m(CD8_m),
	.CD9_m(CD9_m),
	.en_countdown_M(en_countdown_M),
	.en_countdown_m(en_countdown_m)
);

//Create the clock
always
  #10 CLOCK = !CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("timer_mode_TB.vcd") ;
  $dumpvars(0, timer_mode_TB) ;
end

//Test Sequence
initial
begin
		enable_timer_mode = 0 ; 		
		CLOCK  = 0 ;
		RESET  = 1 ;
  #30 	RESET  = 0 ;
  #500  enable_timer_mode = 1 ;

  //Set time out 
  #10000 $finish ; 
end
 
endmodule