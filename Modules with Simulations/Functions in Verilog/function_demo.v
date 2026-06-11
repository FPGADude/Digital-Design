`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: function_demo
// Description:
//   Demonstrates three Verilog functions:
//     1. add_two()  - adds two 8-bit values
//     2. max_two()  - returns the larger of two 8-bit values
//     3. is_even()  - returns 1 if value is even, 0 if odd
//
// Purpose:
//   This module is intended for Vivado simulation and synthesis.
//   After synthesis, open the schematic to show that the functions disappear
//   and become normal combinational hardware.
//////////////////////////////////////////////////////////////////////////////////

module function_demo(
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] value,

    output wire [7:0] sum,
    output wire [7:0] maximum,
    output wire       even_flag
);

    // ------------------------------------------------------------
    // Function 1: Add two 8-bit numbers
    // Synthesizes to an 8-bit adder.
    // ------------------------------------------------------------
    function [7:0] add_two;
        input [7:0] x;
        input [7:0] y;
        begin
            add_two = x + y;
        end
    endfunction

    // ------------------------------------------------------------
    // Function 2: Return the larger of two 8-bit numbers
    // Synthesizes to comparator logic and a multiplexer.
    // ------------------------------------------------------------
    function [7:0] max_two;
        input [7:0] x;
        input [7:0] y;
        begin
            if (x > y)
                max_two = x;
            else
                max_two = y;
        end
    endfunction

    // ------------------------------------------------------------
    // Function 3: Return 1 if value is even
    // Even numbers have LSB = 0, so invert value[0].
    // Synthesizes to simple bit-select and inversion logic.
    // ------------------------------------------------------------
    function is_even;
        input [7:0] x;
        begin
            is_even = ~x[0];
        end
    endfunction

    // ------------------------------------------------------------
    // Function calls
    // These look like software-style calls, but after synthesis,
    // Vivado replaces them with regular combinational logic.
    // ------------------------------------------------------------
    assign sum       = add_two(a, b);
    assign maximum   = max_two(a, b);
    assign even_flag = is_even(value);

endmodule

