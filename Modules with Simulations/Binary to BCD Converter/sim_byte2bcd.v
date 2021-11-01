`timescale 1ns / 1ps

// Test bench for the byte2bcd module
// Authored by David J Marion

module sim_byte2bcd;

    reg [7:0] byte_in;
    wire [11:0] bcd_out;
    integer i;
    
    byte2bcd DUT(.byte_in(byte_in), .bcd_out(bcd_out));

    initial begin
        for(i = 0; i < 256; i = i + 1) begin
            byte_in = i;
            #3;
        end
    end
endmodule
