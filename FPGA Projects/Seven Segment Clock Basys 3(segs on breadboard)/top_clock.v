`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module top_clock(
    input clk_100MHz,           // from BASYS 3
    input btn_min,              // btnR
    input btn_hr,               // btnL
    output blink,               // LED seconds indicator
    output [6:0] min0_out,          // 7-seg digit0
    output [6:0] min1_out,          // 7-seg digit1
    output [6:0] hr0_out,           // 7-seg digit2
    output [6:0] hr1_out            // 7-seg digit3
    );
    
    // Internal wires
    wire clk_1Hz_int;
    wire btn_min_debounced, btn_hr_debounced;
    wire tick_minutes_int, tick_hours_int;
    wire tick_minutes_ored, tick_hours_ored;
    wire [5:0] minutes_int;
    wire [3:0] hours_int;
    wire [1:0] mux_demux_select;
    wire [3:0] min0_int;
    wire [3:0] min1_int;
    wire [3:0] hr0_int;
    wire [3:0] hr1_int;
    wire [6:0] min0_decoded;
    wire [6:0] min1_decoded;
    wire [6:0] hr0_decoded;
    wire [6:0] hr1_decoded;
    wire [6:0] mux_to_demux;
    wire [6:0] mux2x1_zero_int;
    wire [6:0] mux2x1_hr1_in;
    wire hr1_select;
    wire mux2x1_in0 = 7'b000_0000;
    
    // Instantiated modules
    oneHz_generator uno(.clk_in(clk_100MHz), .clk_out(clk_1Hz_int));
    
    btn_debouncer bdm(.clk_in(clk_100MHz), .btn_in(btn_min), .btn_out(btn_min_debounced));
    
    btn_debouncer bdh(.clk_in(clk_100MHz), .btn_in(btn_hr), .btn_out(btn_hr_debounced));
    
    seconds s(.tick_in(clk_1Hz_int), .tick_minutes(tick_minutes_int));
    
    minutes m(.tick_in(tick_minutes_ored), .tick_hours(tick_hours_int), .minutes(minutes_int));
    
    hours h(.tick_in(tick_hours_ored), .hours(hours_int));
    
    seg_mux mux(.in0(min0_decoded), .in1(min1_decoded), .in2(hr0_decoded), .in3(hr1_decoded), .select(mux_demux_select), .mux_out(mux_to_demux));
    
    seg_demux demux(.mux_in(mux_to_demux), .select(mux_demux_select), .out0(min0_out), .out1(min1_out), .out2(hr0_out), .out3(mux2x1_hr1_in));
    
    seg_min0 m0(.minutes(minutes_int), .min0(min0_int));
    
    seg_min1 m1(.minutes(minutes_int), .min1(min1_int));
    
    seg_hr0 h0(.hours(hours_int), .hr0(hr0_int));
    
    seg_hr1 h1(.hours(hours_int), .hr1(hr1_int));
    
    seg_control sc(.clk_in(clk_100MHz), .hours(hours_int), .hr1_enable(hr1_select), .select_out(mux_demux_select));
    
    seg_decoder sdm0(.count_in(min0_int), .decode_out(min0_decoded));
    
    seg_decoder sdm1(.count_in(min1_int), .decode_out(min1_decoded));
    
    seg_decoder sdh0(.count_in(hr0_int), .decode_out(hr0_decoded));
    
    seg_decoder sdh1(.count_in(hr1_int), .decode_out(hr1_decoded));
    
    mux2x1 mux2(.in0(mux2x1_in0), .in1(mux2x1_hr1_in), .select(hr1_select), .mux_out(hr1_out));
    
    // Signal assignments
    assign blink = clk_1Hz_int;
    assign tick_minutes_ored = tick_minutes_int | btn_min_debounced;
    assign tick_hours_ored = tick_hours_int | btn_hr_debounced;
    
endmodule
