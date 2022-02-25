`timescale 1ns / 1ps

// Verilog module for Binary Clock - seconds counter
// Authored by David J Marion

module seconds(
    input tick_in,
    output tick_minutes
    );
    
    reg [5:0] seconds_counter = 0;
    
    always @(posedge tick_in) begin
        if(seconds_counter == 59)
            seconds_counter <= 0;
        else
            seconds_counter <= seconds_counter + 1;
    end
    
    assign tick_minutes = (seconds_counter == 59) ? 1 : 0;
    
endmodule

