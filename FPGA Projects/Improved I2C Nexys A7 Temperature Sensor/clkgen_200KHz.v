`timescale 1ns / 1ps
// Created by David J. Marion
// Date 7.19.2022
// 200kHz Generator for the Nexys A7 Temperature Sensor I2C Master
// NO CHANGES
module clkgen_200KHz(
    input clk_100MHz,
    output clk_200KHz
    );
    
    // 100 x 10^6 / 200 x 10^3 / 2 = 250 <-- 8 bit counter
    reg [7:0] counter = 8'h00;
    reg clk_reg = 1'b1;
    
    always @(posedge clk_100MHz) begin
        if(counter == 249) begin
            counter <= 8'h00;
            clk_reg <= ~clk_reg;
        end
        else
            counter <= counter + 1;
    end
    
    assign clk_200KHz = clk_reg;
    
endmodule
