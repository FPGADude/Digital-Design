`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_control(
    input clk_in,
    input [3:0] hours,
    output hr1_enable,
    output [1:0] select_out
    );
    
    reg [15:0] select_counter = 0;
    
    always @(posedge clk_in) begin
        select_counter <= select_counter + 1;
    end
    
    assign select_out = select_counter[15:14];
    assign hr1_enable = (hours >= 10) ? 1 : 0;
    
endmodule


