`timescale 1ns / 1ps

// 7 Segment Display Clock using new Binary Clock
// Authored by David J. Marion aka FPGA Dude
// Created 4/11/2022

module top(
    input clk_100MHz,           // 100MHz from Basys 3
    input reset,                // btnC
    input tick_hr,              // btnL
    input tick_min,             // btnR
    output blink,               // LED 12
    output [0:6] seg,           // Cathodes
    output [3:0] an             // Anodes
    );
    
    // Internal Connections
    wire [3:0] min_1s, min_10s, hr_1s, hr_10s;
    
    binary_clock bc(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .tick_hr(tick_hr),
        .tick_min(tick_min),
        .tick_1Hz(blink),
        .sec_10s(),         // not connected for this clock
        .sec_1s(),          // not connected for this clock
        .min_10s(min_10s),
        .min_1s(min_1s),
        .hr_10s(hr_10s),
        .hr_1s(hr_1s)
        );
    
    seg_control seg7(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .min_1s(min_1s),
        .min_10s(min_10s),
        .hr_1s(hr_1s),
        .hr_10s(hr_10s),
        .seg(seg),
        .an(an)
        );
    
endmodule
