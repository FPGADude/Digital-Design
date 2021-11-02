/******************************************************************
 Title       : light_fsm2.v	     		 
 Design      : 5 State Finite State Machine	(*Sensor Mode) 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : light_fsm2_TB.v
 Func. Check : PERFECT
 Information : This module contains the finite state machine that 
			   outputs control signals to the Traffic Lights 
			   Decoder module. It is enabled by the output of the
			   Counter2 module and the negedge of the clock. State
			   change occurs on the following posedge of the clock.
*******************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module light_fsm2(
	output A,
	output B,
	output C,
	output en_countdown_Ms,

	input RESET,
	input ENABLE,
	input CLOCK
);

reg [2:0] current_state = 0 ;
reg [2:0] next_state ;
reg en_countdown_Ms;

wire A, B, C ;

parameter S0=3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100;
	  
// Define current and next states
always @(posedge CLOCK or posedge RESET)
 begin
  if(RESET)
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

assign A = current_state[0] ;
assign B = current_state[1] ;
assign C = current_state[2] ;
 
// The code below describes the states transitions
always @(*) 
begin
	
	case (current_state)
		S0: begin
			en_countdown_Ms = 0;
			next_state = S1 ;
			end
		   
		S1: begin
			en_countdown_Ms = 0;
			next_state = S2 ;
			end	
			
		S2: begin
			en_countdown_Ms = 0;
			next_state = S3 ;
			end
			
		S3: begin
			en_countdown_Ms = 1;
			next_state = S4 ;
			end
	
		S4: begin
			en_countdown_Ms = 1;
			next_state = S0 ;
			end

		default:
			begin
			en_countdown_Ms = 0;
	        next_state = S0 ;
			end
	endcase
end 
endmodule