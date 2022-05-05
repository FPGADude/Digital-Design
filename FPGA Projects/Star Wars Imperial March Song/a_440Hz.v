`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 440Hz signal for music tone 'a'
//////////////////////////////////////////////////////////////////////////////////

module a_440Hz(
    input clk_100MHz,
    output o_440Hz     
    );
    
    // 100MHz / 113,636 / 2 = 440.0014Hz
    reg r_440Hz;
    reg [16:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 17'd113_636) begin
            r_counter <= 0;
            r_440Hz <= ~r_440Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_440Hz = r_440Hz;
    
endmodule
