`timescale 1ns / 1ps

// ============================================================
// Module: uart_tx
// Project: Basys 3 4x4 Keypad + LEDs + UART
//
// Purpose:
//   This module sends one 8-bit byte over a UART transmit line.
//   For this keypad project, the byte is normally an ASCII character
//   such as "1", "5", "A", "*", or "#".
//
// UART format:
//   Standard 8-N-1 serial framing:
//     - 1 start bit
//     - 8 data bits
//     - No parity bit
//     - 1 stop bit
//
// Line behavior:
//   - UART TX idles high.
//   - A transmission begins with one low start bit.
//   - The 8 data bits are sent least-significant bit first.
//   - The transmission ends with one high stop bit.
//
// Handshake:
//   - Pulse send high for one clk cycle while busy is low.
//   - data_in is latched when send is accepted.
//   - busy stays high until the full UART frame has been transmitted.
//
// Default baud rate:
//   9600 baud using the Basys 3 100 MHz system clock.
//
// PC serial terminal settings:
//   9600 baud, 8 data bits, no parity, 1 stop bit, no flow control
// ============================================================

module uart_tx(
    input  wire       clk,        // 100 MHz Basys 3 system clock
    input  wire       reset,      // active-high synchronous reset

    input  wire [7:0] data_in,    // byte to transmit, usually an ASCII character
    input  wire       send,       // one-clock pulse requesting a transmission

    output reg        tx,         // UART transmit output pin
    output reg        busy        // high while a UART frame is being transmitted
);

    // ------------------------------------------------------------
    // Baud-rate timing
    // ------------------------------------------------------------
    // For 9600 baud, each bit lasts:
    //
    //   1 / 9600 = 104.166... us
    //
    // With a 100 MHz clock, one clock cycle is 10 ns, so the number
    // of clock cycles per UART bit is:
    //
    //   100,000,000 / 9600 = 10416.666...
    //
    // Rounding to 10417 is accurate enough for normal UART reception.
    // ------------------------------------------------------------
    localparam CLKS_PER_BIT = 10417;

    // UART transmitter states.
    localparam IDLE  = 2'd0;      // wait for send request
    localparam START = 2'd1;      // transmit start bit
    localparam DATA  = 2'd2;      // transmit 8 data bits
    localparam STOP  = 2'd3;      // transmit stop bit

    // Current transmitter state.
    reg [1:0] state;

    // Counts clock cycles within the current UART bit period.
    reg [13:0] clk_count;

    // Selects which data bit is currently being transmitted.
    // UART data is sent LSB first, so this counts from 0 to 7.
    reg [2:0] bit_index;

    // Local copy of data_in. The byte is latched at the start of the
    // transmission so data_in can safely change while the byte is sent.
    reg [7:0] tx_data;

    always @(posedge clk) begin
        if (reset) begin
            // Reset the transmitter to the idle-high UART state.
            state     <= IDLE;
            clk_count <= 14'd0;
            bit_index <= 3'd0;
            tx_data   <= 8'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    // UART line is high while idle.
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 14'd0;
                    bit_index <= 3'd0;

                    // Accept a new byte only in IDLE. The top-level
                    // module also gates send with !busy.
                    if (send) begin
                        tx_data <= data_in;
                        busy    <= 1'b1;
                        state   <= START;
                    end
                end

                START: begin
                    // Start bit is always logic 0.
                    tx   <= 1'b0;
                    busy <= 1'b1;

                    // Hold the start bit for exactly one bit period.
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 14'd0;
                        state     <= DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    // Send the current data bit. UART sends LSB first.
                    tx   <= tx_data[bit_index];
                    busy <= 1'b1;

                    // Hold each data bit for one full bit period.
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 14'd0;

                        if (bit_index == 3'd7) begin
                            // All 8 bits have been sent. Move to stop bit.
                            bit_index <= 3'd0;
                            state     <= STOP;
                        end else begin
                            // Move to the next data bit.
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    // Stop bit is logic 1, same as the idle level.
                    tx   <= 1'b1;
                    busy <= 1'b1;

                    // Hold the stop bit for one bit period, then return
                    // to idle so another byte can be transmitted.
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 14'd0;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    // Safety recovery for impossible state values.
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
