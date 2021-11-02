/********************************************************************
 Title       : sensor_mode_TB.v	     		 
 Design      : ***Stimulus***	 
 Author      : David J. Marion		     	
 Assignment  : Final Project (Traffic Controller)	     	 
 Course      : EE352 Digital Design II
 MUT	     : sensor_mode.v
*********************************************************************/

`timescale 1ns/1ps	//Defines "reference time" and "precision time"

module sensor_mode_TB;

reg CLOCK;
reg RESET;
reg enable_sensor_mode;
reg SET_srl;

wire D0, D1, D2, D3, D4, counter3_RST;

//Instantiate the module under test
sensor_mode SM(
	.CLOCK(CLOCK),								//Inputs
	.RESET(RESET),
	.SET_srl(SET_srl),
	.enable_sensor_mode(enable_sensor_mode),
	
	.D0(D0),									//Outputs
	.D1(D1),
	.D2(D2),
	.D3(D3),
	.D4(D4),
	.counter3_RST(counter3_RST)
);

//Create the clock
always
  #10 CLOCK = ~CLOCK ;
  
//Set up output file for gtkwave
initial
begin
  $dumpfile("sensor_mode_TB.vcd") ;
  $dumpvars(0, sensor_mode_TB) ;
end

//Test Sequence
initial
begin
		enable_sensor_mode = 0 ;
		SET_srl = 0 ;
		CLOCK  = 0 ;
		RESET  = 1 ;
  #25 	RESET  = 0 ;
  #100  enable_sensor_mode = 1 ;
  #100  SET_srl = 1 ;
  #20  SET_srl = 0 ;

  //Set time out 
  #5000 $finish ; 
end
 
endmodule