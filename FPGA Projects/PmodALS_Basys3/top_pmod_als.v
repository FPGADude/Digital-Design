`timescale 1ns / 1ps
/*
    David J. Marion
    June 30, 2026
    
    How to Interface With Pmod ALS - Ambient Light Sensor
    Using SPI communication protocol and display light
    value on the 7-segment display in real-time
    
    For use with the Basys 3 FPGA on Pmod Header JB (top row)
*/

module top_pmod_als(
    input  wire        clk,        // Basys 3 100 MHz clock
    input  wire        reset,      // btnC, active-high reset

    input  wire        als_sdo,    // Pmod ALS SDO -> serial data input
    output wire        als_cs,     // Pmod ALS CS
    output wire        als_sck,    // Pmod ALS SCK

    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    wire [7:0] light_value;

    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;

    pmod_als_reader u_als_reader (
        .clk(clk),
        .reset(reset),
        .als_sdo(als_sdo),
        .als_cs(als_cs),
        .als_sck(als_sck),
        .light_value(light_value)
    );

    bin8_to_bcd u_bcd (
        .bin(light_value),
        .hundreds(hundreds),
        .tens(tens),
        .ones(ones)
    );

    sevenseg_tasks u_sevenseg (
        .clk(clk),
        .reset(reset),
        .digit3(4'd0),
        .digit2(hundreds),
        .digit1(tens),
        .digit0(ones),
        .seg(seg),
        .an(an)
    );

    // LED bar graph
    // Every 16 counts lights one more LED
    assign led = (light_value >= 8'd240) ? 16'hFFFF :
                 (light_value >= 8'd224) ? 16'h7FFF :
                 (light_value >= 8'd208) ? 16'h3FFF :
                 (light_value >= 8'd192) ? 16'h1FFF :
                 (light_value >= 8'd176) ? 16'h0FFF :
                 (light_value >= 8'd160) ? 16'h07FF :
                 (light_value >= 8'd144) ? 16'h03FF :
                 (light_value >= 8'd128) ? 16'h01FF :
                 (light_value >= 8'd112) ? 16'h00FF :
                 (light_value >= 8'd96 ) ? 16'h007F :
                 (light_value >= 8'd80 ) ? 16'h003F :
                 (light_value >= 8'd64 ) ? 16'h001F :
                 (light_value >= 8'd48 ) ? 16'h000F :
                 (light_value >= 8'd32 ) ? 16'h0007 :
                 (light_value >= 8'd16 ) ? 16'h0003 :
                 (light_value >  8'd0  ) ? 16'h0001 :
                                            16'h0000;

endmodule
