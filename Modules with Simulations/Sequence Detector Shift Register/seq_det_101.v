`timescale 1ns / 1ps

module seq_det_101(
    input clk,
    input reset,
    input serial_in,
    output detected_101
    );
    
    reg [2:0] seq_reg;
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            seq_reg <= 0;
        else
            seq_reg <= {seq_reg[1:0], serial_in};
    end
    
    assign detected_101 = (seq_reg == 3'b101) ? 1 : 0;
    
endmodule
