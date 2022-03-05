`timescale 1ns / 1ps

module oneHz_gen(
    input clk_100MHz,
    output clk_1Hz
    );
    
    reg r_1Hz = 0;
    reg [25:0] r_counter = 0;
    
    always @(posedge clk_100MHz)
        if(r_counter == 49_999_999) begin
            r_counter <= 0;
            r_1Hz <= ~r_1Hz;
        end
        else
            r_counter <= r_counter + 1;
    
    assign clk_1Hz = r_1Hz;
    
endmodule
