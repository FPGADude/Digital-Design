`timescale 1ns / 1ps

// Test bench for pwm generator
// Authored by David J Marion

module sim_pwm_gen;

reg clk = 0;
wire pwm30, pwm50, pwm70, pwm90;

pwm_gen1 DUT(
    .clk(clk), 
    .pwm30(pwm30), 
    .pwm50(pwm50), 
    .pwm70(pwm70), 
    .pwm90(pwm90));

always #10 clk = ~clk;

endmodule
