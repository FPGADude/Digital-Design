`timescale 1ns / 1ps

module sim_d_ff;
    reg clk;
    reg en;
    reg data;
    wire q;
    
    d_ff DFF(.clk(clk), .d(data), .en(en), .q(q));

    always #2 clk = ~clk;

    initial begin
        clk = 0;
        en = 1;
        data = 0;
        
        #5; 
        en = 0;
        #4; 
        en = 1;
        data = 1;
        #4; 
        data = 0;
        #4; 
        en = 1;
        data = 1;
        #4;
        en = 0;
        data = 0;
        #4;
        data = 1;
        
        #4 $finish; 
    end

endmodule
