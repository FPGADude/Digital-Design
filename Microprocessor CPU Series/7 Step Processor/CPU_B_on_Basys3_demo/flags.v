// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.16.2022
// Date Updated: 4.14.2026
//
// Flags Register
//
// * No changes required for CPU_B
//
// * Updated with clk for synthesis
// ******************************************************************************

`timescale 1ns / 1ps
module flags(
    input clk,
    input reset,
    input s,
    input [3:0] caez_in,
    output reg [3:0] caez_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            caez_out <= 4'h0;
        else if (s)
            caez_out <= caez_in;
    end

endmodule