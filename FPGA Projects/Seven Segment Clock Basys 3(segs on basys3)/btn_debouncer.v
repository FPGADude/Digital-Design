`timescale 1ns / 1ps

module btn_debouncer(
    input clk_100MHz,
    input btn_in,
    output btn_out
    );
    
    reg temp1, temp2, temp3;
    
    always @(posedge clk_100MHz) begin
        temp1 <= btn_in;
        temp2 <= temp1;
        temp3 <= temp2;
    end
    
    assign btn_out = temp3;
    
endmodule
