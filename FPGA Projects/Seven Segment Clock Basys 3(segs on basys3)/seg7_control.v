`timescale 1ns / 1ps

module seg7_control(
    input clk_100MHz,
    input reset,
    input [2:0] hrs_tens,
    input [3:0] hrs_ones,
    input [2:0] mins_tens,
    input [3:0] mins_ones,
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
                        case(hrs_tens)
                            3'b000 : seg = NULL;
                            3'b001 : seg = ONE;
                        endcase
                    end
                    
            2'b01 : begin       // HOURS ONES DIGIT
                        case(hrs_ones)
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
                    
            2'b10 : begin       // MINUTES TENS DIGIT
                        case(mins_tens)
                            3'b000 : seg = ZERO;
                            3'b001 : seg = ONE;
                            3'b010 : seg = TWO;
                            3'b011 : seg = THREE;
                            3'b100 : seg = FOUR;
                            3'b101 : seg = FIVE;
                        endcase
                    end
                    
            2'b11 : begin       // MINUTES ONES DIGIT
                        case(mins_ones)
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
