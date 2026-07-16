`timescale 1ns / 1ps

//=============================================================================
// Module: clock_enable_generator
//
// Purpose:
//   Generates a single-system-clock-cycle enable pulse at a programmable rate.
//
// Operation:
//   The module counts incoming clock cycles. When the counter reaches
//   CLKS_PER_TICK - 1, the counter resets and tick is asserted for exactly
//   one rising edge of clk.
//
// Important:
//   tick is a clock-enable pulse, not a separate derived clock. All project
//   logic remains synchronous to the original FPGA system clock.
//
// Default configuration:
//   100 MHz input clock / 4,000 Hz tick rate = 25,000 clocks per tick.
//
// Parameters:
//   CLOCK_FREQ_HZ - Frequency of the system clock in hertz.
//   TICK_FREQ_HZ  - Desired number of one-cycle tick pulses per second.
//=============================================================================
module clock_enable_generator #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer TICK_FREQ_HZ  = 4_000
)(
    input wire clk,    // System clock
    input wire reset,  // Active-high synchronous reset
    output reg tick    // One-clock-cycle enable pulse
);

    // Number of system-clock cycles between successive output pulses.
    localparam integer CLKS_PER_TICK = CLOCK_FREQ_HZ / TICK_FREQ_HZ;

    // Counter width required to represent values from 0 to CLKS_PER_TICK - 1.
    // A minimum width of one bit prevents a zero-width vector for very small
    // divider values.
    localparam integer COUNTER_WIDTH =
        (CLKS_PER_TICK <= 2) ? 1 : $clog2(CLKS_PER_TICK);

    // Counts system-clock cycles between tick pulses.
    reg [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}};

    always @(posedge clk) begin
        if (reset) begin
            // Return the divider to its initial state.
            counter <= {COUNTER_WIDTH{1'b0}};
            tick <= 1'b0;
        end else if (counter == CLKS_PER_TICK - 1) begin
            // Terminal count reached: restart the count and issue one pulse.
            counter <= {COUNTER_WIDTH{1'b0}};
            tick <= 1'b1;
        end else begin
            // Continue counting and keep the enable pulse inactive.
            counter <= counter + 1'b1;
            tick <= 1'b0;
        end
    end

endmodule
