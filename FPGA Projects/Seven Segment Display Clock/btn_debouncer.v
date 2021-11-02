`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module btn_debouncer(
    input clk_in,
    input btn_in,
    output btn_out
    );
    
    reg d1, d2, d3;
    
    always @(posedge clk_in) begin
        d1 <= btn_in;
        d2 <= d1;
        d3 <= d2;
    end
    
    assign btn_out = d1 & d2 & d3;
    
endmodule


