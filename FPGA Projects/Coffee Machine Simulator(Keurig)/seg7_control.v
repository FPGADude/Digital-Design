`timescale 1ns / 1ps

module seg7_control(
    input clk_100MHz,       // BASYS 3 clock
    input reset,            // btnC
    input [1:0] cup_count,  // From top
    input [1:0] state,  // From top
    output reg [0:6] seg,       // BASYS 3 cathodes
    output reg [3:0] an         // BASYS 3 anodes
    );
    
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
    
    always @(posedge clk_100MHz) begin
        case(state)
            2'b00 : begin   // Idle state
                      case(an)
                          4'b0111 : seg = 7'b011_0001;
                          4'b1011 : seg = 7'b100_0001;
                          4'b1101 : seg = 7'b001_1000;
                          4'b1110 : begin
                                      case(cup_count)
                                          3 : seg = 7'b000_0110;
                                          2 : seg = 7'b001_0010;
                                          1 : seg = 7'b100_1111;
                                          0 : seg = 7'b000_0001;
                                      endcase
                                  end
                      endcase
                    end
                    
            2'b01 : begin   // Making coffee state
                      case(an)
                          4'b0111 : seg = 7'b011_0001;
                          4'b1011 : seg = 7'b100_0001;
                          4'b1101 : seg = 7'b001_1000;
                          4'b1110 : begin
                                      case(cup_count)
                                          3 : seg = 7'b000_0110;
                                          2 : seg = 7'b001_0010;
                                          1 : seg = 7'b100_1111;
                                          0 : seg = 7'b000_0001;
                                      endcase
                                  end
                      endcase
                    end
                    
            2'b10 : begin   // Coffee done state
                      case(an)
                          4'b0111 : seg = 7'b100_0010;
                          4'b1011 : seg = 7'b000_0001;
                          4'b1101 : seg = 7'b110_1010;
                          4'b1110 : seg = 7'b011_0000;
                      endcase
                    end
                    
            2'b11 : begin   // Need water state
                      case(an)
                          4'b0111 : seg = 7'b011_1000;
                          4'b1011 : seg = 7'b100_1111;
                          4'b1101 : seg = 7'b111_0001;
                          4'b1110 : seg = 7'b111_0001;
                      endcase
                    end
        endcase
    end
    
endmodule
