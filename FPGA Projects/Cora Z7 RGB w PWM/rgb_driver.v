`timescale 1ns / 1ps

module rgb_driver(
    input clk,
    output led0_r, led0_g, led0_b,
    output led1_r, led1_g, led1_b
    );
    
    // Create the PWM to drive RGBs
    reg [6:0] counter_100 = 0;
    wire pwm_30, pwm_20, pwm_10;
    
    always @(posedge clk)
        if(counter_100 == 99)
            counter_100 <= 0;
        else
            counter_100 <= counter_100 + 1;
            
    assign pwm_10 = (counter_100 < 10) ? 1 : 0; // 10% duty cycle
    assign pwm_20 = (counter_100 < 20) ? 1 : 0; // 20% duty cycle
    assign pwm_30 = (counter_100 < 30) ? 1 : 0; // 30% duty cycle
    
    // aqua
    assign led0_r = 1'b0;
    assign led0_g = pwm_30;
    assign led0_b = pwm_20;
    
    // yellow
    assign led1_r = pwm_30;
    assign led1_g = pwm_20;
    assign led1_b = 1'b0;
    
    
endmodule
