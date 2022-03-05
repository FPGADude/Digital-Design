`timescale 1ns / 1ps

module pixel_generation(
    input video_on,
    input [9:0] x, y,
    output reg [11:0] rgb
    );
    
    // RGB Color Values
    parameter RED    = 12'h00F;
    parameter GREEN  = 12'h0F0;
    parameter BLUE   = 12'hF00;
    parameter YELLOW = 12'h0FF;     // RED and GREEN
    parameter AQUA   = 12'hFF0;     // GREEN and BLUE
    parameter VIOLET = 12'hF0F;     // RED and BLUE
    parameter WHITE  = 12'hFFF;     // all ON
    parameter BLACK  = 12'h000;     // all OFF
    parameter GRAY   = 12'hAAA;     // some of each color
    
    // Pixel Location Status Signals
    wire u_white_on, u_yellow_on, u_aqua_on, u_green_on, u_violet_on, u_red_on, u_blue_on;
    wire l_blue_on, l_black1_on, l_violet_on, l_gray_on, l_aqua_on, l_black2_on, l_white_on;
    
    // Drivers for Status Signals
    // Upper Sections
    assign u_white_on  = ((x >= 0)   && (x < 91)   &&  (y >= 0) && (y < 412));
    assign u_yellow_on = ((x >= 91)  && (x < 182)  &&  (y >= 0) && (y < 412));
    assign u_aqua_on   = ((x >= 182) && (x < 273)  &&  (y >= 0) && (y < 412));
    assign u_green_on  = ((x >= 273) && (x < 364)  &&  (y >= 0) && (y < 412));
    assign u_violet_on = ((x >= 364) && (x < 455)  &&  (y >= 0) && (y < 412));
    assign u_red_on    = ((x >= 455) && (x < 546)  &&  (y >= 0) && (y < 412));
    assign u_blue_on   = ((x >= 546) && (x < 640)  &&  (y >= 0) && (y < 412));
    // Lower Sections
    assign l_blue_on   = ((x >= 0)   && (x < 91)   &&  (y >= 412) && (y < 480));
    assign l_black1_on = ((x >= 91)  && (x < 182)  &&  (y >= 412) && (y < 480));
    assign l_violet_on = ((x >= 182) && (x < 273)  &&  (y >= 412) && (y < 480));
    assign l_gray_on   = ((x >= 273) && (x < 364)  &&  (y >= 412) && (y < 480));
    assign l_aqua_on   = ((x >= 364) && (x < 455)  &&  (y >= 412) && (y < 480));
    assign l_black2_on = ((x >= 455) && (x < 546)  &&  (y >= 412) && (y < 480));
    assign l_white_on  = ((x >= 546) && (x < 640)  &&  (y >= 412) && (y < 480));
    
    // Set RGB output value based on status signals
    always @*
        if(~video_on)
            rgb = BLACK;
        else
            if(u_white_on)
                rgb = WHITE;
            else if(u_yellow_on)
                rgb = YELLOW;
            else if(u_aqua_on)
                rgb = AQUA;
            else if(u_green_on)
                rgb = GREEN;
            else if(u_violet_on)
                rgb = VIOLET;
            else if(u_red_on)
                rgb = RED;
            else if(u_blue_on)
                rgb = BLUE;
            else if(l_blue_on)
                rgb = BLUE;
            else if(l_black1_on)
                rgb = BLACK;
            else if(l_violet_on)
                rgb = VIOLET;
            else if(l_gray_on)
                rgb = GRAY;
            else if(l_aqua_on)
                rgb = AQUA;
            else if(l_black2_on)
                rgb = BLACK;
            else if(l_white_on)
                rgb = WHITE;
       
endmodule
