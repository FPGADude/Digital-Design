`timescale 1ns / 1ps

module hours(
    input inc_hours,        // From minutes
    input reset,
    output [3:0] hours
    );
    
    reg [3:0] hrs_ctr = 12;
    
    always @(negedge inc_hours or posedge reset) begin
        if(reset)
            hrs_ctr <= 12;
        else
            if(hrs_ctr == 12)
                hrs_ctr <= 1;
            else
                hrs_ctr <= hrs_ctr + 1;
    end
    
    assign hours = hrs_ctr;
    
endmodule
