`timescale 1ns / 1ps

module minutes(
    input inc_minutes,      // From seconds
    input reset,
    output inc_hours,       // To hours
    output [5:0] minutes    // For LEDs
    );
    
    reg [5:0] min_ctr = 0;
    
    always @(negedge inc_minutes or posedge reset) begin
        if(reset)
            min_ctr <= 0;
        else
            if(min_ctr == 59)
                min_ctr <= 0;
            else
                min_ctr <= min_ctr + 1;
    end
    
    assign inc_hours = (min_ctr == 59) ? 1 : 0;
    assign minutes = min_ctr;
    
endmodule