`timescale 1ns / 1ps

module seq_det_101_fsm(
    input clock,
    input reset,
    input data,
    output detected_101
    );
    
    parameter ZERO    = 2'b00;
    parameter DET_1   = 2'b01;
    parameter DET_10  = 2'b10;
    parameter DET_101 = 2'b11;
    
    reg [1:0] state = ZERO;
    
    always @(posedge clock or negedge reset) begin
        if(~reset)
            state <=  ZERO;
        else
            case(state) 
                ZERO    : if(data == 1) state <= DET_1;
                DET_1   : if(data == 0) state <= DET_10;
                DET_10  : if(data == 1) state <= DET_101;
                          else state <= ZERO;
                DET_101 : if(data == 0) state <= DET_10;
                          else state <= DET_1;
            endcase
    end
    
    assign detected_101 = (state == DET_101) ? 1 : 0;
    
endmodule
