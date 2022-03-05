`timescale 1ns / 1ps

module sim_sr_latch;

    reg set, reset;     // regs to drive inputs
    wire q;             // wire to capture output

    sr_latch DUT(.s(set), .r(reset), .q(q));
    
    initial begin
        set = 0;
        reset = 1;  // reset q to 0
        #1
        reset = 0;
        #5
        set = 1;
        #1
        set = 0;
        #5
        reset = 1;
        #1
        reset = 0;
        // Driving set and reset at same time
        #5
        set = 1;
        reset = 1;
        #2
        set = 0;
        reset = 0;
        #5
        reset = 1;
        set = 1;
        #1 $finish; 
    end

endmodule
