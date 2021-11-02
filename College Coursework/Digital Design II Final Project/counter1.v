/********************************************************************
 Title       : counter1.v	     		 
 Design      : 60 State Finite State Machine (*Timer Mode)	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : counter1_TB.v
 Func. Check : WORKS LIKE A CHARM
 Information : This module contains the finite state machine that 
			   outputs the control signal to enable light_fsm.v which
			   also controls the cycle of traffic lights. This counter
			   goes from 0-59 (60 second traffic light cycle).
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter1(
	output control_signal,
	output en_countdown_M,
	output en_countdown_m,
	
	input  CLOCK,
	input  RESET
    );
	
reg [5:0] current_state = 6'd0;
reg [5:0] next_state ;

reg control_signal;
reg en_countdown_M;
reg en_countdown_m;

parameter S0=6'd0,   S1=6'd1,   S2=6'd2,   S3=6'd3,   S4=6'd4,
		  S5=6'd5,   S6=6'd6,   S7=6'd7,   S8=6'd8,   S9=6'd9,
		  S10=6'd10, S11=6'd11, S12=6'd12, S13=6'd13, S14=6'd14,
		  S15=6'd15, S16=6'd16, S17=6'd17, S18=6'd18, S19=6'd19,
		  S20=6'd20, S21=6'd21, S22=6'd22, S23=6'd23, S24=6'd24,
		  S25=6'd25, S26=6'd26, S27=6'd27, S28=6'd28, S29=6'd29,
		  S30=6'd30, S31=6'd31, S32=6'd32, S33=6'd33, S34=6'd34,
		  S35=6'd35, S36=6'd36, S37=6'd37, S38=6'd38, S39=6'd39,
		  S40=6'd40, S41=6'd41, S42=6'd42, S43=6'd43, S44=6'd44,
		  S45=6'd45, S46=6'd46, S47=6'd47, S48=6'd48, S49=6'd49,
		  S50=6'd50, S51=6'd51, S52=6'd52, S53=6'd53, S54=6'd54,
		  S55=6'd55, S56=6'd56, S57=6'd57, S58=6'd58, S59=6'd59;

//Initialize the output to zero
initial
  begin
	control_signal = 1'b0;
	en_countdown_M = 1'b0;
	en_countdown_m = 1'b0;
  end

	  
// Define current and next states
always @(posedge CLOCK)
  begin
    if (RESET)
		begin
		current_state <= S0 ;
		end
    else
		begin
		current_state <= next_state ;
		end	
  end
  
// Behavioral code for the states
always @(*) 
begin
			
	case (current_state)
		S0: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S1 ;
			end
		   
		S1: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S2 ;			
			end	
			
		S2: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S3 ;
			end
			
		S3: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S4 ;
			end
	
		S4: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S5 ;
			end
		   
		S5: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S6 ;
			end	
			
		S6: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S7 ;
			end
			
		S7: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S8 ;
			end
	
		S8: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S9 ;
			end
		   
		S9: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S10 ;
			end	
		
		S10: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S11 ;
			end
		   
		S11: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S12 ;
			end	
			
		S12: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S13 ;
			end
			
		S13: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S14 ;
			end
	
		S14: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S15 ;
			end
		   
		S15: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S16 ;
			end	
			
		S16: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S17 ;
			end
			
		S17: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S18 ;
			end
	
		S18: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S19 ;
			end
		   
		S19: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S20 ;
			end	

		S20: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S21 ;
			end
		   
		S21: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S22 ;
			end	
			
		S22: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S23 ;
			end
			
		S23: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S24 ;
			end
	
		S24: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S25 ;
			end
		   
		S25: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S26 ;
			end	
			
		S26: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S27 ;
			end
			
		S27: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S28 ;
			end
	
		S28: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S29 ;
			end
		   
		S29: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S30 ;
			end	

		S30: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S31 ;
			end
		   
		S31: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S32 ;
			end	
			
		S32: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S33 ;
			end
			
		S33: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S34 ;
			end
	
		S34: begin
			en_countdown_m = 1'b1 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S35 ;
			end
		   
		S35: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S36 ;
			end	
			
		S36: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S37 ;
			end
			
		S37: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S38 ;
			end
	
		S38: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S39 ;
			end
		   
		S39: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S40 ;
			end	

		S40: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S41 ;
			end
		   
		S41: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S42 ;
			end	
			
		S42: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S43 ;
			end
			
		S43: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S44 ;
			end
	
		S44: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b1 ;
			next_state = S45 ;
			end
		   
		S45: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S46 ;
			end	
			
		S46: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S47 ;
			end
			
		S47: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S48 ;
			end
	
		S48: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S49 ;
			end
		   
		S49: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
			next_state = S50 ;
			end	

		S50: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S51 ;
			end
		   
		S51: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S52 ;
			end	
			
		S52: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S53 ;
			end
			
		S53: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S54 ;
			end
	
		S54: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S55 ;
			end
		   
		S55: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S56 ;
			end	
			
		S56: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b1 ;
			next_state = S57 ;
			end
			
		S57: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S58 ;
			end
	
		S58: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b0 ;
			next_state = S59 ;
			end
		   
		S59: begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b1 ;
			control_signal = 1'b1 ;
			next_state = S0 ;
			end	

		default:
			begin
			en_countdown_m = 1'b0 ;
			en_countdown_M = 1'b0 ;
			control_signal = 1'b0 ;
	        next_state = S0 ;
			end
	endcase
end 
endmodule