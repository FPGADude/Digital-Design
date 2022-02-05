`timescale 1ns / 1ps

module state_machine(
    input clk_1Hz,          // 1Hz
    input btn1,             // btnL - make coffee
    input btn2,             // btnR - fill water
    input reset,            // btnC - reset
    input sw,               // sw0 on BASYS 3
    output [1:0] cup_count, // to seg7 control
    output [2:0] state,     // to seg7 control
    output [15:6] LED_high, // LED 15 thru 6
    output LED_five,        // LED 5
    output [4:0] LED_low    // LED 4 thru 0
    );
    
    // Internal regs
    reg sw_reg;
    reg [3:0] counter;
    reg [15:0] LED_reg;
    reg [1:0] cup_count_reg;
    
    // Define state machine parameters
    parameter idle = 3'b000;
    parameter ready = 3'b001;
    parameter making_coffee = 3'b010;
    parameter finish = 3'b011;
    parameter need_water = 3'b100;
    
    // Define state reg
    reg [2:0] state_reg = 3'b000;
    
    // Define next state logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            state_reg <= idle;
        else
            case(state_reg)
                idle : if(sw_reg)                   state_reg <= ready;
                            
                ready : if(btn1)                    state_reg <= making_coffee; 
                                                  
                making_coffee : if(counter == 15)   state_reg <= finish;
                            
                finish : if(cup_count == 0)         state_reg <= need_water; 
                         else                       state_reg <= idle;      
                            
                need_water : if(btn2)               state_reg <= idle;                 
            endcase
    end
    
    // Switch reg
    always @(negedge sw or posedge clk_1Hz or posedge reset) begin
        if(reset)
            sw_reg <= 0;
        else if(clk_1Hz && state_reg == making_coffee)
            sw_reg <= 0;  
        else
            sw_reg <= 1;
       
    end
    
    // Counter reg
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            counter <= 0;
        else if(state_reg == making_coffee)
            counter <= counter + 1;
    end
    
    // Cup count reg
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            cup_count_reg <= 3;
        else if(btn1 && state_reg == ready)
            cup_count_reg <= cup_count_reg - 1;
        else if(btn2)
            cup_count_reg <= 3;
    end
    
    // LED reg
    always @(posedge clk_1Hz) begin
        if(state_reg == making_coffee)
            case(counter)
                0  : LED_reg = 16'b0000_0000_0000_0001;
                1  : LED_reg = 16'b0000_0000_0000_0011;
                2  : LED_reg = 16'b0000_0000_0000_0111;
                3  : LED_reg = 16'b0000_0000_0000_1111;
                4  : LED_reg = 16'b0000_0000_0001_1111;
                5  : LED_reg = 16'b0000_0000_0011_1111;
                6  : LED_reg = 16'b0000_0000_0111_1111;
                7  : LED_reg = 16'b0000_0000_1111_1111;
                8  : LED_reg = 16'b0000_0001_1111_1111;
                9  : LED_reg = 16'b0000_0011_1111_1111;
                10 : LED_reg = 16'b0000_0111_1111_1111;
                11 : LED_reg = 16'b0000_1111_1111_1111;
                12 : LED_reg = 16'b0001_1111_1111_1111;
                13 : LED_reg = 16'b0011_1111_1111_1111;
                14 : LED_reg = 16'b0111_1111_1111_1111;
                15 : LED_reg = 16'b1111_1111_1111_1111;
            endcase
        else
            LED_reg = 16'b0000_0000_0000_0000;      
    end
    
    assign LED_high = LED_reg[15:6];
    assign LED_five = LED_reg[5];
    assign LED_low = LED_reg[4:0];
    assign state = state_reg;
    assign cup_count = cup_count_reg;
    
endmodule