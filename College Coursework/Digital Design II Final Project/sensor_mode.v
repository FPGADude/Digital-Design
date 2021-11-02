/********************************************************************
 Title       : sensor_mode.v	     		 
 Design      : Sensor Mode Traffic Light Controller	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : light_fsm2.v, light_decoder2.v, counter2.v, counter3.v,
			   srl.v, wdws_decoder.v
 Stimulus    : sensor_mode_TB.v
 Func. Check : ITS A SLAM DUNK!
 Information : This module encapsulates six lower level modules into
			   one module that controls the traffic lights during the 
			   hours of 2100 to 0600.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module sensor_mode(
	output S0,
	output S1,
	output S2,
	output S3,
	output S4,
	output CD0s,
	output CD1s,
	output CD2s,
	output CD3s,
	output CD4s,
	output CD5s,
	output CD6s,
	output CD7s,
	output CD8s,
	output CD9s,
	
	input CLOCK,
	input RESET,
	input enable_sensor_mode,
	input SET_srl
);

//1-bit signals	
wire S0, S1, S2, S3, S4, counter3_RST,
	 EN_int, sig_int, CLOCK, not_CLK_int, 
	 RESET, CLK_int, A_int, B_int, temp1,
	 C_int, SET_srl, enable_sensor_mode,
	 temp3, latch_reset, Q_out, E_int,
	 F_int, G_int, H_int, CD0s, CD1s, CD2s,
	 CD3s, CD4s, CD5s, CD6s, CD7s, CD8s, CD9s, 
	 en_countdown_Ms;

//Bus signals
wire [2:0] select_int1;
wire [3:0] select_int2;

//Assignment statements
assign CLK_int = enable_sensor_mode & CLOCK;
assign not_CLK_int = ~CLK_int;
assign temp1 = RESET | latch_reset;
assign temp3 = RESET | counter3_RST;
assign select_int1[0] = A_int;
assign select_int1[1] = B_int;
assign select_int1[2] = C_int;
assign select_int2[0] = E_int;
assign select_int2[1] = F_int;
assign select_int2[2] = G_int;
assign select_int2[3] = H_int;
assign EN_int  = sig_int & not_CLK_int;	//Enables Light FSM2 on negedge CLOCK,
										//its state change occurs next posedge
									
light_fsm2 LFSM2(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.ENABLE(EN_int),
	.A(A_int),
	.B(B_int),
	.C(C_int),
	.en_countdown_Ms(en_countdown_Ms)
);

light_decoder2 LDEC2(
	.out0(S0),
	.out1(S1),
	.out2(S2),
	.out3(S3),
	.out4(S4),
	.select(select_int1)
);

wdws_decoder WSD1(
	.out0(CD0s),
	.out1(CD1s),
	.out2(CD2s),
	.out3(CD3s),
	.out4(CD4s),
	.out5(CD5s),
	.out6(CD6s),
	.out7(CD7s),
	.out8(CD8s),
	.out9(CD9s),
	.select(select_int2)
);

counter2 CTR2(
	.CLOCK(CLK_int),
	.RESET(RESET),
	.ENABLE(Q_out),
	.control_signal(sig_int),
	.counter3_RST(counter3_RST)
);

srl SRL1(
	.SET(SET_srl),
	.RESET(temp1),
	.Q_out(Q_out)
);

counter3 CTR3(
	.CLOCK(CLK_int),
	.RESET(temp3),
	.ENABLE(Q_out),
	.latch_reset(latch_reset)
);

counter5 CTR5(
	.E(E_int),
	.F(F_int),
	.G(G_int),
	.H(H_int),
	
	.ENABLE(en_countdown_Ms),
	.RESET(RESET),
	.CLOCK(CLK_int)
);

endmodule