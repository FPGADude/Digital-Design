`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/29/2022
// Using Vivado 2021.2
// Generating 698Hz signal for music tone 'fH'
//////////////////////////////////////////////////////////////////////////////////

module fH_698Hz(
    input clk_100MHz,
    output o_698Hz    
    );
    
    // 100MHz / 71,633 / 2 = 698.0023Hz
    reg r_698Hz;
    reg [16:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 17'd71_633) begin
            r_counter <= 0;
            r_698Hz <= ~r_698Hz;
            end
        else
            r_counter <= r_counter + 1;

    assign o_698Hz = r_698Hz;
    
endmodule
