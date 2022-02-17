`timescale 1ns / 1ps

module sw_debounce(
    input clk,      
    input btn_in,   // using a button, not switch, works the same
    output btn_out
    );
    
    reg t0, t1, t2;
    
    always @(posedge clk) begin
        t0 <= btn_in;
        t1 <= t0;
        t2 <= t1;
    end
    
    assign btn_out = t2;
    
endmodule
