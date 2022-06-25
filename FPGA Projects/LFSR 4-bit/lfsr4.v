`timescale 1ns / 1ps

// 4-bit Linear Feedback Shift Register LFSR
// XNOR version - reset to 0000
// *For XOR version - begin lfsr reg at 4'b1111 - reset to 1111

module lfsr4(
    input clk,
    input reset,
    output reg [3:0] lfsr = 4'b0
    );
    
    always @(posedge clk or posedge reset)
        if(reset)
            lfsr <= 4'b0;
        else begin
            lfsr[3:1] <= lfsr[2:0];
            lfsr[0] <= lfsr[3] ~^ lfsr[0];
        end
       
endmodule
