`timescale 1ns / 1ps

// ============================================================================
// Module: button_onepulse
// Project: FPGA Motion Security System
//
// Purpose:
//   Converts a mechanical Basys 3 pushbutton into a clean, single-clock pulse.
//
// Processing stages:
//   1. Two flip-flops synchronize the asynchronous button input.
//   2. A stability counter rejects mechanical contact bounce.
//   3. Rising-edge detection produces exactly one 100 MHz clock pulse.
//
// Parameters:
//   CLK_FREQ_HZ - FPGA system clock frequency.
//   DEBOUNCE_MS - required stable time before accepting a new button level.
// ============================================================================
module button_onepulse #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int DEBOUNCE_MS = 20
)(
    input  logic clk,
    input  logic button_in,
    output logic pulse_out
);

    // Convert the requested debounce interval into clock cycles.
    localparam int STABLE_CYCLES = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam int COUNTER_WIDTH = $clog2(STABLE_CYCLES);

    // Synchronizer, accepted level, delayed level, and debounce counter.
    logic sync_1 = 1'b0;
    logic sync_2 = 1'b0;
    logic debounced = 1'b0;
    logic delayed   = 1'b0;
    logic [COUNTER_WIDTH-1:0] counter = '0;

    // Synchronization, debounce qualification, and rising-edge detection.
    always_ff @(posedge clk) begin
        sync_1 <= button_in;
        sync_2 <= sync_1;

        if (sync_2 == debounced) begin
            counter <= '0;
        end
        else if (counter == STABLE_CYCLES - 1) begin
            counter   <= '0;
            debounced <= sync_2;
        end
        else begin
            counter <= counter + 1'b1;
        end

        delayed   <= debounced;
        pulse_out <= debounced & ~delayed;
    end

endmodule
