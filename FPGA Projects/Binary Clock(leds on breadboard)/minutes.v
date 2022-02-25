`timescale 1ns / 1ps

// Verilog module for Binary Clock - minutes counter
// Authored by David J Marion

module minutes(
    input tick_in,
    output tick_hours,
    output [5:0] minutes
    );
    
    reg [5:0] minutes_counter = 0;
    
    always @(negedge tick_in) begin
        if(minutes_counter == 59)
            minutes_counter <= 0;
        else
            minutes_counter <= minutes_counter + 1;
    end
    
    assign minutes = minutes_counter;
    assign tick_hours = (minutes_counter == 59) ? 1 : 0;
    
endmodule

