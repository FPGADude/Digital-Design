`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: spi_master.v
// Project: Pmod ACL VGA Display for Basys 3
//
// Small SPI byte-transfer engine. It shifts one 8-bit word out on MOSI while 
// sampling one 8-bit word in on MISO, using a divided clock for SCLK.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// Simple SPI master used by the ADXL345 controller.
// The controller provides start/data_out; this module handles the bit-level
// clocking and returns done/data_in when the byte transfer is complete.
module spi_master #(
    parameter CLK_DIV = 50   // 100 MHz / (2*50) = 1 MHz SCLK
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,
    output reg        sclk,
    output reg        mosi,
    input  wire       miso
);

    // SPI mode 3 style for ADXL345: CPOL=1, CPHA=1.
    // Data changes on falling edge and is sampled on rising edge.

    reg [$clog2(CLK_DIV)-1:0] div_count = 0;
    reg [2:0] bit_count = 0;
    reg [7:0] shifter = 0;

    // Byte-transfer state machine.
    // When start is asserted while not busy, the module loads data_out and then
    // toggles sclk using clk_cnt. MOSI changes before the sampling edge, and
    // MISO is sampled into shift_in one bit at a time.
    always @(posedge clk) begin
        if (reset) begin
            rx_data   <= 8'd0;
            busy      <= 1'b0;
            done      <= 1'b0;
            sclk      <= 1'b1;
            mosi      <= 1'b0;
            div_count <= 0;
            bit_count <= 0;
            shifter   <= 0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy      <= 1'b1;
                sclk      <= 1'b1;
                div_count <= 0;
                bit_count <= 3'd7;
                shifter   <= tx_data;
                mosi      <= tx_data[7];
                rx_data   <= 8'd0;
            end else if (busy) begin
                if (div_count == CLK_DIV-1) begin
                    div_count <= 0;
                    sclk <= ~sclk;

                    if (sclk == 1'b1) begin
                        // Falling edge: put next MOSI bit on the line.
                        mosi <= shifter[bit_count];
                    end else begin
                        // Rising edge: sample MISO.
                        rx_data[bit_count] <= miso;
                        if (bit_count == 0) begin
                            busy <= 1'b0;
                            done <= 1'b1;
                            sclk <= 1'b1;
                        end else begin
                            bit_count <= bit_count - 1'b1;
                        end
                    end
                end else begin
                    div_count <= div_count + 1'b1;
                end
            end
        end
    end

endmodule

