`timescale 1ns / 1ps

module oneHz_gen(
    input clk_100MHz,
    input reset,
    output clk_1Hz
    );
    
    reg [25:0] r_counter = 0;
    reg clk_out = 0;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset)
            r_counter <= 26'b0;
        else 
            if(r_counter == 49_999_999) begin
                r_counter <= 26'b0;
                clk_out <= ~clk_out;
            end
            else
                r_counter <= r_counter + 1;
    
    assign clk_1Hz = clk_out;
    
endmodule
