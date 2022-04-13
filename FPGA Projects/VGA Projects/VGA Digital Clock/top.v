`timescale 1ns / 1ps
////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/11/2022
//
// Description: Top module for the VGA Clock
////////////////////////////////////////////////////////////


module top(
    input clk_100MHz,       // 100MHz on Basys 3
    input reset,            // btnC
    input tick_hr,          // btnL
    input tick_min,         // btnR
    output hsync,           // to VGA Connector
    output vsync,           // to VGA Connector
    output [11:0] rgb       // to DAC, to VGA Connector
    );
    
    // Internal Connection Signals
    wire [9:0] w_x, w_y;
    wire video_on, p_tick;
    wire [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    
    // Instantiate Modules
    vga_controller vga(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(p_tick),
        .x(w_x),
        .y(w_y)
        );
 
    new_binary_clock bin(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .tick_hr(tick_hr),
        .tick_min(tick_min),
        .tick_1Hz(),        // not used
        .sec_1s(sec_1s),
        .sec_10s(sec_10s),
        .min_1s(min_1s),
        .min_10s(min_10s),
        .hr_1s(hr_1s),
        .hr_10s(hr_10s)
        );

    pixel_clk_gen pclk(
        .clk(clk_100MHz),
        .video_on(video_on),
        //.tick_1Hz(),
        .x(w_x),
        .y(w_y),
        .sec_1s(sec_1s),
        .sec_10s(sec_10s),
        .min_1s(min_1s),
        .min_10s(min_10s),
        .hr_1s(hr_1s),
        .hr_10s(hr_10s),
        .time_rgb(rgb_next)
        );
 
    // rgb buffer
    always @(posedge clk_100MHz)
        if(p_tick)
            rgb_reg <= rgb_next;
            
    // output
    assign rgb = rgb_reg; 
    
endmodule
