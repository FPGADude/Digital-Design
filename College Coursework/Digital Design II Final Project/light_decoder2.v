/******************************************************************
 Title       : light_decoder2.v	     		 
 Design      : Light Control Decoder (*Sensor Mode) 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II     
 Incl. Mods  : N/A
 Stimulus    : decoder_TB2.v
 Func. Check : LOOKING GOOD
 Information : This module contains the decoder that outputs 
			   signals to control the lighting of traffic lights.
			   It is controlled by the outputs A, B, C from
			   light_fsm2.v. This module is asynchronous.
******************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module light_decoder2(
	output 	out0,
	output 	out1,
	output 	out2,
	output 	out3,
	output 	out4,
  
	input [2:0]	select
);

reg out0, out1, out2, out3, out4 ;

parameter
  sel0 = 4'b0000, sel1 = 4'b0001, sel2 = 4'b0010, sel3 = 4'b0011, sel4 = 4'b0100;
    
always @(*) 
begin
  case ( select )
    sel0:
      begin	
	  out0 = 1'b1; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
      end
	sel1: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b1; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
      end
	sel2:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b1; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
      end
	sel3: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b1; 
	  out4 = 1'b0; 
      end
	sel4:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b1; 
      end
  endcase
end  

endmodule