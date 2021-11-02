/**********************************************************************
Title       : candy_machine.v	     		 
Design      : 15 cent Candy Machine State Machine
Author      : David J. Marion		     	
Assignment  : Lab2	     	 
Course      : EE352 Digital Design II     
Referenced 
	Modules	: N/A
**********************************************************************/

module candy_machine;

	output candy ;
	reg candy = 0;
	reg nickel = 0;
	reg dime = 0;
	reg clock = 0;
	reg reset = 0;

reg [2:0] current_state, next_state ;

parameter S0=3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100 ;

//Define current_state
always@( posedge clock )
begin
	if( reset )
		begin
			current_state <= S0 ;
		end
	else
		begin
			current_state <= next_state ;
		end
end

//Create the clock
always
	#10 clock = !clock ;

// Behavioral code for the states
always @(*)
begin
  next_state = current_state ;
		
  case( current_state )
	S0: begin
		  if( nickel == 1 ) next_state = S1 ;
		  else if( dime == 1 ) next_state = S2 ;
	    end
		   
	S1: begin
		  if( nickel == 1 ) next_state = S2 ;
		  else if( dime == 1 ) next_state = S3 ;	
	    end	
			
	S2: begin
		  if( nickel == 1 ) next_state = S3 ;
		  else if( dime == 1 ) next_state = S4 ;
	    end
			
	S3: begin
	        candy = 1 ;
			#5 candy = 0 ;
			next_state = S0 ;
	    end
		
	S4: begin
	        candy = 1 ; 
			#5 candy = 0 ;
			next_state = S1 ;		
	    end	
	
	default:
	    begin
	        next_state = S0 ;
	        candy = 0 ; 
	    end
  endcase
end

//Test sequence
initial
begin
						//Beginning at S0
	#25 nickel = 1 ;	//Enter S1
	#10 nickel = 0 ;
	#10 nickel = 1 ;	//Enter S2
	#10 nickel = 0 ;
	#10 nickel = 1 ;	//Enter S3, get candy and back to S0
	#10 nickel = 0 ;
	#50 dime = 1 ;		//Enter S2
	#10 dime = 0 ;
	#10 dime = 1 ;		//Enter S4, get candy and back to S1
	#10 dime = 0 ;
	#50 dime = 1 ;		//Enter S3, get candy and back to S0
	#10 dime = 0 ;
	#50 dime = 1 ;		//Enter S2
	#10 dime = 0 ;
	#30 reset = 1 ;		//Check reset function, enter S0, dime lost, sorry charlie
	#10 reset = 0 ;
	
	#300 $finish ;
end

// Set up output file for gtkwave
initial
begin
  $dumpfile("candy_machine.vcd") ;
  $dumpvars(0, candy_machine) ;
end

endmodule

