`timescale 1ns / 1ps

// Having fun with BASYS 3 FPGA board
// Decode 4 switches to 16 LEDs
// Authored by David J Marion

module decoder4x16(
    input [3:0] sw,
    output reg [15:0] LED
    );
    
always @(sw)
    case(sw)
        4'd0 : LED = 16'b0000_0000_0000_0001; 
        4'd1 : LED = 16'b0000_0000_0000_0010;
        4'd2 : LED = 16'b0000_0000_0000_0100;
        4'd3 : LED = 16'b0000_0000_0000_1000;
        4'd4 : LED = 16'b0000_0000_0001_0000;
        4'd5 : LED = 16'b0000_0000_0010_0000;
        4'd6 : LED = 16'b0000_0000_0100_0000;
        4'd7 : LED = 16'b0000_0000_1000_0000;
        4'd8 : LED = 16'b0000_0001_0000_0000;
        4'd9 : LED = 16'b0000_0010_0000_0000;
        4'd10: LED = 16'b0000_0100_0000_0000;
        4'd11: LED = 16'b0000_1000_0000_0000;
        4'd12: LED = 16'b0001_0000_0000_0000;
        4'd13: LED = 16'b0010_0000_0000_0000;
        4'd14: LED = 16'b0100_0000_0000_0000;
        4'd15: LED = 16'b1000_0000_0000_0000;
    endcase    
    
endmodule
