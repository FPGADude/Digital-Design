`timescale 1ns / 1ps
// Created by David J. Marion
// Date: 7.21.2022
// For Nexys A7 Accelerometer reading

module seg7_control(
    input CLK100MHZ,
    input [7:0] x,
    input [7:0] y,
    input [7:0] z,
    output reg [6:0] seg,
    output reg [7:0] digit
    );
    
    // Binary to BCD conversion of X, Y, Z data
    wire [3:0] x_10, x_1, y_10, y_1, z_10, z_1;

    assign x_10 = x / 10;
    assign x_1 = x % 10;
    
    assign y_10 = y / 10;
    assign y_1 = y % 10;

    assign z_10 = z / 10;
    assign z_1 = z % 10;
    
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
    parameter NULL  = 7'b111_1111;  // ALL OFF
    
    // To select each digit in turn
    reg [2:0] digit_select;     // 3 bit counter for selecting each of 8 digits
    reg [16:0] digit_timer;     // counter for digit refresh
    
    // Logic for controlling digit select and digit timer
    always @(posedge CLK100MHZ) begin
                                                // 1ms x 8 displays = 8ms refresh period
        if(digit_timer == 99_999) begin         // The period of 100MHz clock is 10ns (1/100,000,000 seconds)
            digit_timer <= 0;                   // 10ns x 100,000 = 1ms
            digit_select <=  digit_select + 1;
        end
        else
            digit_timer <=  digit_timer + 1;
    end
    
    // Logic for driving the 8 bit anode output based on digit select
    always @(digit_select) begin
        case(digit_select) 
            3'b000 : digit = 8'b1111_1110;   
            3'b001 : digit = 8'b1111_1101;   
            3'b010 : digit = 8'b1111_1011;   
            3'b011 : digit = 8'b1111_0111;
            3'b100 : digit = 8'b1110_1111;   
            3'b101 : digit = 8'b1101_1111;   
            3'b110 : digit = 8'b1011_1111;   
            3'b111 : digit = 8'b0111_1111;   
        endcase
    end
    
    // Logic for driving segments based on which digit is selected and the value of each digit
    always @*
        case(digit_select)
            3'b000 : begin       
                        case(z_1)
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
                    
            3'b001 : begin      
                        case(z_10)
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
                    
            3'b010 : seg = NULL;
                    
            3'b011 : begin       
                        case(y_1)
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
            3'b100 : begin       
                        case(y_10)
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
                    
            3'b101 : seg = NULL;
                    
            3'b110 : begin       
                        case(x_1)
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
                    
            3'b111 : begin       
                        case(x_10)
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
