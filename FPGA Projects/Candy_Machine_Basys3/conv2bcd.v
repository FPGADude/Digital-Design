`timescale 1ns / 1ps

module conv2bcd(
    input [4:0] i_value,    // coin_count | change
    output [3:0] o_low,     // low digit (0-9)
    output [1:0] o_high     // high digit (0,1,2)
    );
    
    reg [1:0] tens;
    reg [3:0] ones;
    
    always @* begin
        tens = i_value / 10;
        ones = i_value % 10;
    end
    
    assign o_low = ones;
    assign o_high = tens;
    
endmodule
