/********************************************************************
 Title       : counter3.v	     		 
 Design      : 16 State Finite State Machine	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : counter3_TB.v
 Func. Check : SWEET
 Information : This module contains the counter that resets the SR Latch.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module counter3(
	output latch_reset,
	
	input ENABLE,
	input RESET,
	input CLOCK
);

reg latch_reset = 0;

reg [3:0] current_state = 4'b0000;
reg [3:0] next_state;

wire ENABLE, RESET, CLOCK;

parameter S0=4'b0000, S1=4'b0001, S2=4'b0010, S3=4'b0011,   
		  S4=4'b0100, S5=4'b0101, S6=4'b0110, S7=4'b0111,   
		  S8=4'b1000, S9=4'b1001, S10=4'b1010, S11=4'b1011, 
		  S12=4'b1100, S13=4'b1101, S14=4'b1110, S15=4'b1111;

always @(posedge CLOCK)
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

always @(*)
begin
	case(current_state)
		S0: begin
			latch_reset = 1'b0 ;
			next_state = S1 ;
			end
		   
		S1: begin
			latch_reset = 1'b0 ;
			next_state = S2 ;			
			end	
			
		S2: begin
			latch_reset = 1'b0 ;
			next_state = S3 ;
			end
			
		S3: begin
			latch_reset = 1'b0 ;
			next_state = S4 ;
			end
	
		S4: begin
			latch_reset = 1'b0 ;
			next_state = S5 ;
			end
		   
		S5: begin
			latch_reset = 1'b0 ;
			next_state = S6 ;
			end	
			
		S6: begin
			latch_reset = 1'b0 ;
			next_state = S7 ;
			end
			
		S7: begin
			latch_reset = 1'b0 ;
			next_state = S8 ;
			end
	
		S8: begin
			latch_reset = 1'b0 ;
			next_state = S9 ;
			end
		   
		S9: begin
			latch_reset = 1'b0 ;
			next_state = S10 ;
			end	
		
		S10: begin
			latch_reset = 1'b0 ;
			next_state = S11 ;
			end
		   
		S11: begin
			latch_reset = 1'b0 ;
			next_state = S12 ;
			end	
			
		S12: begin
			latch_reset = 1'b0 ;
			next_state = S13 ;
			end
			
		S13: begin
			latch_reset = 1'b0 ;
			next_state = S14 ;
			end
	
		S14: begin
			latch_reset = 1'b0 ;
			next_state = S15 ;
			end

		S15: begin
			latch_reset = 1'b1 ;
			next_state = S0 ;
			end

		default:
			begin
			latch_reset = 1'b0 ;
	        next_state = S0 ;
			end
	endcase	
end
endmodule