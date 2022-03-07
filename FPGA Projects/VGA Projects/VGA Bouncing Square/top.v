`timescale 1ns / 1ps

module top(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnC on Basys 3
    output hsync,           // VGA port on Basys 3
    output vsync,           // VGA port on Basys 3
    output [11:0] rgb       // to DAC, 3 bits to VGA port on Basys 3
    );
    
    wire w_video_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg [11:0] rgb_reg;
    wire[11:0] rgb_next;
    
    vga_controller vc(.clk_100MHz(clk_100MHz), .reset(reset), .video_on(w_video_on), .hsync(hsync), 
                      .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    pixel_generation pg(.clk(clk_100MHz), .reset(reset), .video_on(w_video_on), 
                        .x(w_x), .y(w_y), .rgb(rgb_next));
    
    always @(posedge clk_100MHz)
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
 
endmodule
