`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: David J. Marion
// 
// Create Date: 07/20/2022 08:05:32 PM
// Design Name: Nexys A7 3-Axis Accelerometer SPI top
// Module Name: top
// Project Name: Nexys A7 Accelerometer
// Target Devices: Nexys A7-50T
// Tool Versions: Vivado 2021.2
// Description: SPI communications with 3-axis accelerometer ADXL362
//
// Comments: THIS DOES NOT WORK!
//           Synthesis - GOOD
//           Implementation - GOOD
//           Generate Bitstream - GOOD
//           Functionality on Nexys - NOT GOOD
//              The six 7-Segment Displays being used light up with 00 00 00,
//              and no change from moving the Nexys around. In theory, this
//              module should work, and we should see the six segments change
//              as the Nexys board is moved around as the accelerometer is
//              reading accelerations in X, Y, Z directions.
//           - Without any way to see what is going on after the board has been
//             programmed, we can only guess at what the problem might be.
//           - The only solution is to try other things and see if it works and
//             hopefully find what works.
//           - A good place to start is with the SPI Master module. Maybe, the
//             timing is not quite right.
//
//
//  NEW INFORMATION: I did not account for the SPI Mode, which is mode 0, meaning
//                   CPOL = 0, and CPHA = 0. (Hopefully, this is an easy fix.)
//                   The mode is all about the SCLK edge for data sends and
//                   receipts. Which edge is detected is dependent on the mode.
//                   - CPHA --> 0 means first edge, 1 means second edge
//                   - CPOL --> sclk idle position, 0 for low, 1 for high
//
// My mistake was just letting the sclk go to the device right from the start and
// not putting the sclk in an idle position iaw the SPI mode.
//
// NEW COMMENTS: Revamped the spi_master to satisfy the SPI mode. Added LEDs to
//               view the X, Y, Z data. STILL NOT WORKING!!!!
//////////////////////////////////////////////////////////////////////////////////


module top(
    input CLK100MHZ,            // nexys a7 system clock
    input MISO,                 // master coms receive line
    output SCLK,                // spi clock = 1MHz
    output CSN,                 // ~cs for spi
    output MOSI,                // master coms transmit line
    output [14:0] LED,
    output [6:0] SEG,           // 7 Segments
    output [7:0] AN             // 8 Anodes - using only 6
    );
    
    wire w_4MHz;
    wire [7:0] x, y, z;
    
    spi_master master(
        .iclk(w_4MHz),
        .sclk(SCLK),
        .miso(MISO),
        .mosi(MOSI),
        .csn(CSN),
        .x_data(x),
        .y_data(y),
        .z_data(z)
    );
    
    iclk_gen i_clock_generation(
        .CLK100MHZ(CLK100MHZ),
        .clk_4MHz(w_4MHz)
    );
    
    seg7_control seven_segment_control(
        .CLK100MHZ(CLK100MHZ),
        .x(x),
        .y(y),
        .z(z),
        .seg(SEG),
        .digit(AN)   
    );
    
    assign LED[14:10] = x[4:0];
    assign LED[9:5] = y[4:0];
    assign LED[4:0] = z[4:0];
    
endmodule
