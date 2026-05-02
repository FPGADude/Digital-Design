// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Updated: 4.14.2026
//
// Temporary Register
//
// * No changes required for CPU_B
//
// * Updated with clk for synthesis
// **************************************************************************************

`timescale 1ns / 1ps
module tmp(
    input clk,
    input reset,
    input s,
    input [7:0] t_in,
    output reg [7:0] t_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            t_out <= 8'h00;
        else if (s)
            t_out <= t_in;
    end

endmodule