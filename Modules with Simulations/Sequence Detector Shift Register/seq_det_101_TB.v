`timescale 1ns / 1ps
module seq_det_101_TB;
    reg clk;
    reg reset;
    reg serial_in;
    wire detected_101;
    integer i;
    
    reg [15:0] data = 16'b0101_0010_1001_1101;

    seq_det_101 sd(.clk(clk), .reset(reset), .serial_in(serial_in), .detected_101(detected_101));
    
    always #2 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        serial_in = 0;
        i = 0;
        #9 reset = 0;
        for(i = 0; i < 16; i = i + 1) begin
            serial_in = data[i];
            #4;
        end
    
        #4 $finish;        
    end
endmodule
