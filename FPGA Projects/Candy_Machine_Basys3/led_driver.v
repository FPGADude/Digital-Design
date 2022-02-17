`timescale 1ns / 1ps

module led_driver(
    input clk,      // 2Hz
    output [15:0] LED
    );
    
    reg [15:0] scheme1 = 16'b0101_0101_0101_0101;
    reg [15:0] scheme2 = 16'b1010_1010_1010_1010;
    
    assign LED = (clk == 1) ? scheme1 : scheme2;
    
endmodule
