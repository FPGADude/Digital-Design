/********************************************************************
 Title       : timer_mode.v	     		 
 Design      : Timer Mode Traffic Light Controller	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : light_fsm.v, light_decoder.v, counter1.v, counter4.v,
			   wdwt_decoder_Maj.v, counter6.v, wdwt_decoder_min.v
 Stimulus    : timer_mode_TB.v
 Func. Check : None
 Information : This module encapsulates seven lower level modules into
			   one module that controls the traffic lights during the 
			   hours of 0600 to 2100.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module timer_mode(
	input CLOCK,
	input RESET,
	input enable_timer_mode,
	
	output CD0_M,
	output CD1_M,
	output CD2_M,
	output CD3_M,
	output CD4_M,
	output CD5_M,
	output CD6_M,
	output CD7_M,
	output CD8_M,
	output CD9_M,
	
	output CD0_m,
	output CD1_m,
	output CD2_m,
	output CD3_m,
	output CD4_m,
	output CD5_m,
	output CD6_m,
	output CD7_m,
	output CD8_m,
	output CD9_m,	
		
	output T0,
	output T1,
	output T2,
	output T3,
	output T4,
	output T5,
	output T6,
	output T7,
	output T8,
	output T9,
	output en_countdown_M,
	output en_countdown_m
);

//1-bit signals	
wire T0, T1, T2, T3, T4, T5, T6, T7, T8, T9,
	 CD0_M, CD1_M, CD2_M, CD3_M, CD4_M, CD5_M, CD6_M, CD7_M, CD8_M, CD9_M,
	 CD0_m, CD1_m, CD2_m, CD3_m, CD4_m, CD5_m, CD6_m, CD7_m, CD8_m, CD9_m,
	 EN_int, sig_int, A_int, B_int, C_int, D_int, not_CLK_int, CLOCK, RESET, 
	 CLK_int, W_int, X_int, Y_int, Z_int, en_countdown_M, en_countdown_m,
	 E_int, F_int, G_int, H_int, enable_timer_mode;

//Bus signals
wire [3:0] select_int1;
wire [3:0] select_int2;
wire [3:0] select_int3;

//Assignment statements
assign CLK_int = enable_timer_mode & CLOCK;
assign not_CLK_int = ~CLK_int;
assign select_int1[0] = A_int;
assign select_int1[1] = B_int;
assign select_int1[2] = C_int;
assign select_int1[3] = D_int;
assign select_int2[0] = W_int;
assign select_int2[1] = X_int;
assign select_int2[2] = Y_int;
assign select_int2[3] = Z_int;
assign select_int3[0] = E_int;
assign select_int3[1] = F_int;
assign select_int3[2] = G_int;
assign select_int3[3] = H_int;
assign EN_int  = sig_int & not_CLK_int;	//Enables Light FSM on negedge CLOCK
										//State change occurs next posedge
									
//Instantiate included modules	
light_fsm LFSM(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.ENABLE(EN_int),
	.A(A_int),
	.B(B_int),
	.C(C_int),
	.D(D_int)	
);

light_decoder LDEC(
	.out0(T0),
	.out1(T1),
	.out2(T2),
	.out3(T3),
	.out4(T4),
	.out5(T5),
	.out6(T6),
	.out7(T7),
	.out8(T8),
	.out9(T9),
	.select(select_int1)
);

counter1 CTR1(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.control_signal(sig_int),
	.en_countdown_M(en_countdown_M),
	.en_countdown_m(en_countdown_m)
);	

counter4 CTR4(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.ENABLE(en_countdown_M),
	
	.W(W_int),
	.X(X_int),
	.Y(Y_int),
	.Z(Z_int)
);

counter6 CTR6(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.ENABLE(en_countdown_m),
	
	.E(E_int),
	.F(F_int),
	.G(G_int),
	.H(H_int)
);

wdwt_decoder_Maj TD_M(
	.out0(CD0_M),
	.out1(CD1_M),
	.out2(CD2_M),
	.out3(CD3_M),
	.out4(CD4_M),
	.out5(CD5_M),
	.out6(CD6_M),
	.out7(CD7_M),
	.out8(CD8_M),
	.out9(CD9_M),
  
	.select(select_int2)
);

wdwt_decoder_min TD_m(
	.out0(CD0_m),
	.out1(CD1_m),
	.out2(CD2_m),
	.out3(CD3_m),
	.out4(CD4_m),
	.out5(CD5_m),
	.out6(CD6_m),
	.out7(CD7_m),
	.out8(CD8_m),
	.out9(CD9_m),
  
	.select(select_int3)
);
endmodule