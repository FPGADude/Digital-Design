/******************************************************************
 Title       : wdws_decoder.v	     		 
 Design      : Walk/Don't Walk Light Decoder (*Sensor Mode)
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II     
 Incl. Mods  : N/A
 Stimulus    : wdws_decoder_TB.v
 Func. Check : None
 Information : This module contains the decoder that outputs 
			   signals to control the lighting of traffic lights.
			   It is controlled by the outputs E, F, G, H from
			   counter5.v. This module is asynchronous.
******************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module wdws_decoder(
	output 	out0,
	output 	out1,
	output 	out2,
	output 	out3,
	output 	out4,
	output 	out5,
	output 	out6,
	output 	out7,
	output 	out8,
	output 	out9,
  
	input [3:0]	select
	);

reg out0, out1, out2, out3, out4, out5, out6, out7, out8, out9;

parameter
  sel0 = 4'b0000, sel1 = 4'b0001, sel2 = 4'b0010, sel3 = 4'b0011, sel4 = 4'b0100,
  sel5 = 4'b0101, sel6 = 4'b0110, sel7 = 4'b0111, sel8 = 4'b1000, sel9 = 4'b1001;
    
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
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel1: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b1; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel2:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b1; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel3: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b1; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel4:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b1; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel5: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b1; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel6:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b1; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel7: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b1; 
	  out8 = 1'b0; 
	  out9 = 1'b0;
      end
	sel8:
      begin	
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b1; 
	  out9 = 1'b0;
      end
	sel9: 
	  begin
	  out0 = 1'b0; 
	  out1 = 1'b0; 
	  out2 = 1'b0; 
	  out3 = 1'b0; 
	  out4 = 1'b0; 
	  out5 = 1'b0; 
	  out6 = 1'b0; 
	  out7 = 1'b0; 
	  out8 = 1'b0; 
	  out9 = 1'b1;
      end
  endcase
end  
endmodule