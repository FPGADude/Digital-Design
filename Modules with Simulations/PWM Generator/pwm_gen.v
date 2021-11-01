`timescale 1ns / 1ps

// Verilog module to generate a pulse width modulated signal
// Authored by David J Marion

module pwm_gen(
    input clk,
    output pwm30,
    output pwm50,
    output pwm70,
    output pwm90
    );
    
reg [6:0] counter = 0;		// to hold the value of 99

always @(posedge clk) begin
    if (counter < 100) 
	counter <= counter + 1;
    else 
	counter <= 0;
end

  
assign pwm30 = (counter < 30) ? 1 : 0; 	// Create a 30% duty cycle  
    
assign pwm50 = (counter < 50) ? 1 : 0; 	// Create a 50% duty cycle
   
assign pwm70 = (counter < 70) ? 1 : 0; 	// Create a 70% duty cycle 

assign pwm90 = (counter < 90) ? 1 : 0; 	// Create a 90% duty cycle
    
endmodule
