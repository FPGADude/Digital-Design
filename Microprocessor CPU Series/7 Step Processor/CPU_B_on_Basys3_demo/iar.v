// From the book: "But How Do It Know?" pg. 112
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Edited: 4.14.2026
//
// Instruction Address Register (IAR)
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
//
// * Updated with clk for synthesis
// *******************************************************************************************

`timescale 1ns / 1ps
module iar(
    input clk,
    input reset,
    input s,
    input e,
    input [7:0] a_in,
    output [7:0] a_out
);

    reg [7:0] addr_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            addr_reg <= 8'h00;
        else if (s)
            addr_reg <= a_in;
    end

    assign a_out = e ? addr_reg : 8'h00;

endmodule