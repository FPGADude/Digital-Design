`timescale 1ns / 1ps
// Created by David J. Marion
// Date 4.27.2023
// 7 Segment Control for the Basys 3 PmodTMP2 Temperature Sensor
module seg7(
    input clk_100MHz,               // Basys 3 clock
    input SW,                       // SW0 on Basys 3
    input [7:0] c_data,             // Celsius data from i2c master
    input [7:0] f_data,             // Fahrenheit data from temp converter
    output reg [0:6] SEG,           // 7 Segments of Displays
    output reg [3:0] AN             // 4 Anodes of 8 to display Temp
    );
    
    // Binary to BCD conversion of temperature data
    wire [3:0] c_tens, c_ones, f_tens, f_ones;
    assign c_tens = c_data / 10;            // tens value of celsius data
    assign c_ones = c_data % 10;            // ones value of celsius data
    assign f_tens = f_data / 10;            // tens value of fahrenheit data
    assign f_ones = f_data % 10;            // ones value of fahrenheit data
    
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
    parameter DEG   = 7'b001_1100;  // degrees symbol
    parameter C     = 7'b011_0001;  // C
    parameter F     = 7'b011_1000;  // F
    
    // To select each digit in turn
    reg [1:0] anode_select;         // 2 bit counter for selecting each of 4 digits
    reg [16:0] anode_timer;         // counter for digit refresh
    
    // Logic for controlling digit select and digit timer
    always @(posedge clk_100MHz) begin
        // 1ms x 4 displays = 4ms refresh period
        if(anode_timer == 99_999) begin         // The period of 100MHz clock is 10ns (1/100,000,000 seconds)
            anode_timer <= 0;                   // 10ns x 100,000 = 1ms
            anode_select <=  anode_select + 1;
        end
        else
            anode_timer <=  anode_timer + 1;
    end
    
    // Logic for driving the 4 bit anode output based on digit select
    always @(anode_select) begin
        case(anode_select) 
            2'b00 : AN = 4'b1110;   // Turn on ones digit
            2'b01 : AN = 4'b1101;   // Turn on tens digit
            2'b10 : AN = 4'b1011;   // Turn on hundreds digit
            2'b11 : AN = 4'b0111;   // Turn on thousands digit
        endcase
    end
    
    always @*
        case(anode_select)
            2'b00 : begin
                        if(SW)
                            SEG = F;    // Set to F for Fahrenheit
                        else
                            SEG = C;    // Set to C for Celsius    
            end      
                  
            2'b01 : SEG = DEG;          // Set to degrees symbol
                    
            2'b10 : begin               // TEMPERATURE ONES DIGIT
                        if(SW)
                            case(f_ones)
                                4'b0000 : SEG = ZERO;
                                4'b0001 : SEG = ONE;
                                4'b0010 : SEG = TWO;
                                4'b0011 : SEG = THREE;
                                4'b0100 : SEG = FOUR;
                                4'b0101 : SEG = FIVE;
                                4'b0110 : SEG = SIX;
                                4'b0111 : SEG = SEVEN;
                                4'b1000 : SEG = EIGHT;
                                4'b1001 : SEG = NINE;
                            endcase
                        else
                            case(c_ones)
                                4'b0000 : SEG = ZERO;
                                4'b0001 : SEG = ONE;
                                4'b0010 : SEG = TWO;
                                4'b0011 : SEG = THREE;
                                4'b0100 : SEG = FOUR;
                                4'b0101 : SEG = FIVE;
                                4'b0110 : SEG = SIX;
                                4'b0111 : SEG = SEVEN;
                                4'b1000 : SEG = EIGHT;
                                4'b1001 : SEG = NINE;
                            endcase
            end
                    
            2'b11 : begin       // TEMPERATURE TENS DIGIT
                        if(SW)
                            case(f_tens)
                                4'b0000 : SEG = ZERO;
                                4'b0001 : SEG = ONE;
                                4'b0010 : SEG = TWO;
                                4'b0011 : SEG = THREE;
                                4'b0100 : SEG = FOUR;
                                4'b0101 : SEG = FIVE;
                                4'b0110 : SEG = SIX;
                                4'b0111 : SEG = SEVEN;
                                4'b1000 : SEG = EIGHT;
                                4'b1001 : SEG = NINE;
                            endcase
                        else
                            case(c_tens)
                                4'b0000 : SEG = ZERO;
                                4'b0001 : SEG = ONE;
                                4'b0010 : SEG = TWO;
                                4'b0011 : SEG = THREE;
                                4'b0100 : SEG = FOUR;
                                4'b0101 : SEG = FIVE;
                                4'b0110 : SEG = SIX;
                                4'b0111 : SEG = SEVEN;
                                4'b1000 : SEG = EIGHT;
                                4'b1001 : SEG = NINE;
                            endcase 
            end
        endcase
    
endmodule
