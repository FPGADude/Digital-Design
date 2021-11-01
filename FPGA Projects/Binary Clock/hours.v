`timescale 1ns / 1ps

// Verilog module for Binary Clock - hours counter
// Authored by David J Marion

module hours(
    input tick_in,
    output [3:0] hours
    );
    
    reg [3:0] hours_counter = 1;
    
    always @(negedge tick_in) begin
        if(hours_counter == 12)
            hours_counter <= 1;
        else
            hours_counter <= hours_counter + 1;
    end
    
    assign hours = hours_counter;
    
endmodule

