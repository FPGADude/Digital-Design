`timescale 1ns / 1ps

module d_ff(
    input clock,
    input reset,
    input d,
    output reg q
    );
    
    always @(posedge clock or negedge reset) begin
        if(~reset)
            q <= 0;
        else
            q <= d;
    end
    
endmodule
