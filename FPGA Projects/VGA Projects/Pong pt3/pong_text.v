`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference book: "FPGA Prototyping by Verilog Examples"
//                      "Xilinx Spartan-3 Version"
// Written by: Dr. Pong P. Chu
// Published by: Wiley, 2008
//
// Adapted for Basys 3 by David J. Marion aka FPGA Dude
//
//////////////////////////////////////////////////////////////////////////////////


module pong_text(
    input clk,
    input [1:0] ball,
    input [3:0] dig0, dig1,
    input [9:0] x, y,
    output [3:0] text_on,
    output reg [11:0] text_rgb
    );
    
    // signal declaration
    wire [10:0] rom_addr;
    reg [6:0] char_addr, char_addr_s, char_addr_l, char_addr_r, char_addr_o;
    reg [3:0] row_addr;
    wire [3:0] row_addr_s, row_addr_l, row_addr_r, row_addr_o;
    reg [2:0] bit_addr;
    wire [2:0] bit_addr_s, bit_addr_l, bit_addr_r, bit_addr_o;
    wire [7:0] ascii_word;
    wire ascii_bit, score_on, logo_on, rule_on, over_on;
    wire [7:0] rule_rom_addr;
    
   // instantiate ascii rom
   ascii_rom ascii_unit(.clk(clk), .addr(rom_addr), .data(ascii_word));
   
   // ---------------------------------------------------------------------------
   // score region
   // - display two-digit score and ball # on top left
   // - scale to 16 by 32 text size
   // - line 1, 16 chars: "Score: dd Ball: d"
   // ---------------------------------------------------------------------------
   assign score_on = (y >= 32) && (y < 64) && (x[9:4] < 16);
   //assign score_on = (y[9:5] == 0) && (x[9:4] < 16);
   assign row_addr_s = y[4:1];
   assign bit_addr_s = x[3:1];
   always @*
    case(x[7:4])
        4'h0 : char_addr_s = 7'h53;     // S
        4'h1 : char_addr_s = 7'h43;     // C
        4'h2 : char_addr_s = 7'h4F;     // O
        4'h3 : char_addr_s = 7'h52;     // R
        4'h4 : char_addr_s = 7'h45;     // E
        4'h5 : char_addr_s = 7'h3A;     // :
        4'h6 : char_addr_s = {3'b011, dig1};    // tens digit
        4'h7 : char_addr_s = {3'b011, dig0};    // ones digit
        4'h8 : char_addr_s = 7'h00;     //
        4'h9 : char_addr_s = 7'h00;     //
        4'hA : char_addr_s = 7'h42;     // B
        4'hB : char_addr_s = 7'h41;     // A
        4'hC : char_addr_s = 7'h4c;     // L
        4'hD : char_addr_s = 7'h4c;     // L
        4'hE : char_addr_s = 7'h3A;     // :
        4'hF : char_addr_s = {5'b01100, ball};
    endcase
    
    // --------------------------------------------------------------------------
    // logo region
    // - display logo "PONG" at top center
    // - used as background
    // - scale to 64 by 128 text size
    // --------------------------------------------------------------------------
    assign logo_on = (y[9:7] == 2) && (3 <= x[9:6]) && (x[9:6] <= 6);
    assign row_addr_l = y[6:3];
    assign bit_addr_l = x[5:3];
    always @*
        case(x[8:6])
            3'o3 :    char_addr_l = 7'h50; // P
            3'o4 :    char_addr_l = 7'h4F; // O
            3'o5 :    char_addr_l = 7'h4E; // N
            default : char_addr_l = 7'h47; // G
        endcase
    
    // --------------------------------------------------------------------------
    // rule region
    // - display rule (4 by 16 tiles) on center
    // - rule text:
    //      Rule:
    //          Use two buttons
    //          to move paddle
    //          up and down
    // --------------------------------------------------------------------------
    assign rule_on = (x[9:7] == 2) && (y[9:6] == 2);
    assign row_addr_r = y[3:0];
    assign bit_addr_r = x[2:0];
    assign rule_rom_addr = {y[5:4], x[6:3]};
    always @*
        case(rule_rom_addr)
            // row 1
            6'h00 : char_addr_r = 7'h52;    // R
            6'h01 : char_addr_r = 7'h55;    // U
            6'h02 : char_addr_r = 7'h4c;    // L
            6'h03 : char_addr_r = 7'h45;    // E
            6'h04 : char_addr_r = 7'h3A;    // :
            6'h05 : char_addr_r = 7'h00;    //
            6'h06 : char_addr_r = 7'h00;    //
            6'h07 : char_addr_r = 7'h00;    //
            6'h08 : char_addr_r = 7'h00;    //
            6'h09 : char_addr_r = 7'h00;    //
            6'h0A : char_addr_r = 7'h00;    //
            6'h0B : char_addr_r = 7'h00;    //
            6'h0C : char_addr_r = 7'h00;    //
            6'h0D : char_addr_r = 7'h00;    //
            6'h0E : char_addr_r = 7'h00;    //
            6'h0F : char_addr_r = 7'h00;    //
            // row 2
            6'h10 : char_addr_r = 7'h55;    // U
            6'h11 : char_addr_r = 7'h53;    // S
            6'h12 : char_addr_r = 7'h45;    // E
            6'h13 : char_addr_r = 7'h00;    // 
            6'h14 : char_addr_r = 7'h54;    // T
            6'h15 : char_addr_r = 7'h57;    // W
            6'h16 : char_addr_r = 7'h4F;    // O
            6'h17 : char_addr_r = 7'h00;    //
            6'h18 : char_addr_r = 7'h42;    // B
            6'h19 : char_addr_r = 7'h55;    // U
            6'h1A : char_addr_r = 7'h54;    // T
            6'h1B : char_addr_r = 7'h54;    // T
            6'h1C : char_addr_r = 7'h4F;    // O
            6'h1D : char_addr_r = 7'h4E;    // N
            6'h1E : char_addr_r = 7'h53;    // S
            6'h1F : char_addr_r = 7'h00;    //
            // row 3
            6'h20 : char_addr_r = 7'h54;    // T
            6'h21 : char_addr_r = 7'h4F;    // O
            6'h22 : char_addr_r = 7'h00;    // 
            6'h23 : char_addr_r = 7'h4D;    // M
            6'h24 : char_addr_r = 7'h4F;    // O
            6'h25 : char_addr_r = 7'h56;    // V
            6'h26 : char_addr_r = 7'h45;    // E
            6'h27 : char_addr_r = 7'h00;    //
            6'h28 : char_addr_r = 7'h50;    // P
            6'h29 : char_addr_r = 7'h41;    // A
            6'h2A : char_addr_r = 7'h44;    // D
            6'h2B : char_addr_r = 7'h44;    // D
            6'h2C : char_addr_r = 7'h4C;    // L
            6'h2D : char_addr_r = 7'h45;    // E
            6'h2E : char_addr_r = 7'h00;    // 
            6'h2F : char_addr_r = 7'h00;    //
            // row 4
            6'h30 : char_addr_r = 7'h55;    // U
            6'h31 : char_addr_r = 7'h50;    // P
            6'h32 : char_addr_r = 7'h00;    // 
            6'h33 : char_addr_r = 7'h41;    // A
            6'h34 : char_addr_r = 7'h4E;    // N
            6'h35 : char_addr_r = 7'h44;    // D
            6'h36 : char_addr_r = 7'h00;    // 
            6'h37 : char_addr_r = 7'h44;    // D
            6'h38 : char_addr_r = 7'h4F;    // O
            6'h39 : char_addr_r = 7'h57;    // W
            6'h3A : char_addr_r = 7'h4E;    // N
            6'h3B : char_addr_r = 7'h2E;    // 
            6'h3C : char_addr_r = 7'h00;    // 
            6'h3D : char_addr_r = 7'h00;    // 
            6'h3E : char_addr_r = 7'h00;    // 
            6'h3F : char_addr_r = 7'h00;    //
        endcase
    // --------------------------------------------------------------------------
    // game over region
    // - display "GAME OVER" at center
    // - scale to 32 by 64 text size
    // --------------------------------------------------------------------------
    assign over_on = (y[9:6] == 3) && (5 <= x[9:5]) && (x[9:5] <= 13);
    assign row_addr_o = y[5:2];
    assign bit_addr_o = x[4:2];
    always @*
        case(x[8:5])
            4'h5 : char_addr_o = 7'h47;     // G
            4'h6 : char_addr_o = 7'h41;     // A
            4'h7 : char_addr_o = 7'h4D;     // M
            4'h8 : char_addr_o = 7'h45;     // E
            4'h9 : char_addr_o = 7'h00;     //
            4'hA : char_addr_o = 7'h4F;     // O
            4'hB : char_addr_o = 7'h56;     // V
            4'hC : char_addr_o = 7'h45;     // E
            default : char_addr_o = 7'h52;  // R
        endcase
    
    // mux for ascii ROM addresses and rgb
    always @* begin
        text_rgb = 12'h0FF;     // aqua background
        
        if(score_on) begin
            char_addr = char_addr_s;
            row_addr = row_addr_s;
            bit_addr = bit_addr_s;
            if(ascii_bit)
                text_rgb = 12'hF00; // red
        end
        
        else if(rule_on) begin
            char_addr = char_addr_r;
            row_addr = row_addr_r;
            bit_addr = bit_addr_r;
            if(ascii_bit)
                text_rgb = 12'hF00; // red
        end
        
        else if(logo_on) begin
            char_addr = char_addr_l;
            row_addr = row_addr_l;
            bit_addr = bit_addr_l;
            if(ascii_bit)
                text_rgb = 12'hFF0; // yellow
        end
        
        else begin // game over
            char_addr = char_addr_o;
            row_addr = row_addr_o;
            bit_addr = bit_addr_o;
            if(ascii_bit)
                text_rgb = 12'hF00; // red
        end        
    end
    
    assign text_on = {score_on, logo_on, rule_on, over_on};
    
    // ascii ROM interface
    assign rom_addr = {char_addr, row_addr};
    assign ascii_bit = ascii_word[~bit_addr];
      
endmodule
