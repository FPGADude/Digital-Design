`timescale 1ns / 1ps
// instantiate PMOS: pmos instance_name(out, data, control)
// instantiate NMOS: nmos instance_name(out, data, control)
// instantiate CMOS: cmos instance_name(out, data, ncontrol, pcontrol)
// Since pmos, nmos, and cmos are Verilog primitives an instance name is optional

module cmos_gates(
    input a, b, c, d, e,
    output x, y, z
    );
    
    wire w1, w2;
    
    supply1 pwr;    // Needed for switch level circuits
    supply0 gnd;
    
    // NAND gate, assign x = ~(a & b); or nand (x, a, b);
    pmos (x, pwr, a);
    pmos (x, pwr, b); 
    nmos (x, w1, a);
    nmos (w1, gnd, b);

    // NOR gate, assign y = ~(c + d); or nor (y, c, d);
    pmos (w2, pwr, c);
    pmos (y, w2, d); 
    nmos (y, gnd, c);
    nmos (y, gnd, d);
 
    // NOT gate, assign z = ~e; or not (z, e);
    pmos (z, pwr, e);
    nmos (z, gnd, e);

endmodule
