`timescale 1ns / 1ps
// Created by David J. Marion
// Date: 7.21.2022
// For Nexys A7 Accelerometer reading
// Generate the ICLK for SPI Master = 4MHz
module sclk_gen(
    input CLK100MHZ,
    output clk_4MHz
    );
    
    // Generate a 4MHz clock from a 100MHz clock
    // 100 x 10^6 / 4 x 10^6 / 2 = 12.5 --> not possible with 50% duty cycle
    // 100 x 10^6 / 4 x 10^6 = 25
    // So, need to count to 13 for high period, count to 25 for low period
    reg [4:0] counter = 5'b0;
    reg clk_reg = 1'b1;
    
    always @(posedge CLK100MHZ) begin
        if(counter == 12)
            clk_reg <= 1'b0;
        if(counter == 24) begin
            clk_reg <= 1'b1;
            counter <= 5'b0;
        end    
        else
            counter <= counter + 1;
    end        
    
    assign clk_4MHz = clk_reg;
    
endmodule
