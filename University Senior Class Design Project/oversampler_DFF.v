`timescale 1ns / 1ps

// LiDAR data receiver oversampler D-type flip flop
// Authored by David J Marion
 
module oversampler_DFF(
    input data_in,      // Data bit coming in from LD06 LiDAR sensor
    input latch,        // Enable data bit capture, tick12 signal from counter32
    input reset,        // Asynchronous system reset signal
    output reg data_out // Data bit to be sent to shift_reg376 
    );
    
    always @(posedge latch or posedge reset) begin
        if(reset)
            data_out <= 1'b0;
        else
            data_out <= data_in;
    end    
        
endmodule
