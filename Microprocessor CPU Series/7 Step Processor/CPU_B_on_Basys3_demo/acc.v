// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Date Updated: 4.14.2026
//
// Accumulator Register
//
// * No changes required for CPU_B
//
// * Changed output assignment from 8'bz to 8'b0
//
// * Updated with clk input for synthesis
// ***********************************************************************

`timescale 1ns / 1ps
module acc(
    input clk,		// updated for synthesis
    input reset,
    input s,
    input e,
    input [7:0] d_in,
    output [7:0] d_out
);

    reg [7:0] data_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            data_reg <= 8'h00;
        else if (s)
            data_reg <= d_in;
    end

    assign d_out = e ? data_reg : 8'h00;

endmodule