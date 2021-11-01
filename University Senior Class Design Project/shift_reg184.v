`timescale 1ns / 1ps

// LiDAR data receiver output shift register
// Parallel-In to Serial-Out
// Authored by David J Marion

module shift_reg184(
    input [183:0] data_in,      // 184-bit parallel in from shift_reg376
    input reset,                // Asynchronous system reset
    input load,                 // Set 184-bit data received
    input clk,                  // Synchronous shifting signal
    output data_out             // Serial data out
    );
    
    reg [183:0] data_packet;    // 184-bit internal register
    
    always @(posedge clk or posedge reset or posedge load) begin
        if(reset)
            data_packet <= 184'd0;
        else 
            if(load)
                data_packet <= data_in;
            else
                data_packet <= {data_packet[182:0], 1'b0};         
    end
    
    assign data_out = data_packet[183];
    
endmodule
