`timescale 1ns / 1ps

module top(
    input clk_100MHz,
    input btnL,     // make coffee
    input btnR,     // fill water
    input btnC,     // reset
    output [0:6] seg,   // 7 segment display
    output [3:0] an,    // 7 segment display
    output [15:0] LED
    );
    
    wire clk_1Hz, btnL_int, btnR_int;
    wire [1:0] state_int, cup_count_int;
    
    state_machine sm(.clk_1Hz(clk_1Hz), .btn1(btnL_int), .btn2(btnR_int), .reset(btnC), 
                     .LED(LED), .state(state_int), .cup_count(cup_count_int));
    oneHz_gen oneHz(.clk_100MHz(clk_100MHz), .reset(btnC), .clk_1Hz(clk_1Hz));
    btn_debouncer b1(.clk_100MHz(clk_100MHz), .btn_in(btnL), .btn_out(btnL_int));
    btn_debouncer b2(.clk_100MHz(clk_100MHz), .btn_in(btnR), .btn_out(btnR_int));
    seg7_control s7(.clk_100MHz(clk_100MHz), .reset(btnC), .state(state_int),
                    .cup_count(cup_count_int), .seg(seg), .an(an));
    
    
endmodule
