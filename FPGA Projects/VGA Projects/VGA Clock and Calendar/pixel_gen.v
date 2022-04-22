`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/13/2022
//
// Purpose: receive clock and calendar BCD values, write clock and
// calendar on VGA screen
///////////////////////////////////////////////////////////////////////

module pixel_gen(
    input clk,
    input video_on,
    //input tick_1Hz,       // use signal if blinking colon(s) is desired
    input [9:0] x, y,
    input [3:0] sec_1s, sec_10s,
    input [3:0] min_1s, min_10s,
    input [3:0] hr_1s, hr_10s,
    input am_pm,
    input [3:0] m_10s, m_1s,
    input [3:0] d_10s, d_1s,
    input [3:0] y_10s, y_1s,
    input [3:0] c_10s, c_1s,
    output reg [11:0] rgb
    );
  
    // *** Constant Declarations for Clock ***
    // Hour 10s Digit section = 32 x 64         
    localparam H10_X_L = 160;                   
    localparam H10_X_R = 191;                   
    localparam H10_Y_T = 192;                   
    localparam H10_Y_B = 256;                   
   
    // Hour 1s Digit section = 32 x 64          
    localparam H1_X_L = 192;                    
    localparam H1_X_R = 223;                    
    localparam H1_Y_T = 192;                    
    localparam H1_Y_B = 256;                    
   
    // Colon 1 section = 32 x 64                
    localparam C1_X_L = 224;                    
    localparam C1_X_R = 255;                    
    localparam C1_Y_T = 192;                    
    localparam C1_Y_B = 256;                    
   
    // Minute 10s Digit section = 32 x 64       
    localparam M10_X_L = 256;                   
    localparam M10_X_R = 287;                   
    localparam M10_Y_T = 192;                   
    localparam M10_Y_B = 256;                   
   
    // Minute 1s Digit section = 32 x 64        
    localparam M1_X_L = 288;                    
    localparam M1_X_R = 319;                    
    localparam M1_Y_T = 192;                    
    localparam M1_Y_B = 256;                    
   
    // Colon 2 section = 32 x 64                
    localparam C2_X_L = 320;                    
    localparam C2_X_R = 351;                    
    localparam C2_Y_T = 192;                    
    localparam C2_Y_B = 256;                    
   
    // Second 10s Digit section = 32 x 64       
    localparam S10_X_L = 352;                   
    localparam S10_X_R = 383;                   
    localparam S10_Y_T = 192;                   
    localparam S10_Y_B = 256;                   
   
    // Second 1s Digit section = 32 x 64        
    localparam S1_X_L = 384;                    
    localparam S1_X_R = 415;                    
    localparam S1_Y_T = 192;                    
    localparam S1_Y_B = 256;                    
   
    // A or P Digit section = 32 x 64           
    localparam AP_X_L = 416;                    
    localparam AP_X_R = 447;                    
    localparam AP_Y_T = 192;                    
    localparam AP_Y_B = 256;                    
   
    // M Digit section = 32 x 64                
    localparam APM_X_L = 448;                   
    localparam APM_X_R = 479;                   
    localparam APM_Y_T = 192;                   
    localparam APM_Y_B = 256;                   
    
    // *** Constant Declarations for Calendar ***
    // Month 10s Digit section = 32 x 64
    localparam Mo10_X_L = 160;
    localparam Mo10_X_R = 191;
    localparam Mo10_Y_T = 257;
    localparam Mo10_Y_B = 320;
    
    // Month 1s Digit section = 32 x 64
    localparam Mo1_X_L = 192;
    localparam Mo1_X_R = 223;
    localparam Mo1_Y_T = 257;
    localparam Mo1_Y_B = 320;
    
    // Period 1 section = 32 x 64
    localparam P1_X_L = 224;
    localparam P1_X_R = 255;
    localparam P1_Y_T = 257;
    localparam P1_Y_B = 320;
    
    // Day 10s Digit section = 32 x 64
    localparam D10_X_L = 256;
    localparam D10_X_R = 287;
    localparam D10_Y_T = 257;
    localparam D10_Y_B = 320;
    
    // Day 1s Digit section = 32 x 64
    localparam D1_X_L = 288;
    localparam D1_X_R = 319;
    localparam D1_Y_T = 257;
    localparam D1_Y_B = 320;
    
    // Period 2 section = 32 x 64
    localparam P2_X_L = 320;
    localparam P2_X_R = 351;
    localparam P2_Y_T = 257;
    localparam P2_Y_B = 320;
    
    // Century 10s Digit section = 32 x 64
    localparam Ce10_X_L = 352;
    localparam Ce10_X_R = 383;
    localparam Ce10_Y_T = 257;
    localparam Ce10_Y_B = 320;
    
    // Century 1s Digit section = 32 x 64
    localparam Ce1_X_L = 384;
    localparam Ce1_X_R = 415;
    localparam Ce1_Y_T = 257;
    localparam Ce1_Y_B = 320;
    
    // Year 10s Digit section = 32 x 64
    localparam Y10_X_L = 416;
    localparam Y10_X_R = 447;
    localparam Y10_Y_T = 257;
    localparam Y10_Y_B = 320;
    
    // Year 1s Digit section = 32 x 64
    localparam Y1_X_L = 448;
    localparam Y1_X_R = 479;
    localparam Y1_Y_T = 257;
    localparam Y1_Y_B = 320;
    
    
    
    // Object Status Signals for Clock
    wire H10_on, H1_on, C1_on, M10_on, M1_on, C2_on, S10_on, S1_on, AP_on, APM_on;
    // Object Status Signals for Calendar
    wire Mo10_on, Mo1_on, P1_on, D10_on, D1_on, P2_on, Ce10_on, Ce1_on, Y10_on, Y1_on;
    
    // ROM Interface Signals
    wire [10:0] rom_addr;
    reg [6:0] char_addr;   // 3'b011 + BCD value of time component
    wire [6:0] char_addr_h10, char_addr_h1, char_addr_m10, char_addr_m1, char_addr_s10, char_addr_s1, char_addr_c1, char_addr_c2;
    wire [6:0] char_addr_mo10, char_addr_mo1, char_addr_d10, char_addr_d1, char_addr_ce10, char_addr_ce1, char_addr_y10, char_addr_y1;
    wire [6:0] char_addr_p1, char_addr_p2, char_addr_ap, char_addr_apm;
    reg [3:0] row_addr;    // row address of digit
    wire [3:0] row_addr_h10, row_addr_h1, row_addr_m10, row_addr_m1, row_addr_s10, row_addr_s1, row_addr_c1, row_addr_c2;
    wire [3:0] row_addr_mo10, row_addr_mo1, row_addr_d10, row_addr_d1, row_addr_ce10, row_addr_ce1, row_addr_y10, row_addr_y1;
    wire [3:0] row_addr_p1, row_addr_p2, row_addr_ap, row_addr_apm; 
    reg [2:0] bit_addr;    // column address of rom data
    wire [2:0] bit_addr_h10, bit_addr_h1, bit_addr_m10, bit_addr_m1, bit_addr_s10, bit_addr_s1, bit_addr_c1, bit_addr_c2;
    wire [2:0] bit_addr_mo10, bit_addr_mo1, bit_addr_d10, bit_addr_d1, bit_addr_ce10, bit_addr_ce1, bit_addr_y10, bit_addr_y1;
    wire [2:0] bit_addr_p1, bit_addr_p2, bit_addr_ap, bit_addr_apm;
    wire [7:0] digit_word;  // data from rom
    wire digit_bit;
    
    
    // Clock
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
    
    assign char_addr_ap = {3'b100, 3'b000, am_pm};
    assign row_addr_ap = y[5:2];    // scaling to 32x64
    assign bit_addr_ap = x[4:2];    // scaling to 32x64
    
    assign char_addr_apm = 7'h4d;   // M
    assign row_addr_apm = y[5:2];   // scaling to 32x64
    assign bit_addr_apm = x[4:2];   // scaling to 32x64
    
    
    // Calendar
    assign char_addr_mo10 = {3'b011, m_10s};
    assign row_addr_mo10 = y[5:2];   // scaling to 32x64
    assign bit_addr_mo10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_mo1 = {3'b011, m_1s};
    assign row_addr_mo1 = y[5:2];   // scaling to 32x64
    assign bit_addr_mo1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_p1 = 7'h2e;
    assign row_addr_p1 = y[5:2];    // scaling to 32x64
    assign bit_addr_p1 = x[4:2];    // scaling to 32x64
    
    assign char_addr_d10 = {3'b011, d_10s};
    assign row_addr_d10 = y[5:2];   // scaling to 32x64
    assign bit_addr_d10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_d1 = {3'b011, d_1s};
    assign row_addr_d1 = y[5:2];   // scaling to 32x64
    assign bit_addr_d1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_p2 = 7'h2e;
    assign row_addr_p2 = y[5:2];    // scaling to 32x64
    assign bit_addr_p2 = x[4:2];    // scaling to 32x64
    
    assign char_addr_ce10 = {3'b011, c_10s};
    assign row_addr_ce10 = y[5:2];   // scaling to 32x64
    assign bit_addr_ce10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_ce1 = {3'b011, c_1s};
    assign row_addr_ce1 = y[5:2];   // scaling to 32x64
    assign bit_addr_ce1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_y10 = {3'b011, y_10s};
    assign row_addr_y10 = y[5:2];   // scaling to 32x64 
    assign bit_addr_y10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_y1 = {3'b011, y_1s};
    assign row_addr_y1 = y[5:2];    // scaling to 32x64
    assign bit_addr_y1 = x[4:2];    // scaling to 32x64
    
    
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
                          
    // AM / PM sections assert signals
    assign AP_on = (AP_X_L <= x) && (x <= AP_X_R) &&
                   (AP_Y_T <= y) && (y <= AP_Y_B);
    assign APM_on = (APM_X_L <= x) && (x <= APM_X_R) &&
                    (APM_Y_T <= y) && (y <= APM_Y_B);
        
        
        
    // Month sections assert signals
    assign Mo10_on = (Mo10_X_L <= x) && (x <= Mo10_X_R) &&
                     (Mo10_Y_T <= y) && (y <= Mo10_Y_B) && (m_10s != 0); // turn off digit if month 10s = 1-9
    assign Mo1_on =  (Mo1_X_L <= x) &&  (x <= Mo1_X_R) &&
                     (Mo1_Y_T <= y) &&  (y <= Mo1_Y_B);
    
    // Period 1 ROM assert signals
    assign P1_on = (P1_X_L <= x) && (x <= P1_X_R) &&
                   (P1_Y_T <= y) && (y <= P1_Y_B);
                               
    // Day sections assert signals
    assign D10_on = (D10_X_L <= x) && (x <= D10_X_R) &&
                    (D10_Y_T <= y) && (y <= D10_Y_B);
    assign D1_on =  (D1_X_L <= x) &&  (x <= D1_X_R) &&
                    (D1_Y_T <= y) &&  (y <= D1_Y_B);                             
    
    // Period 2 ROM assert signals
    assign P2_on = (P2_X_L <= x) && (x <= P2_X_R) &&
                   (P2_Y_T <= y) && (y <= P2_Y_B);
                  
    // Century sections assert signals
    assign Ce10_on = (Ce10_X_L <= x) && (x <= Ce10_X_R) &&
                     (Ce10_Y_T <= y) && (y <= Ce10_Y_B);
    assign Ce1_on =  (Ce1_X_L <= x) &&  (x <= Ce1_X_R) &&
                     (Ce1_Y_T <= y) &&  (y <= Ce1_Y_B);
                          
    // Year sections assert signals
    assign Y10_on = (Y10_X_L <= x) && (x <= Y10_X_R) &&
                    (Y10_Y_T <= y) && (y <= Y10_Y_B);
    assign Y1_on =  (Y1_X_L <= x) && (x <= Y1_X_R) &&
                    (Y1_Y_T <= y) && (y <= Y1_Y_B);    
           
        
        
    // Mux for ROM Addresses and RGB    
    always @* begin
        if(~video_on)
            rgb = 12'h0;            // blank
        else begin
            rgb = 12'h777;          // gray background
            if(H10_on) begin
                char_addr = char_addr_h10;
                row_addr = row_addr_h10;
                bit_addr = bit_addr_h10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(H1_on) begin
                char_addr = char_addr_h1;
                row_addr = row_addr_h1;
                bit_addr = bit_addr_h1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(C1_on) begin
                char_addr = char_addr_c1;
                row_addr = row_addr_c1;
                bit_addr = bit_addr_c1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(M10_on) begin
                char_addr = char_addr_m10;
                row_addr = row_addr_m10;
                bit_addr = bit_addr_m10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(M1_on) begin
                char_addr = char_addr_m1;
                row_addr = row_addr_m1;
                bit_addr = bit_addr_m1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(C2_on) begin
                char_addr = char_addr_c2;
                row_addr = row_addr_c2;
                bit_addr = bit_addr_c2;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(S10_on) begin
                char_addr = char_addr_s10;
                row_addr = row_addr_s10;
                bit_addr = bit_addr_s10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(S1_on) begin
                char_addr = char_addr_s1;
                row_addr = row_addr_s1;
                bit_addr = bit_addr_s1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end  
            else if(AP_on) begin
                char_addr = char_addr_ap;
                row_addr = row_addr_ap;
                bit_addr = bit_addr_ap;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(APM_on) begin
                char_addr = char_addr_apm;
                row_addr = row_addr_apm;
                bit_addr = bit_addr_apm;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            
            else if(Mo10_on) begin
                char_addr = char_addr_mo10;
                row_addr = row_addr_mo10;
                bit_addr = bit_addr_mo10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Mo1_on) begin
                char_addr = char_addr_mo1;
                row_addr = row_addr_mo1;
                bit_addr = bit_addr_mo1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(P1_on) begin
                char_addr = char_addr_p1;
                row_addr = row_addr_p1;
                bit_addr = bit_addr_p1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(D10_on) begin
                char_addr = char_addr_d10;
                row_addr = row_addr_d10;
                bit_addr = bit_addr_d10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(D1_on) begin
                char_addr = char_addr_d1;
                row_addr = row_addr_d1;
                bit_addr = bit_addr_d1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(P2_on) begin
                char_addr = char_addr_p2;
                row_addr = row_addr_p2;
                bit_addr = bit_addr_p2;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Ce10_on) begin
                char_addr = char_addr_ce10;
                row_addr = row_addr_ce10;
                bit_addr = bit_addr_ce10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Ce1_on) begin
                char_addr = char_addr_ce1;
                row_addr = row_addr_ce1;
                bit_addr = bit_addr_ce1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end  
            else if(Y10_on) begin
                char_addr = char_addr_y10;
                row_addr = row_addr_y10;
                bit_addr = bit_addr_y10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Y1_on) begin
                char_addr = char_addr_y1;
                row_addr = row_addr_y1;
                bit_addr = bit_addr_y1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end 
        end
    end    
    
    // ROM Interface    
    assign rom_addr = {char_addr, row_addr};
    assign digit_bit = digit_word[~bit_addr];    
                          
endmodule
