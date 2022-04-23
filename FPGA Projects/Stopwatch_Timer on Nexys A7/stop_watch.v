`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on April 18, 2022
//////////////////////////////////////////////////////////////////////////////////

module stop_watch(
    input clk_100MHz,
    input reset,
    input start,
    input stop,
    output [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s
    );
    
    // Button Debouncing
    reg a, b, c, d, e, f;
    wire w_start, w_stop;
    
    always @(posedge clk_100MHz) 
    begin
        a <= start;
        b <= a;
        c <= b;                
    end
    assign w_start = c;
    
    always @(posedge clk_100MHz)
    begin
        d <= stop;
        e <= d;
        f <= e;
    end
    assign w_stop = f;
    
    // Start/Stop register
    reg ss = 0;
    wire w_ss;

    // Start/Stop register control, it is essentially an SR Latch
    always @*
        if(w_start)
            ss = 1;
        else if(w_stop)
            ss = 0;
    
    assign w_ss = ss;
    
    // Create the 100 Hz generator to drive the counters
    reg [18:0] ctr_reg = 0; // 19 bits to cover 500,000
    reg r_100Hz = 0;
    wire clk_100Hz;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset) begin
            ctr_reg <= 0;
            r_100Hz <= 0;
        end
        else
            if(ctr_reg == 499_999) begin  // 100MHz / 100Hz / 2 = 500,000
                ctr_reg <= 0;
                r_100Hz <= ~r_100Hz;
            end
            else
                ctr_reg <= ctr_reg + 1;
    
    assign clk_100Hz = r_100Hz;
    
    // Registers for each counter
    reg [6:0] sec100_ctr = 0;
    reg [5:0] sec_ctr = 0;
    reg [5:0] min_ctr = 0;
    reg [6:0] hr_ctr = 0;
    
    // 1/100s of seconds reg control
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            sec100_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99)
                    sec100_ctr <= 0;
                else
                    sec100_ctr <= sec100_ctr + 1;
       
    // seconds reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            sec_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99)
                    if(sec_ctr == 59)
                        sec_ctr <= 0;
                    else
                        sec_ctr <= sec_ctr + 1;    
    
    // minutes reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            min_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99 && sec_ctr == 59)
                    if(min_ctr == 59)
                        min_ctr <= 0;
                    else
                        min_ctr <= min_ctr + 1;  
                    
    // hours reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            hr_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99 && sec_ctr == 59 && min_ctr == 59)
                    if(hr_ctr == 99)
                        hr_ctr <= 0;
                    else
                        hr_ctr <= hr_ctr + 1;  
                    
    // Binary to BCD conversion for output signals
    assign sec100_10s = sec100_ctr / 10;
    assign sec100_1s  = sec100_ctr % 10;
    assign sec_10s    = sec_ctr / 10;
    assign sec_1s     = sec_ctr % 10;
    assign min_10s    = min_ctr / 10;
    assign min_1s     = min_ctr % 10;
    assign hr_10s     = hr_ctr / 10;
    assign hr_1s      = hr_ctr % 10;
    
    
endmodule
