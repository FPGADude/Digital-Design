`timescale 1ns / 1ps

module traffic_controller_fsm #(
            parameter MAIN_G_SEC = 10,
            parameter YELLOW_SEC = 3,
            parameter SIDE_G_SEC = 7
)(
    input wire clk,     // 100MHz
    input wire reset,
    input wire tick,
    output reg [2:0] main_lights,
    output reg [2:0] side_lights
    );
    
    // State encodings
    localparam MAIN_GRN = 2'b00;
    localparam MAIN_YLO = 2'b01;
    localparam SIDE_GRN = 2'b10;
    localparam SIDE_YLO = 2'b11;
    
    // state reg and counter reg
    reg [1:0] current_state = MAIN_GRN;
    reg [1:0] next_state;
    reg [3:0] count = 4'h1;
    reg [3:0] count_next;
    
    // state and counter logic
    always @(posedge clk)
        if(reset) begin
            current_state <= MAIN_GRN;
            count <= 4'h1;
        end
        else
            if(tick) begin
                current_state <= next_state;
                count <= count_next;
            end
    
    // next state and next count logic
    always @* begin
        next_state = current_state;
        count_next = count + 1;
        case(current_state)
            MAIN_GRN:
                if(count == MAIN_G_SEC) begin
                    next_state = MAIN_YLO;
                    count_next = 4'b1;
                end
            MAIN_YLO:
                if(count == YELLOW_SEC) begin
                    next_state = SIDE_GRN;
                    count_next = 4'b1;
                end
            
            SIDE_GRN:
                if(count == SIDE_G_SEC) begin
                    next_state = SIDE_YLO;
                    count_next = 4'b1;
                end
            SIDE_YLO:
                if(count == YELLOW_SEC) begin
                    next_state = MAIN_GRN;
                    count_next = 4'b1;
                end
            default: begin
                next_state = MAIN_GRN;
                count_next = 4'b1;
            end
        endcase
    end
    
    // output logic
    always @*
        case(current_state)
            MAIN_GRN: begin
                main_lights = 3'b100;   // green
                side_lights = 3'b100;   // red
            end
            MAIN_YLO: begin
                main_lights = 3'b010;   // yellow
                side_lights = 3'b100;   // red
            end 
            SIDE_GRN: begin
                main_lights = 3'b001;   // red
                side_lights = 3'b001;   // green
            end
            SIDE_YLO: begin
                main_lights = 3'b001;   // red
                side_lights = 3'b010;   // yellow
            end
            default: begin
                main_lights = 3'b001;   // red
                side_lights = 3'b100;   // red
            end
        
        endcase
    
    
    
    
endmodule
