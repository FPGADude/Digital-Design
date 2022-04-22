`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/11/2022
//
// For use with a system input clock signal of 100MHz
//
// Description: This module contains a binary clock, complete with button
// debouncing circuitry for incrementing hour and minute. This module
// outputs seconds, minutes, and hours values in BCD format, as well as
// the 1Hz signal generated to increment the seconds counter.
//
// For incrementing hours and minutes using buttons: hours and minutes 
// are incremented at posedge 1Hz signal while the corresponding button is held.
////////////////////////////////////////////////////////////////////////////////

module new_binary_clock(
    input clk_100MHz,                   // sys clock
    input reset,                        // reset clock
    input tick_hr,                      // to increment hours
    input tick_min,                     // to increment minutes
    input set_am_pm,                    // to set AM or PM
    output tick_1Hz,                    // 1Hz output signal
    output am_pm,
    output end_of_day,                  // 11:59:59 PM
    output [3:0] sec_1s, sec_10s,       // BCD outputs for seconds
    output [3:0] min_1s, min_10s,       // BCD outputs for minutes
    output [3:0] hr_1s, hr_10s          // BCD outputs for hours
    );
    
	// signals for button debouncing
	reg a, b, c, d, e, f, g, h, i;
	wire db_hr, db_min, db_am_pm;
	
	// debounce tick hour button input
	always @(posedge clk_100MHz) begin
		a <= tick_hr;
		b <= a;
		c <= b;
	end
	assign db_hr = c;
	
	// debounce tick minute button input
	always @(posedge clk_100MHz) begin
		d <= tick_min;
		e <= d;
		f <= e;
	end
	assign db_min = f;
	
	// debounce am / pm button input
	always @(posedge clk_100MHz) begin
	   g <= set_am_pm;
	   h <= g;
	   i <= h;
	end
	assign db_am_pm = i;
	
    // ********************************************************
    // create the 1Hz signal
    reg [31:0] ctr_1Hz = 32'h0;
    reg r_1Hz = 1'b0;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset)
            ctr_1Hz <= 32'h0;
        else
            if(ctr_1Hz == 49_999_999) begin
                ctr_1Hz <= 32'h0;
                r_1Hz <= ~r_1Hz;
            end
            else
                ctr_1Hz <= ctr_1Hz + 1;
     
    // ********************************************************
    // regs for each time value and am/pm reg
    reg [5:0] seconds_ctr = 6'b0;   // 0
    reg [5:0] minutes_ctr = 6'b0;   // 0
    reg [3:0] hours_ctr = 4'hc;     // 12
    reg am_pm_reg = 1'b0;           // AM  
    
    // signal for am/pm reg control, marks end of 12 hour period
    wire switch_am_pm = ((hours_ctr == 11) && (minutes_ctr == 59) && (seconds_ctr == 59)) ? 1 : 0;        
	
	// seconds counter reg control
    always @(posedge tick_1Hz or posedge reset)     // tick_1Hz
        if(reset)
            seconds_ctr <= 6'b0;
        else
            if(seconds_ctr == 59)
                seconds_ctr <= 6'b0;
            else
                seconds_ctr <= seconds_ctr + 1;
            
    // minutes counter reg control       
    always @(posedge tick_1Hz or posedge reset)      // tick_1Hz
        if(reset)
            minutes_ctr <= 6'b0;
        else 
//            if(seconds_ctr == 59)
            if(db_min | (seconds_ctr == 59))
                if(minutes_ctr == 59)
                    minutes_ctr <= 6'b0;
                else
                    minutes_ctr <= minutes_ctr + 1;
                    
    // hours counter reg control
    always @(posedge tick_1Hz or posedge reset)      // tick_1Hz
        if(reset)
            hours_ctr <= 4'hc;  // 12
        else 
//            if(minutes_ctr == 59 && seconds_ctr == 59)
            if(db_hr | (minutes_ctr == 59 && seconds_ctr == 59))
                if(hours_ctr == 12)
                    hours_ctr <= 4'h1;
                else
                    hours_ctr <= hours_ctr + 1;
       
    // AM/PM reg control
    always @(posedge tick_1Hz or posedge reset)      // tick_1Hz
        if(reset)
            am_pm_reg = 0;
        else
//            if(switch_am_pm)
            if(db_am_pm | switch_am_pm)
                am_pm_reg <= ~am_pm_reg;   
                    
    // ********************************************************                
    // convert binary values to output bcd values
    assign sec_10s = seconds_ctr / 10;
    assign sec_1s  = seconds_ctr % 10;
    assign min_10s = minutes_ctr / 10;
    assign min_1s  = minutes_ctr % 10;
    assign hr_10s  = hours_ctr   / 10;
    assign hr_1s   = hours_ctr   % 10; 
        
    // ******************************************************** 
    // 1Hz output            
    assign tick_1Hz = r_1Hz; 
    
    // End of day output
    assign end_of_day = ((hours_ctr == 11) && (minutes_ctr == 59) && (seconds_ctr == 59) && (am_pm_reg == 1)) ? 1 : 0;
         
    // AM/PM output signal     
    assign am_pm = am_pm_reg;        
endmodule