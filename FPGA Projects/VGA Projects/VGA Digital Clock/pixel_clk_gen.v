`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/11/2022
//
// Purpose: receive clock BCD values, write clock on VGA screen
///////////////////////////////////////////////////////////////////////

module pixel_clk_gen(
    input clk,
    input video_on,
    //input tick_1Hz,       // use signal if blinking colon(s) is desired
    input [9:0] x, y,
    input [3:0] sec_1s, sec_10s,
    input [3:0] min_1s, min_10s,
    input [3:0] hr_1s, hr_10s,
    output reg [11:0] time_rgb
    );
  
    // *** Constant Declarations ***
    // Hour 10s Digit section = 32 x 64
    localparam H10_X_L = 192;
    localparam H10_X_R = 223;
    localparam H10_Y_T = 192;
    localparam H10_Y_B = 256;
    
    // Hour 1s Digit section = 32 x 64
    localparam H1_X_L = 224;
    localparam H1_X_R = 255;
    localparam H1_Y_T = 192;
    localparam H1_Y_B = 256;
    
    // Colon 1 section = 32 x 64
    localparam C1_X_L = 256;
    localparam C1_X_R = 287;
    localparam C1_Y_T = 192;
    localparam C1_Y_B = 256;
    
    // Minute 10s Digit section = 32 x 64
    localparam M10_X_L = 288;
    localparam M10_X_R = 319;
    localparam M10_Y_T = 192;
    localparam M10_Y_B = 256;
    
    // Minute 1s Digit section = 32 x 64
    localparam M1_X_L = 320;
    localparam M1_X_R = 351;
    localparam M1_Y_T = 192;
    localparam M1_Y_B = 256;
    
    // Colon 2 section = 32 x 64
    localparam C2_X_L = 352;
    localparam C2_X_R = 383;
    localparam C2_Y_T = 192;
    localparam C2_Y_B = 256;
    
    // Second 10s Digit section = 32 x 64
    localparam S10_X_L = 384;
    localparam S10_X_R = 415;
    localparam S10_Y_T = 192;
    localparam S10_Y_B = 256;
    
    // Second 1s Digit section = 32 x 64
    localparam S1_X_L = 416;
    localparam S1_X_R = 447;
    localparam S1_Y_T = 192;
    localparam S1_Y_B = 256;
    
    // Object Status Signals
    wire H10_on, H1_on, C1_on, M10_on, M1_on, C2_on, S10_on, S1_on;
    
    // ROM Interface Signals
    wire [10:0] rom_addr;
    reg [6:0] char_addr;   // 3'b011 + BCD value of time component
    wire [6:0] char_addr_h10, char_addr_h1, char_addr_m10, char_addr_m1, char_addr_s10, char_addr_s1, char_addr_c1, char_addr_c2;
    reg [3:0] row_addr;    // row address of digit
    wire [3:0] row_addr_h10, row_addr_h1, row_addr_m10, row_addr_m1, row_addr_s10, row_addr_s1, row_addr_c1, row_addr_c2;
    reg [2:0] bit_addr;    // column address of rom data
    wire [2:0] bit_addr_h10, bit_addr_h1, bit_addr_m10, bit_addr_m1, bit_addr_s10, bit_addr_s1, bit_addr_c1, bit_addr_c2;
    wire [7:0] digit_word;  // data from rom
    wire digit_bit;
    
    
    assign char_addr_h10 = {3'b011, hr_10s};
    assign row_addr_h10 = y[5:2];   // scaling to 32x64
    assign bit_addr_h10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_h1 = {3'b011, hr_1s};
    assign row_addr_h1 = y[5:2];   // scaling to 32x64
    assign bit_addr_h1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_c1 = 7'h3a;
    assign row_addr_c1 = y[5:2];    // scaling to 32x64
    assign bit_addr_c1 = x[4:2];    // scaling to 32x64
    
    assign char_addr_m10 = {3'b011, min_10s};
    assign row_addr_m10 = y[5:2];   // scaling to 32x64
    assign bit_addr_m10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_m1 = {3'b011, min_1s};
    assign row_addr_m1 = y[5:2];   // scaling to 32x64
    assign bit_addr_m1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_c2 = 7'h3a;
    assign row_addr_c2 = y[5:2];    // scaling to 32x64
    assign bit_addr_c2 = x[4:2];    // scaling to 32x64
    
    assign char_addr_s10 = {3'b011, sec_10s};
    assign row_addr_s10 = y[5:2];   // scaling to 32x64
    assign bit_addr_s10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_s1 = {3'b011, sec_1s};
    assign row_addr_s1 = y[5:2];   // scaling to 32x64
    assign bit_addr_s1 = x[4:2];   // scaling to 32x64
    
    // Instantiate digit rom
    clock_digit_rom cdr(.clk(clk), .addr(rom_addr), .data(digit_word));
    
    // Hour sections assert signals
    assign H10_on = (H10_X_L <= x) && (x <= H10_X_R) &&
                    (H10_Y_T <= y) && (y <= H10_Y_B) && (hr_10s != 0); // turn off digit if hours 10s = 1-9
    assign H1_on =  (H1_X_L <= x) && (x <= H1_X_R) &&
                    (H1_Y_T <= y) && (y <= H1_Y_B);
    
    // Colon 1 ROM assert signals
    assign C1_on = (C1_X_L <= x) && (x <= C1_X_R) &&
                   (C1_Y_T <= y) && (y <= C1_Y_B);
                               
    // Minute sections assert signals
    assign M10_on = (M10_X_L <= x) && (x <= M10_X_R) &&
                    (M10_Y_T <= y) && (y <= M10_Y_B);
    assign M1_on =  (M1_X_L <= x) && (x <= M1_X_R) &&
                    (M1_Y_T <= y) && (y <= M1_Y_B);                             
    
    // Colon 2 ROM assert signals
    assign C2_on = (C2_X_L <= x) && (x <= C2_X_R) &&
                   (C2_Y_T <= y) && (y <= C2_Y_B);
                  
    // Second sections assert signals
    assign S10_on = (S10_X_L <= x) && (x <= S10_X_R) &&
                    (S10_Y_T <= y) && (y <= S10_Y_B);
    assign S1_on =  (S1_X_L <= x) && (x <= S1_X_R) &&
                    (S1_Y_T <= y) && (y <= S1_Y_B);
                          
        
    // Mux for ROM Addresses and RGB    
    always @* begin
        time_rgb = 12'h222;             // black background
        if(H10_on) begin
            char_addr = char_addr_h10;
            row_addr = row_addr_h10;
            bit_addr = bit_addr_h10;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(H1_on) begin
            char_addr = char_addr_h1;
            row_addr = row_addr_h1;
            bit_addr = bit_addr_h1;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(C1_on) begin
            char_addr = char_addr_c1;
            row_addr = row_addr_c1;
            bit_addr = bit_addr_c1;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(M10_on) begin
            char_addr = char_addr_m10;
            row_addr = row_addr_m10;
            bit_addr = bit_addr_m10;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(M1_on) begin
            char_addr = char_addr_m1;
            row_addr = row_addr_m1;
            bit_addr = bit_addr_m1;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(C2_on) begin
            char_addr = char_addr_c2;
            row_addr = row_addr_c2;
            bit_addr = bit_addr_c2;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(S10_on) begin
            char_addr = char_addr_s10;
            row_addr = row_addr_s10;
            bit_addr = bit_addr_s10;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end
        else if(S1_on) begin
            char_addr = char_addr_s1;
            row_addr = row_addr_s1;
            bit_addr = bit_addr_s1;
            if(digit_bit)
                time_rgb = 12'hF00;     // red
        end  
    end    
    
    // ROM Interface    
    assign rom_addr = {char_addr, row_addr};
    assign digit_bit = digit_word[~bit_addr];    
                          
endmodule
