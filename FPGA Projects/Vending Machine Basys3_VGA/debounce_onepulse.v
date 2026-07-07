// ============================================================================
// debounce_onepulse.v
// ----------------------------------------------------------------------------
// Debounces a mechanical pushbutton and generates a single-clock pulse on each
// clean rising edge.
//
// Mechanical buttons bounce for a few milliseconds.  Without debouncing, one
// press can look like many presses to the FPGA.  This module first synchronizes
// the asynchronous button input into the 100 MHz system clock domain, waits for
// the signal to remain stable for DEBOUNCE_MS, and then produces:
//
//   clean : debounced button level
//   pulse : one 100 MHz clock cycle when clean rises from 0 to 1
//
// The vending machine uses one instance for each Basys 3 button.
// ============================================================================
`timescale 1ns / 1ps

module debounce_onepulse #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 10
)(
    input  wire clk,
    input  wire reset,
    input  wire noisy,
    output reg  clean,
    output reg  pulse
);

    localparam integer COUNT_MAX = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam integer COUNT_W   = 20;

    reg sync0, sync1;
    reg stable_state;
    reg [COUNT_W-1:0] count;
    reg clean_d;

    always @(posedge clk) begin
        if (reset) begin
            sync0        <= 1'b0;
            sync1        <= 1'b0;
            stable_state <= 1'b0;
            clean        <= 1'b0;
            clean_d      <= 1'b0;
            pulse        <= 1'b0;
            count        <= {COUNT_W{1'b0}};
        end else begin
            sync0 <= noisy;
            sync1 <= sync0;

            if (sync1 == stable_state) begin
                count <= {COUNT_W{1'b0}};
            end else begin
                if (count >= COUNT_MAX[COUNT_W-1:0]) begin
                    stable_state <= sync1;
                    clean        <= sync1;
                    count        <= {COUNT_W{1'b0}};
                end else begin
                    count <= count + 1'b1;
                end
            end

            clean_d <= clean;
            pulse   <= clean & ~clean_d;
        end
    end
endmodule
