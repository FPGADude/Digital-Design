`timescale 1ns / 1ps

module top_voting_machine(
    input clk_100MHz,           // from Basys 3
    input [15:0] sw,            // 16 switches to input code to open/close voting
    input btn_1,                // btnL for candidate 1
    input btn_2,                // btnC for candidate 2
    input btn_3,                // btnR for candidate 3
    input btn_ov_cv,            // btnD for opening/closing voting
    input reset,                // btnU for system reset
    output [0:6] seg,           // 7 segment cathodes
    output [3:0] an,            // 7 segment anodes
    output [15:0] LED           // 16 LEDs show when voting is open
    );
    
    // Internal wires for connecting modules
    wire w_1Hz, w_2Hz;                                      // output from Hz generators
    wire w_btn1, w_btn2, w_btn3, w_btn_ov_cv, w_reset;      // output from debouncers to sm
    wire w_en_leds;                                         // output from sm to led driver
    wire [3:0] w_vote_count;                                // output from sm to 7 seg control
    wire [1:0] w_the_state;                                 // output from sm to 7 seg control
    wire [1:0] w_the_winner;
    wire w_tens;
    wire [3:0] w_ones;
    
    // Instantiate inner modules
    // Hz Generators
    oneHz_gen uno(.clk_100MHz(clk_100MHz), .clk_1Hz(w_1Hz));
    twoHz_gen dos(.clk_100MHz(clk_100MHz), .clk_2Hz(w_2Hz));
    // Button Debouncers
    btn_debounce b1(.clk(clk_100MHz), .btn_in(btn_1), .btn_out(w_btn1));
    btn_debounce b2(.clk(clk_100MHz), .btn_in(btn_2), .btn_out(w_btn2));
    btn_debounce b3(.clk(clk_100MHz), .btn_in(btn_3), .btn_out(w_btn3));
    btn_debounce bovcv(.clk(clk_100MHz), .btn_in(btn_ov_cv), .btn_out(w_btn_ov_cv));
    btn_debounce rst(.clk(clk_100MHz), .btn_in(reset), .btn_out(w_reset));
    // Binary to BCD Converter
    bin2bcd b2b(.bin_in(w_vote_count), .tens(w_tens), .ones(w_ones));
    // LED Driver
    led_driver led_d(.clk_2Hz(w_2Hz), .enable(w_en_leds), .LED(LED));
    // State Machine
    state_machine sm(.clk_1Hz(w_1Hz), .btn1(w_btn1), .btn2(w_btn2), .btn3(w_btn3), .btn_ov_cv(w_btn_ov_cv), 
                     .reset(w_reset), .sw(sw), .vote_count(w_vote_count), .the_state(w_the_state), 
                     .the_winner(w_the_winner), .enable_leds(w_en_leds));
    // 7 Segment Display Controller
    seg7_control seg7(.clk_100MHz(clk_100MHz), .the_state(w_the_state), .vc_tens(w_tens), .vc_ones(w_ones), 
                      .the_winner(w_the_winner), .seg(seg), .an(an), .reset(w_reset));
    
endmodule
