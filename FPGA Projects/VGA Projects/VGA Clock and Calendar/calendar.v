`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/13/2022
//
// Description: This module contains a calendar that is driven by hours, minutes,
// seconds, and an am_or_pm signal from the binary clock core new_binary_clock.v.
//
//////////////////////////////////////////////////////////////////////////////////

module calendar(
    input clk_100MHz,           // 100MHz from Basys 3
    input tick_1Hz,             // 1Hz signal from binary clock module
    input reset,                // system reset
    input end_of_day,           // from bin clk
    input inc_month,            
    input inc_day,
    input inc_year,
    input inc_century,
    output [3:0] m_10s, m_1s,   // month BCD (not used in simulation)
    output [3:0] d_10s, d_1s,   // day BCD (not used in simulation)
    output [3:0] y_10s, y_1s,   // year BCD (not used in simulation)
    output [3:0] c_10s, c_1s    // century BCD (not used in simulation)
    );
    
    // button debouncing
    reg a, b, c, d, e, f, g, h, i, j, k, l;
    wire w_day, w_month, w_year, w_cent;
    
    always @(posedge clk_100MHz) begin
        a <= inc_day;
        b <= a;
        c <= b;
    end
    assign w_day = c;
    
    always @(posedge clk_100MHz) begin
        d <= inc_month;
        e <= d;
        f <= e;
    end
    assign w_month = f;
    
    always @(posedge clk_100MHz) begin
        g <= inc_year;
        h <= g;
        i <= h;
    end
    assign w_year = i;
    
    always @(posedge clk_100MHz) begin
        j <= inc_century;
        k <= j;
        l <= k;
    end
    assign w_cent = l;
    
    // calendar regs and logic
    reg [3:0] month = 1;
    reg [4:0] day = 1;
    reg [6:0] year = 22;
    reg [6:0] century = 20;
    
    wire end_of_year;
    assign end_of_year = ((month == 12 && day == 31) & end_of_day) ? 1 : 0;
    wire end_of_century;
    assign end_of_century = ((year == 99) & end_of_year) ? 1 : 0;
    wire leap_year;
    assign leap_year = (year % 4 == 0) ? 1 : 0;
    
    // day register control
    always @(posedge tick_1Hz or posedge reset) begin
        if(reset)
            day = 5'd1;
        else
            if(w_day | end_of_day)
                case(month)
                    1 : begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    2 : begin
                            if(~leap_year && day == 28)
                                day <= 1;
                            else if(leap_year && day == 29)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    3 : begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    4 : begin
                            if(day == 30)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    5 : begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    6 : begin
                            if(day == 30)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    7 : begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    8 : begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    9 : begin
                            if(day == 30)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    10: begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    11: begin
                            if(day == 30)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    12: begin
                            if(day == 31)
                                day <= 1;
                            else
                                day <= day + 1;
                        end
                    default: day = 1;
                endcase
    end
    
    // month register control
    always @(posedge tick_1Hz or posedge reset) begin
        if(reset)
            month = 4'd1;
        else
            if(w_month)
                if(month == 12)
                    month <= 1;
                else
                    month <= month + 1;
            else if((month == 1 && day == 31) & end_of_day)
                month <= 2;
            else if((month == 2 && day == 28) & end_of_day & ~leap_year)
                month <= 3;
            else if((month == 2 && day == 29) & end_of_day & leap_year)
                month <= 3;
            else if((month == 3 && day == 31) & end_of_day)
                month <= 4;
            else if((month == 4 && day == 30) & end_of_day)
                month <= 5;
            else if((month == 5 && day == 31) & end_of_day)
                month <= 6;
            else if((month == 6 && day == 30) & end_of_day)
                month <= 7;
            else if((month == 7 && day == 31) & end_of_day)
                month <= 8;
            else if((month == 8 && day == 31) & end_of_day)
                month <= 9;
            else if((month == 9 && day == 30) & end_of_day)
                month <= 10;
            else if((month == 10 && day == 31) & end_of_day)
                month <= 11;
            else if((month == 11 && day == 30) & end_of_day)
                month <= 12;
            else if(end_of_year & end_of_day)
                month <= 1;
    end
    
    // year register control
    always @(posedge tick_1Hz or posedge reset) begin
        if(reset)
            year = 7'd22;
        else
            if(w_year | end_of_year)
                if(year == 99)
                    year <= 0;
                else
                    year <= year + 1;
    end
    
    // century register control
    always @(posedge tick_1Hz or posedge reset) begin
        if(reset)
            century = 7'd20;
        else
            if(w_cent | end_of_century)
                if(century == 99)
                    century <= 0;
                else
                    century <= century + 1;
    end
    
    // convert calendar values to BCD
    assign m_10s = month / 10;
    assign m_1s  = month % 10;
    assign d_10s = day / 10;
    assign d_1s  = day % 10;
    assign y_10s = year / 10;
    assign y_1s  = year % 10;
    assign c_10s = century / 10;
    assign c_1s  = century % 10;
    
endmodule
