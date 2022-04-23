`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on April 18, 2022
//////////////////////////////////////////////////////////////////////////////////

module top(
    input clk_100MHz,           // 100MHz from Nexys A7
    input reset,                // btnC
    input start,                // btnU
    input stop,                 // btnD
    output [0:6] seg,           // 7 segments
    output dp,                  // decimal point
    output [7:0] an             // 8 anodes
    );
    
    wire [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s;
    
    stop_watch sw(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .start(start),
        .stop(stop),
        .hr_10s(hr_10s), 
        .hr_1s(hr_1s), 
        .min_10s(min_10s), 
        .min_1s(min_1s), 
        .sec_10s(sec_10s), 
        .sec_1s(sec_1s), 
        .sec100_10s(sec100_10s), 
        .sec100_1s(sec100_1s)
        );
    
    seg_display_driver sdd(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .hr_10s(hr_10s), 
        .hr_1s(hr_1s), 
        .min_10s(min_10s), 
        .min_1s(min_1s), 
        .sec_10s(sec_10s), 
        .sec_1s(sec_1s), 
        .sec100_10s(sec100_10s), 
        .sec100_1s(sec100_1s),
        .seg(seg),
        .dp(dp),       
        .digit(an)      
        );
    
endmodule
