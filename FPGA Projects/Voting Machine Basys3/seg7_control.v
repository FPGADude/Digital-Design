`timescale 1ns / 1ps

module seg7_control(
    input clk_100MHz,
    input reset,
    input [1:0] the_state,      // from state machine
    input vc_tens,              // from bin2bcd
    input [3:0] vc_ones,        // from bin2bcd
    input [1:0] the_winner,     // from state machine
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
    
    always @*
        case(the_state)
            2'b00 : // Idle state
                    begin
                        case(an)
                            4'b0111 : seg = NULL;
                            4'b1011 : seg = NULL;
                            4'b1101 : seg = NULL;
                            4'b1110 : seg = NULL;
                        endcase
                    end
            
            2'b01 : // Voting Open state
                    begin
                        case(an)
                            4'b0111 : seg = NULL;
                            4'b1011 : seg = NULL;
                            4'b1101 : case(vc_tens)
                                        0 : seg = NULL;
                                        1 : seg = ONE; 
                                      endcase  
                            4'b1110 : case(vc_ones)
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
                        endcase
                    end
            
            2'b10 : // Voting Closed state
                    begin
                        case(an)
                            4'b0111 : seg = NULL;
                            4'b1011 : seg = NULL;
                            4'b1101 : case(vc_tens)
                                        0 : seg = NULL;
                                        1 : seg = ONE; 
                                      endcase  
                            4'b1110 : case(vc_ones)
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
                        endcase
                    end
            
            2'b11 : // Display Winner state
                    begin
                        case(an)
                            4'b0111 : case(the_winner)
                                        2'b00 : seg = ZERO;
                                        2'b01 : seg = ONE;
                                        2'b10 : seg = TWO;
                                        2'b11 : seg = THREE;
                                      endcase
                            4'b1011 : seg = NULL;
                            4'b1101 : case(vc_tens)
                                        0 : seg = NULL;
                                        1 : seg = ONE; 
                                      endcase  
                            4'b1110 : case(vc_ones)
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
                        endcase
                    end                    
        endcase
        
    
endmodule
