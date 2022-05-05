`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 415Hz signal for music tone 'gS'
//////////////////////////////////////////////////////////////////////////////////

module gS_415Hz(
    input clk_100MHz,
    output o_415Hz     
    );
    
    // 100MHz / 120,481 / 2 = 415.0032Hz
    reg r_415Hz;
    reg [17:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 18'd120_481) begin
            r_counter <= 0;
            r_415Hz <= ~r_415Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_415Hz = r_415Hz;
    
endmodule
