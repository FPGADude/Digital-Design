`timescale 1ns / 1ps

module oneHz_gen(
    input clk,          // 100MHz from Nexys
    output clk_1Hz
    );
    
    reg [25:0] r_counter = 0;
    reg r_clk_1Hz = 0;
    
    always @(posedge clk) begin
        if(r_counter == 49_999_999) begin
            r_counter <= 0;
            r_clk_1Hz <= ~r_clk_1Hz;
        end
        else
            r_counter <= r_counter + 1;
    end
    
    assign clk_1Hz = r_clk_1Hz;
    
endmodule
