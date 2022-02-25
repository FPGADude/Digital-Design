`timescale 1ns / 1ps

module d_ff(
    input clk,          // system clock
    input d,            // data bit coming in
    input en,           // enable storing of data bit
    output reg q        // stored data bit
    );
    
    always @(posedge clk) begin
        if(en)
            q <= d;
    end
endmodule
