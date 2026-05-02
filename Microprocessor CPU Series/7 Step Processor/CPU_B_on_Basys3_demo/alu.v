// From the book: "But How Do It Know?" pg. 87, 88
// Written by: J. Clark Scott
//
// Verilog HDL implementation of the computer described in the book.
// Created by: David J. Marion
// Date: 11.15.2022
// Updated: 4.14.2026
//
// Arithmetic and Logic Unit (ALU)
//
// OPTION:
// *** Replace the NOT operation with a DEC operation that will decrement a value by 1.
// *** To me, this improves the utility for the processor for a loop variable.
//	   The NOT operation can still be accomplished by simply XORing the value with 0xFF,
//	   which will in effect flip all the bits in the value.
//
// *** Removed the carry in from the ADD operation.
//
// * Updated for synthesis
// **************************************************************************************

`timescale 1ns / 1ps
module alu(
    input [7:0] A,
    input [7:0] B,
    input c_in,
    input [2:0] op,
    output [7:0] C,
    output c_out,
    output a_larger,
    output equal,
    output zero
);

    parameter [2:0] ADD = 3'o0,
                    RSH = 3'o1,
                    LSH = 3'o2,
                    NOT = 3'o3,
                    AND = 3'o4,
                    OR  = 3'o5,
                    XOR = 3'o6,
                    CMP = 3'o7;

    reg [8:0] out_reg;

    always @(*) begin
        case(op)
            ADD: out_reg = {1'b0, A} + {1'b0, B};
            RSH: out_reg = {1'b0, c_in, A[7:1]};
            LSH: out_reg = {1'b0, A[6:0], c_in};
            NOT: out_reg = {1'b0, ~A};
            AND: out_reg = {1'b0, A & B};
            OR : out_reg = {1'b0, A | B};
            XOR: out_reg = {1'b0, A ^ B};
            CMP: out_reg = {1'b0, A ^ B};
            default: out_reg = 9'h000;
        endcase
    end

    assign C        = out_reg[7:0];
    assign zero     = ~|C;
    assign equal    = ((op == CMP) && (zero == 1'b1)) ? 1'b1 : 1'b0;
    assign a_larger = ((op == CMP) && (A > B)) ? 1'b1 : 1'b0;
    assign c_out    = (op == ADD) ? out_reg[8] :
                      (op == RSH) ? A[0] :
                      (op == LSH) ? A[7] : 1'b0;

endmodule