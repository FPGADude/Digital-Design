/********************************************************************
 Title       : srl.v	     		 
 Design      : SET/RESET LATCH	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 Incl. Mods  : N/A
 Stimulus    : srl_TB.v
 Func. Check : LOOKING GOOD
 Information : This module contains the SR Latch with Q-out to 
			   enable counter2 in sensor mode and counter3 in 
			   the top module. The two counters work together 
			   when a sensor is activated.
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module srl(
	output Q_out,
	
	input SET,		
	input RESET
);

reg Q_out = 0 ;

wire SET, RESET;

always @(posedge SET or posedge RESET)
begin
	if(SET)
	begin
		Q_out <= 1;
	end
	
	else if(RESET)
	begin
		Q_out <= 0;
	end
end
endmodule