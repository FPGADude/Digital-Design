`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 349Hz signal for music tone 'f'
//////////////////////////////////////////////////////////////////////////////////

module f_349Hz(
    input clk_100MHz,
    output o_349Hz  
    );
    
    // 100MHz / 143,266 / 2 = 349.0012Hz
    reg r_349Hz;
    reg [17:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 18'd143_266) begin
            r_counter <= 0;
            r_349Hz <= ~r_349Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_349Hz = r_349Hz;
    
endmodule

