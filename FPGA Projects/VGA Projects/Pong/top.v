`timescale 1ns / 1ps

module top(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnR
    input up,               // btnU
    input down,             // btnD
    output hsync,           // to VGA port
    output vsync,           // to VGA port
    output [11:0] rgb       // to DAC, to VGA port
    );
    
    wire w_reset, w_up, w_down, w_vid_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    
    vga_controller vga(.clk_100MHz(clk_100MHz), .reset(w_reset), .video_on(w_vid_on),
                       .hsync(hsync), .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    pixel_gen pg(.clk(clk_100MHz), .reset(w_reset), .up(w_up), .down(w_down), 
                 .video_on(w_vid_on), .x(w_x), .y(w_y), .rgb(rgb_next));
    debounce dbR(.clk(clk_100MHz), .btn_in(reset), .btn_out(w_reset));
    debounce dbU(.clk(clk_100MHz), .btn_in(up), .btn_out(w_up));
    debounce dbD(.clk(clk_100MHz), .btn_in(down), .btn_out(w_down));
    
    // rgb buffer
    always @(posedge clk_100MHz)
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
    
endmodule
