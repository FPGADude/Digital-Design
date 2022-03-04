`timescale 1ns / 1ps

module oneHz_gen(
    input clk_100MHz,       // from Basys 3
    output clk_1Hz
    );
    
    reg [25:0] counter_reg = 0;
    reg clk_reg = 0;
    
    always @(posedge clk_100MHz) begin
        if(counter_reg == 49_999_999) begin
            counter_reg <= 0;
            clk_reg <= ~clk_reg;
        end
        else
            counter_reg <= counter_reg + 1;
    end
    
    assign clk_1Hz = clk_reg;
    
endmodule
