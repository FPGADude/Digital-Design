`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: David J. Marion
// 
// Create Date: 07/22/2022 12:11:30 PM
// Design Name: Accelerator Top Module
// Module Name: top
// Project Name: Nexys A7 - Reading the 3-Axis Accelerometer using SPI
// Target Devices: Nexys A7-50T
// Tool Versions: Vivado 2021.2
// Description: Read 3-axis accelerometer data output on 7 segment displays and LEDs
// 
// References:
//      Digilent Nexys A7 RM
//      Analog Device ADXL362 Datasheet
//////////////////////////////////////////////////////////////////////////////////


module top(
    input CLK100MHZ,            // nexys a7 clock
    input ACL_MISO,             // master in
    output ACL_MOSI,            // master out
    output ACL_SCLK,            // spi sclk
    output ACL_CSN,             // spi ~chip select
    output [14:0] LED,          // X = LED[14:10], Y = LED[9:5], Z = LED[4:0]
    output [6:0] SEG,           // 7 segments of display
    output DP,                  // decimal point of display
    output [7:0] AN             // 8 displays
    );
    
    wire w_4MHz;
    wire [14:0] acl_data;
        
    iclk_gen clock_generation(
        .CLK100MHZ(CLK100MHZ),
        .clk_4MHz(w_4MHz)
    );
    
    spi_master master(
        .iclk(w_4MHz),
        .miso(ACL_MISO),
        .sclk(ACL_SCLK),
        .mosi(ACL_MOSI),
        .cs(ACL_CSN),
        .acl_data(acl_data)
    );
    
    seg7_control display_control(
        .CLK100MHZ(CLK100MHZ),
        .acl_data(acl_data),
        .seg(SEG),
        .dp(DP),
        .an(AN)
    );

    assign LED[14:10] = acl_data[14:10];    // 5 bits of x data
    assign LED[9:5]   = acl_data[9:5];     // 5 bits of y data
    assign LED[4:0]   = acl_data[4:0];      // 5 bits of z data
    
endmodule
