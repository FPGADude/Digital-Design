`timescale 1ns / 1ps
/*****************************************************
* Written by: David J. Marion
* Byte Calculator on BASYS 3 FPGA
*****************************************************/

module byte_calculator(
    input clk,
    input [7:0] byte_A,
    input [7:0] byte_B,
    input [4:0] op_select,
    output reg [8:0] result
    );
    
    wire reset;
    assign reset = op_select[4];
    // op_select[4] = btnC = reset
    // op_select[3] = btnU = ADD
    // op_select[2] = btnR = SUB
    // op_select[1] = btnD = MULT
    // op_select[0] = btnL = DIV
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            result <= 8'b0000_0000;
        else
            case(op_select)
                5'b01000 : result <= byte_A + byte_B;
                5'b00100 : result <= byte_A - byte_B;
                5'b00010 : result <= byte_A * byte_B;
                5'b00001 : result <= byte_A / byte_B;
            endcase
    end
    
    
endmodule
