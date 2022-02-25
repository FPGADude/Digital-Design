`timescale 1ns / 1ps

module top_bin_clock(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnC Basys 3
    input inc_mins,         // btnR Basys 3
    input inc_hrs,          // btnL Basys 3
    output [3:0] hours,     // Internal
    output sig_1Hz,         // Internal
    output [5:0] minutes    // Internal
    );
    
    wire w_1Hz;                                 // 1Hz signal
    wire inc_hrs_db, reset_db, inc_mins_db;     // debounced button signals
    wire w_inc_mins, w_inc_hrs;                 // mod to mod
    wire inc_mins_or, inc_hrs_or;               // from OR gates
    
    btn_debouncer bL(.clk_100MHz(clk_100MHz), .btn_in(inc_hrs), .btn_out(inc_hrs_db));
    btn_debouncer bC(.clk_100MHz(clk_100MHz), .btn_in(reset), .btn_out(reset_db));
    btn_debouncer bR(.clk_100MHz(clk_100MHz), .btn_in(inc_mins), .btn_out(inc_mins_db));
    oneHz_generator uno(.clk_100MHz(clk_100MHz), .clk_1Hz(w_1Hz));
    seconds sec(.clk_1Hz(w_1Hz), .reset(reset_db), .inc_minutes(w_inc_mins));
    minutes min(.inc_minutes(inc_mins_or), .reset(reset_db), .inc_hours(w_inc_hrs), .minutes(minutes));
    hours hr(.inc_hours(inc_hrs_or), .reset(reset_db), .hours(hours));
    
    assign inc_hrs_or = w_inc_hrs | inc_hrs_db;
    assign inc_mins_or = w_inc_mins | inc_mins_db;
    assign sig_1Hz = w_1Hz;
    
endmodule
