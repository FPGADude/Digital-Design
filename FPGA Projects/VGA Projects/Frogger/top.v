`timescale 1ns / 1ps

// Frogger Remake
// By: David J. Marion aka FPGA Dude
// Last Edit: 3/10/2022
// Information:
// Drawing the Frogger background screen based on Atari screenshot.
// Commented sections of code to be added later as game is developed.

module top(
    input clk_100MHz,       // Basys 3 oscillator
    input reset,            // btnC
//    input up,               // btnU
//    input down,             // btnD
//    input left,             // btnL
//    input right,            // btnR
    output hsync,           // to VGA port
    output vsync,           // to VGA port
    output [11:0] rgb       // to DAC, to VGA port
    );
    
    // Internal Signals
    wire [9:0] w_x, w_y;
    wire w_p_tick, w_video_on, w_reset;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
//    wire w_up, w_down, w_left, w_right;
    
    // Instantiate Inner Modules
    vga_controller vga( .clk_100MHz(clk_100MHz),
                        .reset(w_reset),
                        .video_on(w_video_on),
                        .p_tick(w_p_tick),
                        .hsync(hsync),
                        .vsync(vsync),
                        .x(w_x),
                        .y(w_y));
    
    pixel_gen pg(       //.clk_100MHz(clk_100MHz),
                        //.reset(w_reset),
                        .video_on(w_video_on),
                        .x(w_x),
                        .y(w_y),
                        .rgb(rgb_next));
    
    debounce btnC(      .clk(clk_100MHz), 
                        .btn_in(reset), 
                        .btn_out(w_reset));
    
//    debounce btnU(      .clk(clk_100MHz), 
//                        .btn_in(up), 
//                        .btn_out(w_up));
    
//    debounce btnD(      .clk(clk_100MHz), 
//                        .btn_in(down), 
//                        .btn_out(w_down));
    
//    debounce btnL(      .clk(clk_100MHz),  
//                        .btn_in(left), 
//                        .btn_out(w_left));
    
//    debounce btnR(  .clk(clk_100MHz),  
//                    .btn_in(right), 
//                    .btn_out(w_right));
    
    // rgb buffer
    always @(posedge clk_100MHz) 
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
    
endmodule
