`timescale 1ns / 1ps

module twoHz_gen(
    input clk_100MHz,           // from Basys 3
    output clk_2Hz
    );
    
    reg [24:0] counter_reg = 0;
    reg clk_reg = 0;
    
    always @(posedge clk_100MHz) begin
        if(counter_reg == 24_999_999) begin
            counter_reg <= 0;
            clk_reg <= ~clk_reg;
        end
        else
            counter_reg <= counter_reg + 1;
    end
    
    assign clk_2Hz = clk_reg;
    
endmodule
