`timescale 1ns / 1ps

module sim_alu;
    parameter W = 8;
    reg [1:0] opcode;
    reg [W-1:0] operand_A, operand_B;
    wire [W-1:0] alu_result;
    wire [2:0] flags;
    
    alu #(.W(W)) DUT(
        .opcode(opcode), 
        .operand_A(operand_A), 
        .operand_B(operand_B), 
        .alu_result(alu_result), 
        .flags(flags)
        );

    initial begin
        operand_A = 8'd32;
        operand_B = 8'd32;
        opcode = 2'b00;     // ADD
        #2
        opcode = 2'b01;     // SUB, check for Z flag
        #2;
        
        operand_A = 8'b1010_1010;
        operand_B = 8'b0101_0101;
        opcode = 2'b10;     // AND, check for Z flag
        #2
        opcode = 2'b11;     // OR, check for N flag
        #2;
        
        operand_A = 8'b1111_1111;
        operand_B = 8'b0000_0001;
        opcode = 2'b00;     // ADD, check for C flag
        #2;
        
        operand_A = 8'd0;
        operand_B = 8'd0;
        opcode = 2'b00;     // ADD, check for Z flag
        #2;
        
        operand_A = 8'b0111_1111;
        operand_B = 8'b1111_1111;
        opcode = 2'b01;     // SUB, check for N flag
        
        #2 $finish;
    end

endmodule
