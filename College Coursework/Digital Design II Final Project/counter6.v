/********************************************************************
 Title       : counter6.v	     		 
 Design      : 10 State Finite State Machine (*Timer Mode)	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : counter6_TB.v
 Func. Check : None
 Information : This module contains the finite state machine that 
			   outputs the select signals to wdwt_decoder_min.v 
			   which controls the don't walk countdown for minor st.
			   This counter goes from 0-9 (10 second countdown). This 
			   module is enabled by an output from counter1.v.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter6(
	output E,
	output F,
	output G, 
	output H,
		
	input  CLOCK,
	input  RESET,
	input  ENABLE
    );
	
reg [3:0] current_state = 4'b0000 ;
reg [3:0] next_state ;

wire E, F, G, H;

assign E = current_state[0];
assign F = current_state[1];
assign G = current_state[2];
assign H = current_state[3];

parameter S0=4'b0000, S1=4'b0001, S2=4'b0010, S3=4'b0011, S4=4'b0100, 
		  S5=4'b0101, S6=4'b0110, S7=4'b0111, S8=4'b1000, S9=4'b1001;
	  
// Define current and next states
always @(posedge CLOCK)
begin
  if (RESET)
	begin
		current_state <= S0 ;
	end
  else if(ENABLE == 0)
	begin
		current_state <= current_state ;
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
				next_state = S1 ;
			end
		   
		S1: begin
				next_state = S2 ;			
			end	
			
		S2: begin
				next_state = S3 ;
			end
			
		S3: begin
				next_state = S4 ;
			end
	
		S4: begin
				next_state = S5 ;
			end
		   
		S5: begin
				next_state = S6 ;
			end	
			
		S6: begin
				next_state = S7 ;
			end
			
		S7: begin
				next_state = S8 ;
			end
	
		S8: begin
				next_state = S9 ;
			end
		   
		S9: begin
				next_state = S0 ;
			end	
		
		default:
			begin
				next_state = S0 ;
			end
	endcase
end 
endmodule