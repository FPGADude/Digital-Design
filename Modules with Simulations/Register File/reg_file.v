`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/20/2022
//
// Description: This module contains a parameterized register file.
//
//////////////////////////////////////////////////////////////////////////////////

module register_file
    #(  parameter W_ADDR = 3,
                  W_DATA = 8
     )
    (
        input   clk,
        input   we,                       // write enable
        input   [W_ADDR-1:0] w_address,   // write address
        input   [W_ADDR-1:0] r_address,   // read address
        input   [W_DATA-1:0] w_data,      // data to write to reg
        output  [W_DATA-1:0] r_data       // data read from reg    
    );
    
    reg [W_DATA-1:0] reg_file [2**W_ADDR-1:0];  // create the register file
    
    always @(posedge clk)
        if(we)  // if write enabled
            reg_file[w_address] <= w_data;
            
    assign r_data = reg_file[r_address];
    
endmodule
