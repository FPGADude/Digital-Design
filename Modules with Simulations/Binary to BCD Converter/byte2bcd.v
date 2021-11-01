`timescale 1ns / 1ps

// Binary byte to binary coded decimal(BCD) converter
// Authored by David J Marion

module byte2bcd(
    input [7:0] byte_in,                        // 8 bits, value 0 - 255
    output [11:0] bcd_out                       // 12 bits of 3 nibbles
    );
    
    reg [3:0] hundreds, tens, ones;             // 3 nibbles
    reg [6:0] temp_reg;                         // temp storage for value up to 99
    
    always @(*) begin                           // Ex. using 255 as value
        hundreds = byte_in / 100;               // = 2, the rest is truncated
        temp_reg = byte_in % 100;               // = 55, the remainder
        tens = temp_reg / 10;                   // = 5, the rest is truncated
        ones = temp_reg % 10;                   // = 5, the remainder
    end
    
    assign bcd_out = {hundreds, tens, ones};    // = 255, 0010 0101 0101
    
endmodule
