`timescale 1ns / 1ps

module rom(
    input [3:0] addr,       // memory address
    output reg [3:0] data   // data at each memory address
    );
    
    always @*
        case(addr)
            4'h0 : data = 4'hF;
            4'h1 : data = 4'hE;
            4'h2 : data = 4'hD;
            4'h3 : data = 4'hC;
            4'h4 : data = 4'hB;
            4'h5 : data = 4'hA;
            4'h6 : data = 4'h9;
            4'h7 : data = 4'h8;
            4'h8 : data = 4'h7;
            4'h9 : data = 4'h6;
            4'hA : data = 4'h5;
            4'hB : data = 4'h4;
            4'hC : data = 4'h3;
            4'hD : data = 4'h2;
            4'hE : data = 4'h1;
            4'hF : data = 4'h0;
        endcase
    
endmodule
