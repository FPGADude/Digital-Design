`timescale 1ns / 1ps

module seconds(
    input clk_1Hz,      // From oneHz_generator
    input reset,
    output inc_minutes  // To minutes
    );
    
    reg [5:0] sec_ctr = 0;
    
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            sec_ctr <= 0;
        else
            if(sec_ctr == 59) 
                sec_ctr <= 0;
            else
                sec_ctr <= sec_ctr + 1;
    end
    
    assign inc_minutes = (sec_ctr == 59) ? 1 : 0;
    
endmodule
