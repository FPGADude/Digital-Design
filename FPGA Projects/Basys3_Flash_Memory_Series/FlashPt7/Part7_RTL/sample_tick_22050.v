`timescale 1ns / 1ps

// ============================================================================
// 22.05 kHz Audio Sample Tick Generator
//
// 100 MHz is not an integer multiple of 22,050 Hz, so a simple integer clock
// divider would introduce sample-rate error. This accumulator implements a
// fractional divider: 22,050 is added every 100 MHz clock, and a one-clock
// tick is emitted whenever the accumulator crosses 100,000,000.
//
// The intervals vary by at most one 100 MHz clock, while the long-term average
// sample rate is exactly 22,050 samples per second.
// ============================================================================
module sample_tick_22050 (
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    reg [26:0] accumulator;

    always @(posedge clk) begin
        if (reset) begin
            accumulator <= 27'd0;
            tick        <= 1'b0;
        end else begin
            // tick is asserted for one 100 MHz clock only.
            tick <= 1'b0;

            if (accumulator >= (100_000_000 - 22_050)) begin
                accumulator <= accumulator + 22_050 - 100_000_000;
                tick        <= 1'b1;
            end else begin
                accumulator <= accumulator + 22_050;
            end
        end
    end

endmodule
