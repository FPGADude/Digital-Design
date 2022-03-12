`timescale 1ns / 1ps

// Test Bench for cmos_gates.v

module sim_cmos;

    reg a, b, c, d, e;
    wire x, y, z;
    
    cmos_gates DUT(.a(a), .b(b), .c(c), .d(d), .e(e), .x(x), .y(y), .z(z));

    initial begin
        a = 0;
        b = 0;
        c = 0;
        d = 0;
        e = 0;
        #1
        a = 0;
        b = 1;
        c = 0;
        d = 1;
        #1
        a = 1;
        b = 0;
        c = 1;
        d = 0;
        e = 1;
        #1
        a = 1;
        b = 1;
        c = 1;
        d = 1;
        #1   
        
        $finish;
    end

endmodule
