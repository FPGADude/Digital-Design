`timescale 1ns / 1ps

module seq_det_101(
    input clock,
    input reset,
    input data,
    output detected_101
    );
    
    wire a2b, b2c, c;
    
    d_ff dA(.clock(clock), .reset(reset), .d(data), .q(a2b));
    d_ff dB(.clock(clock), .reset(reset), .d(a2b), .q(b2c));
    d_ff dC(.clock(clock), .reset(reset), .d(b2c), .q(c));
    
    assign detected_101 = a2b & ~b2c & c;
    
endmodule
