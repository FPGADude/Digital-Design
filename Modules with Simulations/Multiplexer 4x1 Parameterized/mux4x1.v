`timescale 1ns / 1ps

// This Verilog module contains a parameterized 4x1 multiplexer
// Authored by David J Marion

module mux4x1
    #(parameter W = 4)  // choose the bit width
    (
        input [W-1:0] A,
        input [W-1:0] B,
        input [W-1:0] C,
        input [W-1:0] D,
        input [1:0] select,
        output reg [W-1:0] mux_out
    );
    
    always @(select) begin
        case(select)
            2'b00 : mux_out = A;
            2'b01 : mux_out = B;
            2'b10 : mux_out = C;
            2'b11 : mux_out = D;
            default : mux_out = 'b0;
        endcase
    end
    
endmodule
