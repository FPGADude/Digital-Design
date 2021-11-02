/********************************************************************
 Title       : counter2.v	     		 
 Design      : 15 State Finite State Machine (*Sensor Mode)	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : counter2_TB.v
 Func. Check : WORKS GREAT
 Information : This module contains the finite state machine that 
			   outputs the control signal to enable light_fsm2.v which
			   also controls the cycle of traffic lights. This counter
			   goes from 0-15 (16 second traffic light cycle). This 
			   module is enabled by the walk or car input in the next
			   higher module sensor_mode.v.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter2(
	output control_signal,
	output counter3_RST,
	output W,
	output X,
	output Y, 
	output Z,
	
	input  CLOCK,
	input  RESET,
	input  ENABLE
    );
	
reg [3:0] current_state = 4'b0000 ;
reg [3:0] next_state ;

wire W, X, Y, Z;

assign W = current_state[0];
assign X = current_state[1];
assign Y = current_state[2];
assign Z = current_state[3];

reg control_signal ;
reg counter3_RST ;

parameter S0=4'b0000, S1=4'b0001, S2=4'b0010, S3=4'b0011,   
		  S4=4'b0100, S5=4'b0101, S6=4'b0110, S7=4'b0111,   
		  S8=4'b1000, S9=4'b1001, S10=4'b1010, S11=4'b1011, 
		  S12=4'b1100, S13=4'b1101, S14=4'b1110, S15=4'b1111;
	  
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
			control_signal = 1'b0 ;
			counter3_RST = 1'b1 ;
			next_state = S1 ;
			end
		   
		S1: begin
			control_signal = 1'b1 ;
			counter3_RST = 1'b0 ;
			next_state = S2 ;			
			end	
			
		S2: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S3 ;
			end
			
		S3: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S4 ;
			end
	
		S4: begin
			control_signal = 1'b1 ;
			counter3_RST = 1'b0 ;
			next_state = S5 ;
			end
		   
		S5: begin
			control_signal = 1'b1 ;
			counter3_RST = 1'b0 ;
			next_state = S6 ;
			end	
			
		S6: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S7 ;
			end
			
		S7: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S8 ;
			end
	
		S8: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S9 ;
			end
		   
		S9: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S10 ;
			end	
		
		S10: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S11 ;
			end
		   
		S11: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S12 ;
			end	
			
		S12: begin
			control_signal = 1'b1 ;
			counter3_RST = 1'b0 ;
			next_state = S13 ;
			end
			
		S13: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S14 ;
			end
	
		S14: begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b0 ;
			next_state = S15 ;
			end

		S15: begin
			control_signal = 1'b1 ;
			counter3_RST = 1'b0 ;
			next_state = S0 ;
			end

		default:
			begin
			control_signal = 1'b0 ;
			counter3_RST = 1'b1 ;
	        next_state = S0 ;
			end
	endcase
end 
endmodule