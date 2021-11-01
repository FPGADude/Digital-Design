`timescale 1ns / 1ps

// Test bench for the parameterized Fibonacci sequence generator
// Authored by David J Marion

module sim_fibonacci;

    parameter N = 32;   // Only need to change this to resize output width
    reg clk, reset;
    wire [N-1:0] fib_out;

    fibonacci #(.W(N)) DUT(.clk(clk), .reset(reset), .fib_out(fib_out));

    always #2 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 0;
        #4 reset = 1;
        
        #500 $finish;
    end

endmodule
