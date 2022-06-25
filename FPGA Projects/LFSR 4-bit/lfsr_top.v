`timescale 1ns / 1ps

module lfsr_top(
    input clk_100MHz,
    input reset,
    output [3:0] LED
    );
    
    wire w_1Hz;
    
    lfsr4 r4(
        .clk(w_1Hz),
        .reset(reset),
        .lfsr(LED)
    );
    
    oneHz_gen uno(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .clk_1Hz(w_1Hz)
    );
     
endmodule
