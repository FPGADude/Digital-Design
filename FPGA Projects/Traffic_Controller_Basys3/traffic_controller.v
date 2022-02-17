`timescale 1ns / 1ps

module traffic_controller(
    input reset,            // button
    input clk_100MHz,       
    output [2:0] main_st,   // LEDs
    output [2:0] cross_st   // LEDs
    );
    
    wire w_1Hz, w_reset;
    
    state_machine sm(.reset(w_reset), .clk_1Hz(w_1Hz), 
                     .main_st(main_st), .cross_st(cross_st));
    oneHz_gen uno(.clk_100MHz(clk_100MHz), .reset(w_reset), .clk_1Hz(w_1Hz));
    sw_debounce db(.clk(clk_100MHz), .btn_in(reset), .btn_out(w_reset) );
    
endmodule
