// Written by David J. Marion for CPU_B (New 7-Step Processor Design)
// Date: 6.6.2023
// Updated: 4.14.2026
//
// * Updated for synthesis


`timescale 1ns / 1ps
module io(
    input IO_input_output,      // 0 = input, 1 = output
    input IO_data_address,      // 0 = data, 1 = address
    input IO_clk_e,
    input IO_clk_s,
    input [0:3] instruction,    // 0111 for IO instr
    input [7:0] cpu_out,

    output [7:0] cpu_in,
    output enable_input,
    output set_output,
    output data_address,

    inout [7:0] cpu_in_out
);

    wire is_io;

    assign is_io = (instruction == 4'h7);

    // Input data to CPU
    assign cpu_in = (!IO_input_output && is_io && enable_input) ?
                    cpu_in_out : 8'h00;

    // Output data to outside module
    assign cpu_in_out = (IO_input_output && is_io) ?
                        cpu_out : 8'bz;

    // Output control signals to outside world
    assign enable_input = (!IO_input_output && is_io) ? IO_clk_e : 1'b0;
    assign set_output   = ( IO_input_output && is_io) ? IO_clk_s : 1'b0;
    assign data_address = IO_data_address;

endmodule