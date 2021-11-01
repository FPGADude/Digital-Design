`timescale 1ns / 1ps

// LiDAR data receiver clock source
// LiDAR data transmits @ 230,400 baud
// Clock source -> 230,400 x 25 = 5.76 MHz
// Authored by David J Marion

module clock_source(
    input clk_in,
    output clk_out
    );
    
    // Instaniate clocking wizard clock 5.76 MHz
    clk_wiz_0 instance_name(
    .clk_100MHz(clk_in),    // Input clock of 100 MHz
    .clk_25x(clk_out)       // Output clock of 5.76 MHz   
    );
    
endmodule
