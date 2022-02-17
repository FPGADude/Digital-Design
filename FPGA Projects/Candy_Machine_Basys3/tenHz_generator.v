`timescale 1ns / 1ps

module tenHz_generator(
    input clk_100MHz,
    input reset,
    output clk_10Hz
    );
    
    reg [23:0] counter_reg = 0;
    reg clk_out_reg = 0;
    
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            counter_reg = 0;
            clk_out_reg = 0;
        end
        else 
            if(counter_reg == 9_999_999) begin
                counter_reg <= 0;
                clk_out_reg <= ~clk_out_reg; 
            end
            else
                counter_reg <= counter_reg + 1;
    end
    
    assign clk_10Hz = clk_out_reg;
    
endmodule
