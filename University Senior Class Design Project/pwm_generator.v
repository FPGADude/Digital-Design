`timescale 1ns / 1ps

// LiDAR data receiver PWM LiDAR motor control signal generator
// Authored by David J Marion

module pwm_generator(
    input clk_in,       // Clocked input signal from tick24
    input reset,        // Asynchronous system reset
    output pwm_out      // PWM generated output signal to LiDAR
    );
    
    reg [6:0] counter;  // 7-bit register
    
    always @(posedge clk_in or posedge reset) begin
        if(reset)
            counter <= 0;
        else
            if(counter < 100)
                counter <= counter + 1;
            else
                counter <= 0;
    end
    
    assign pwm_out = (counter < 30) ? 1 : 0;    // 30% duty cycle
    
endmodule
