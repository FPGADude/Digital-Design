`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: David J. Marion
// 
// Create Date: 07/19/2022 9:00:00 PM
// Design Name: Nexys A7 Temp Sensor1
// Module Name: top
// Project Name: Thermometer
// Target Devices: Nexys A7-50T
// Tool Versions: Vivado 2021.2
// Description: I2C communication with ADT7420 temp sensor aboard Nexys A7
//              - temperature read out on 8 LEDs and 7 Segment Displays
//             
// Comments: Works great!
//////////////////////////////////////////////////////////////////////////////////

module top(
    input         CLK100MHZ,        // nexys clk signal
    input         reset,            // btnC on nexys
    inout         TMP_SDA,          // i2c sda on temp sensor - bidirectional
    output        TMP_SCL,          // i2c scl on temp sensor
    output [6:0]  SEG,              // 7 segments of each display
    output [3:0]  AN,               // 4 anodes of 4 displays
    output [3:0]  NAN,              // 4 anodes always OFF
    output [7:0]  LED               // nexys leds = binary temp in deg C
    );
    
    wire sda_dir;                   // direction of SDA signal - to or from master
    wire w_200kHz;                  // 200kHz SCL
    wire [7:0] w_data;              // 8 bits of temperature data

    // Instantiate i2c master
    i2c_master master(
        .clk_200kHz(w_200kHz),
        .reset(reset),
        .temp_data(w_data),
        .SDA(TMP_SDA),
        .SDA_dir(sda_dir),
        .SCL(TMP_SCL)
    );
    
    // Instantiate 200kHz clock generator
    clkgen_200kHz cgen(
        .clk_100MHz(CLK100MHZ),
        .clk_200kHz(w_200kHz)
    );
    
    // Instantiate 7 segment control
    seg7 seg(
        .clk_100MHz(CLK100MHZ),
        .temp_data(w_data),
        .SEG(SEG),
        .NAN(NAN),
        .AN(AN)
    );
    
    // Set LED value to temp data
    assign LED = w_data;

endmodule
