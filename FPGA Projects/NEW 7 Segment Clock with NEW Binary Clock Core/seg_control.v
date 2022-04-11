`timescale 1ns / 1ps

module seg_control(
    input clk_100MHz,
    input reset,
    input [3:0] min_1s,
    input [3:0] min_10s,
    input [3:0] hr_1s,
    input [3:0] hr_10s,
    output reg [0:6] seg,
    output reg [3:0] an
    );
    
    // Parameters for segment values
    parameter NULL  = 7'b111_1111;  // Turn off all segments
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
    
    
    // To select each anode in turn
    reg [1:0] anode_select;
    reg [16:0] anode_timer;
        
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            anode_select <= 0;
            anode_timer <= 0; 
        end
        else
            if(anode_timer == 99_999) begin
                anode_timer <= 0;
                anode_select <=  anode_select + 1;
            end
            else
                anode_timer <=  anode_timer + 1;
    end
    
    always @(anode_select) begin
        case(anode_select) 
            2'b00 : an = 4'b0111;
            2'b01 : an = 4'b1011;
            2'b10 : an = 4'b1101;
            2'b11 : an = 4'b1110;
        endcase
    end
    
    // To drive the segments
    always @*
        case(anode_select)
            2'b00 : begin       // HOURS TENS DIGIT
                        case(hr_10s)
                            4'h0 : seg = NULL;
                            4'h1 : seg = ONE;
                        endcase
                    end
                    
            2'b01 : begin       // HOURS ONES DIGIT
                        case(hr_1s)
                            4'h0 : seg = ZERO;
                            4'h1 : seg = ONE;
                            4'h2 : seg = TWO;
                            4'h3 : seg = THREE;
                            4'h4 : seg = FOUR;
                            4'h5 : seg = FIVE;
                            4'h6 : seg = SIX;
                            4'h7 : seg = SEVEN;
                            4'h8 : seg = EIGHT;
                            4'h9 : seg = NINE;
                        endcase
                    end
                    
            2'b10 : begin       // MINUTES TENS DIGIT
                        case(min_10s)
                            4'h0 : seg = ZERO;
                            4'h1 : seg = ONE;
                            4'h2 : seg = TWO;
                            4'h3 : seg = THREE;
                            4'h4 : seg = FOUR;
                            4'h5 : seg = FIVE;
                        endcase
                    end
                    
            2'b11 : begin       // MINUTES ONES DIGIT
                        case(min_1s)
                            4'h0 : seg = ZERO;
                            4'h1 : seg = ONE;
                            4'h2 : seg = TWO;
                            4'h3 : seg = THREE;
                            4'h4 : seg = FOUR;
                            4'h5 : seg = FIVE;
                            4'h6 : seg = SIX;
                            4'h7 : seg = SEVEN;
                            4'h8 : seg = EIGHT;
                            4'h9 : seg = NINE;
                        endcase
                    end
        endcase
    
    
    
    
endmodule
