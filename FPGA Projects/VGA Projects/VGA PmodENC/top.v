`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineers: Michelle Yu
//				  Josh Sackos
// 
// Create Date:    11:38:09 06/12/2012 
// Module Name:    PmodENC 
// Project Name:  PmodENC
// Target Devices: Nexys3
// Tool versions: Xilinx ISE Design Suite 14.1
//
// Description: 
//	This project changes the seven segment display when the position of rotary shaft
// is changed. The number on the seven segment display is relative to the start position.
// When the rotary button is pressed, the program resets. The switch controls whether 
// the seven segment display turns on or off. 
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
//
// Edited for the Basys 3 by David J. Marion aka FPGA Dude
// Edit Date: 4/5/2022
//
//////////////////////////////////////////////////////////////////////////////////
module top(
    input clk_100MHz,       // 100MHz from Basys 3
    input reset,            // btnC
    input [7:4] JB,         // PMOD JB
    output [1:0] LED,       // LED[1], LED[0]
    output [3:0] an,        // 7 Segment anodes
    output [6:0] seg,        // 7 Segment cathodes
    output hsync,           // VGA port on Basys 3
    output vsync,           // VGA port on Basys 3
    output [11:0] rgb       // to DAC, 3 bits to VGA port on Basys 3
    );
	
	// Internal wires 
	wire [4:0] w_enc;
	wire w_l, w_r;
	wire w_vid_on, w_tick;
	wire [9:0] w_x, w_y;
	reg [11:0] rgb_reg;
	wire [11:0] rgb_next;
	 
	// Instantiate Modules
    debounce db(.clk(clk_100MHz), .Ain(JB[4]), .Bin(JB[5]), .Aout(w_A), .Bout(w_B));
 	encoder enc (.clk(clk_100MHz), .A(w_A), .B(w_B), .BTN(JB[6]), .EncOut(w_enc), .LED(LED));
 	seg7_control seg7 (.clk(clk_100MHz), .sw(JB[7]), .enc(w_enc), .anode(an), .seg_out(seg));
    pixel_gen pg(.clk(clk_100MHz), .reset(reset), .video_on(w_vid_on),
                 .x(w_x), .y(w_y), .enc(w_enc), .sw(JB[7]), .rgb(rgb_next));
    vga_controller vga(.clk_100MHz(clk_100MHz), .reset(reset), .video_on(w_vid_on),
                       .hsync(hsync), .vsync(vsync), .p_tick(w_tick), 
                       .x(w_x), .y(w_y));

    always @(posedge clk_100MHz)
        if(w_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
    
endmodule

