`timescale 1ns / 1ps

// LiDAR data receiver counter32 
// Produces enabling signals for oversampler and shift reg
// Authored by David J Marion

module counter32(
    input sig_in,       // Synchronous clock input
    input reset,        // Asynchronous system reset
    output reg tick12,  // Enable oversampler data capture
    output reg tick24   // Enable data shift from oversampler to shift_reg376
    );
    
    reg [4:0] counter;  // 5-bit register 
    
    always @(posedge sig_in or posedge reset) begin
        if(reset)
            counter <= 5'b0_0000;
        else if(counter == 5'b1_1000)   //24
            counter <= 5'b0_0000;
        else
            counter <= counter + 1;
    end
    
    always @(posedge sig_in) begin
        if(counter == 5'b0_1100)        //12
            tick12 <= 1'b1;
        else
            tick12 <= 1'b0;
    end
    
    always @(posedge sig_in) begin
        if(counter == 5'b1_1000)        //24
            tick24 <= 1'b1;
        else
            tick24 <= 1'b0;
    end

endmodule
