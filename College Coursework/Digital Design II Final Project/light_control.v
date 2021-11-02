/********************************************************************
 Title       : light_control.v	     		 
 Design      : Signal Router
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : light_control_TB.v
 Func. Check : None
 Information : This module routes sensor mode and timer mode outputs
			   to power the traffic lights.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module light_control(
	//To lights on Major St.
	output rA_Maj,
	output rMR_Maj,
	output yA_Maj,
	output yLR_Maj,
	output gA_Maj,
	output gLR_Maj,
	//To lights on minor st.
	output rLR_min,
	output yA_min,
	output yLR_min,
	output gA_min,
	output gLR_min,
	//To walk/don't walk for Major St.
	output W_Maj,
	output DW_Maj,
	//To countdown segments Major St.
	output a_Maj,
	output b_Maj,
	output c_Maj,
	output d_Maj,
	output e_Maj,
	output f_Maj,
	output g_Maj,
	output h_Maj,
	output i_Maj,
	//To walk/don't walk for minor st.
	output W_min,
	output DW_min,
	//To countdown segments minor st.
	output a_min,
	output b_min,
	output c_min,
	output d_min,
	output e_min,
	output f_min,
	output g_min,
	output h_min,
	output i_min,
	//From timer mode light_decoder
	input T0,
	input T1,
	input T2,
	input T3,
	input T4,
	input T5,
	input T6,
	input T7,
	input T8,
	input T9,
	//From sensor mode light_decoder2
	input S0,
	input S1, 
	input S2, 
	input S3,
	input S4,
	//From decoder for Major St. don't walk countdown
	input CD0_M,
	input CD1_M,
	input CD2_M,
	input CD3_M,
	input CD4_M,
	input CD5_M,
	input CD6_M,
	input CD7_M,
	input CD8_M,
	input CD9_M,
	//From decoder for minor st. don't walk countdown
	input CD0_m,
	input CD1_m,
	input CD2_m,
	input CD3_m,
	input CD4_m,
	input CD5_m,
	input CD6_m,
	input CD7_m,
	input CD8_m,
	input CD9_m,
	
	input CD0s,
	input CD1s,
	input CD2s,
	input CD3s,
	input CD4s,
	input CD5s,
	input CD6s,
	input CD7s,
	input CD8s,
	input CD9s,
	
	input CLOCK,			//For the blinking lights
	input en_countdown_M,
	input en_countdown_m,
	input EN_S0,
	input EN_T0,
	input EM				//To switch to emergency mode
);

wire T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T8_CLK, en_countdown_M,
	 S0, S1, S2, S3, S4, CLOCK, S0_CLK, S3_CLK, EM, en_countdown_m,
	 CD0_M, CD1_M, CD2_M, CD3_M, CD4_M, CD5_M, CD6_M, CD7_M, CD8_M, CD9_M,
	 CD0_m, CD1_m, CD2_m, CD3_m, CD4_m, CD5_m, CD6_m, CD7_m, CD8_m, CD9_m,
	 CD0s, CD1s, CD2s, CD3s, CD4s, CD5s, CD6s, CD7s, CD8s, CD9s,
	 rA_Maj, rMR_Maj, yA_Maj, yLR_Maj, gA_Maj, gLR_Maj, not_en_countdown_M,
	 rLR_min, yA_min, yLR_min, gA_min, gLR_min, EN_T0, not_en_countdown_m,
	 w1, w2, w3, w4, w5, w6, w7, S0_int, T0_int, EN_S0, not_EM, EM_CLK,
	 W_Maj, W_min, DW_Maj, DW_min, a_min, b_min, c_min, d_min, e_min, f_min,
	 g_min, h_min, i_min, a_Maj, b_Maj, c_Maj, d_Maj, e_Maj, f_Maj, g_Maj,
	 h_Maj, i_Maj; 

assign not_EM = ~EM;

assign T0_int = EN_T0 & T0 & not_EM;
assign S0_int = EN_S0 & S0 & not_EM;
assign EM_CLK = EM & CLOCK;	 
assign S0_CLK = CLOCK & S0_int;
assign S3_CLK = CLOCK & S3;
assign T8_CLK = CLOCK & T8;
assign w1 = S2 | S3 | S4 | EM_CLK;
assign w2 = T0_int | T3 | T4 | T5 | T6 | T7 | T8 | T9;
assign w3 = T0_int | T1 | T2 | T5 | T6 | T7 | T8 | T9;
assign w4 = S2 | S3 | S4 | EM_CLK;
assign w5 = S0_int | S1 | S2 | EM_CLK;
assign w6 = T0_int | T1 | T2 | T3 | T4 | T5 | T6 | T7;
assign w7 = T7 | T8_CLK | T9;
assign not_en_countdown_M = ~en_countdown_M;
assign not_en_countdown_m = ~en_countdown_m;

assign rA_Maj  = w1 | w2;
assign rMR_Maj = w3 | w4;
assign yA_Maj  = T2 | S1 | S0_CLK;
assign yLR_Maj = T4 | S1;
assign gA_Maj  = T1;
assign gLR_Maj = T3 | S0_int;
assign rLR_min = w5 | w6;
assign yA_min  = w7 | S3_CLK | S4;
assign yLR_min = T9 | S4;
assign gA_min  = T6;
assign gLR_min = T8 | S3;

assign DW_Maj = EM_CLK | T0_int | T1 | T2 | T3 | T4 | T5 | T6 | T7 | S0_int | S1 | S2;
assign DW_min = EM_CLK | T0_int | T1 | T2 | S1 | S2 | S3 | S4;
assign W_Maj  = T8 & not_en_countdown_M;
assign W_min  = (T3 & not_en_countdown_m)| S0_int;

assign a_min = CD0_m | CD1_m | CD2_m | CD3_m | CD4_m | CD5_m | CD7_m | CD8_m;
assign b_min = CD0_m | CD1_m | CD2_m | CD3_m | CD6_m | CD7_m | CD8_m | CD9_m;
assign c_min = CD0_m | CD1_m | CD2_m | CD3_m | CD4_m | CD5_m | CD6_m | CD7_m | CD9_m;
assign d_min = CD0_m | CD1_m | CD2_m | CD4_m | CD5_m | CD7_m | CD8_m;
assign e_min = CD0_m | CD2_m | CD4_m | CD8_m;
assign f_min = CD0_m | CD1_m | CD2_m | CD4_m | CD5_m | CD6_m; 
assign g_min = CD1_m | CD2_m | CD4_m | CD5_m | CD6_m | CD7_m | CD8_m;
assign h_min = CD0_m;
assign i_min = CD0_m;

assign a_Maj = CD0_M | CD1_M | CD2_M | CD3_M | CD4_M | CD5_M | CD7_M | CD8_M |
			   CD0s | CD1s | CD2s | CD3s | CD4s | CD5s | CD7s | CD8s;
assign b_Maj = CD0_M | CD1_M | CD2_M | CD3_M | CD6_M | CD7_M | CD8_M | CD9_M |
			   CD0s | CD1s | CD2s | CD3s | CD6s | CD7s | CD8s | CD9s;
assign c_Maj = CD0_M | CD1_M | CD2_M | CD3_M | CD4_M | CD5_M | CD6_M | CD7_M | CD9_M |
			   CD0s | CD1s | CD2s | CD3s | CD4s | CD5s | CD6s | CD7s | CD9s;
assign d_Maj = CD0_M | CD1_M | CD2_M | CD4_M | CD5_M | CD7_M | CD8_M |
			   CD0s | CD1s | CD2s | CD4s | CD5s | CD7s | CD8s;
assign e_Maj = CD0_M | CD2_M | CD4_M | CD8_M | CD0s | CD2s | CD4s | CD8s;
assign f_Maj = CD0_M | CD1_M | CD2_M | CD4_M | CD5_M | CD6_M |
			   CD0s | CD1s | CD2s | CD4s | CD5s | CD6s;
assign g_Maj = CD1_M | CD2_M | CD4_M | CD5_M | CD6_M | CD7_M | CD8_M |
			   CD1s | CD2s | CD4s | CD5s | CD6s | CD7s | CD8s;
assign h_Maj = CD0_M | CD0s;
assign i_Maj = CD0_M | CD0s;
	 
endmodule