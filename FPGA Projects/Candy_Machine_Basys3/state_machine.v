`timescale 1ns / 1ps

module state_machine(
    input clk,                      // 100MHz
    input reset,
    input btn_25,                   // input a quarter
    input btn_10,                   // input a dime
    input btn_5,                    // input a nickel
    output [2:0] the_state,         // to 7-segment control
    output reg [4:0] change         // to 7-segment control
    );
   
    reg [5:0] counter_reg = 0;
    reg [5:0] ch_counter_reg = 0;
    
    // 7 states
    reg [2:0] state_reg;
    parameter idle = 3'b000;
    parameter s_5  = 3'b001;    // 5 cents
    parameter s_10 = 3'b010;    // 10 cents
    parameter s_15 = 3'b011;    // 15 cents
    parameter s_20 = 3'b100;    // 20 cents
    parameter s_25 = 3'b101;    // 25 cents, candy = 1
    parameter ch   = 3'b110;    // change return state
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            state_reg <= idle;
        else
            case(state_reg)
                idle :  begin
                            change = 5'd0;
                            if(btn_25)
                                state_reg <= s_25;
                            else if(btn_10)
                                state_reg <= s_10;
                            else if(btn_5)
                                state_reg <= s_5;
                        end
                        
                s_5 :   begin
                            if(btn_25) begin
                                state_reg <= s_25;
                                change <= 5'd5;
                                end
                            else if(btn_10)
                                state_reg <= s_15;
                            else if(btn_5)
                                state_reg <= s_10;
                        end
                        
                s_10 :   begin
                            if(btn_25) begin
                                state_reg <= s_25;
                                change <= 5'd10;
                                end
                            else if(btn_10)
                                state_reg <= s_20;
                            else if(btn_5)
                                state_reg <= s_15;
                        end
                        
                s_15 :  begin
                            if(btn_25) begin
                                state_reg <= s_25;
                                change <= 5'd15;
                                end
                            else if(btn_10)
                                state_reg <= s_25;
                            else if(btn_5)
                                state_reg <= s_20;
                        end
                        
                s_20 :  begin
                            if(btn_25) begin
                                state_reg <= s_25;
                                change <= 5'd20;
                                end
                            else if(btn_10) begin
                                state_reg <= s_15;
                                change = 5;
                                end
                            else if(btn_5)
                                state_reg <= s_25;
                        end
                        
                s_25 :  begin
                            if(counter_reg == 29)
                                state_reg <= ch;
                        end
                        
                ch   :  begin
                            if(ch_counter_reg == 29)
                                state_reg <= idle;
                        end
            endcase
    end
    
    // Counter control
    always @(posedge clk or posedge reset) begin
        if(reset)
            counter_reg <= 0;
        else
            if(state_reg == s_25)
                if(counter_reg == 29)
                    counter_reg <= 0;
                else
                    counter_reg <= counter_reg + 1;
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            ch_counter_reg <= 0;
        else
            if(state_reg == ch)
                if(ch_counter_reg == 29)
                    ch_counter_reg <= 0;
                else
                    ch_counter_reg <= ch_counter_reg + 1;
    end
    
    assign the_state = state_reg;
    
endmodule
