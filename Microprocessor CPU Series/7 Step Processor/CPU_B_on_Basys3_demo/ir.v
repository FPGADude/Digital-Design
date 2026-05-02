// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Date Updated: 4.14.2026
//
// Instruction Register (IR)
//
// * No changes required for CPU_B
//
// * Updated with clk for synthesis
// **************************************************************************************

`timescale 1ns / 1ps
module ir(
    input clk,
    input reset,
    input s,
    input [7:0] i_in,
    output reg [7:0] i_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            i_out <= 8'h00;
        else if (s)
            i_out <= i_in;
    end

endmodule