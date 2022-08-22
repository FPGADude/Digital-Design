`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Reference book:
// "FPGA Prototyping by Verilog Examples"
// "Xilinx Spartan-3 Version"
// Dr. Pong P. Chu
// Wiley
//
// Adapted for Artix-7
// David J. Marion
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////////////

module fifo_test(
    input clk_100MHz,       // 100MHz
    input reset,            // btnC
    input wr,               // btnU - upload
    input rd,               // btnD - download
    input [2:0] sw,         // data value 3 bits
    output full,            // LED15
    output empty,           // LED0
    output [2:0] data_out   // read data - LEDs 7,6,5
    );
    
    // signal declaration
    wire write, read;
    
    debounce_explicit debounce_unit1(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .btn(wr),
        .db_level(),        // unconnected
        .db_tick(write)
    );
   
    debounce_explicit debounce_unit2(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .btn(rd),
        .db_level(),        // unconnected
        .db_tick(read)
    );
    
    fifo #(.DATA_SIZE(3), .ADDR_SPACE_EXP(2)) fifo_unit(
        .clk(clk_100MHz),
        .reset(reset),
        .write_to_fifo(write),
        .read_from_fifo(read),
        .write_data_in(sw),
        .read_data_out(data_out),
        .full(full),
        .empty(empty)
        );
    
endmodule
