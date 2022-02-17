`timescale 1ns / 1ps

module top(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnR 
    input btn_25,           // btnU
    input btn_10,           // btnC
    input btn_5,            // btnD
    output [0:6] seg,       // 7-segment cathodes
    output [3:0] an,        // 7-segment anodes
    output [15:0] LED       // 16 LEDs
    );
    
    // Internal wires
    wire btnR, btnU, btnC, btnD;
    wire w_2Hz, w_10Hz;
    wire [4:0] w_change;
    wire [2:0] w_the_state;
    wire [1:0] ch_high;     // change tens digit
    wire [3:0] ch_low;      // change ones digit
    
    // Instantiate inner modules
    btn_debounce bdR(.clk(clk_100MHz), .btn_in(reset), .btn_out(btnR));
    btn_debounce bdU(.clk(clk_100MHz), .btn_in(btn_25), .btn_out(btnU));
    btn_debounce bdC(.clk(clk_100MHz), .btn_in(btn_10), .btn_out(btnC));
    btn_debounce bdD(.clk(clk_100MHz), .btn_in(btn_5), .btn_out(btnD));
    state_machine sm(.clk(w_10Hz), .reset(btnR), .btn_25(btnU), .btn_10(btnC), .btn_5(btnD),
                     .the_state(w_the_state), .change(w_change));    
    led_driver ld(.clk(w_2Hz), .LED(LED));
    twoHz_gen dos(.clk_100MHz(clk_100MHz), .reset(btnR), .clk_2Hz(w_2Hz));
    tenHz_generator ten(.clk_100MHz(clk_100MHz), .reset(btnR), .clk_10Hz(w_10Hz));
    conv2bcd bcd_ch(.i_value(w_change), .o_low(ch_low), .o_high(ch_high));
    seg7_control sev(.clk(clk_100MHz), .reset(btnR), .change_high(ch_high), .change_low(ch_low), 
                     .the_state(w_the_state), .seg(seg), .an(an));
    
endmodule
