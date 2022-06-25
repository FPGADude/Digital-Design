`timescale 1ns / 1ps

// Generate 1Hz output from 100MHz input
// For LFSR demonstration purposes

module oneHz_gen(
    input clk_100MHz,
    input reset,
    output clk_1Hz
    );
    
    reg [25:0] r_count = 0;
    reg r_1Hz = 0;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset)
            r_count <= 26'b0;
        else
            if(r_count == 49_999_999) begin
                r_count <= 26'b0;
                r_1Hz <= ~r_1Hz;
            end
            else
                r_count <= r_count + 1;
    
    assign clk_1Hz = r_1Hz;
    
endmodule
