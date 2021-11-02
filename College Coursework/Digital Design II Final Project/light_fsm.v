/******************************************************************
 Title       : light_fsm.v	     		 
 Design      : 10 State Finite State Machine (*Timer Mode)	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : light_fsm_TB.v
 Func. Check : GOOD
 Information : This module contains the finite state machine that 
			   outputs control signals to the Traffic Lights 
			   Decoder module. It is enabled by the output of the
			   Counter1 module and the negedge of the clock. State
			   change occurs on the following posedge of the clock.
*******************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module light_fsm(

	output A,
	output B,
	output C,
	output D,

	input  RESET, 
	input  ENABLE, 
	input  CLOCK 
	);

reg [3:0] current_state = 0 ;
reg [3:0] next_state ;

wire A, B, C, D ;


parameter S0=4'b0000, S1=4'b0001, S2=4'b0010, S3=4'b0011, S4=4'b0100,
		  S5=4'b0101, S6=4'b0110, S7=4'b0111, S8=4'b1000, S9=4'b1001;
	  
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
assign D = current_state[3] ;
 
// The code below describes the states transitions
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