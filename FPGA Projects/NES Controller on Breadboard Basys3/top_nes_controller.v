`timescale 1ns / 1ps
module top_nes_controller(
    input        clk,           // 100MHz
    input        btnC,          // reset
    input        nes_data,      // JA1 
    output       nes_latch,     // JA2
    output       nes_clk,       // JA3
    output [7:0] led            
    );
    
    nes_controller CONTROLLER
(
		.clk(clk), 
		.reset(btnC), 
		.data(nes_data),
		.latch(nes_latch), 
		.nes_clk(nes_clk),
		.A(led[0]), 
		.B(led[1]), 
		.select(led[2]), 
		.start(led[3]), 
		.up(led[4]), 
		.down(led[5]), 
		.left(led[6]), 
		.right(led[7])
        );
    
endmodule