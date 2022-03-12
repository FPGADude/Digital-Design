`timescale 1ns / 1ps

module top(
    input clk_100MHz,   // from Basys 3
    input [3:0] rows,   // Pmod JB pins 10 to 7
    output [3:0] cols,  // Pmod JB pins 4 to 1
    output [3:0] an,    // 7 segment anodes
    output [6:0] seg    // 7 segment cathodes
    );

	wire [3:0] w_dec;

	decoder d(.clk_100MHz(clk_100MHz), .row(rows),
			.col(cols), .dec_out(w_dec));

	seg7_control s(.dec(w_dec), .an(an), .seg(seg));

endmodule
