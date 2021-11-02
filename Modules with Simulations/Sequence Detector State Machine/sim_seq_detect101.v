`timescale 1ns / 1ps

// Test bench for the 101 sequence detector state machine
// Authored by David J Marion

module sim_seq_detect101;

    reg clk;
    reg reset;
    reg serial_in;
    wire detected_101;
    
    reg [3:0] counter = 0;
    reg [15:0] data = 16'b1001_0100_1101_0110;
    
    seq_detect101 DUT(.clk(clk), .reset(reset), .serial_in(serial_in), .detected_101(detected_101));
    
    // Create the clock
    always #2 clk = ~clk;

    // Create a serial input
    always @(posedge clk) begin
        serial_in = data[counter];
        counter = counter + 1;
    end
    
    initial begin
        clk = 0;
        reset = 1;
        #5 reset = 0;
        
        #100 $finish;
    end

endmodule
