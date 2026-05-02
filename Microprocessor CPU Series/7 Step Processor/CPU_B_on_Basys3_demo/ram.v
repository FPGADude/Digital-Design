// From the book: "But How Do It Know?" pg. 52
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Edited: 4.14.2026
//
// Main Memory 
//
// Main memory using RTL instead of gate level modeling.
//
// * Changes required for CPU_B:
// 		- remove inout port and change to have input and output ports
//
// * Updated with clk for synthesis
// *******************************************************************************************

`timescale 1ns / 1ps
module ram(
    input clk,
    input reset,
    input [7:0] a,
    input sa,
    input s,
    input e,
    input [7:0] d_in,
    output [7:0] d_out
);

    reg [7:0] addr_reg;
    reg [7:0] mem_reg [0:255];

    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem_reg[i] = 8'h00;

        // Fibonacci program, 18 bytes
        mem_reg[0]  = 8'b00100000;
        mem_reg[1]  = 8'b00000000;
        mem_reg[2]  = 8'b00100001;
        mem_reg[3]  = 8'b00000001;
        mem_reg[4]  = 8'b00100010;
        mem_reg[5]  = 8'b11111111;
        mem_reg[6]  = 8'b00100011;
        mem_reg[7]  = 8'b00000110;
        mem_reg[8]  = 8'b10000100; // ADD R1,R0
        mem_reg[9]  = 8'b01111000; // OUT R0
        mem_reg[10] = 8'b10000001; // ADD R0,R1
        mem_reg[11] = 8'b01111001; // OUT R1
        mem_reg[12] = 8'b10001011; // ADD R2,R3
        mem_reg[13] = 8'b01010001; // JZ ...
        mem_reg[14] = 8'b00000000; // top_label = 0
        mem_reg[15] = 8'b01000000; // JMP ...
        mem_reg[16] = 8'b00001000; // loop_top = 8
        mem_reg[17] = 8'b00000000; // .BYTE 0
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            addr_reg <= 8'h00;
        else if (sa)
            addr_reg <= a;
    end

    always @(posedge clk) begin
        if (s)
            mem_reg[addr_reg] <= d_in;
    end

    assign d_out = e ? mem_reg[addr_reg] : 8'h00;

endmodule