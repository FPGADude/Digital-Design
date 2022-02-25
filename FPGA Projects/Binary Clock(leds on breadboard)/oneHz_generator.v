`timescale 1ns / 1ps

// Verilog module for Binary Clock - generate one second signal
// Authored by David J Marion

module oneHz_generator(
    input clk_in,       // 100MHz
    output clk_out      // 1Hz
    );
    
    reg [25:0] clk_counter = 0;
    reg clk_1Hz = 0;
    
    always @(posedge clk_in) begin
        if(clk_counter == 49_999_999) begin
            clk_counter <= 0;
            clk_1Hz <= ~clk_1Hz;
        end
        else
            clk_counter <= clk_counter + 1;
    end
    
    assign clk_out = clk_1Hz;
    
endmodule

