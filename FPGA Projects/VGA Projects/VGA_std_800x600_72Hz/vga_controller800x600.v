// Created by David J. Marion aka FPGA Dude
// VGA Controller for 800x600 @72Hz standard
// Requires a 50MHz pixel clock
// For use with an FPGA with a 100MHz clock
module vga_controller(
	input clk_100MHz, 
	input reset,
	output hsync, 
	output vsync, 
	output video_on, 
	output p_tick,
	output [10:0] x, 
	output [10:0] y
);
	
	// VESA Signal 800 x 600 @ 72Hz timing
	// constant declarations for VGA sync parameters
	localparam H_DISPLAY       = 800; // horizontal display area
	localparam H_L_BORDER      =  64; // horizontal left border
	localparam H_R_BORDER      =  56; // horizontal right border
	localparam H_RETRACE       =  120; // horizontal retrace
	localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
	localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
	localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;
	
	localparam V_DISPLAY       = 600; // vertical display area
	localparam V_T_BORDER      =  37; // vertical top border
	localparam V_B_BORDER      =  23; // vertical bottom border
	localparam V_RETRACE       =   6; // vertical retrace
	localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
    	localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
	localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;
	
	// mod-2 counter to generate 50 MHz pixel tick
	reg pixel_reg;
	wire pixel_next, pixel_tick;
	
	always @(posedge clk)
		pixel_reg <= pixel_next;
	
	assign pixel_next = ~pixel_reg; // next state is complement of current
	
	assign pixel_tick = (pixel_reg == 0); // assert tick half of the time
	
	// registers to keep track of current pixel location
	reg [10:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
	
	// register to keep track of vsync and hsync signal states
	reg vsync_reg, hsync_reg;
	wire vsync_next, hsync_next;
 
	// infer registers
	always @(posedge clk, posedge reset)
		if(reset)
		    begin
                    v_count_reg <= 0;
                    h_count_reg <= 0;
                    vsync_reg   <= 0;
                    hsync_reg   <= 0;
	            end
		else
		    begin
                    v_count_reg <= v_count_next;
                    h_count_reg <= h_count_next;
                    vsync_reg   <= vsync_next;
                    hsync_reg   <= hsync_next;
	            end
			
	// next-state logic of horizontal vertical sync counters
	always @*
		begin
		h_count_next = pixel_tick ? 
		               h_count_reg == H_MAX ? 0 : h_count_reg + 1
			       : h_count_reg;
		
		v_count_next = pixel_tick && h_count_reg == H_MAX ? 
		               (v_count_reg == V_MAX ? 0 : v_count_reg + 1) 
			       : v_count_reg;
		end
		
        // hsync and vsync are active low signals
        // hsync signal asserted during horizontal retrace
        assign hsync_next = h_count_reg >= START_H_RETRACE 
                            && h_count_reg <= END_H_RETRACE;
   
        // vsync signal asserted during vertical retrace
        assign vsync_next = v_count_reg >= START_V_RETRACE 
                            && v_count_reg <= END_V_RETRACE;

        // video only on when pixels are in both horizontal and vertical display region
        assign video_on = (h_count_reg < H_DISPLAY) 
                           && (v_count_reg < V_DISPLAY);

        // output signals
        assign hsync  = hsync_reg;
        assign vsync  = vsync_reg;
        assign x      = h_count_reg;
        assign y      = v_count_reg;
        assign p_tick = pixel_tick;
endmodule
