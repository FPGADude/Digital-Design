`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on April 18, 2022
//
// Edited on April 20, 2022 --> added decimal points on 7-Segment Display to 
//                              separate each two digit value.
//
//////////////////////////////////////////////////////////////////////////////////

module seg_display_driver(
    input clk_100MHz,
    input reset,
    input [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s,
    output reg [0:6] seg,       // segment pattern 0-9
    output reg dp,              // decimal point
    output reg [7:0] digit      // digit select signals
    );

    // Parameters for segment patterns
    parameter ZERO  = 7'b000_0001;  // 0
    parameter ONE   = 7'b100_1111;  // 1
    parameter TWO   = 7'b001_0010;  // 2 
    parameter THREE = 7'b000_0110;  // 3
    parameter FOUR  = 7'b100_1100;  // 4
    parameter FIVE  = 7'b010_0100;  // 5
    parameter SIX   = 7'b010_0000;  // 6
    parameter SEVEN = 7'b000_1111;  // 7
    parameter EIGHT = 7'b000_0000;  // 8
    parameter NINE  = 7'b000_0100;  // 9
    
    // To select each digit in turn
    reg [2:0] digit_select;     // 3 bit counter for selecting each of 8 digits
    reg [16:0] digit_timer;     // counter for digit refresh
    
    // Logic for controlling digit select and digit timer
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            digit_select <= 0;
            digit_timer <= 0; 
        end
        else                                        // 1/1000 = 1ms x 4 displays = 4ms refresh period
            if(digit_timer == 99_999) begin       // 100MHz / 100,000 = 1000 : each display on for 1ms
                digit_timer <= 0;
                digit_select <=  digit_select + 1;
            end
            else
                digit_timer <=  digit_timer + 1;
    end
    
    // Logic for driving the 8 bit anode output based on digit select
    always @(digit_select) begin
        case(digit_select) 
            3'b000 : digit = 8'b11111110;   // 1/100th of second ones  
            3'b001 : digit = 8'b11111101;   // 1/100th of second tens   
            3'b010 : digit = 8'b11111011;   // second ones
            3'b011 : digit = 8'b11110111;   // second tens          
            3'b100 : digit = 8'b11101111;   // minute ones       
            3'b101 : digit = 8'b11011111;   // minute tens             
            3'b110 : digit = 8'b10111111;   // hours ones     
            3'b111 : digit = 8'b01111111;   // hours tens     
        endcase
    end
    
    // Logic for driving segments based on which digit is selected and the value of each digit
    // Added drivers for the decimal point to appear on some digits
    always @*
        case(digit_select)
            3'b000 : begin       // 1/100 of Seconds 1s DIGIT
                        dp = 1'b1;
                        case(sec100_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b001 : begin       // 1/100 of Seconds 10s DIGIT
                        dp = 1'b1;
                        case(sec100_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b010 : begin       // Seconds 1s DIGIT
                        dp = 1'b0;
                        case(sec_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b011 : begin       // Seconds 10s DIGIT
                        dp = 1'b1;
                        case(sec_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
           3'b100 : begin       // Minute 1s DIGIT
                        dp = 1'b0;
                        case(min_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b101 : begin       // Minute 10s DIGIT
                        dp = 1'b1;
                        case(min_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b110 : begin       // Hour 1s DIGIT
                        dp = 1'b0;
                        case(hr_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b111 : begin       // Hour 10s DIGIT
                        dp = 1'b1;
                        case(hr_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end 
        endcase   
  
endmodule
