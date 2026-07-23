`timescale 1ns / 1ps
//==============================================================================
// Module:      top_cmod_tmp2_esp32
// Project:     FPGA Wi-Fi Temperature Monitor
// Board:       Digilent Cmod A7-15T
//
// Final production architecture:
//
//   Pmod TMP2
//       |
//       | I2C
//       v
//   tmp2_i2c_reader
//       |
//       | raw 16-bit sensor word + data_valid
//       v
//   tmp2_packet_tx
//       |
//       | byte stream + valid/busy handshake
//       v
//   uart_tx
//       |
//       | 115200-baud binary UART
//       v
//   ESP32 GPIO16 / RX2
//
// Cleanup note:
//   The earlier development design also instantiated tmp2_uart_formatter and a
//   second UART transmitter to print readable text through the Cmod USB-UART.
//   That path was useful during bring-up, but it is not required by the final
//   wireless system. It has therefore been removed from this production top
//   module. The ESP32 receives the compact binary packet and performs all
//   temperature conversion and display formatting.
//
// LEDs:
//   led0 toggles after every completed TMP2 read.
//   led1 indicates that the TMP2 did not acknowledge its I2C address.
//==============================================================================

module top_cmod_tmp2_esp32(
    input  wire sysclk,
    input  wire btn0,

    inout  wire tmp2_scl,
    inout  wire tmp2_sda,

    output wire esp32_tx,

    output wire led0,
    output wire led1
);

    // Cmod button 0 is used as an active-HIGH synchronous reset.
    wire reset = btn0;

    //--------------------------------------------------------------------------
    // TMP2 measurement interface
    //--------------------------------------------------------------------------
    wire [15:0] raw_temperature;
    wire        temperature_valid;
    wire        sensor_error;

    tmp2_i2c_reader #(
        .CLK_FREQ_HZ(12_000_000),
        .I2C_FREQ_HZ(100_000),
        .SAMPLE_HZ  (1)
    ) tmp2_reader (
        .clk             (sysclk),
        .reset           (reset),
        .i2c_scl         (tmp2_scl),
        .i2c_sda         (tmp2_sda),
        .raw_temperature (raw_temperature),
        .data_valid      (temperature_valid),
        .sensor_error    (sensor_error)
    );

    //--------------------------------------------------------------------------
    // Four-byte binary packet generator
    //--------------------------------------------------------------------------
    wire [7:0] packet_uart_data;
    wire       packet_uart_valid;
    wire       packet_uart_busy;

    tmp2_packet_tx packet_transmitter (
        .clk             (sysclk),
        .reset           (reset),
        .raw_temperature (raw_temperature),
        .new_temperature (temperature_valid),
        .uart_data       (packet_uart_data),
        .uart_valid      (packet_uart_valid),
        .uart_busy       (packet_uart_busy)
    );

    //--------------------------------------------------------------------------
    // Physical UART transmitter to the ESP32
    //--------------------------------------------------------------------------
    uart_tx #(
        .CLK_FREQ_HZ(12_000_000),
        .BAUD_RATE  (115_200)
    ) esp32_uart_transmitter (
        .clk        (sysclk),
        .reset      (reset),
        .data_in    (packet_uart_data),
        .data_valid (packet_uart_valid),
        .tx         (esp32_tx),
        .busy       (packet_uart_busy)
    );

    //--------------------------------------------------------------------------
    // Status LEDs
    //--------------------------------------------------------------------------
    reg sample_toggle;

    always @(posedge sysclk) begin
        if (reset)
            sample_toggle <= 1'b0;
        else if (temperature_valid)
            sample_toggle <= ~sample_toggle;
    end

    assign led0 = sample_toggle;
    assign led1 = sensor_error;

endmodule
