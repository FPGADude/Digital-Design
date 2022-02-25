`timescale 1ns / 1ps

// Verilog module for Binary Clock - TOP module for BASYS 3 FPGA board
// Authored by David J Marion

module top_clock(
    input clk_100MHz,           // 100MHz from BASYS 3
    input btn_min,              // btnR on BASYS 3
    input btn_hr,               // btnL on BASYS 3
    output blink,               // 1 LED for the seconds
    output [5:0] minute,        // 6 LEDs for the minutes
    output [3:0] hour           // 4 LEDs for the hours
    );
    
    // Internal signals
    wire clk_1Hz_int;
    wire btn_min_debounced, btn_hr_debounced;
    wire tick_min_int, tick_hr_int;
    wire tick_min_orred, tick_hr_orred;
    
    // Instantiated modules
    oneHz_generator uno(.clk_in(clk_100MHz), .clk_out(clk_1Hz_int));
    seconds s(.tick_in(clk_1Hz_int), .tick_minutes(tick_min_int));
    minutes m(.tick_in(tick_min_orred), .tick_hours(tick_hr_int), .minutes(minute));
    hours h(.tick_in(tick_hr_orred), .hours(hour));
    btn_debouncer dbm(.clk_in(clk_100MHz), .btn_in(btn_min), .btn_out(btn_min_debounced));
    btn_debouncer dbh(.clk_in(clk_100MHz), .btn_in(btn_hr), .btn_out(btn_hr_debounced));
    
    // Internal assignments
    assign blink = clk_1Hz_int;
    assign tick_min_orred = tick_min_int | btn_min_debounced;
    assign tick_hr_orred = tick_hr_int | btn_hr_debounced;
    
endmodule

