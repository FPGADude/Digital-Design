`timescale 1ns / 1ps

// ============================================================================
// Module: pir_input_conditioner
// Project: FPGA Motion Security System
//
// Purpose:
//   Safely brings the asynchronous Pmod PIR output into the 100 MHz FPGA clock
//   domain and converts a qualified motion assertion into a one-clock event.
//
// Processing stages:
//   1. Two-flip-flop synchronizer reduces metastability risk.
//   2. Stability qualification requires the synchronized input to remain at
//      its new level for QUALIFY_MS before the filtered level changes.
//   3. Rising-edge detection generates motion_event for the security FSM.
//
// Outputs:
//   pir_level    - qualified current PIR output level.
//   motion_event - one-clock pulse when pir_level first changes from 0 to 1.
// ============================================================================
module pir_input_conditioner #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int QUALIFY_MS  = 40
)(
    input  logic clk,
    input  logic pir_async,
    output logic pir_level,
    output logic motion_event
);

    // Translate the required stable interval into system-clock cycles.
    localparam int QUALIFY_CYCLES = (CLK_FREQ_HZ / 1000) * QUALIFY_MS;
    localparam int COUNTER_WIDTH  = $clog2(QUALIFY_CYCLES);

    // Synchronizer, qualified level, delayed level, and stability counter.
    logic sync_1 = 1'b0;
    logic sync_2 = 1'b0;
    logic filtered = 1'b0;
    logic delayed  = 1'b0;
    logic [COUNTER_WIDTH-1:0] counter = '0;

    // Synchronize, qualify changes, and generate a rising-edge event pulse.
    always_ff @(posedge clk) begin
        sync_1 <= pir_async;
        sync_2 <= sync_1;

        if (sync_2 == filtered) begin
            counter <= '0;
        end
        else if (counter == QUALIFY_CYCLES - 1) begin
            counter  <= '0;
            filtered <= sync_2;
        end
        else begin
            counter <= counter + 1'b1;
        end

        delayed      <= filtered;
        motion_event <= filtered & ~delayed;
    end

    // Export the stable sensor level separately from the one-cycle event.
    assign pir_level = filtered;

endmodule
