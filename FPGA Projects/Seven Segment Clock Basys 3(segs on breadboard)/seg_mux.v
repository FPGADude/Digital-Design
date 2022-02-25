`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_mux(
    input [6:0] in0,
    input [6:0] in1,
    input [6:0] in2,
    input [6:0] in3,
    input [1:0] select,
    output [6:0] mux_out
    );
    
    assign mux_out =    (select == 2'b00) ? in0 :
                        (select == 2'b01) ? in1 :
                        (select == 2'b10) ? in2 : in3;
endmodule


