`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// MECHANICAL BUTTON DEBOUNCER
//
// A physical pushbutton does not make one perfect electrical transition; its
// contacts can bounce rapidly between 0 and 1. Without filtering, one press
// can become several movement/rotation commands.
//
// The asynchronous button is first synchronized to the FPGA clock, then the
// new state must remain stable for STABLE_MS before clean_out changes.
///////////////////////////////////////////////////////////////////////////////
module button_debouncer #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer STABLE_MS   = 10
)(
    input wire clk, input wire reset, input wire noisy_in,
    output reg clean_out
);
    localparam integer STABLE_CYCLES = (CLK_FREQ_HZ / 1000) * STABLE_MS;
    reg sync0, sync1;
    reg [31:0] count;

    always @(posedge clk) begin
        if (reset) begin sync0 <= 0; sync1 <= 0; end
        else begin sync0 <= noisy_in; sync1 <= sync0; end
    end

    always @(posedge clk) begin
        if (reset) begin clean_out <= 0; count <= 0; end
        else if (sync1 == clean_out) count <= 0;
        else if (count >= STABLE_CYCLES-1) begin
            clean_out <= sync1;
            count <= 0;
        end else count <= count + 1'b1;
    end
endmodule
