`timescale 1ns / 1ps

module led_driver(
    input clk_2Hz,
    input enable,           // enabled during open voting
    output reg [15:0] LED
    );
    
    parameter S0 = 16'h5555;
    parameter S1 = 16'hAAAA;
    
    reg ctr = 0;
    
    always @(posedge clk_2Hz)
        ctr <= ~ctr;
    
    always @(posedge clk_2Hz)
        if(enable)
            if(ctr == 0)
                LED = S0;
            else
                LED = S1;
        else
            LED = 16'h8001;
  
endmodule
