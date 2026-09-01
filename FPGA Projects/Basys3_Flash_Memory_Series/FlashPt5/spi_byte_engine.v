`timescale 1ns / 1ps

// ============================================================================
// SPI Mode-0 Byte Engine
//
// Sends and receives one SPI byte at a time.
//
// Mode 0:
//   CPOL = 0 : SCLK idles LOW
//   CPHA = 0 : MISO is sampled on the rising edge
//
// With a 100 MHz FPGA clock and HALF_PERIOD_CLKS = 50,
// the generated SPI clock is 1 MHz.
// ============================================================================

module spi_mode0_byte_engine #(
    parameter integer HALF_PERIOD_CLKS = 50
)(
    input  wire       clk,
    input  wire       reset,

    input  wire       start,
    input  wire [7:0] tx_byte,
    input  wire       miso,

    output reg        sck,
    output reg        mosi,
    output reg [7:0]  rx_byte,

    output reg        busy,
    output reg        done
);

    integer half_count;

    reg [2:0] bit_index;
    reg [7:0] rx_shift;


    always @(posedge clk) begin

        if (reset) begin

            sck        <= 1'b0;
            mosi       <= 1'b0;
            rx_byte    <= 8'h00;

            busy       <= 1'b0;
            done       <= 1'b0;

            half_count <= 0;
            bit_index  <= 3'd7;
            rx_shift   <= 8'h00;

        end else begin

            // done is a one-clock pulse.
            done <= 1'b0;


            // ------------------------------------------------------------
            // Idle / start a new byte
            // ------------------------------------------------------------
            if (!busy) begin

                sck <= 1'b0;

                if (start) begin

                    busy       <= 1'b1;
                    half_count <= 0;
                    bit_index  <= 3'd7;
                    rx_shift   <= 8'h00;

                    // Present the MSB before the first rising edge.
                    mosi       <= tx_byte[7];

                end

            end else begin

                // --------------------------------------------------------
                // Generate one half-period of SCLK.
                // --------------------------------------------------------
                if (half_count >= HALF_PERIOD_CLKS - 1) begin

                    half_count <= 0;


                    // ----------------------------------------------------
                    // Rising edge: sample MISO.
                    // ----------------------------------------------------
                    if (sck == 1'b0) begin

                        sck <= 1'b1;

                        rx_shift[bit_index] <= miso;


                    // ----------------------------------------------------
                    // Falling edge: prepare the next MOSI bit.
                    // ----------------------------------------------------
                    end else begin

                        sck <= 1'b0;

                        if (bit_index == 3'd0) begin

                            busy    <= 1'b0;
                            done    <= 1'b1;
                            rx_byte <= rx_shift;
                            mosi    <= 1'b0;

                        end else begin

                            bit_index <= bit_index - 1'b1;
                            mosi      <= tx_byte[bit_index - 1'b1];

                        end
                    end

                end else begin

                    half_count <= half_count + 1;

                end
            end
        end
    end

endmodule
