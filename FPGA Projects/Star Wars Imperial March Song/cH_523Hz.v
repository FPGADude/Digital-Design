`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 523Hz signal for music tone 'cH'
//////////////////////////////////////////////////////////////////////////////////

module cH_523Hz(
    input clk_100MHz,
    output o_523Hz      // PMOD JB[0]
    );
    
    // 100MHz / 95,602 / 2 = 523.0016Hz
    reg r_523Hz;
    reg [16:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 17'd95_602) begin
            r_counter <= 0;
            r_523Hz <= ~r_523Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_523Hz = r_523Hz;
    
endmodule

