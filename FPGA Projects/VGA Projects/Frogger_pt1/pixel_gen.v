`timescale 1ns / 1ps

module pixel_gen(
    //input clk_100MHz,   // sys clock
    //input reset,        // sys reset
    input video_on,     // from VGA controller
    input [9:0] x,      // from VGA controller
    input [9:0] y,      // from VGA controller
    output reg [11:0] rgb   // to VGA port
    );
    
    // RGB Color Values
    //parameter RED    = 12'h00F;
    parameter GREEN  = 12'h2A6;
    parameter BLUE   = 12'hA21;
    parameter YELLOW = 12'h5FF; 
    parameter BLACK  = 12'h000;
    
    // Pixel Location Status Signals
    wire bottom_green_on, top_black_on, left_green_on, right_green_on;
    wire upper_green__on, upper_yellow_on, lower_yellow_on;
    wire home1_on, home2_on, home3_on, home4_on, home5_on;      // all homes blue
    wire wall1_on, wall2_on, wall3_on, wall4_on;                // all walls green
    wire street_on, water_on;
    
    // Drivers for Status Signals
    assign bottom_green_on  = ((x >= 0)   && (x < 640)   &&  (y >= 452) && (y < 480));
    assign top_black_on = ((x >= 0)  && (x < 640)  &&  (y >= 0) && (y < 32));
    assign left_green_on   = ((x >= 0) && (x < 32)  &&  (y >= 32) && (y < 452));
    assign right_green_on  = ((x >= 608) && (x < 640)  &&  (y >= 32) && (y < 452));
    assign upper_green_on = ((x >= 32) && (x < 608)  &&  (y >= 32) && (y < 36));
    assign upper_yellow_on    = ((x >= 32) && (x < 608)  &&  (y >= 228) && (y < 260));
    assign lower_yellow_on   = ((x >= 32) && (x < 608)  &&  (y >= 420) && (y < 452));
    assign home1_on = ((x >= 32)   && (x < 96)   &&  (y >= 36) && (y < 68));
    assign wall1_on  = ((x >= 96) && (x < 160)  && (y >= 36) && (y < 68));
    assign home2_on = ((x >= 160) && (x < 224)  &&  (y >= 36) && (y < 68));
    assign wall2_on  = ((x >= 224) && (x < 288)  && (y >= 36) && (y < 68));
    assign home3_on = ((x >= 288) && (x < 352)  &&   (y >= 36) && (y < 68));
    assign wall3_on  = ((x >= 352) && (x < 416)  && (y >= 36) && (y < 68));
    assign home4_on = ((x >= 416) && (x < 480)  &&  (y >= 36) && (y < 68));
    assign wall4_on  = ((x >= 480) && (x < 544)  && (y >= 36) && (y < 68));
    assign home5_on = ((x >= 544) && (x < 608)  &&  (y >= 36) && (y < 68));    
    assign street_on = ((x >= 32) && (x < 608)  && (y >= 260) && (y < 420));
    assign water_on = ((x >= 32) && (x < 608)  &&  (y >= 68) && (y < 228));
    
    // Set RGB output value based on status signals
    always @*
        if(~video_on)
            rgb = BLACK;
        else
            if(bottom_green_on)
                rgb = GREEN;
            else if(top_black_on)
                rgb = BLACK;
            else if(left_green_on)
                rgb = GREEN;
            else if(right_green_on)
                rgb = GREEN;
            else if(upper_green_on)
                rgb = GREEN;
            else if(upper_yellow_on)
                rgb = YELLOW;
            else if(lower_yellow_on)
                rgb = YELLOW;
            else if(home1_on)
                rgb = BLUE;
            else if(home2_on)
                rgb = BLUE;
            else if(home3_on)
                rgb = BLUE;
            else if(home4_on)
                rgb = BLUE;
            else if(home5_on)
                rgb = BLUE;
            else if(wall1_on)
                rgb = GREEN;
            else if(wall2_on)
                rgb = GREEN;
            else if(wall3_on)
                rgb = GREEN;
            else if(wall4_on)
                rgb = GREEN;
            else if(street_on)
                rgb = BLACK;
            else if(water_on)
                rgb = BLUE;
   
endmodule
