`timescale 1ns / 1ps

module top(
    input clk_100MHz,
    input reset,
    output [3:0] count
    );
    
    wire w_1Hz;
    
    johnson_counter jc(
        .clk(w_1Hz),
        .reset(reset),
        .count(count)
        );
        
    oneHz_gen uno(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .clk_1Hz(w_1Hz)
        );
    
    
endmodule
