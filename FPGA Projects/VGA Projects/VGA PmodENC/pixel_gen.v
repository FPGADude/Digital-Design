`timescale 1ns / 1ps

module pixel_gen(
    input clk,
    input reset,
    input video_on,
    input [9:0] x, y,
    input [4:0] enc,
    input sw,
    output reg [11:0] rgb
    ); 
    
    // RGB Color Values
    parameter WHITE   = 12'hFFF;    // sw ON
    parameter BLACK   = 12'h000;    // sw OFF
    parameter RED1    = 12'hF00;    // 0      
    parameter GREEN1  = 12'h0F0;    // 1    
    parameter BLUE1   = 12'h00F;    // 2    
    parameter YELLOW1 = 12'h0FF;    // 3    
    parameter AQUA1   = 12'hFF0;    // 4
    parameter VIOLET1 = 12'hF0F;    // 5    
    parameter GRAY1   = 12'hAAA;    // 6   
    parameter RED2    = 12'hA00;    // 7    
    parameter GREEN2  = 12'h0A0;    // 8    
    parameter BLUE2   = 12'h00A;    // 9    
    parameter YELLOW2 = 12'h0AA;    // 10    
    parameter AQUA2   = 12'hAA0;    // 11    
    parameter VIOLET2 = 12'hA0A;    // 12    
    parameter RED3    = 12'h500;    // 13
    parameter GREEN3  = 12'h050;    // 14
    parameter BLUE3   = 12'h005;    // 15
    parameter YELLOW3 = 12'h055;    // 16
    parameter AQUA3   = 12'h550;    // 17
    parameter VIOLET3 = 12'h505;    // 18
    parameter GRAY2   = 12'h555;    // 19
    
    // rectangular area in center of screen
    parameter RECT_WIDTH  = 320;
    parameter RECT_HEIGHT = 240;
    
    // rectangle boundaries and position
    wire [9:0] rect_x_l, rect_x_r;              // left and right boundary
    wire [9:0] rect_y_t, rect_y_b;              // top and bottom boundary
    
    reg [9:0] rect_x_reg = 160;                 // rectangle left location
    reg [9:0] rect_y_reg = 120;                 // rectangle right location

     // square boundaries
    assign rect_x_l = rect_x_reg;                   // left boundary
    assign rect_y_t = rect_y_reg;                   // top boundary
    assign rect_x_r = rect_x_l + RECT_WIDTH - 1;   // right boundary
    assign rect_y_b = rect_y_t + RECT_HEIGHT - 1;   // bottom boundary
    
    // square status signal
    wire rect_on;
    assign rect_on = (rect_x_l <= x) && (x <= rect_x_r) &&
                     (rect_y_t <= y) && (y <= rect_y_b);
  
    always @*
        if(~video_on)
            rgb = BLACK;
        else
            if(rect_on)
                case(enc)
                    0  : rgb = RED1;
                    1  : rgb = RED2;
                    2  : rgb = RED3;
                    3  : rgb = YELLOW1;
                    4  : rgb = YELLOW2;
                    5  : rgb = YELLOW3;
                    6  : rgb = GREEN1;
                    7  : rgb = GREEN2;
                    8  : rgb = GREEN3;
                    9  : rgb = AQUA1;
                    10 : rgb = AQUA2;
                    11 : rgb = AQUA3;
                    12 : rgb = BLUE1;
                    13 : rgb = BLUE2;
                    14 : rgb = BLUE3;
                    15 : rgb = VIOLET1;
                    16 : rgb = VIOLET2;
                    17 : rgb = VIOLET3;
                    18 : rgb = GRAY1;
                    19 : rgb = GRAY2;
                endcase
            else if(sw & ~rect_on)
                rgb = WHITE;
            else 
                rgb = BLACK;
                    
            

            
       
endmodule
