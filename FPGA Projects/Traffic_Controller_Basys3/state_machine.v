`timescale 1ns / 1ps

module state_machine(
    input reset,    // btnC on BASYS 3
    input clk_1Hz,
    output reg [2:0] main_st,   // 3-bits out PMOD_B
    output reg [2:0] cross_st   // 3-bits out PMOD_C
    );
    
    // Define states
    parameter main_green_cross_red  = 2'b00;
    parameter main_yellow_cross_red = 2'b01;
    parameter main_red_cross_green  = 2'b10;
    parameter main_red_cross_yellow = 2'b11;
    
    // The state register
    reg [1:0] state_reg;    // 4 states = 2 bits
    
    // Timer for light changes
    reg [4:0] light_counter = 0;    // main green = 15 seconds
                                    // main yellow = 3 seconds
                                    // cross green = 10 seconds
                                    // cross yellow = 3 seconds
                                    // total seconds = 31 = 5 bits
    
    // Next state logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            state_reg <= main_green_cross_red;  // reset state
        else
            case(state_reg)
                main_green_cross_red  : if(light_counter == 15)     state_reg <= main_yellow_cross_red;
                main_yellow_cross_red : if(light_counter == 18)     state_reg <= main_red_cross_green;
                main_red_cross_green  : if(light_counter == 28)     state_reg <= main_red_cross_yellow;
                main_red_cross_yellow : if(light_counter == 31)     state_reg <= main_green_cross_red;
                default : state_reg <= main_green_cross_red; 
            endcase
    end
    
    // Light Counter control
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            light_counter <= 0;
        else
            if(light_counter == 31) 
                light_counter <= 0;
            else
                light_counter <= light_counter + 1;
    end
    
    always @(posedge clk_1Hz) begin
        case(state_reg) 
            main_green_cross_red  : begin
                                        main_st  = 3'b001;  // green
                                        cross_st = 3'b100;  // red
                                    end
            main_yellow_cross_red : begin
                                        main_st  = 3'b010;  // yellow
                                        cross_st = 3'b100;  // red
                                    end
            main_red_cross_green  : begin
                                        main_st  = 3'b100;  // red
                                        cross_st = 3'b001;  // green
                                    end
            main_red_cross_yellow : begin
                                        main_st  = 3'b100;  // red
                                        cross_st = 3'b010;  // yellow
                                    end
        endcase
    end
    
endmodule
