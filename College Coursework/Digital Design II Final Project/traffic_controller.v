/********************************************************************
 Title       : traffic_controller.v	     		 
 Design      : Traffic Light Controller	w/ sensor and timer modes
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : timer_mode.v, sensor_mode.v, light_control.v, light_fsm.v,
			   light_fsm2.v, light_decoder.v, light_decoder2.v, srl.v,
			   counter1.v, counter2.v, counter3.v, counter4.v, counter5.v,
			   counter6.v, wdwt_decoder_Maj.v, wdwt_decoder_min.v,
			   wdws_decoder.v
 Stimulus    : traffic_controller_TB.v
 Func. Check : FULLY FUNCTIONAL
 Information : This module is the top module. Inputs are a synchronizing
			   clock, a reset button, a 24hr clock that changes output
			   at 0600 and 2100, a walk button, a car sensor, and an 
			   emergency mode button for the police that blinks all red
			   traffic lights. Outputs are the enable lines for each 
			   traffic light, the WALK and DON'T WALK indicators, as
			   well as outputs to the 9 LED Segments that make up the
			   DON'T WALK countdown timer lights.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module traffic_controller(
	//MAJOR ST SIGNALS
	output rA_Maj,		//RED ARROW
	output rMR_Maj,		//other (2) RED LIGHTS
	output yA_Maj,		//YELLOW ARROW
	output yLR_Maj,		//other (2) YELLOW LIGHTS
	output gA_Maj,		//GREEN ARROW
	output gLR_Maj,		//other (2) GREEN LIGHTS
	
	output W_Maj,		//WALK across Major
	output DW_Maj,		//DON'T WALK across Major
	//9 segments for the DON'T WALK across Major countdown 
	output a_Maj,		
	output b_Maj,
	output c_Maj,
	output d_Maj,
	output e_Maj,
	output f_Maj,
	output g_Maj,
	output h_Maj,
	output i_Maj,
	
	//MINOR ST SIGNALS
	output rLR_min,		//both RED LIGHTS
	output yA_min,		//YELLOW ARROW
	output yLR_min,		//other (2) YELLOW LIGHTS
	output gA_min,		//GREEN ARROW
	output gLR_min,		//other (2) GREEN LIGHTS
	
	output W_min,		//WALK across Minor 
	output DW_min,		//DON'T WALK across Minor
	//9 segments for the DON'T WALK across Minor countdown
	output a_min,
	output b_min,
	output c_min,
	output d_min,
	output e_min,
	output f_min,
	output g_min,
	output h_min,
	output i_min,
	
	input CLOCK,		//System clock, synchronizing
	input RESET,		//Enabled by operator 
	input CLK_24hr,		//Emits the signal for mode select 1 = timer, 0 = sensor
	input WALK,			//button
	input CAR,			//pressure sensor
	input EMERGENCY		//Emergency on/off switch enabled by police/operator
);

wire T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, RST_int,
	 S0, S1, S2, S3, S4, CLOCK, RESET, EMERGENCY,
	 CD0s, CD1s, CD2s, CD3s, CD4s, CD5s, CD6s, CD7s, CD8s, CD9s,
	 CD0_M, CD1_M, CD2_M, CD3_M, CD4_M, CD5_M, CD6_M, CD7_M, CD8_M, CD9_M,
	 CD0_m, CD1_m, CD2_m, CD3_m, CD4_m, CD5_m, CD6_m, CD7_m, CD8_m, CD9_m, 
	 rA_Maj, rMR_Maj, yA_Maj, yLR_Maj, gA_Maj, gLR_Maj, 
	 rLR_min, yA_min, yLR_min, gA_min, gLR_min, temp2, h_Maj, i_Maj,
	 W_Maj, DW_Maj, W_min, DW_min, a_min, b_min, c_min, d_min, e_min, f_min,
	 g_min, h_min, i_min, a_Maj, b_Maj, c_Maj, d_Maj, e_Maj, f_Maj, g_Maj,
	 not_CLK_24hr, CLK_24hr, RST_int2, en_countdown_M,
	 SET_srl, W_C, WALK, CAR, en_countdown_m;

assign temp2 = not_CLK_24hr | RST_int;
assign RST_int = EMERGENCY | RESET;
assign RST_int2 = RST_int | CLK_24hr;
assign W_C = WALK | CAR;
assign not_CLK_24hr = ~CLK_24hr;
assign SET_srl = W_C & CLOCK & not_CLK_24hr;
	 
//Instantiate included modules
timer_mode TM0(
	//Inputs
	.CLOCK(CLOCK),
	.RESET(temp2),
	.enable_timer_mode(CLK_24hr),
	//Outputs	
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

sensor_mode SM0(
	//Outputs
	.S0(S0),
	.S1(S1),
	.S2(S2),
	.S3(S3),
	.S4(S4),
	.CD0s(CD0s),
	.CD1s(CD1s),
	.CD2s(CD2s),
	.CD3s(CD3s),
	.CD4s(CD4s),
	.CD5s(CD5s),
	.CD6s(CD6s),
	.CD7s(CD7s),
	.CD8s(CD8s),
	.CD9s(CD9s),
	//Inputs
	.CLOCK(CLOCK),
	.RESET(RST_int2),
	.enable_sensor_mode(not_CLK_24hr),
	.SET_srl(SET_srl)
);

light_control LC0(
	//Outputs
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
	.i_min(i_min),

	//Inputs
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
	
	.CD0s(CD0s),
	.CD1s(CD1s),
	.CD2s(CD2s),
	.CD3s(CD3s),
	.CD4s(CD4s),
	.CD5s(CD5s),
	.CD6s(CD6s),
	.CD7s(CD7s),
	.CD8s(CD8s),
	.CD9s(CD9s),
	
	.en_countdown_M(en_countdown_M),
	.en_countdown_m(en_countdown_m),
	.CLOCK(CLOCK),
	.EM(EMERGENCY),
	.EN_S0(not_CLK_24hr),
	.EN_T0(CLK_24hr)
);

endmodule