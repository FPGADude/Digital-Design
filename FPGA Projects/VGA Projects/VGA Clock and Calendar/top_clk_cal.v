`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/14/2022
//
// Synopsis: Simulating the a binary clock with a calendar. The binary clock
// drives the calendar through the w_end_of_day signal.
//////////////////////////////////////////////////////////////////////////////////

module top_clk_cal(
    input clk_100MHz,
    input reset,
    input inc_hour, inc_minute, inc_month, inc_day, inc_year, inc_century, sw_am_pm,
    output am_pm, o_1Hz,
    output [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, 
    output [3:0] m_10s, m_1s, d_10s, d_1s, y_10s, y_1s, c_10s, c_1s
    );
    
    wire w_end_of_day, w_1hz;
    
    calendar cal(
        .clk_100MHz(clk_100MHz),
        .tick_1Hz(w_1Hz),
        .reset(reset),
        .end_of_day(w_end_of_day),
        .inc_month(inc_month),
        .inc_day(inc_day),
        .inc_year(inc_year),
        .inc_century(inc_century),
        .m_10s(m_10s),
        .m_1s(m_1s),
        .d_10s(d_10s),
        .d_1s(d_1s),
        .y_10s(y_10s),
        .y_1s(y_1s),
        .c_10s(c_10s),
        .c_1s(c_1s)
        );
    
    new_binary_clock bin_clk(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .am_pm(am_pm),
        .tick_1Hz(w_1Hz),
        .end_of_day(w_end_of_day),
        .set_am_pm(sw_am_pm),
        .tick_hr(inc_hour),
        .tick_min(inc_minute),
        .hr_10s(hr_10s),
        .hr_1s(hr_1s),
        .min_10s(min_10s),
        .min_1s(min_1s),
        .sec_10s(sec_10s),
        .sec_1s(sec_1s) 
        );       
    
    assign o_1Hz = w_1Hz;
    
endmodule
