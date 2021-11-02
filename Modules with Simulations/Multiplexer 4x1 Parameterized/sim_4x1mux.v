`timescale 1ns / 1ps

// Test bench for the parameterized 4x1 multiplexer
// Authored by David J Marion

module sim_4x1mux;

    reg [3:0] A, B, C, D;
    reg [1:0] select;
    wire [3:0] mux_out;
    
    // Instantiate device under test
    mux4x1 DUT(.A(A), .B(B), .C(C), .D(D), .select(select), .mux_out(mux_out));

    initial begin
        A = 4'b0000;    // 0
        B = 4'b0101;    // 5
        C = 4'b1010;    // 10
        D = 4'b1111;    // 15
        select = 2'b00;
        #2 select = 2'b01;
        #2 select = 2'b10;
        #2 select = 2'b11;
        #2 select = 2'b00;
    
        #2 $finish;   
    end
    
endmodule
