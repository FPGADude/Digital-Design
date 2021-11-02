`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_decoder(
    input [3:0] count_in,
    output [6:0] decode_out
    );
    
    reg [6:0] decoder = 7'b000_0000;
    
    always @(*) begin
        case(count_in)
            4'b0000 : decoder = 7'b111_1110;    // 0
            4'b0001 : decoder = 7'b001_1000;    // 1
            4'b0010 : decoder = 7'b110_1101;    // 2
            4'b0011 : decoder = 7'b011_1101;    // 3
            4'b0100 : decoder = 7'b001_1011;    // 4
            4'b0101 : decoder = 7'b011_0111;    // 5
            4'b0110 : decoder = 7'b111_0111;    // 6
            4'b0111 : decoder = 7'b001_1100;    // 7
            4'b1000 : decoder = 7'b111_1111;    // 8
            4'b1001 : decoder = 7'b001_1111;    // 9
            default : decoder = 7'b111_1001;    // d
        endcase
    end
    
    assign decode_out = decoder;
    
endmodule

