`timescale 1ns / 1ps

// Having fun with BASYS 3 FPGA board
// Encoding 16 switches into 4 LEDs
// Authored by David J Marion

module encoder16(
    input [15:0] sw,
    output reg [3:0] LED
    );
    
always @(sw)
begin
    case(sw)
        sw[0] : LED = 4'b0000;
        sw[1] : LED = 4'b0001;
        sw[2] : LED = 4'b0010;
        sw[3] : LED = 4'b0011;
        sw[4] : LED = 4'b0100;
        sw[5] : LED = 4'b0101;
        sw[6] : LED = 4'b0110;
        sw[7] : LED = 4'b0111;
        sw[8] : LED = 4'b1000;
        sw[9] : LED = 4'b1001;
        sw[10]: LED = 4'b1010;
        sw[11]: LED = 4'b1011;
        sw[12]: LED = 4'b1100;
        sw[13]: LED = 4'b1101;
        sw[14]: LED = 4'b1110;
        sw[15]: LED = 4'b1111;
    endcase
end    
 
endmodule
