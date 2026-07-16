`timescale 1ns / 1ps

//=============================================================================
// Module: uart_tx
//
// Purpose:
//   Serializes one 8-bit data byte into a standard UART 8-N-1 frame.
//
// Frame format:
//   Idle high -> one low start bit -> eight data bits, LSB first
//   -> one high stop bit.
//
// Shift-register loading:
//   {stop bit, data_in[7:0], start bit}
//
// Parameters:
//   CLOCK_FREQ_HZ - FPGA system-clock frequency.
//   BAUD_RATE     - Desired UART baud rate.
//
// Observable outputs:
//   busy           - High during the complete 10-bit transmission.
//   bit_index      - Identifies the current UART frame bit from 0 through 9.
//   shift_register - Exposes the active frame for ILA observation.
//   baud_tick      - One-clock pulse each time the transmitter advances.
//
// Notes:
//   The CLKS_PER_BIT calculation includes half the baud rate before integer
//   division, providing nearest-integer rounding rather than truncation.
//=============================================================================
module uart_tx #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input wire clk,                  // System clock
    input wire reset,                // Active-high synchronous reset
    input wire start,                // One-clock request to transmit data_in
    input wire [7:0] data_in,        // Byte to serialize
    output wire tx,                  // UART serial output
    output reg busy,                 // High while a frame is being transmitted
    output reg [3:0] bit_index,      // Current frame bit number, 0 through 9
    output reg [9:0] shift_register, // Start, data, and stop bits
    output reg baud_tick             // One-clock pulse at each bit boundary
);

    // Number of 100 MHz system clocks assigned to one UART bit period.
    localparam integer CLKS_PER_BIT =
        (CLOCK_FREQ_HZ + (BAUD_RATE/2)) / BAUD_RATE;

    // Width needed to count from zero through CLKS_PER_BIT - 1.
    localparam integer BAUD_COUNTER_WIDTH = $clog2(CLKS_PER_BIT);

    // Counts system clocks within the current UART bit period.
    reg [BAUD_COUNTER_WIDTH-1:0] baud_counter = 0;

    // During transmission, the least-significant shift-register bit drives TX.
    // UART idles at logic high whenever no frame is active.
    assign tx = busy ? shift_register[0] : 1'b1;

    always @(posedge clk) begin
        if (reset) begin
            // Return the transmitter to the UART idle condition.
            baud_counter <= 0;
            shift_register <= 10'b1111111111;
            bit_index <= 0;
            busy <= 0;
            baud_tick <= 0;
        end else begin
            // baud_tick is asserted only on a bit-boundary clock cycle.
            baud_tick <= 0;

            if (!busy) begin
                // Keep timing and bit position reset while waiting for data.
                baud_counter <= 0;
                bit_index <= 0;

                if (start) begin
                    // Load stop bit, eight data bits, and start bit so the
                    // start bit appears first at shift_register[0].
                    shift_register <= {1'b1, data_in, 1'b0};
                    busy <= 1'b1;
                end
            end else if (baud_counter == CLKS_PER_BIT - 1) begin
                // The current bit period is complete.
                baud_counter <= 0;
                baud_tick <= 1'b1;

                if (bit_index == 9) begin
                    // Stop bit completed: return the transmitter to idle.
                    busy <= 0;
                    bit_index <= 0;
                    shift_register <= 10'b1111111111;
                end else begin
                    // Shift the next frame bit into position zero. A logic one
                    // enters at the MSB side, preserving the UART idle level.
                    shift_register <= {1'b1, shift_register[9:1]};
                    bit_index <= bit_index + 1'b1;
                end
            end else begin
                // Hold the current UART bit and continue timing its duration.
                baud_counter <= baud_counter + 1'b1;
            end
        end
    end

endmodule
