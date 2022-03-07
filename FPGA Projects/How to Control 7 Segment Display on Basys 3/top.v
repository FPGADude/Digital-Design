`timescale 1ns / 1ps

module top(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnC
    output [0:6] seg,       // 7 segment display segment pattern
    output [3:0] digit      // 7 segment display anodes
    );
    
    // Internal wires for connecting inner modules
    wire w_10Hz;
    wire [3:0] w_1s, w_10s, w_100s, w_1000s;
    
    // Instantiate inner design modules
    tenHz_gen hz10(.clk_100MHz(clk_100MHz), .reset(reset), .clk_10Hz(w_10Hz));
    
    digits digs(.clk_10Hz(w_10Hz), .reset(reset), .ones(w_1s), 
                .tens(w_10s), .hundreds(w_100s), .thousands(w_1000s));
    
    seg7_control seg7(.clk_100MHz(clk_100MHz), .reset(reset), .ones(w_1s), .tens(w_10s),
                      .hundreds(w_100s), .thousands(w_1000s), .seg(seg), .digit(digit));
  
endmodule
