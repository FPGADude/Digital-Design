`timescale 1ns / 1ps

module seg7_control(
    input clk,          // 100MHz
    input reset,
    input [1:0] change_high,
    input [3:0] change_low,
    input [2:0] the_state,
    output reg [0:6] seg,
    output reg [3:0] an
    );
    
    // Parameters for segment display values
    parameter NULL  = 7'b111_1111;  // Turn off all segments
    parameter ZERO  = 7'b000_0001;  // 0
    parameter ONE   = 7'b100_1111;  // 1
    parameter TWO   = 7'b001_0010;  // 2 
    parameter FIVE  = 7'b010_0100;  // 5
    parameter N     = 7'b110_1010;  // n
    parameter J     = 7'b100_0011;  // j
    parameter O     = 7'b110_0010;  // o
    parameter Y     = 7'b100_0100;  // y 
    parameter C     = 7'b011_0001;  // C
    parameter H     = 7'b110_1000;  // h
    parameter B     = 7'b110_0000;  // b
    parameter U     = 7'b110_0011;  // u
    
    
    reg [1:0] anode_select;
    reg [16:0] anode_timer;
    
    always @(posedge clk or posedge reset) begin
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
    
    always @(posedge clk) begin
        case(the_state)
            3'b000 : begin   // Idle state
                      case(an)
                          4'b0111 : seg = NULL;
                          4'b1011 : seg = B;
                          4'b1101 : seg = U;
                          4'b1110 : seg = Y;
                      endcase
                    end
                    
            3'b001 : begin   // 5 cents state
                      case(an)
                          4'b0111 : seg = NULL;
                          4'b1011 : seg = NULL;
                          4'b1101 : seg = FIVE;
                          4'b1110 : seg = NULL;
                      endcase
                    end
            
            3'b010 : begin   // 10 cents state
                      case(an)
                          4'b0111 : seg = NULL;
                          4'b1011 : seg = ONE;
                          4'b1101 : seg = ZERO;
                          4'b1110 : seg = NULL;
                      endcase
                    end
                    
            3'b011 : begin   // 15 cents state
                      case(an)
                          4'b0111 : seg = NULL;
                          4'b1011 : seg = ONE;
                          4'b1101 : seg = FIVE;
                          4'b1110 : seg = NULL;
                      endcase
                    end
                    
            3'b100 : begin   // 20 cents state
                      case(an)
                          4'b0111 : seg = NULL;
                          4'b1011 : seg = TWO;
                          4'b1101 : seg = ZERO;
                          4'b1110 : seg = NULL;
                      endcase
                    end
                    
            3'b101 : begin   // 25 cents state
                      case(an)
                          4'b0111 : seg = N;
                          4'b1011 : seg = J;
                          4'b1101 : seg = O;
                          4'b1110 : seg = Y;
                      endcase
                    end
                    
            3'b110 : begin   // return change state
                      case(an)
                          4'b0111 : seg = C;
                          4'b1011 : seg = H;
                          4'b1101 : begin
                                        case(change_high)
                                            2'b00  : seg = NULL;
                                            2'b01  : seg = ONE;
                                            2'b10  : seg = TWO;
                                            default: seg = ZERO;
                                        endcase
                                    end
                          4'b1110 : begin
                                        case(change_low)
                                            4'b0000 : seg = ZERO;
                                            4'b0101 : seg = FIVE;
                                            default : seg = NULL;
                                        endcase
                                    end
                      endcase
                    end
        endcase
    end  
endmodule
