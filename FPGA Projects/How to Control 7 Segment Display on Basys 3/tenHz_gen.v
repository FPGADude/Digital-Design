`timescale 1ns / 1ps

module tenHz_gen(
    input clk_100MHz,
    input reset,
    output clk_10Hz
    );
    
    reg [22:0] ctr_reg = 0; // 23 bits to cover 5,000,000
    reg clk_out_reg = 0;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset) begin
            ctr_reg <= 0;
            clk_out_reg <= 0;
        end
        else
            if(ctr_reg == 4_999_999) begin  // 100MHz / 10Hz / 2 = 5,000,000
                ctr_reg <= 0;
                clk_out_reg <= ~clk_out_reg;
            end
            else
                ctr_reg <= ctr_reg + 1;
    
    assign clk_10Hz = clk_out_reg;
    
endmodule
