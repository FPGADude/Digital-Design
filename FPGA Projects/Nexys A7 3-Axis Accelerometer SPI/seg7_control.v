`timescale 1ns / 1ps
// Created by David J. Marion
// Date 7.22.2022
// For NexysA7 Accelerometer Reading


module seg7_control(
    input CLK100MHZ,
    input [14:0] acl_data,
    output reg [6:0] seg,
    output reg dp,
    output reg [7:0] an
    );
    
    // Take sign bits out of accelerometer data
    wire x_sign, y_sign, z_sign;
    assign x_sign = acl_data[14];
    assign y_sign = acl_data[9];
    assign z_sign = acl_data[4];
    
    // Take 6 bits of axis data out of accelerometer data
    wire [3:0] x_data, y_data, z_data;
    assign x_data = acl_data[13:10];
    assign y_data = acl_data[8:5];
    assign z_data = acl_data[3:0];
    
    // Binary to BCD conversion for each axis 6-bit data
    wire [3:0] x_10, x_1, y_10, y_1, z_10, z_1;
    assign x_10 = x_data / 10;
    assign x_1  = x_data % 10;
    assign y_10 = y_data / 10;
    assign y_1  = y_data % 10;
    assign z_10 = z_data / 10;
    assign z_1  = z_data % 10;
    
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
    parameter NULL  = 7'b111_1111;  // all OFF
    
    // To select each anode in turn
    reg [2:0] anode_select = 3'b0;     // 3 bit counter for selecting each of 8 anodes
    reg [16:0] anode_timer = 17'b0;    // counter for anode refresh
    
    // Logic for controlling anode select and anode timer
    always @(posedge CLK100MHZ) begin               // 1ms x 8 displays = 8ms refresh period                             
        if(anode_timer == 99_999) begin             // The period of 100MHz clock is 10ns (1/100,000,000 seconds)
            anode_timer <= 0;                       // 10ns x 100,000 = 1ms
            anode_select <=  anode_select + 1;
        end
        else
            anode_timer <=  anode_timer + 1;
    end
    
    // Logic for driving the 8 bit anode output based on anode select
    always @(anode_select) begin
        case(anode_select) 
            3'b000 : an = 8'b1111_1110;   
            3'b001 : an = 8'b1111_1101;  
            3'b010 : an = 8'b1111_1011;  
            3'b011 : an = 8'b1111_0111;
            3'b100 : an = 8'b1110_1111;   
            3'b101 : an = 8'b1101_1111;  
            3'b110 : an = 8'b1011_1111;  
            3'b111 : an = 8'b0111_1111; 
        endcase
    end
    
    // Logic for driving segments based on which anode is selected
    always @*
        case(anode_select)
            3'b000 : begin
                        if(z_sign)                  // if sign is negative
                            dp = 1'b0;              // ON
                        else
                            dp = 1'b1;              // OFF 
                                
                        case(z_1)                   // Z axis ones digit
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
                        dp = 1'b1;                  // OFF  
                        
                        case(z_10)                  // Z axis tens digit
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
                    
            3'b010 : begin                          // anode not used
                        dp = 1'b1;
                        seg = NULL;     
                    end
                    
            3'b011 : begin
                        if(y_sign)                  // if sign is negative
                            dp = 1'b0;              // ON
                        else
                            dp = 1'b1;              // OFF
                        
                        case(y_1)                   // Y axis ones digit
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
                        dp = 1'b1;                  // OFF
                         
                        case(y_10)                  // Y axis tens digit
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
                    
            3'b101 : begin                          // anode not used
                        dp = 1'b1;
                        seg = NULL;    
                        
                    end
                    
            3'b110 : begin 
                        if(x_sign)                  // if sign is negative
                            dp = 1'b0;              // ON
                        else
                            dp = 1'b1;              // OFF
                        
                        case(x_1)                   // X axis ones digit
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
                        dp = 1'b1;                  // OFF
                         
                        case(x_10)                  // X axis tens digit
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
