`timescale 1ns / 1ps

module seq_det_101_fsm_TB;
    reg clock;
    reg reset;
    reg data;
    wire detected_101;
    integer i;
    
    seq_det_101_fsm DUT(.clock(clock), .reset(reset), .data(data), .detected_101(detected_101));
    
    reg [15:0] data_reg = 16'b0110_1001_0101_1010;
    
    always #2 clock = ~clock;
    
    initial begin
        clock = 0;
        reset = 0;
        data = 0;
        i = 0;
        #5 reset = 1;
        
        for(i = 0; i < 16; i = i + 1) begin
            data = data_reg[i];
            #4;
        end
        
        $finish;
    end

endmodule
