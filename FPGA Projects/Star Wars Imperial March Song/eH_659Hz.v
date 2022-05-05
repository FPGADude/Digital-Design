`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 659Hz signal for music tone 'eH'
//////////////////////////////////////////////////////////////////////////////////

module eH_659Hz(
    input clk_100MHz,
    output o_659Hz    
    );
    
    // 100MHz / 75,872 / 2 = 659.0046Hz
    reg r_659Hz;
    reg [16:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 17'd75_872) begin
            r_counter <= 0;
            r_659Hz <= ~r_659Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_659Hz = r_659Hz;
    
endmodule

