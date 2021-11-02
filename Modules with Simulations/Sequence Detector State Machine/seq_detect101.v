`timescale 1ns / 1ps

// 101 Sequence Detector State Machine
// Authored by David J Marion

module seq_detect101(
    input clk,
    input reset,
    input serial_in,
    output reg detected_101
    );
    
    reg [1:0] current_state, next_state;
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;
    parameter S3 = 2'b11;
    
    // Define state transition
    always @(posedge clk) begin
        if(reset)
            current_state <= S0;
        else
            current_state <= next_state;
    end
    
    // Define state change behavior
    always @(*) begin
        next_state = current_state;
        detected_101 = 1'b0;
        case(current_state)
            S0 : if(serial_in == 1'b1) next_state = S1;
            
            S1 : if(serial_in == 1'b0) next_state = S2;   
            
            S2 : if(serial_in == 1'b1) next_state = S3;
                 else next_state = S0;
            
            S3 : begin
                 detected_101 = 1'b1;
                 if(serial_in == 1'b0) next_state = S2;
                 else next_state = S1;
                 end
            
            default: begin
                        next_state <= S0;
                        detected_101 = 1'b0;
                     end
        endcase
    end
  
endmodule
