// From the book: "But How Do It Know?" pg. 67
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 6.3.2023
// Date Updated: 4.14.2026
//
// General Purpose Register
//
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
//
// * Updated with clk for synthesis
// *******************************************************************************************

`timescale 1ns / 1ps
module gpr(
    input clk,
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