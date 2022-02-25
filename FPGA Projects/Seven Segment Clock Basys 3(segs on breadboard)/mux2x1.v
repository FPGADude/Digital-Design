`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module mux2x1(
    input [6:0] in0,
    input [6:0] in1,
    input select,
    output [6:0] mux_out
    );
    
    assign mux_out = (select) ? in1 : in0;
    
endmodule

