`timescale 1ns / 1ps

module top_7seg_clock(
    input clk_100MHz,
    input reset,
    input inc_hrs,
    input inc_mins,
    output blink,
    output [0:6] seg,
    output [3:0] an
    );
    
    wire [3:0] v_hours;
    wire [5:0] v_minutes, hours_pad;
    wire [2:0] hrs_tens, mins_tens;
    wire [3:0] hrs_ones, mins_ones;
    
    // Binary Clock
    top_bin_clock bin(.clk_100MHz(clk_100MHz), .reset(reset), .inc_hrs(inc_hrs), .inc_mins(inc_mins),
                      .sig_1Hz(blink), .hours(v_hours), .minutes(v_minutes));
    
    // New modules for segment display
    bin2bcd hrs(.bin_in(hours_pad), .tens(hrs_tens), .ones(hrs_ones));
    bin2bcd mins(.bin_in(v_minutes), .tens(mins_tens), .ones(mins_ones));
    seg7_control seg7(.clk_100MHz(clk_100MHz), .reset(reset), .hrs_tens(hrs_tens), .hrs_ones(hrs_ones), .mins_tens(mins_tens), 
                      .mins_ones(mins_ones), .seg(seg), .an(an));
    
    assign hours_pad = {2'b00, v_hours};     // Pad hours vector with zeros to size for bin2bcd
    
endmodule
