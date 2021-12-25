`timescale 1ns / 1ps

module oneHz_gen(
    input clk_100MHz,   // from BASYS 3
    input reset,        // btnC on BASYS 3
    output clk_1Hz
    );
    
    reg clk_1Hz_reg = 0;
    reg [25:0] counter_reg;
    
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset)
            counter_reg <= 0;
        else
            if(counter_reg == 49_999_999) begin
                counter_reg <= 0;
                clk_1Hz_reg <= ~clk_1Hz_reg;
            end    
            else
                counter_reg <= counter_reg + 1;
    end
    
    assign clk_1Hz = clk_1Hz_reg;
    
endmodule
