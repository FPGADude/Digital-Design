`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/13/2022
//
// Description: Top module for VGA clock and calendar
//
//////////////////////////////////////////////////////////////////////////////////
module top(
    input clk_100MHz,           // 100MHz from Basys 3
    input reset,                // sw[15], sys reset
    input inc_hr,               // btnL, set hour
    input inc_min,              // btnR, set minute
    input inc_month,            // btnU, set month
    input inc_day,              // btnC, set day
    input inc_year,             // btnD, set year
    input inc_cent,             // sw[3], set century
    input set_am_pm,            // sw[0], set am/pm
    output blink,               // LED[1], 1Hz signal
    output hsync,               // to VGA Connector
    output vsync,               // to VGA Connector
    output [11:0] rgb           // to DAC, to VGA Connector
    );
    
    wire [9:0] w_x, w_y;
    wire video_on, p_tick, am_pm, w_1Hz;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    wire [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s;
    wire [3:0] m_10s, m_1s, d_10s, d_1s, c_10s, c_1s, y_10s, y_1s;
    wire [5:0] seconds, minutes;
    wire [3:0] hours;
    
    vga_controller vgc(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(p_tick),
        .x(w_x),
        .y(w_y)
        );

    pixel_gen pg(
        .clk(clk_100MHz),
        .video_on(video_on),
        .x(w_x),
        .y(w_y),
        .sec_10s(sec_10s),
        .sec_1s(sec_1s),
        .min_10s(min_10s),
        .min_1s(min_1s),
        .hr_10s(hr_10s),
        .hr_1s(hr_1s),
        .am_pm(am_pm),
        .m_10s(m_10s),
        .m_1s(m_1s),
        .d_10s(d_10s),
        .d_1s(d_1s),
        .y_10s(y_10s),
        .y_1s(y_1s),
        .c_10s(c_10s),
        .c_1s(c_1s),
        .rgb(rgb_next)
        );

    new_binary_clock bc(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .tick_hr(inc_hr),
        .tick_min(inc_min),
        .set_am_pm(set_am_pm),
        .tick_1Hz(w_1Hz),
        .am_pm(am_pm),
        .seconds(seconds),
        .minutes(minutes),
        .hours(hours),
        .sec_10s(sec_10s),
        .sec_1s(sec_1s),
        .min_10s(min_10s),
        .min_1s(min_1s),
        .hr_10s(hr_10s),
        .hr_1s(hr_1s)
        );
    
    calendar cal(
        .clk_100MHz(clk_100MHz),
        .tick_1Hz(w_1Hz),
        .reset(reset),
        .seconds(seconds),
        .minutes(minutes),
        .hours(hours),
        .am_pm(am_pm),
        .inc_month(inc_month),
        .inc_day(inc_day),
        .inc_year(inc_year),
        .inc_century(inc_cent),
        .m_10s(m_10s),
        .m_1s(m_1s),
        .d_10s(d_10s),
        .d_1s(d_1s),
        .y_10s(y_10s),
        .y_1s(y_1s),
        .c_10s(c_10s),
        .c_1s(c_1s)
        );

    // RGB buffer
    always @(posedge clk_100MHz)
        if(p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
    assign blink = w_1Hz;
    
endmodule
