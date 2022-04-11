`timescale 1ns / 1ps

module my_debounce(
    input clk,
    input btn_in,
    output btn_out
    );
    
    reg a, b, c;
    
    always @(posedge clk) begin
        a <= btn_in;
        b <= a;
        c <= b;
    end
    
    assign btn_out = c;
    
endmodule
