`timescale 1ns / 1ps

// S R input combinations:
// 0 0 -> no change to q
// 0 1 -> q = 0
// 1 0 -> q = 1
// 1 1 -> should not be allowed to happen. what should the value of q be?

module sr_latch(
    input s,        // set
    input r,        // reset
    output reg q    // latched value
    );
    
    always @*
        if(s)
            q = 1;
        else if(r)
            q = 0;
    
endmodule
