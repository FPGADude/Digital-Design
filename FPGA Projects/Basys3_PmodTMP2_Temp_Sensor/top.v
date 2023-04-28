`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: David J. Marion
// 
// Create Date: 4.27.2023
// Design Name: Basys 3 with PmodTMP2 - Temperature Sensor
// Module Name: top
// Project Name: Thermometer
// Target Devices: Basys 3 Artix-7 35T
// Tool Versions: Vivado 2021.2
// Description: I2C communication with ADT7420 temp sensor aboard PmodTMP2
//             
// Comments: Same modules from Nexys A7 with some tweaks.
//           Reset logic has been removed as it is not really needed.
//           This project can output Celsius or Fahrenheit on 7-segment display
//           and on LEDs depending on a switch.
//////////////////////////////////////////////////////////////////////////////////

module top(
    input         clk_100MHz,       // basys clk signal
    input         SW,               // switch temperature display
    inout         TMP_SDA,          // i2c sda on temp sensor - bidirectional
    output        TMP_SCL,          // i2c scl on temp sensor
    output [0:6]  SEG,              // 7 segments of each display (CHANGE ENDIANESS)
    output [3:0]  AN,               // 4 anodes of 4 displays
    output [7:0]  LED               // basys leds = binary temp in deg C
    );
    
    wire w_200kHz;                  // 200kHz SCL
    wire [7:0] c_data;              // celsius data
    wire [7:0] f_data;              // fahrenheit data

    i2c_master master(
        .clk_200kHz(w_200kHz),
        .temp_data(c_data),
        .SDA(TMP_SDA),
        .SCL(TMP_SCL)
    );
    
    clkgen_200kHz cgen(
        .clk_100MHz(clk_100MHz),    // changed clk name to match constraints file
        .clk_200kHz(w_200kHz)
    );
    
    seg7 seg(
        .clk_100MHz(clk_100MHz),    // changed clk name to match constraints file
        .SW(SW),
        .c_data(c_data),
        .f_data(f_data),
        .SEG(SEG),
        .AN(AN)
    );
    
    temp_converter tc(
        .c(c_data),
        .f(f_data)
    );
    
    assign LED = SW ? f_data : c_data;

endmodule