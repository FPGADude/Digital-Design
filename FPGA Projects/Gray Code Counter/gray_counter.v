`timescale 1ns / 1ps

module gray_counter(
    input clk,
    input reset,
    output [2:0] o_bin,
    output [2:0] o_gray_code
    );
    
    // 3-bit binary counter
    reg [2:0] bin_counter = 0;
    
    always @(posedge clk or posedge reset)
        if(reset)
            bin_counter <= 0;
        else
            bin_counter <= bin_counter + 1;
        
    assign o_bin = bin_counter;
        
    // *** Hard Coding a Gray Code Register to Binary Counter Values
//    reg [2:0] r_gc = 0;             // gray code reg   
    
//    always @(bin_counter)
//        case(bin_counter)
//            0 : r_gc = 3'b000;
//            1 : r_gc = 3'b001;
//            2 : r_gc = 3'b011;
//            3 : r_gc = 3'b010;
//            4 : r_gc = 3'b110;
//            5 : r_gc = 3'b111;
//            6 : r_gc = 3'b101;
//            7 : r_gc = 3'b100;
//        endcase
       
//    assign o_gray_code = r_gc;      // gray code output tied to gray code reg
    // *****************************************************************************
        
    // *** Combinational Logic of Binary Counter Values to Generate Gray Code Output
    assign o_gray_code[2] = bin_counter[2];                     // high-order bit always same
    assign o_gray_code[1] = bin_counter[2] ^ bin_counter[1];    // lesser order bits are the result
    assign o_gray_code[0] = bin_counter[1] ^ bin_counter[0];    // of XOR logic 
    // *****************************************************************************    
        
endmodule
